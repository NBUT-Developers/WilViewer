{------------------------------------------------------------------------------}
{ ��Ԫ����: MirMap.pas                                                         }
{                                                                              }
{ ��Ԫ����: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ ��������: 2005-01-02 20:30:00                                                }
{                                                                              }
{ ���ܽ���:                                                                    }
{                                                                              }
{   ����2��ͼ�ļ���ȡ��Ԫ                                                      }
{                                                                              }
{ ʹ��˵��:                                                                    }
{                                                                              }
{ ������ʷ:                                                                    }
{                                                                              }
{ �д�����:                                                                    }
{                                                                              }
{   1.ԭʼ�ļ� MapUnit.pas ��������һЩ��ͼ����, ���õ�ʱ���ٿ���:             }
{     procedure TMap.UpdateMapPos (mx, my: integer); //mx,my��������           }
{------------------------------------------------------------------------------}
unit MirMap;

interface

uses
   Windows, SysUtils, Math, Assist, DirectDraw, AdvDraw, Globals, MirWil;

{------------------------------------------------------------------------------}
// ��ͼ������Ϣ����
{------------------------------------------------------------------------------}
const
  LONGHEIGHT_IMAGE = 35;        // ��ͼ�ϵ�ǰ��ͼ���ĸ߶�(�� MapPoint Ϊ��λ)

  
{------------------------------------------------------------------------------}
// ��ͼ�ļ��ṹ����
{------------------------------------------------------------------------------}
type
  // ��ͼ�ļ�ͷ�ṹ (52�ֽ�, ע��: ԭ�ļ�ͷ��СΪ56�ֽ�)
  // ���� UpdateDate ƫ������
  PMapHeader = ^TMapHeader;
  TMapHeader = packed record
    Width      : Word;                      // ���      2
    Height     : Word;                      // �߶�      2
    Title      : string[16];                // ����      17
    UpdateDate : TDateTime;                 // ��������  8
    Reserved   : array[0..22] of Char;      // ����      23
  end;

  // ��ͼ�����ݽṹ
  PMapPoint = ^TMapPoint;
  TMapPoint = packed record
    BackImg     : Word;     // ����ͼƬ����(BackImg-1), ͼƬ�� Tile.wil ��
    MiddImg     : Word;     // ����Сͼ����(MiddImg-1), ͼƬ�� SmTile.wil ��
    ForeImg     : Word;     // ǰ��
    DoorIndex   : Byte;     //    $80 (��¦), ���� �ĺ� �ε���
    DoorOffset  : Byte;     //    ���� ���� �׸��� ��� ��ġ, $80 (����/����(�⺻))
    AniFrame    : Byte;     //    $80(Draw Alpha) +  ������ ��
    AniTick     : Byte;
    Area        : Byte;     //    ���� ����
    Light       : Byte;     //    0..1..4 ���� ȿ��
  end;

type

{------------------------------------------------------------------------------}
// TMirMap class
{------------------------------------------------------------------------------}
  TMirMap = class(TObject)
  private
    FFileName: string;
    FFileHandle: THandle;     // WIN32 �ļ����
    FFileMapping: THandle;    // �ڴ�ӳ���ļ����
    FFilePointer: Pointer;    // �ڴ�ӳ��ָ��
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

    // ��ͼ�ļ���, ָ��Ϊ�մ����رյ�ͼ
    property FileName: string read FFileName write SetFileName;

    // ��ͼ���
    property Width: Word read FWidth;
    // ��ͼ�߶�
    property Height: Word read FHeight;
    // ָ����ͼ�����Ϣ (����Ϊ TMapPoint ָ��, ֱ��ָ���ͼ�ļ�)
    property Point[X, Y: Word]: PMapPoint read GetPoint;

    // ��ͼ����
    property Title: string read FTitle;
    // ��ͼ��������(��������)
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
  // TODO: �������еĳ˷���������Ż�Ϊ�ӷ�
begin

  // TODO: ������ȷ�� AniCount
  AniCount := 1000;

  // ������ͼ
  for J := Y to Y + AHeight do
  begin
    // ��������곬����ͼ��Χ����ֹ
    // TODO: ��ʱ I, J ����Ϊ Word, ����ԶΪ False, Ӧ�ø���, ��������ĺ���
    if J >= FHeight then Break;

    for I := X to X + AWidth do
    begin
      // ��������곬����ͼ��Χ����ֹ
      if I >= FWidth then Break;

      // ȡ���괦�ĵ�ͼ��Ϣ
      Pt := GetPoint(I, J);

      // �����ż����, �򻭴�鱳��, ����ͼ�ߴ��� 96 * 64 
      if (J mod 2 = 0) and (I mod 2 = 0) then
      begin
        ImageIndex := Pt.BackImg and $7FFF;
        if ImageIndex > 0 then
          G_WilTile.BitBlt(ImageIndex - 1, DC, (I-X) * 48, (J-Y) * 32);
      end;

      // ��Сͼ, Сͼ�ߴ��� 48 * 32 (Сͼ�����һЩ��ͼ�������ı�Ե)
      ImageIndex := Pt.MiddImg;
      if ImageIndex > 0 then  
        G_WilTileSm.BitBlt(ImageIndex - 1, DC, (I-X) * 48, (J-Y) * 32);
    end;
  end;

  // ��ǰ��, ǰ��ͼ�ߴ��� 48 * 32
  for J := Y to Y + AHeight do
  begin
    // ��������곬����ͼ��Χ����ֹ
    if J >= FHeight then Break;

    for I := X to X + AWidth do
    begin
      // ��������곬����ͼ��Χ����ֹ
      if I >= FWidth then Break;

      // ȡ���괦�ĵ�ͼ��Ϣ
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
  // �ر��Ѵ򿪵��ļ��������Դ
  FileName := '';

  inherited;
end;

function TMirMap.GetPoint(X, Y: Word): PMapPoint;
begin
  Result := IncPointer(FFilePointer, SizeOf(TMapHeader) +
    SizeOf(TMapPoint) * (FHeight * X + Y));

  //  ע��, Mir �ĵ�ַ����ƺ���һ���ͼ����ͬ
  //  Result := IncPointer(FFilePointer, SizeOf(TMapHeader) +
  //    SizeOf(TMapPoint) * (FWidth * Y + X));
end;

procedure TMirMap.SetFileName(const Value: string);
begin
  // ����ļ�����ͬ���˳�
  if FFileName = Value then Exit;

  // ����Ѿ��򿪹���ͼ�ļ�, �����ͷ���ǰ���ļ����
  if FFileName <> '' then
  begin
    UnmapViewOfFile(FFilePointer);
    CloseHandle(FFileMapping);
    CloseHandle(FFileHandle);
  end;

  // ����ļ���Ϊ�����˳�
  if Value = '' then Exit;
  
  // �����ļ����
  FFileHandle := CreateFile(PChar(Value), GENERIC_READ, FILE_SHARE_READ, nil,
  OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL or FILE_FLAG_RANDOM_ACCESS, 0);

  if FFileHandle = INVALID_HANDLE_VALUE then
    raise Exception.CreateFmt('�� "%s" ʧ��!', [Value]);

  // �����ļ�ӳ��
  FFileMapping := CreateFileMapping(FFileHandle, nil, PAGE_READONLY, 0, 0, nil);

  if FFileMapping = 0 then
  begin
    CloseHandle(FFileHandle);
    raise Exception.CreateFmt('�����ļ�ӳ�� "%s" ʧ��!', [Value]);
  end;

  // �����ļ�ӳ��
  FFilePointer := MapViewOfFile(FFileMapping, FILE_MAP_READ, 0, 0, 0);

  if FFilePointer = nil then
  begin
    CloseHandle(FFileMapping);
    CloseHandle(FFileHandle);
    raise Exception.CreateFmt('ӳ���ļ� "%s" ʧ��!', [Value]);
  end;

  // ������ͼͷ��Ϣ
  FWidth := PMapHeader(FFilePointer)^.Width;
  FHeight := PMapHeader(FFilePointer)^.Height;
  FTitle := PMapHeader(FFilePointer)^.Title;
  FUpdateDate := PMapHeader(FFilePointer)^.UpdateDate;

  // �����ͼ�ļ���
  FFileName := Value;
end;

procedure TMirMap.DrawBackground(Surface: IDirectDrawSurface7;
  CenterX, CenterY, ShiftX, ShiftY: Integer);
var
  MapRect: TRect;               // ��Ҫ���Ƶ� MAP ���귶Χ
  OffsetX, OffsetY: Integer;    // X, Y ���Ͻ�ƫ��
  AdjustX, AdjustY: Integer;    // �ڻ汳��ʱ�Ƿ���Ҫ��������/����(����BkImg��ż��/�з�ʽ����)
  I, J: Integer;
  Pt: PMapPoint;
  ImageIndex: Word;
begin
  // �Ե�ͼ�м�������/���ϵĿ��(����)
  I := (FClientWidth - MAPUNIT_WIDTH) div 2 - ShiftX;
  J := (FClientHeight - MAPUNIT_HEIGHT) div 2 - ShiftY;

  // ������Ҫ���Ƶĵ�ͼ�㷶Χ(TMapPoint)
  MapRect.Left := Max(0, CenterX - Ceil(I / MAPUNIT_WIDTH));
  MapRect.Right := Min(FWidth, CenterX + Ceil((FClientWidth - I) / MAPUNIT_WIDTH));
  MapRect.Top := Max(0, CenterY - Ceil(J / MAPUNIT_HEIGHT));
  MapRect.Bottom := Min(FHeight, CenterY + Ceil((FClientHeight - J) / MAPUNIT_HEIGHT));

//  MapRect.Left := MapRect.Left - MapRect.Left mod 2;
//  MapRect.Top := MapRect.Top - MapRect.Top mod 2;

  // ���㿪ʼ����ʱ��ƫ��ֵ(����)
  OffsetX := I - (CenterX - MapRect.Left) * MAPUNIT_WIDTH;
  OffsetY := J - (CenterY - MapRect.Top) * MAPUNIT_HEIGHT;

  // ���Ʊ��� (BkImg)
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

  // ���Ʊ������� (MidImg)
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
  MapRect: TRect;               // ��Ҫ���Ƶ� MAP ���귶Χ
  OffsetX, OffsetY: Integer;    // X, Y ���Ͻ�ƫ��
  I, J: Integer;
  Pt: PMapPoint;
  InfoPtr: PImageInfo;
  ImageIndex: Word;
  AniIndex: Byte;
  IsBlend: Boolean;
begin
  // �Ե�ͼ�м�������/���ϵĿ��(����)
  I := (FClientWidth - MAPUNIT_WIDTH) div 2 - ShiftX;
  J := (FClientHeight - MAPUNIT_HEIGHT) div 2 - ShiftY;

  // ������Ҫ���Ƶĵ�ͼ�㷶Χ(TMapPoint)
  MapRect.Left := Max(0, CenterX - Ceil(I / MAPUNIT_WIDTH));
  MapRect.Right := Min(FWidth, CenterX + Ceil((FClientWidth - I) / MAPUNIT_WIDTH));
  MapRect.Top := Max(0, CenterY - Ceil(J / MAPUNIT_HEIGHT));
  MapRect.Bottom := Min(FHeight, CenterY + Ceil((FClientHeight - J) / MAPUNIT_HEIGHT) + LONGHEIGHT_IMAGE);

  // ���㿪ʼ����ʱ��ƫ��ֵ(����)
  OffsetX := I - (CenterX - MapRect.Left) * MAPUNIT_WIDTH;
  OffsetY := J - (CenterY - MapRect.Top) * MAPUNIT_HEIGHT;

  // ����ǰ�� (FrImg)
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

      // ���ͼƬ�ߴ�=48/32��������ʽ����
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
        // ������ǻ�Ϸ�ʽ
        if not IsBlend then
        begin
          if (InfoPtr^.Width <> 48) or (InfoPtr^.Height <> 32) then
            G_WilObjects[Pt.Area].Draw(ImageIndex - 1, Surface,
              (I - MapRect.Left) * MAPUNIT_WIDTH + OffsetX,
              (J - MapRect.Top + 1) * MAPUNIT_HEIGHT + OffsetY - InfoPtr^.Height, // Ҫ�ü�ȥͼƬ�߶�
              FClientWidth, FClientHeight, True);
        end
        else
        // ����, �ǻ�Ϸ�ʽ
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
