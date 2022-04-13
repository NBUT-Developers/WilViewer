{------------------------------------------------------------------------------}
{ ��Ԫ����: MirWil.pas                                                         }
{                                                                              }
{ ��Ԫ����: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ ��������: 2005-01-02 20:30:00                                                }
{                                                                              }
{ ���ܽ���:                                                                    }
{   ����2 Wil �ļ���ȡ��Ԫ                                                     }
{                                                                              }
{ ʹ��˵��:                                                                    }
{                                                                              }
{   WIL λͼ�ļ�: �� �ļ�ͷ+��ɫ��(256ɫ)+(TImageInfo+λͼ Bits)*N�� ���      }
{   WIX �����ļ�: ʵ���Ͼ���һ���ļ�ͷ+ָ������, ָ��ָ�� TImageInfo �ṹ      }
{                                                                              }
{ ������ʷ:                                                                    }
{                                                                              }
{ �д�����:                                                                    }
{                                                                              }
{    WIL �ĵ�ɫ���ǲ��Ƕ���һ���ģ�����ǣ������ʡ��                          }
{    ע�⣺ WIL �����ݸ�ʽ���嶼��û�� pack �� record                          }
{                                                                              }
{    Weapon.wix ��������: �����ļ�ͷ���õ�ͼƬ����Ϊ 40856, ʵ���ܶ���������   }
{      Ϊ 40855, ����Դ��������������е�ԭ������û�м��ɶ���������.         }
{      ������Ҫ�ؽ�����. Ŀǰ�Ľ���������� LoadIndexFile �и��ݶ�����ʵ����   }
{      �ݶ� FImageCount ��������.                                              }
{                                                                              }
{------------------------------------------------------------------------------}
unit MirWil;

interface

uses
  SysUtils, Windows, DirectDraw, Assist, AdvDraw;

{------------------------------------------------------------------------------}
// WIL ��������
{------------------------------------------------------------------------------}
var
  UseDIBSurface: Boolean = True;  // �Ƿ��ڴ��� WIL Surface ʱʹ�� DIB ����
                                  // ���ֱ��ʹ�� WIL �ļ��е�λͼ Bits �����������ɫ
                                  // ��ʾ����ȷ���ڴ���Դ�����еĽ��Ҳ����ˡ�

{------------------------------------------------------------------------------}
// WIL �ļ���ʽ����
{------------------------------------------------------------------------------}
type
  // WIL �ļ�ͷ��ʽ (56Byte)
  PImageHeader = ^TImageHeader;
  TImageHeader = record
    Title       : string[40];   // ���ļ����� 'WEMADE Entertainment inc.'
    ImageCount  : Integer;      // ͼƬ����
    ColorCount  : Integer;      // ɫ������
    PaletteSize : Integer;      // ��ɫ���С
  end;

  // WIL ͼ����Ϣ (ע��, û�� pack record)
  PImageInfo = ^TImageInfo;
  TImageInfo = record
    Width  : SmallInt;   // λͼ���
    Height : SmallInt;   // λͼ�߶�
    PX     : SmallInt;   // δ֪,�ƺ�����Ҳ��
    PY     : SmallInt;   // δ֪,�ƺ�����Ҳ��
    Bits   : PByte;      // δʹ��, ʵ�ʴ��ļ�����ʱ,Ҫ�ٶ� 4 �ֽ�, ���Ǵ�ֵδ��
  end;

  // WIX �����ļ�ͷ��ʽ
  PIndexHeader = ^TIndexHeader;
  TIndexHeader = record
    Title      : string[40];    // 'WEMADE Entertainment inc.'
    IndexCount : integer;       // ��������
  end;

