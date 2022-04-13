{------------------------------------------------------------------------------}
{ 单元名称: PixelDIB.pas                                                       }
{                                                                              }
{ 单元作者: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ 创建日期: 2005-01-02 20:30:00                                                }
{                                                                              }
{ 功能介绍:                                                                    }
{   传奇2 图片文件读取单元                                                     }
{                                                                              }
{ 使用说明:                                                                    }
{                                                                              }
{ 更新历史:                                                                    }
{                                                                              }
{ 尚存问题:                                                                    }
{                                                                              }
{------------------------------------------------------------------------------}
unit PixelDIB;

interface

uses SysUtils, Windows;

type

  // 256色调色板
  PRGBQuads = ^TRGBQuads;
  TRGBQuads = array[0..255] of RGBQUAD;

  TPixelDIB = class(TObject)
  private
    FWidth: LongInt;
    FHeight: LongInt;
    FBitsPerPixel: Word;
    FPBits: Pointer;
    FPColorTable: PRGBQuads;
    FBytesPerPixel: Byte;
    procedure SetWidth(const Value: LongInt);
    procedure SetBitsPerPixel(const Value: Word);
    procedure SetHeight(const Value: LongInt);
    procedure SetPColorTable(const Value: PRGBQuads);
    procedure SetPBits(const Value: Pointer);
    procedure SetBytesPerPixel(const Value: Byte);
  public
    constructor Create(AWidth, AHeight: LongInt; ABytesPerPixel: Byte);
    destructor Destroy; override;
    procedure SaveToFile(const FileName: string);

    property Width: LongInt read FWidth write SetWidth;
    property Height: LongInt read FHeight write SetHeight;
    property BitsPerPixel: Word read FBitsPerPixel write SetBitsPerPixel;
    property PColorTable: PRGBQuads read FPColorTable write SetPColorTable;
    property PBits: Pointer read FPBits write SetPBits;
    property BytesPerPixel: Byte read FBytesPerPixel write SetBytesPerPixel;
  end;

implementation

{ TDIB }

constructor TPixelDIB.Create(AWidth, AHeight: Integer; ABytesPerPixel: Byte);
begin
  FWidth := AWidth;
  FHeight := AHeight;
  FBytesPerPixel := ABytesPerPixel;

  if (ABytesPerPixel < 1) or (ABytesPerPixel > 3) then
    raise Exception.Create('Error');

end;

destructor TPixelDIB.Destroy;
begin
  inherited;
end;

procedure TPixelDIB.SaveToFile(const FileName: string);
var
  FileHeader: BITMAPFILEHEADER;
  InfoHeader: BITMAPINFOHEADER;
  ColorTableSize: Integer;

  F: file;
begin
  if FBytesPerPixel = 1 then
    ColorTableSize := SizeOf(RGBQuad) * 256 else
    ColorTableSize := 0;

  FileHeader.bfType := MakeWord(Ord('B'), Ord('M'));
  FileHeader.bfSize := SizeOf(FileHeader) + SizeOf(InfoHeader) + ColorTableSize +
    FWidth * FHeight * FBytesPerPixel;
  FileHeader.bfReserved1 := 0;
  FileHeader.bfReserved2 := 0;
  FileHeader.bfOffBits := SizeOf(FileHeader) + SizeOf(InfoHeader) + ColorTableSize;

  InfoHeader.biSize := SizeOf(InfoHeader);
  InfoHeader.biWidth := FWidth;
  InfoHeader.biHeight := FHeight;
  InfoHeader.biPlanes := 1;
  InfoHeader.biBitCount := 8 * FBytesPerPixel;
  InfoHeader.biCompression := 0;
  InfoHeader.biSizeImage := 0;
  InfoHeader.biXPelsPerMeter := 0;
  InfoHeader.biYPelsPerMeter := 0;
  InfoHeader.biClrUsed := 0;
  InfoHeader.biClrImportant := 0;

  FileMode := fmOpenWrite;
  AssignFile(F, FileName);
  Rewrite(F, 1);

  try
    BlockWrite(F, FileHeader, SizeOf(FileHeader));
    BlockWrite(F, InfoHeader, SizeOf(InfoHeader));
    if ColorTableSize > 0 then
      BlockWrite(F, FPColorTable^, ColorTableSize);
    BlockWrite(F, FPBits^, FBytesPerPixel * FWidth * FHeight);
  finally
    CloseFile(F);
  end;
end;

procedure TPixelDIB.SetBitsPerPixel(const Value: Word);
begin
  FBitsPerPixel := Value;
end;

procedure TPixelDIB.SetBytesPerPixel(const Value: Byte);
begin
  FBytesPerPixel := Value;
end;

procedure TPixelDIB.SetHeight(const Value: LongInt);
begin
  FHeight := Value;
end;

procedure TPixelDIB.SetPBits(const Value: Pointer);
begin
  FPBits := Value;
end;

procedure TPixelDIB.SetPColorTable(const Value: PRGBQuads);
begin
  FPColorTable := Value;
end;

procedure TPixelDIB.SetWidth(const Value: LongInt);
begin
  FWidth := Value;
end;

end.
