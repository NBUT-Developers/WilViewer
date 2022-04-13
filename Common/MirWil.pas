{------------------------------------------------------------------------------}
{ 单元名称: MirWil.pas                                                         }
{                                                                              }
{ 单元作者: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ 创建日期: 2005-01-02 20:30:00                                                }
{                                                                              }
{ 功能介绍:                                                                    }
{   传奇2 Wil 文件读取单元                                                     }
{                                                                              }
{ 使用说明:                                                                    }
{                                                                              }
{   WIL 位图文件: 由 文件头+调色板(256色)+(TImageInfo+位图 Bits)*N项 组成      }
{   WIX 索引文件: 实际上就是一个文件头+指针数组, 指针指向 TImageInfo 结构      }
{                                                                              }
{ 更新历史:                                                                    }
{                                                                              }
{ 尚存问题:                                                                    }
{                                                                              }
{    WIL 的调色板是不是都是一样的？如果是，则可以省略                          }
{    注意： WIL 的数据格式定义都是没有 pack 的 record                          }
{                                                                              }
{    Weapon.wix 数据有误: 索引文件头设置的图片数量为 40856, 实际能读出的数量   }
{      为 40855, 传奇源代码可以正常运行的原因是它没有检测可读出的内容.         }
{      可能需要重建索引. 目前的解决方法是在 LoadIndexFile 中根据读出的实际内   }
{      容对 FImageCount 进行修正.                                              }
{                                                                              }
{------------------------------------------------------------------------------}
unit MirWil;

interface

uses
  SysUtils, Windows, DirectDraw, Assist, AdvDraw;

{------------------------------------------------------------------------------}
// WIL 常量定义
{------------------------------------------------------------------------------}
var
  UseDIBSurface: Boolean = True;  // 是否在创建 WIL Surface 时使用 DIB 绘制
                                  // 如果直接使用 WIL 文件中的位图 Bits 会出现少量颜色
                                  // 显示不正确，在传奇源代码中的结果也是如此。

{------------------------------------------------------------------------------}
// WIL 文件格式定义
{------------------------------------------------------------------------------}
type
  // WIL 文件头格式 (56Byte)
  PImageHeader = ^TImageHeader;
  TImageHeader = record
    Title       : string[40];   // 库文件标题 'WEMADE Entertainment inc.'
    ImageCount  : Integer;      // 图片数量
    ColorCount  : Integer;      // 色彩数量
    PaletteSize : Integer;      // 调色板大小
  end;

  // WIL 图像信息 (注意, 没有 pack record)
  PImageInfo = ^TImageInfo;
  TImageInfo = record
    Width  : SmallInt;   // 位图宽度
    Height : SmallInt;   // 位图高度
    PX     : SmallInt;   // 未知,似乎不用也可
    PY     : SmallInt;   // 未知,似乎不用也可
    Bits   : PByte;      // 未使用, 实际从文件读出时,要少读 4 字节, 即是此值未读
  end;

  // WIX 索引文件头格式
  PIndexHeader = ^TIndexHeader;
  TIndexHeader = record
    Title      : string[40];    // 'WEMADE Entertainment inc.'
    IndexCount : integer;       // 索引总数
  end;