{------------------------------------------------------------------------------}
// TWilFile class
{------------------------------------------------------------------------------}

  // TWilFile
  TWilFile = class(TObject)
  private
    FFileName: string;            // WIL �ļ���
    FFileHandle: THandle;         // �ļ����
    FFileMapping: THandle;        // �ļ�ӳ����
    FFilePointer: Pointer;        // �ļ�����ָ��(ʹ���ļ�ӳ��)

    FIndexArr: array of Integer;  // ͼƬ��������(�� WIX �ļ��ж�ȡ)
    FMainColorTable: PRGBQuads;   // ��ɫ��ָ��(ֱ��ָ�� WIL �ļ���)
    FImageCount: Integer;         // ͼƬ����
    FBitmapInfo: TBitmapInfo256;  // λͼ��Ϣͷ��(���� SetDIBitsToDevice)

    FDDSurfaceDesc2: TDDSurfaceDesc2;
    FSurfaces: array of IDirectDrawSurface7;
    FMainDirectDraw: IDirectDraw7;

    procedure LoadIndexFile;      // ���� WIX �ļ��� IndexArr ��
    procedure CreateMapView;      // ���� WIL �ļ�ӳ��
    function GetSurfaces(AIndex: Integer): IDirectDrawSurface7;
    function GetImageInfo(AIndex: Integer): PImageInfo;

    public
    MainColorTablebak:TRGBQuads;
    IndexArrbak:array of integer;
    //����wil,wix�ļ�ͷ�ã�
    imgheadbak:TImageHeader;
    idxheadbak:TIndexHeader;
  //  customimgcount:integer;

    FilePointersaved: pointer;
    constructor Create(const AFileName: string; ADirectDraw: IDirectDraw7 = nil);
    destructor Destroy; override;

    // Draw: �� Index λ�õ�ͼƬ������ Surface �� X, Y λ��
    procedure Draw(Index: Integer; DstSurf: IDirectDrawSurface7; X, Y,
      DstWidth, DstHeight: Integer; Transparent: Boolean);
    // DrawEx: �� Index λ�õ�ͼƬ������ Surface �� X, Y λ��, ���� Image ��ƫ��λ��
    procedure DrawEx(Index: Integer; DstSurf: IDirectDrawSurface7; X, Y,
      DstWidth, DstHeight: Integer; Transparent: Boolean);


    // BitBlt: �� Index λ�õ�ͼƬ������ DC �� X, Y λ��
    procedure BitBlt(Index: Integer; DC: HDC; X, Y: Integer); 
    // StretchBlt: �����ŷ�ʽ��ͼƬ������ DC
    procedure StretchBlt(Index: Integer; DC: HDC; X, Y, Width, Height: Integer;
      ROP: Cardinal);
    // SaveToFile: ������λ�õ�ͼƬ����Ϊ BMP �ļ�
    procedure SaveToFile(Index: Integer; const FileName: string; const FiletxtName:string);
    // �Ѵ򿪵� WIL �ļ���
    property FileName: string read FFileName;
  //  FFilePointer: Pointer;        // �ļ�����ָ��(ʹ���ļ�ӳ��)
    // ����ɫ��ָ��

    property MainColorTable: PRGBQuads read FMainColorTable;
    // IDirectDraw7, ���ڴ��� Surfaces ����, �����ָ��Ҳ����ʹ�� BitBlt
    property MainDirectDraw: IDirectDraw7 read FMainDirectDraw write FMainDirectDraw;
    // ͼƬ����
    property ImageCount: Integer read FImageCount;
    // ͼƬ�� Surface
    property Surfaces[AIndex: Integer]: IDirectDrawSurface7 read GetSurfaces;
    // ͼƬ����Ϣ
    property ImageInfo[AIndex: Integer]: PImageInfo read GetImageInfo;
  end;


implementation

{ TWilFile }

