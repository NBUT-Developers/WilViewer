{------------------------------------------------------------------------------}
{ 单元名称: MirMap.pas                                                         }
{                                                                              }
{ 单元作者: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ 创建日期: 2005-01-02 20:30:00                                                }
{                                                                              }
{ 功能介绍:                                                                    }
{                                                                              }
{   传奇2地图文件读取单元                                                      }
{                                                                              }
{ 使用说明:                                                                    }
{                                                                              }
{ 更新历史:                                                                    }
{                                                                              }
{ 尚存问题:                                                                    }
{                                                                              }
{   1.原始文件 MapUnit.pas 中修正了一些地图数据, 到用的时侯再看看:             }
{     procedure TMap.UpdateMapPos (mx, my: integer); //mx,my象素坐标           }
{------------------------------------------------------------------------------}
unit MirMap;

interface

uses
   Windows, SysUtils, Math, Assist, DirectDraw, AdvDraw, Globals, MirWil;

{------------------------------------------------------------------------------}
// 地图常量信息定义
{------------------------------------------------------------------------------}
const
  LONGHEIGHT_IMAGE = 35;        // 地图上的前景图最大的高度(以 MapPoint 为单位)

  
{------------------------------------------------------------------------------}
// 地图文件结构定义
{------------------------------------------------------------------------------}
type
  // 地图文件头结构 (52字节, 注意: 原文件头大小为56字节)
  // 估计 UpdateDate 偏移有误
  PMapHeader = ^TMapHeader;
  TMapHeader = packed record
    Width      : Word;                      // 宽度      2
    Height     : Word;                      // 高度      2
    Title      : string[16];                // 标题      17
    UpdateDate : TDateTime;                 // 更新日期  8
    Reserved   : array[0..22] of Char;      // 保留      23
  end;

  // 地图点数据结构
  PMapPoint = ^TMapPoint;
  TMapPoint = packed record
    BackImg     : Word;     // 背景图片索引(BackImg-1), 图片在 Tile.wil 中
    MiddImg     : Word;     // 背景小图索引(MiddImg-1), 图片在 SmTile.wil 中
    ForeImg     : Word;     // 前景
    DoorIndex   : Byte;     //    $80 (巩娄), 巩狼 侥喊 牢郸胶
    DoorOffset  : Byte;     //    摧腮 巩狼 弊覆狼 惑措 困摹, $80 (凯覆/摧塞(扁夯))
    AniFrame    : Byte;     //    $80(Draw Alpha) +  橇贰烙 荐
    AniTick     : Byte;
    Area        : Byte;     //    瘤开 沥焊
    Light       : Byte;     //    0..1..4 堡盔 瓤苞
  end;

type

{------------------------------------------------------------------------------}
// TMirMap class
{------------------------------------------------------------------------------}
  TMirMap = class(TObject)
  private
    FFileName: string;
    FFileHandle: THandle;     // WIN32 文件句柄
    FFileMapping: THandle;    // 内存映射文件句柄
    FFilePointer: Pointer;    // 内存映射指针
    FHeight: Word;
    FWidth: Word;
    FTitle: string;
    FUpdateDate: TDateTime;

{    FCenterX: Integer;
    FCenterY: Integer;
    FShiftX: Integer;
    FShiftY: Integer;}
    FClientWidth: Integer;
    FClientHeight: Integer;

    procedure SetFileName(const Value: string);
    function GetPoint(X, Y: Word): PMapPoint;
  protected

  public
    AniTick: Cardinal;
    AniCount: Integer;
    
    constructor Create(AClientWidth, AClientHeight: Integer);

    destructor Destroy; override;

    function CanMove(X, Y: Word): Boolean;

    function CanFly(X, Y: Word): Boolean;

    procedure BitBlt(DC: HDC; X, Y, AWidth, AHeight: Word);

    procedure DrawBackground(Surface: IDirectDrawSurface7;
      CenterX, CenterY, ShiftX, ShiftY: Integer);

    procedure DrawForeground(Surface: IDirectDrawSurface7;
      CenterX, CenterY, ShiftX, ShiftY: Integer; FirstStep: Boolean);

    // 地图文件名, 指定为空串将关闭地图
    property FileName: string read FFileName write SetFileName;

    // 地图宽度
    property Width: Word read FWidth;
    // 地图高度
    property Height: Word read FHeight;
    // 指定地图点的信息 (返回为 TMapPoint 指针, 直接指向地图文件)
    property Point[X, Y: Word]: PMapPoint read GetPoint;

    // 地图标题
    property Title: string read FTitle;
    // 地图更新日期(可能有误)
    property UpdateDate: TDateTime read FUpdateDate;
  end;



{ TMirMap }
implementation

procedure TMirMap.BitBlt(DC: HDC; X, Y, AWidth, AHeight: Word);
var
  Pt: PMapPoint;
  I, J: Word;
  ImageIndex, AniIndex: Word;
  AniCount: Integer;
  // TODO: 本函数中的乘法运算可以优化为加法
begin

  // TODO: 更新正确的 AniCount
  AniCount := 1000;

  // 画背景图
  for J := Y to Y + AHeight do
  begin
    // 如果纵坐标超出地图范围则终止
    // TODO: 这时 I, J 定义为 Word, 会永远为 False, 应该更正, 包括下面的函数
    if J >= FHeight then Break;

    for I := X to X + AWidth do
    begin
      // 如果横坐标超出地图范围则终止
      if I >= FWidth then Break;

      // 取坐标处的地图信息
      Pt := GetPoint(I, J);

      // 如果是偶数行, 则画大块背景, 背景图尺寸是 96 * 64 
      if (J mod 2 = 0) and (I mod 2 = 0) then
      begin
        ImageIndex := Pt.BackImg and $7FFF;
        if ImageIndex > 0 then
          G_WilTile.BitBlt(ImageIndex - 1, DC, (I-X) * 48, (J-Y) * 32);
      end;

      // 画小图, 小图尺寸是 48 * 32 (小图用于填补一些大图画不到的边缘)
      ImageIndex := Pt.MiddImg;
      if ImageIndex > 0 then  
        G_WilTileSm.BitBlt(ImageIndex - 1, DC, (I-X) * 48, (J-Y) * 32);
    end;
  end;

  // 画前景, 前景图尺寸是 48 * 32
  for J := Y to Y + AHeight do
  begin
    // 如果纵坐标超出地图范围则终止
    if J >= FHeight then Break;

    for I := X to X + AWidth do
    begin
      // 如果横坐标超出地图范围则终止
      if I >= FWidth then Break;

      // 取坐标处的地图信息
      Pt := GetPoint(I, J);

      ImageIndex := Pt.ForeImg and $7FFF;
      if ImageIndex > 0 then
      begin
        AniIndex := Pt.AniFrame;
        if (AniIndex and $80 > 0) then AniIndex := AniIndex and $7F;
        if AniIndex > 0 then
          ImageIndex := ImageIndex + (AniCount mod (AniIndex * (Pt.AniTick + 1)))
            div (Pt.AniTick + 1);
        if (Pt.DoorOffset and $80 > 0) and (Pt.DoorIndex and $7F > 0) then
          Inc(ImageIndex, Pt.DoorIndex and $7F);

        // TODO: check value
        if Pt.Area > 6 then
          raise Exception.Create('err');

        G_WilObjects[Pt.Area].BitBlt(ImageIndex - 1, DC, (I-X) * 48, (J-Y) * 32);
      end;
    end;
  end;
end;

constructor TMirMap.Create(AClientWidth, AClientHeight: Integer);
begin
  FClientWidth := AClientWidth;
  FClientHeight := AClientHeight;
end;

destructor TMirMap.Destroy;
begin
  // 关闭已打开的文件句柄等资源
  FileName := '';

  inherited;
end;

function TMirMap.GetPoint(X, Y: Word): PMapPoint;
begin
  Result := IncPointer(FFilePointer, SizeOf(TMapHeader) +
    SizeOf(TMapPoint) * (FHeight * X + Y));

  //  注意, Mir 的地址存放似乎与一般地图方向不同
  //  Result := IncPointer(FFilePointer, SizeOf(TMapHeader) +
  //    SizeOf(TMapPoint) * (FWidth * Y + X));
end;

procedure TMirMap.SetFileName(const Value: string);
begin
  // 如果文件名相同则退出
  if FFileName = Value then Exit;

  // 如果已经打开过地图文件, 则先释放先前的文件句柄
  if FFileName <> '' then
  begin
    UnmapViewOfFile(FFilePointer);
    CloseHandle(FFileMapping);
    CloseHandle(FFileHandle);
  end;

  // 如果文件名为空则退出
  if Value = '' then Exit;
  
  // 创建文件句柄
  FFileHandle := CreateFile(PChar(Value), GENERIC_READ, FILE_SHARE_READ, nil,
  OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_RANDOM_ACCESS, 0);

  if FFileHandle = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('打开 "%s" 失败!', [Value]);

  // 创建文件映射
  FFileMapping := CreateFileMapping(FFileHandle, nil, PAGE_READONLY, 0, 0, nil);

  if FFileMapping = 0 then
  begin
    CloseHandle(FFileHandle);
    raise Exception.CreateFmt('创建文件映射 "%s" 失败!', [Value]);
  end;

  // 进行文件映射
  FFilePointer := MapViewOfFile(FFileMapping, FILE_MAP_READ, 0, 0, 0);

  if FFilePointer = nil then
  begin
    CloseHandle(FFileMapping);
    CloseHandle(FFileHandle);
    raise Exception.CreateFmt('映射文件 "%s" 失败!', [Value]);
  end;

  // 读出地图头信息
  FWidth := PMapHeader(FFilePointer)^.Width;
  FHeight := PMapHeader(FFilePointer)^.Height;
  FTitle := PMapHeader(FFilePointer)^.Title;
  FUpdateDate := PMapHeader(FFilePointer)^.UpdateDate;

  // 保存地图文件名
  FFileName := Value;
end;

procedure TMirMap.DrawBackground(Surface: IDirectDrawSurface7;
  CenterX, CenterY, ShiftX, ShiftY: Integer);
var
  MapRect: TRect;               // 需要绘制的 MAP 坐标范围
  OffsetX, OffsetY: Integer;    // X, Y 左上角偏移
  AdjustX, AdjustY: Integer;    // 在绘背景时是否需要调整最左/上行(由于BkImg以偶行/列方式绘制)
  I, J: Integer;
  Pt: PMapPoint;
  ImageIndex: Word;
begin
  // 自地图中间至最左/最上的宽度(象素)
  I := (FClientWidth - MAPUNIT_WIDTH) div 2 - ShiftX;
  J := (FClientHeight - MAPUNIT_HEIGHT) div 2 - ShiftY;

  // 计算需要绘制的地图点范围(TMapPoint)
  MapRect.Left := Max(0, CenterX - Ceil(I / MAPUNIT_WIDTH));
  MapRect.Right := Min(FWidth, CenterX + Ceil((FClientWidth - I) / MAPUNIT_WIDTH));
  MapRect.Top := Max(0, CenterY - Ceil(J / MAPUNIT_HEIGHT));
  MapRect.Bottom := Min(FHeight, CenterY + Ceil((FClientHeight - J) / MAPUNIT_HEIGHT));

//  MapRect.Left := MapRect.Left - MapRect.Left mod 2;
//  MapRect.Top := MapRect.Top - MapRect.Top mod 2;

  // 计算开始绘制时的偏移值(象素)
  OffsetX := I - (CenterX - MapRect.Left) * MAPUNIT_WIDTH;
  OffsetY := J - (CenterY - MapRect.Top) * MAPUNIT_HEIGHT;

  // 绘制背景 (BkImg)
  AdjustX := MapRect.Left mod 2;
  AdjustY := MapRect.Top mod 2;
  for I := MapRect.Left - AdjustX to MapRect.Right do
  for J := MapRect.Top - AdjustY to MapRect.Bottom do
  begin
    if (I mod 2 = 0) and (J mod 2 = 0) then
    begin
      Pt := GetPoint(I, J);
      ImageIndex := Pt.BackImg and $7FFF;
      if ImageIndex > 0 then
      begin
        G_WilTile.Draw(ImageIndex - 1, Surface,
          (I - MapRect.Left) * MAPUNIT_WIDTH + OffsetX,
          (J - MapRect.Top) * MAPUNIT_HEIGHT + OffsetY,
          FClientWidth, FClientHeight, False);
      end;
    end;
  end;

  // 绘制背景补充 (MidImg)
  for I := MapRect.Left to MapRect.Right do
  for J := MapRect.Top to MapRect.Bottom do
  begin
    Pt := GetPoint(I, J);
    ImageIndex := Pt.MiddImg;
    if ImageIndex > 0 then
    begin
      G_WilTileSm.Draw(ImageIndex - 1, Surface,
        (I - MapRect.Left) * MAPUNIT_WIDTH + OffsetX,
        (J - MapRect.Top) * MAPUNIT_HEIGHT + OffsetY,
        FClientWidth, FClientHeight, False);
    end;
  end;
end;

procedure TMirMap.DrawForeground(Surface: IDirectDrawSurface7; CenterX,
  CenterY, ShiftX, ShiftY: Integer; FirstStep: Boolean);
var
  MapRect: TRect;               // 需要绘制的 MAP 坐标范围
  OffsetX, OffsetY: Integer;    // X, Y 左上角偏移
  I, J: Integer;
  Pt: PMapPoint;
  InfoPtr: PImageInfo;
  ImageIndex: Word;
  AniIndex: Byte;
  IsBlend: Boolean;
begin
  // 自地图中间至最左/最上的宽度(象素)
  I := (FClientWidth - MAPUNIT_WIDTH) div 2 - ShiftX;
  J := (FClientHeight - MAPUNIT_HEIGHT) div 2 - ShiftY;

  // 计算需要绘制的地图点范围(TMapPoint)
  MapRect.Left := Max(0, CenterX - Ceil(I / MAPUNIT_WIDTH));
  MapRect.Right := Min(FWidth, CenterX + Ceil((FClientWidth - I) / MAPUNIT_WIDTH));
  MapRect.Top := Max(0, CenterY - Ceil(J / MAPUNIT_HEIGHT));
  MapRect.Bottom := Min(FHeight, CenterY + Ceil((FClientHeight - J) / MAPUNIT_HEIGHT) + LONGHEIGHT_IMAGE);

  // 计算开始绘制时的偏移值(象素)
  OffsetX := I - (CenterX - MapRect.Left) * MAPUNIT_WIDTH;
  OffsetY := J - (CenterY - MapRect.Top) * MAPUNIT_HEIGHT;

  // 绘制前景 (FrImg)
  for I := MapRect.Left to MapRect.Right do
  for J := MapRect.Top to MapRect.Bottom do
  begin
    Pt := GetPoint(I, J);
    ImageIndex := Pt.ForeImg and $7FFF;
    if ImageIndex > 0 then
    begin
      IsBlend := False;
      AniIndex := Pt.AniFrame;
      if AniIndex and $80 > 0 then
      begin
        IsBlend := True;
        AniIndex := AniIndex and $7F;
      end;
      if AniIndex > 0 then
      begin
        Inc(ImageIndex, (AniCount mod (AniIndex * (Pt.AniTick + 1))) div (Pt.AniTick + 1));
      end;
      if (Pt.DoorOffset and $80 > 0) and (Pt.DoorIndex and $7F > 0) then
        Inc(ImageIndex, Pt.DoorIndex and $7F);

      // TODO: check value
      if Pt.Area > 6 then
        raise Exception.Create('err');

      InfoPtr := G_WilObjects[Pt.Area].ImageInfo[ImageIndex - 1];

      // 如果图片尺寸=48/32则按正常方式绘制
      if FirstStep then
      begin
        if (InfoPtr^.Width = 48) and (InfoPtr^.Height = 32) then
        begin
          G_WilObjects[Pt.Area].Draw(ImageIndex - 1, Surface,
            (I - MapRect.Left) * MAPUNIT_WIDTH + OffsetX,
            (J - MapRect.Top) * MAPUNIT_HEIGHT + OffsetY,
            FClientWidth, FClientHeight, True);
        end
      end
      else begin
        // 如果不是混合方式
        if not IsBlend then
        begin
          if (InfoPtr^.Width <> 48) or (InfoPtr^.Height <> 32) then
            G_WilObjects[Pt.Area].Draw(ImageIndex - 1, Surface,
              (I - MapRect.Left) * MAPUNIT_WIDTH + OffsetX,
              (J - MapRect.Top + 1) * MAPUNIT_HEIGHT + OffsetY - InfoPtr^.Height, // 要用减去图片高度
              FClientWidth, FClientHeight, True);
        end
        else
        // 否则, 是混合方式
  {          G_WilObjects[Pt.Area].Draw(ImageIndex - 1, Surface,
              (I - MapRect.Left) * MAPUNIT_WIDTH + OffsetX + InfoPtr^.PX - 2,
              (J - MapRect.Top) * MAPUNIT_HEIGHT + OffsetY + InfoPtr^.PY - 68,
              FClientWidth, FClientHeight, True)}
          DrawBlend(Surface,
              (I - MapRect.Left) * MAPUNIT_WIDTH + OffsetX + InfoPtr^.PX - 2,
              (J - MapRect.Top) * MAPUNIT_HEIGHT + OffsetY + InfoPtr^.PY - 68,
              FClientWidth, FClientHeight,
            G_WilObjects[Pt.Area].Surfaces[ImageIndex - 1],
            InfoPtr^.Width, InfoPtr^.Height, 0);
      end;
    end;
  end;
end;

function TMirMap.CanFly(X, Y: Word): Boolean;
var
  Pt: PMapPoint;
begin
  Result := False;
  
  if X >= FWidth then Exit;
  if Y >= FHeight then Exit;

  Pt := Point[X, Y];
  Result := Pt.ForeImg and $8000 = 0;
  if Result then
  begin
    if (Pt.DoorIndex and $80 > 0) and (Pt.DoorOffset and $80 = 0) then
      Result := False;
  end;
end;

function TMirMap.CanMove(X, Y: Word): Boolean;
var
  Pt: PMapPoint;
begin
  Result := False;
  
  if X >= FWidth then Exit;
  if Y >= FHeight then Exit;
   
  Pt := Point[X, Y];
  Result := (Pt.BackImg and $8000 = 0) and (Pt.ForeImg and $8000 = 0);
  if Result then
  begin
    if (Pt.DoorIndex and $80 > 0) and (Pt.DoorOffset and $80 = 0) then
      Result := False;
  end;
end;

end.