{------------------------------------------------------------------------------}
// TWilFile class
{------------------------------------------------------------------------------}

  // TWilFile
  TWilFile = class(TObject)
  private
    FFileName: string;            // WIL 文件名
    FFileHandle: THandle;         // 文件句柄
    FFileMapping: THandle;        // 文件映射句柄
    FFilePointer: Pointer;        // 文件内容指针(使用文件映射)

    FIndexArr: array of Integer;  // 图片索引数组(从 WIX 文件中读取)
    FMainColorTable: PRGBQuads;   // 调色板指针(直接指向 WIL 文件中)
    FImageCount: Integer;         // 图片数量
    FBitmapInfo: TBitmapInfo256;  // 位图信息头部(用于 SetDIBitsToDevice)

    FDDSurfaceDesc2: TDDSurfaceDesc2;
    FSurfaces: array of IDirectDrawSurface7;
    FMainDirectDraw: IDirectDraw7;

    procedure LoadIndexFile;      // 读入 WIX 文件至 IndexArr 中
    procedure CreateMapView;      // 创建 WIL 文件映射
    function GetSurfaces(AIndex: Integer): IDirectDrawSurface7;
    function GetImageInfo(AIndex: Integer): PImageInfo;

    public
    MainColorTablebak:TRGBQuads;
    IndexArrbak:array of integer;
    //制造wil,wix文件头用；
    imgheadbak:TImageHeader;
    idxheadbak:TIndexHeader;
  //  customimgcount:integer;

    FilePointersaved: pointer;
    constructor Create(const AFileName: string; ADirectDraw: IDirectDraw7 = nil);
    destructor Destroy; override;

    // Draw: 将 Index 位置的图片绘制至 Surface 的 X, Y 位置
    procedure Draw(Index: Integer; DstSurf: IDirectDrawSurface7; X, Y,
      DstWidth, DstHeight: Integer; Transparent: Boolean);
    // DrawEx: 将 Index 位置的图片绘制至 Surface 的 X, Y 位置, 包含 Image 的偏移位置
    procedure DrawEx(Index: Integer; DstSurf: IDirectDrawSurface7; X, Y,
      DstWidth, DstHeight: Integer; Transparent: Boolean);


    // BitBlt: 将 Index 位置的图片绘制至 DC 的 X, Y 位置
    procedure BitBlt(Index: Integer; DC: HDC; X, Y: Integer); 
    // StretchBlt: 以缩放方式将图片绘制至 DC
    procedure StretchBlt(Index: Integer; DC: HDC; X, Y, Width, Height: Integer;
      ROP: Cardinal);
    // SaveToFile: 将索引位置的图片保存为 BMP 文件
    procedure SaveToFile(Index: Integer; const FileName: string; const FiletxtName:string);
    // 已打开的 WIL 文件名
    property FileName: string read FFileName;
  //  FFilePointer: Pointer;        // 文件内容指针(使用文件映射)
    // 主调色板指针

    property MainColorTable: PRGBQuads read FMainColorTable;
    // IDirectDraw7, 用于创建 Surfaces 数组, 如果不指定也可以使用 BitBlt
    property MainDirectDraw: IDirectDraw7 read FMainDirectDraw write FMainDirectDraw;
    // 图片总数
    property ImageCount: Integer read FImageCount;
    // 图片的 Surface
    property Surfaces[AIndex: Integer]: IDirectDrawSurface7 read GetSurfaces;
    // 图片的信息
    property ImageInfo[AIndex: Integer]: PImageInfo read GetImageInfo;
  end;


implementation

{ TWilFile }

constructor TWilFile.Create(const AFileName: string; ADirectDraw: IDirectDraw7 = nil);
begin
  FFileName := AFileName;

  FMainDirectDraw := ADirectDraw;
  
  // 读入图片索引文件
  LoadIndexFile;

  // 创建 WIL 文件的映射
  CreateMapView;

  // 读入 WIL 文件头数据

  // 读入文件头中的图片数量, (图片数量已由 LoadIndexFile 设置, 这是由
  // 于 Weapon.wix 中的数量错误导致的修改, savetime 2005.1.3)
  // FImageCount := PImageHeader(FFilePointer)^.ImageCount;

  // 设置 FSurfaces 数组大小
  SetLength(FSurfaces, FImageCount);
  // 保存调色板指针
  FMainColorTable := IncPointer(FFilePointer, SizeOf(TImageHeader));
   //保存调色板以备用
  MainColorTablebak:=PRGBQuads(MainColorTable)^;

  // 设置位图固定信息，以免每次 Blt 时设置
  // TODO: 位图文件头还可进一步压缩
  with FBitmapInfo.bmiHeader do
  begin
    biSize := SizeOf(TBitmapInfoHeader);
    // 这二项由读入图片后设置
    // biWidth := ImagePos^.Width;
    // biHeight := ImagePos^.Height;
    biPlanes := 1;
    biBitCount := 8;
    biCompression := BI_RGB;    // 注意，这里只使用未压缩数据
    biSizeImage := 0;           // 压缩时才需要 biSizeImage
    biXPelsPerMeter := 0;
    biYPelsPerMeter := 0;
    biClrUsed := 0;
    biClrImportant := 0;
  end;

  // 初始化 FDDSurfaceDesc2, 以免每次创建 Surface 时初始化
  // 此处不用 FillChar(FDDSurfaceDesc2)
  FDDSurfaceDesc2.dwSize := SizeOf(FDDSurfaceDesc2);
  FDDSurfaceDesc2.dwFlags := DDSD_CAPS or DDSD_WIDTH or DDSD_HEIGHT;
  FDDSurfaceDesc2.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_SYSTEMMEMORY;



end;

procedure TWilFile.CreateMapView;
var
  ContentFileName: string;
  customimgcount:integer;