constructor TWilFile.Create(const AFileName: string; ADirectDraw: IDirectDraw7 = nil);
begin
  FFileName := AFileName;

  FMainDirectDraw := ADirectDraw;
  
  // ����ͼƬ�����ļ�
  LoadIndexFile;

  // ���� WIL �ļ���ӳ��
  CreateMapView;

  // ���� WIL �ļ�ͷ����

  // �����ļ�ͷ�е�ͼƬ����, (ͼƬ�������� LoadIndexFile ����, ������
  // �� Weapon.wix �е����������µ��޸�, savetime 2005.1.3)
  // FImageCount := PImageHeader(FFilePointer)^.ImageCount;

  // ���� FSurfaces �����С
  SetLength(FSurfaces, FImageCount);
  // �����ɫ��ָ��
  FMainColorTable := IncPointer(FFilePointer, SizeOf(TImageHeader));
   //�����ɫ���Ա���
  MainColorTablebak:=PRGBQuads(MainColorTable)^;

  // ����λͼ�̶���Ϣ������ÿ�� Blt ʱ����
  // TODO: λͼ�ļ�ͷ���ɽ�һ��ѹ��
  with FBitmapInfo.bmiHeader do
  begin
    biSize := SizeOf(TBitmapInfoHeader);
    // ������ɶ���ͼƬ������
    // biWidth := ImagePos^.Width;
    // biHeight := ImagePos^.Height;
    biPlanes := 1;
    biBitCount := 8;
    biCompression := BI_RGB;    // ע�⣬����ֻʹ��δѹ������
    biSizeImage := 0;           // ѹ��ʱ����Ҫ biSizeImage
    biXPelsPerMeter := 0;
    biYPelsPerMeter := 0;
    biClrUsed := 0;
    biClrImportant := 0;
  end;

  // ��ʼ�� FDDSurfaceDesc2, ����ÿ�δ��� Surface ʱ��ʼ��
  // �˴����� FillChar(FDDSurfaceDesc2)
  FDDSurfaceDesc2.dwSize := SizeOf(FDDSurfaceDesc2);
  FDDSurfaceDesc2.dwFlags := DDSD_CAPS or DDSD_WIDTH or DDSD_HEIGHT;
  FDDSurfaceDesc2.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_SYSTEMMEMORY;



end;

procedure TWilFile.CreateMapView;
var
  ContentFileName: string;
  customimgcount:integer;
begin
  // WIL �ļ���
  ContentFileName := FFileName + '.WIL';

  // �� WIL �ļ�
  FFileHandle := CreateFile(PChar(ContentFileName), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_RANDOM_ACCESS, 0);

  if FFileHandle = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('���ļ� "%s" ʧ��!', [ContentFileName]);

  // �����ļ�ӳ�����
  FFileMapping := CreateFileMapping(FFileHandle, nil, PAGE_READONLY, 0, 0, nil);

  if FFileMapping = 0 then
  begin
    CloseHandle(FFileHandle);
    raise Exception.CreateFmt('�����ļ�ӳ�� "%s" ʧ��!', [ContentFileName]);
  end;

  // ӳ���ļ����ڴ�
  FFilePointer := MapViewOfFile(FFileMapping, FILE_MAP_READ, 0, 0, 0);
  //��������ָ�빩�Ժ�ʹ��
  if FFilePointer <> nil then
  FilePointersaved:=FFilePointer



  else begin
    CloseHandle(FFileMapping);
    CloseHandle(FFileHandle);
    raise Exception.CreateFmt('ӳ���ļ� "%s" ʧ��!', [ContentFileName]);
  end;

  //,,���⴦�����:����imgheader��һЩ��Ա��imgheadbak������ݽṹ
  imgheadbak.Title:=PImageHeader(FFilePointer)^.Title;
  imgheadbak.ColorCount:=PImageHeader(FFilePointer)^.ColorCount;
  imgheadbak.PaletteSize:=PImageHeader(FFilePointer)^.PaletteSize;
  imgheadbak.ImageCount:=customimgcount;

end;

destructor TWilFile.Destroy;
var
  I: Integer;
begin
  // ��������ļ�����
  SetLength(FIndexArr, 0);
  SetLength(IndexArrbak, 0);

  // ��� FSurfaces ����
  for I := 0 to Length(FSurfaces) - 1 do
    FSurfaces[I] := nil;
  SetLength(FSurfaces, 0);

  // ��� FMainDirectDraw
  FMainDirectDraw := nil;

  // �ر��ļ�ӳ�估��ؾ��
  UnmapViewOfFile(FFilePointer);
  CloseHandle(FFileMapping);
  CloseHandle(FFileHandle);

  inherited;
end;

procedure TWilFile.LoadIndexFile;
var
  F: file;
  IdxHeader: TIndexHeader;
  NumRead: Integer; //ʵ�ʶ�����ͼƬ��
  IndexFileName: string;
  customidxcount: integer;//customimgcount:integer; //
begin
  // �����ļ���
  IndexFileName := FFileName + '.WIX';

  // �������ļ�
  FileMode := fmOpenRead;
  AssignFile(F, IndexFileName);
  Reset(F, 1);
  try
    // �������ļ�ͷ,,����NumRead
    BlockRead(F, IdxHeader, SizeOf(IdxHeader), NumRead);
    if NumRead <> SizeOf(IdxHeader) then
      raise Exception.CreateFmt('"%s" �ļ�ͷ����!', [IndexFileName]);

    // �������������С
    SetLength(FIndexArr, IdxHeader.IndexCount);
    SetLength(IndexArrbak, IdxHeader.IndexCount);

    // �������ڴ�������   ����PInteger(FIndexArr)^
    BlockRead(F, PInteger(FIndexArr)^, IdxHeader.IndexCount * 4, NumRead);

          //,,���⴦�����2:����idxheader��һЩ��Ա
     idxheadbak.Title:=idxheader.Title;        //�ǵ��ͷ�idxheadbak����ṹŶ
     idxheadbak.IndexCount:=customidxcount;

    //,,���⴦�����3:����indexarrbak,,indexarrbak�������鿪ͷ
     PInteger(IndexArrbak)^:=PInteger(FIndexArr)^;

    if NumRead = IdxHeader.IndexCount * 4 then
      FImageCount := IdxHeader.IndexCount
    else
      // ���� Weapon.wix �������ļ�ͷ�е�ͼƬ����ʵ�ʵ�����������ͬ, Ϊ�˼���,
      // ���������쳣, ��ϸ��������ļ����ϱ�ע.
      // raise Exception.CreateFmt('"%s" �ļ����ݴ���!', [IndexFileName]);
      FImageCount := NumRead div 4;
  finally
    CloseFile(F);
  end;
end;

procedure TWilFile.BitBlt(Index: Integer; DC: HDC; X, Y: Integer);
var
  ImageInfo: PImageInfo;
  PBits: Pointer;
begin
  // ��� Index �Ƿ�Ϸ�
  if (Index < 0) or (Index >= FImageCount) then
    raise Exception.Create('TWilFile.BitBlt ���鳬��!');

  // ��λ��ͼƬλ��
  ImageInfo := IncPointer(FFilePointer, FIndexArr[Index]);

  // ����λͼ��С
  with FBitmapInfo.bmiHeader do
  begin
    biWidth := ImageInfo^.Width;
    biHeight := ImageInfo^.Height;
  end;

  // ����ɫ��
  Move(MainColorTable^, FBitmapInfo.bmiColors, SizeOf(FBitMapInfo.bmiColors));

  // PBits ָ��λͼ�� Bits
  PBits := IncPointer(ImageInfo, SizeOf(TImageInfo) - 4);

  // ֱ�ӽ� DIB Bits д���豸����
  SetDIBitsToDevice(DC, X, Y, ImageInfo^.Width, ImageInfo^.Height, 0, 0, 0,
    ImageInfo^.Height, PBits, PBitmapInfo(PBitmapInfo256(@FBitmapInfo))^,
    DIB_RGB_COLORS);
end;

procedure TWilFile.StretchBlt(Index: Integer; DC: HDC; X, Y, Width, Height: Integer;
  ROP: Cardinal);
var
  ImageInfo: PImageInfo;
  PBits: Pointer;
begin
  // ��� Index �Ƿ�Ϸ�
  if (Index < 0) or (Index >= FImageCount) then
    raise Exception.Create('TWilFile.StretchBlt ���鳬��!');

  // ��λ��ͼƬλ��
  ImageInfo := IncPointer(FFilePointer, FIndexArr[Index]);

  // ����λͼ��С
  with FBitmapInfo.bmiHeader do
  begin
    biWidth := ImageInfo^.Width;
    biHeight := ImageInfo^.Height;
  end;
  
  // ����ɫ��
  Move(MainColorTable^, FBitmapInfo.bmiColors, SizeOf(FBitMapInfo.bmiColors));

  // PBits ָ��λͼ�� Bits
  PBits := IncPointer(ImageInfo, SizeOf(TImageInfo) - 4);

  // ���ŷ�ʽ�� DIB Bits д���豸����
  StretchDIBits(DC, X, Y, Width, Height, 0, 0, ImageInfo^.Width, ImageInfo^.Height,
    PBits, PBitmapInfo(PBitmapInfo256(@FBitmapInfo))^, DIB_RGB_COLORS, ROP);