begin
  // WIL 文件名
  ContentFileName := FFileName + '.WIL';

  // 打开 WIL 文件
  FFileHandle := CreateFile(PChar(ContentFileName), GENERIC_READ, FILE_SHARE_READ, nil,
    OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_RANDOM_ACCESS, 0);

  if FFileHandle = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('打开文件 "%s" 失败!', [ContentFileName]);

  // 创建文件映射对象
  FFileMapping := CreateFileMapping(FFileHandle, nil, PAGE_READONLY, 0, 0, nil);

  if FFileMapping = 0 then
  begin
    CloseHandle(FFileHandle);
    raise Exception.CreateFmt('创建文件映射 "%s" 失败!', [ContentFileName]);
  end;

  // 映射文件至内存
  FFilePointer := MapViewOfFile(FFileMapping, FILE_MAP_READ, 0, 0, 0);
  //立即保存指针供以后使用
  if FFilePointer <> nil then
  FilePointersaved:=FFilePointer



  else begin
    CloseHandle(FFileMapping);
    CloseHandle(FFileHandle);
    raise Exception.CreateFmt('映射文件 "%s" 失败!', [ContentFileName]);
  end;

  //,,额外处理过程:保存imgheader的一些成员到imgheadbak这个备份结构
  imgheadbak.Title:=PImageHeader(FFilePointer)^.Title;
  imgheadbak.ColorCount:=PImageHeader(FFilePointer)^.ColorCount;
  imgheadbak.PaletteSize:=PImageHeader(FFilePointer)^.PaletteSize;
  imgheadbak.ImageCount:=customimgcount;

end;

destructor TWilFile.Destroy;
var
  I: Integer;
begin
  // 清除索引文件内容
  SetLength(FIndexArr, 0);
  SetLength(IndexArrbak, 0);

  // 清除 FSurfaces 数组
  for I := 0 to Length(FSurfaces) - 1 do
    FSurfaces[I] := nil;
  SetLength(FSurfaces, 0);

  // 清除 FMainDirectDraw
  FMainDirectDraw := nil;

  // 关闭文件映射及相关句柄
  UnmapViewOfFile(FFilePointer);
  CloseHandle(FFileMapping);
  CloseHandle(FFileHandle);

  inherited;
end;

procedure TWilFile.LoadIndexFile;
var
  F: file;
  IdxHeader: TIndexHeader;
  NumRead: Integer; //实际读出的图片数
  IndexFileName: string;
  customidxcount: integer;//customimgcount:integer; //
begin
  // 索引文件名
  IndexFileName := FFileName + '.WIX';

  // 打开索引文件
  FileMode := fmOpenRead;
  AssignFile(F, IndexFileName);
  Reset(F, 1);
  try
    // 读索引文件头,,读到NumRead
    BlockRead(F, IdxHeader, SizeOf(IdxHeader), NumRead);
    if NumRead <> SizeOf(IdxHeader) then
      raise Exception.CreateFmt('"%s" 文件头错误!', [IndexFileName]);

    // 设置索引数组大小
    SetLength(FIndexArr, IdxHeader.IndexCount);
    SetLength(IndexArrbak, IdxHeader.IndexCount);

    // 读索引内存至数组   读到PInteger(FIndexArr)^
    BlockRead(F, PInteger(FIndexArr)^, IdxHeader.IndexCount * 4, NumRead);

          //,,额外处理过程2:保存idxheader的一些成员
     idxheadbak.Title:=idxheader.Title;        //记得释放idxheadbak这个结构哦
     idxheadbak.IndexCount:=customidxcount;

    //,,额外处理过程3:保存indexarrbak,,indexarrbak代表数组开头
     PInteger(IndexArrbak)^:=PInteger(FIndexArr)^;

    if NumRead = IdxHeader.IndexCount * 4 then
      FImageCount := IdxHeader.IndexCount
    else
      // 由于 Weapon.wix 的索引文件头中的图片数与实际的索引个数不同, 为了兼容,
      // 即不触发异常, 详细情况见此文件最上标注.
      // raise Exception.CreateFmt('"%s" 文件内容错误!', [IndexFileName]);
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
  // 检查 Index 是否合法
  if (Index < 0) or (Index >= FImageCount) then
    raise Exception.Create('TWilFile.BitBlt 数组超界!');

  // 定位到图片位置
  ImageInfo := IncPointer(FFilePointer, FIndexArr[Index]);

  // 设置位图大小
  with FBitmapInfo.bmiHeader do
  begin
    biWidth := ImageInfo^.Width;
    biHeight := ImageInfo^.Height;
  end;

  // 填充调色板
  Move(MainColorTable^, FBitmapInfo.bmiColors, SizeOf(FBitMapInfo.bmiColors));

  // PBits 指向位图的 Bits
  PBits := IncPointer(ImageInfo, SizeOf(TImageInfo) - 4);

  // 直接将 DIB Bits 写到设备环境
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
  // 检查 Index 是否合法
  if (Index < 0) or (Index >= FImageCount) then
    raise Exception.Create('TWilFile.StretchBlt 数组超界!');

  // 定位到图片位置
  ImageInfo := IncPointer(FFilePointer, FIndexArr[Index]);

  // 设置位图大小
  with FBitmapInfo.bmiHeader do
  begin
    biWidth := ImageInfo^.Width;
    biHeight := ImageInfo^.Height;
  end;
  
  // 填充调色板
  Move(MainColorTable^, FBitmapInfo.bmiColors, SizeOf(FBitMapInfo.bmiColors));

  // PBits 指向位图的 Bits
  PBits := IncPointer(ImageInfo, SizeOf(TImageInfo) - 4);

  // 缩放方式将 DIB Bits 写到设备环境
  StretchDIBits(DC, X, Y, Width, Height, 0, 0, ImageInfo^.Width, ImageInfo^.Height,
    PBits, PBitmapInfo(PBitmapInfo256(@FBitmapInfo))^, DIB_RGB_COLORS, ROP);