end;

function TWilFile.GetSurfaces(AIndex: Integer): IDirectDrawSurface7;
var
  InfoPtr: PImageInfo;    // ͼ����Ϣ, ʹ����ʱ�������ӿ��ٶ�
  ColorKey: TDDColorKey;  // ͸��ɫֵ
  DDSD: TDDSurfaceDesc2;  // ���� Surface.Lock
  Y: Integer;             // Surface ����ֵ
  PBits: PByte;           // ָ�� Bits ��ָ��
  DC: HDC;                // ���� Surface.GetDC
begin
  // ��� AIndex �Ƿ�Ϸ�
  if (AIndex < 0) or (AIndex >= FImageCount) then
    raise Exception.Create('TWilFile.GetSurfaces ���鳬��!');

  // ��� MainDirectDraw �Ƿ����
  if FMainDirectDraw = nil then
    raise Exception.Create('����ָ�� MainDirectDraw!');

  // �������λ�õ� FSurface �Ѿ�����, ��ֱ�ӷ��ظ�ֵ
  Result := FSurfaces[AIndex];
  if FSurfaces[AIndex] <> nil then Exit;

  // ���򴴽��µ� FSurface[AIndex]
  InfoPtr := ImageInfo[AIndex];

  FDDSurfaceDesc2.dwWidth := InfoPtr^.Width;
  FDDSurfaceDesc2.dwHeight := InfoPtr^.Height;

  if FMainDirectDraw.CreateSurface(FDDSurfaceDesc2, FSurfaces[AIndex], nil) <> DD_OK then
    raise Exception.Create('���ܴ��� WIL Surface!');

  if UseDIBSurface then // д�����λͼ����֮һ��ʹ�� DC, BitBlt
  begin
    if FSurfaces[AIndex].GetDC(DC) = DD_OK then
    begin
      SelectObject(DC, NULL_BRUSH);
      Rectangle(DC, 0, 0, ImageInfo[AIndex]^.Width, ImageInfo[AIndex]^.Height);
      BitBlt(AIndex, DC, 0, 0);
      FSurfaces[AIndex].ReleaseDC(DC);
    end
    else
    begin   // �����ȡ DC ʧ��, ��رյ�ǰ FSurface
      FSurfaces[AIndex] := nil;
      Exit;
    end;
  end
  else // д�����λͼ����֮����ֱ�ӿ��� WIL Bits ������ Surface
  begin
    DDSD.dwSize := SizeOf(DDSD);
    if FSurfaces[AIndex].Lock(nil, DDSD, DDLOCK_WAIT, 0) <> DD_OK then Exit;
    // ����Ƚ���֣���Ҫ��λͼ�����һ��д������һ�У�������
    PBits := IncPointer(InfoPtr, (SizeOf(TImageInfo) - 4) +
      ((InfoPtr^.Height - 1) * InfoPtr^.Width));
    try
      for Y := 0 to InfoPtr^.Height - 1 do
      begin
        Move(PBits^, DDSD.lpSurface^, InfoPtr^.Width);
        Inc(PByte(DDSD.lpSurface), DDSD.lPitch);
        Dec(PBits, InfoPtr^.Width);
      end;
    finally
      FSurfaces[AIndex].Unlock(nil);
    end;
  end;

  // ���� ColorKey (��ɫ)
  ColorKey.dwColorSpaceLowValue := 0;
  ColorKey.dwColorSpaceHighValue := 0;
  FSurfaces[AIndex].SetColorKey(DDCKEY_SRCBLT, @ColorKey);

  // ���ص�ǰ Surface
  Result := FSurfaces[AIndex];
end;

function TWilFile.GetImageInfo(AIndex: Integer): PImageInfo;
begin
  // ��� AIndex �Ƿ�Ϸ�
  if (AIndex < 0) or (AIndex >= FImageCount) then
    raise Exception.Create('TWilFile.GetImageInfo ���鳬��!');

  // ��λ��ͼƬλ��
  Result := IncPointer(FFilePointer, FIndexArr[AIndex]);