end;

function TWilFile.GetSurfaces(AIndex: Integer): IDirectDrawSurface7;
var
  InfoPtr: PImageInfo;    // 图像信息, 使用临时变量将加快速度
  ColorKey: TDDColorKey;  // 透明色值
  DDSD: TDDSurfaceDesc2;  // 用于 Surface.Lock
  Y: Integer;             // Surface 的行值
  PBits: PByte;           // 指向 Bits 的指针
  DC: HDC;                // 用于 Surface.GetDC
begin
  // 检查 AIndex 是否合法
  if (AIndex < 0) or (AIndex >= FImageCount) then
    raise Exception.Create('TWilFile.GetSurfaces 数组超界!');

  // 检查 MainDirectDraw 是否存在
  if FMainDirectDraw = nil then
    raise Exception.Create('必须指定 MainDirectDraw!');

  // 如果索引位置的 FSurface 已经创建, 则直接返回该值
  Result := FSurfaces[AIndex];
  if FSurfaces[AIndex] <> nil then Exit;

  // 否则创建新的 FSurface[AIndex]
  InfoPtr := ImageInfo[AIndex];

  FDDSurfaceDesc2.dwWidth := InfoPtr^.Width;
  FDDSurfaceDesc2.dwHeight := InfoPtr^.Height;

  if FMainDirectDraw.CreateSurface(FDDSurfaceDesc2, FSurfaces[AIndex], nil) <> DD_OK then
    raise Exception.Create('不能创建 WIL Surface!');

  if UseDIBSurface then // 写入表面位图方法之一：使用 DC, BitBlt
  begin
    if FSurfaces[AIndex].GetDC(DC) = DD_OK then
    begin
      SelectObject(DC, NULL_BRUSH);
      Rectangle(DC, 0, 0, ImageInfo[AIndex]^.Width, ImageInfo[AIndex]^.Height);
      BitBlt(AIndex, DC, 0, 0);
      FSurfaces[AIndex].ReleaseDC(DC);
    end
    else
    begin   // 如果获取 DC 失败, 则关闭当前 FSurface
      FSurfaces[AIndex] := nil;
      Exit;
    end;
  end
  else // 写入表面位图方法之二：直接拷贝 WIL Bits 数据至 Surface
  begin
    DDSD.dwSize := SizeOf(DDSD);
    if FSurfaces[AIndex].Lock(nil, DDSD, DDLOCK_WAIT, 0) <> DD_OK then Exit;
    // 这里比较奇怪，需要从位图的最后一行写入表面第一行，逆行序
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

  // 设置 ColorKey (黑色)
  ColorKey.dwColorSpaceLowValue := 0;
  ColorKey.dwColorSpaceHighValue := 0;
  FSurfaces[AIndex].SetColorKey(DDCKEY_SRCBLT, @ColorKey);

  // 返回当前 Surface
  Result := FSurfaces[AIndex];
end;

function TWilFile.GetImageInfo(AIndex: Integer): PImageInfo;
begin
  // 检查 AIndex 是否合法
  if (AIndex < 0) or (AIndex >= FImageCount) then
    raise Exception.Create('TWilFile.GetImageInfo 数组超界!');

  // 定位到图片位置
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
  // 检查 AIndex 是否合法
  if (Index < 0) or (Index >= FImageCount) then
    raise Exception.Create('TWilFile.SaveToFile 数组超界!');

  // 图片信息指针
  InfoPtr := ImageInfo[Index];

  // 色彩表内存大小
  ColorTableSize := SizeOf(TRGBQuad) * 256;

  // 位图文件头
  FileHeader.bfType := MakeWord(Ord('B'), Ord('M'));
  FileHeader.bfSize := SizeOf(FileHeader) + SizeOf(InfoHeader) + ColorTableSize +
    InfoPtr^.Width * InfoPtr^.Height;
  FileHeader.bfReserved1 := 0;
  FileHeader.bfReserved2 := 0;
  FileHeader.bfOffBits := SizeOf(FileHeader) + SizeOf(InfoHeader) + ColorTableSize;

  // 位图信息头
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

  // 开始保存bmp文件
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


 //保存坐标信息,txt格式保存
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