end;

procedure TWilFile.SaveToFile(Index: Integer; const FileName: string; const FiletxtName:string);
var
  FileHeader: BITMAPFILEHEADER;
  InfoHeader: BITMAPINFOHEADER;
  ColorTableSize: Integer;
  InfoPtr: PImageInfo;
  PBits: PByte;
  F: file;
  txtf:TextFile;
begin
  // ��� AIndex �Ƿ�Ϸ�
  if (Index < 0) or (Index >= FImageCount) then
    raise Exception.Create('TWilFile.SaveToFile ���鳬��!');

  // ͼƬ��Ϣָ��
  InfoPtr := ImageInfo[Index];

  // ɫ�ʱ��ڴ��С
  ColorTableSize := SizeOf(TRGBQuad) * 256;

  // λͼ�ļ�ͷ
  FileHeader.bfType := MakeWord(Ord('B'), Ord('M'));
  FileHeader.bfSize := SizeOf(FileHeader) + SizeOf(InfoHeader) + ColorTableSize +
    InfoPtr^.Width * InfoPtr^.Height;
  FileHeader.bfReserved1 := 0;
  FileHeader.bfReserved2 := 0;
  FileHeader.bfOffBits := SizeOf(FileHeader) + SizeOf(InfoHeader) + ColorTableSize;

  // λͼ��Ϣͷ
  InfoHeader.biSize := SizeOf(InfoHeader);
  InfoHeader.biWidth := InfoPtr^.Width;
  InfoHeader.biHeight := InfoPtr^.Height;
  InfoHeader.biPlanes := 1;
  InfoHeader.biBitCount := 8;
  InfoHeader.biCompression := 0;
  InfoHeader.biSizeImage := 0;
  InfoHeader.biXPelsPerMeter := 0;
  InfoHeader.biYPelsPerMeter := 0;
  InfoHeader.biClrUsed := 0;
  InfoHeader.biClrImportant := 0;

  // ��ʼ����bmp�ļ�
  FileMode := fmOpenWrite;
  AssignFile(F, FileName);
  Rewrite(F, 1);


  try
   BlockWrite(F, FileHeader, SizeOf(FileHeader));
   BlockWrite(F, InfoHeader, SizeOf(InfoHeader));
    if ColorTableSize > 0 then
       BlockWrite(F, FMainColorTable^, ColorTableSize);
       PBits := IncPointer(InfoPtr, SizeOf(TImageInfo) - 4);
  BlockWrite(F, PBits^, InfoPtr^.Width * InfoPtr^.Height);

  finally
    CloseFile(F);
  end;


 //����������Ϣ,txt��ʽ����
begin
    FileMode := 2;
    AssignFile(txtf, FiletxtName);
    Rewrite(txtf);
    try
      WriteLn(txtf, InfoPtr^.px);
      WriteLn(txtf, InfoPtr^.py);
    finally
      CloseFile(txtf);
    end;
  end;


end;

procedure TWilFile.Draw(Index: Integer; DstSurf: IDirectDrawSurface7;
  X, Y, DstWidth, DstHeight: Integer; Transparent: Boolean);
var
  R: TRect;
  SizePtr: PImageInfo;
begin
  SizePtr := ImageInfo[Index];
  SetRect(R, X, Y, X + SizePtr.Width, Y + SizePtr.Height);
  FastBlt(DstSurf, X, Y, DstWidth, DstHeight, Surfaces[Index], SizePtr.Width,
    SizePtr.Height, Transparent);
end;

procedure TWilFile.DrawEx(Index: Integer; DstSurf: IDirectDrawSurface7;
  X, Y, DstWidth, DstHeight: Integer; Transparent: Boolean);
var
  SizePtr: PImageInfo;
begin
  SizePtr := ImageInfo[Index];
  FastBlt(DstSurf, X + SizePtr.PX, Y + SizePtr.PY, DstWidth, DstHeight,
    Surfaces[Index], SizePtr.Width, SizePtr.Height, Transparent);
end;

end.

