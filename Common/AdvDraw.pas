{------------------------------------------------------------------------------}
{ ��Ԫ����: AdvDraw.pas                                                        }
{                                                                              }
{ ��Ԫ����: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ ��������: 2005-01-04                                                         }
{                                                                              }
{ ���ܽ���:                                                                    }
{                                                                              }
{   �߼�ͼ�δ�������                                                         }
{                                                                              }
{ ʹ��˵��:                                                                    }
{                                                                              }
{ ������ʷ:                                                                    }
{                                                                              }
{ �д�����:                                                                    }
{                                                                              }
{------------------------------------------------------------------------------}
unit AdvDraw;

interface

uses SysUtils, Windows, Math, DirectDraw, DebugUnit;

const
   MAXGRADE = 64;
   DIVUNIT = 4;
   NEARESTPALETTEINDEX_FILE = 'Nearest.idx';
   
var
  Color256Mix: array[0..255, 0..255] of byte;
  Color256Anti: array[0..255, 0..255] of byte;
  HeavyDarkColorLevel: array[0..255, 0..255] of byte;
  LightDarkColorLevel: array[0..255, 0..255] of byte;
  DengunColorLevel: array[0..255, 0..255] of byte;
{  BrightColorLevel: array[0..255] of byte;
  GrayScaleLevel: array[0..255] of byte;
  RedishColorLevel: array[0..255] of byte;
  BlackColorLevel: array[0..255] of byte;
  WhiteColorLevel: array[0..255] of byte;
  GreenColorLevel: array[0..255] of byte;
  YellowColorLevel: array[0..255] of byte;
  BlueColorLevel: array[0..255] of byte;
  FuchsiaColorLevel: array[0..255] of byte;
  RgbIndexTable: array[0..MAXGRADE-1, 0..MAXGRADE-1, 0..MAXGRADE-1] of byte;}
  
type

{------------------------------------------------------------------------------}
// 256 ɫλͼ��Ϣ
{------------------------------------------------------------------------------}

  // 256ɫ��ɫ��
  PRGBQuads = ^TRGBQuads;
  TRGBQuads = array[0..255] of TRGBQuad;

  // 256ɫλͼ��Ϣ�ṹ
  PBitmapInfo256 = ^TBitmapInfo256;
  TBitmapInfo256 = packed record
    bmiHeader: TBitmapInfoHeader;
    bmiColors: TRGBQuads;
  end;

  // 256ɫ��ɫ��
  PPaletteEntries = ^TPaletteEntries;
  TPaletteEntries = array[0..255] of TPaletteEntry;

  // TODO: ���������ȥ��
  TNearestIndexHeader = record
    Title: string[30];
    IndexCount: integer;
    desc: array[0..10] of byte;
  end;

{------------------------------------------------------------------------------}
// ���ߺ���
{------------------------------------------------------------------------------}
procedure RGBQuadToPaletteEntry(const ARGBQuad: TRGBQuad; var APaletteEntry: TPaletteEntry);

// FastBlt - �Զ���Ҫ���Ƶľ���������м���
procedure FastBlt(DstSurf: IDirectDrawSurface7; X, Y, DstWidth, DstHeight: Integer;
  SrcSurf: IDirectDrawSurface7; SrcWidth, SrcHeight: Integer; Transparent: Boolean);

procedure BrightEffect(Surface: IDirectDrawSurface7; Width, Height: Integer);

procedure BuildNearestIndex (const ColorTable: TRGBQuads);
procedure SaveNearestIndex (flname: string);
function LoadNearestIndex (flname: string): Boolean;

procedure DrawBlend(DstSurf: IDirectDrawSurface7; DstX, DstY, DstWidth,
  DstHeight: Integer; SrcSurf: IDirectDrawSurface7; SrcWidth, SrcHeight: Integer;
  BlendMode: Integer);

procedure DrawSurfaceText(const Surface: IDirectDrawSurface7; Text: string;
  X, Y: Integer; Font: HFont; Color: TColorRef);


implementation


procedure DrawSurfaceText(const Surface: IDirectDrawSurface7; Text: string;
  X, Y: Integer; Font: HFont; Color: TColorRef);
var
  DC: HDC;
begin
  if Surface.GetDC(DC) <> DD_OK then Exit;
  try
    SetBkMode(DC, TRANSPARENT);
    SelectObject(DC, Font);
    SetTextColor(DC, RGB(64, 64, 0));
    TextOut(DC, X+1, Y+1, PChar(Text), Length(Text));
//    TextOut(DC, X-1, Y-1, PChar(Text), Length(Text));
//    TextOut(DC, X-1, Y+1, PChar(Text), Length(Text));
//    TextOut(DC, X+1, Y-1, PChar(Text), Length(Text));
    SetTextColor(DC, Color);
    TextOut(DC, X, Y, PChar(Text), Length(Text));
  finally
    Surface.ReleaseDC(DC);
  end;
end;

procedure RGBQuadToPaletteEntry(const ARGBQuad: TRGBQuad; var APaletteEntry: TPaletteEntry);
begin
  with APaletteEntry do
    with ARGBQuad do
    begin
      peRed := rgbRed;
      peGreen := rgbGreen;
      peBlue := rgbBlue;
      peFlags := 0;
    end;
end;

procedure FastBlt(DstSurf: IDirectDrawSurface7; X, Y, DstWidth, DstHeight: Integer;
  SrcSurf: IDirectDrawSurface7; SrcWidth, SrcHeight: Integer; Transparent: Boolean);
const
  BltFastFlags: array[Boolean] of Integer =
    (DDBLTFAST_WAIT or DDBLTFAST_NOCOLORKEY,
     DDBLTFAST_WAIT or DDBLTFAST_SRCCOLORKEY);
var
  SrcR: TRect;
  Result: HRESULT;
begin
  if DstSurf = nil then raise Exception.Create('DstSurf = nil!');
  if SrcSurf = nil then raise Exception.Create('SrcSurf = nil!');

  if X >= 0 then
  begin
    if X > DstWidth then Exit;
    SrcR.Left := 0;
  end
  else begin
    if -X >= SrcWidth then Exit;
    SrcR.Left := -X;
  end;

  if Y >= 0 then
  begin
    if Y > DstHeight then Exit;
    SrcR.Top := 0;
  end
  else begin
    if -Y >= SrcHeight then Exit;
    SrcR.Top := -Y;
  end;

  SrcR.Right := SrcWidth;
  if X + SrcWidth > DstWidth then
    Dec(SrcR.Right, (X + SrcWidth - DstWidth));

  SrcR.Bottom := SrcHeight;
  if Y + SrcHeight > DstHeight then
    Dec(SrcR.Bottom, (Y + SrcHeight - DstHeight));

  if (SrcR.Right = SrcR.Left) or (SrcR.Top = SrcR.Bottom) then Exit;

  if X < 0 then X := 0;
  if Y < 0 then Y := 0;

  Result := DstSurf.BltFast(X, Y, SrcSurf, @SrcR, BltFastFlags[Transparent]);
  if Result <> DD_OK then
  begin
    DebugOut('_debugout.txt', format('%d, %d, %d, %d', [srcr.Left, SrcR.top,
      srcr.Right, srcr.Bottom]));
    raise exception.Create('FastBlt failed in AdvDraw!');
  end;
end;



var
// BRIGHTMASK: Int64 = $0000000; //Ҫ����������ĳ̶ȣ�ӦΪ
 BRIGHTMASK: Int64 = $4040404040404040; //Ҫ����������ĳ̶ȣ�ӦΪ
                    										//0xABCDEFGHABCDEFGH��ʽ
                                        //��һ�ľͿ���������ɫ�ƹ�Ч��
procedure BrightEffect(Surface: IDirectDrawSurface7; Width, Height: Integer);
var
  DDSD: TDDSurfaceDesc2;
  SurfaceBits: Pointer;
  Pitch: Integer;
begin
  FillChar(DDSD, SizeOf(DDSD), #0);
  DDSD.dwSize := SizeOf(DDSD);
  if Surface.Lock(nil, DDSD, DDLOCK_WAIT, 0) <> DD_OK then Exit;
  SurfaceBits := DDSD.lpSurface;
  Pitch := DDSD.lPitch;
  Width := Width div 2;
  try
    asm
      MOVQ mm1,BRIGHTMASK
      MOV EAX,SurfaceBits;  // ӦΪ��̨�����ָ�� lpSurfase
//      add eax,Pitch;
      MOV ECX,Height        // Ҫ���������ĸ߶�

    @@OUTLOOP:
      PUSH EAX
      MOV EBX,Width         // Ҫ���������Ŀ��/2
//      SHR EBX,1
    @@INLOOP:
      MOVQ mm0,[EAX]
      PADDUSB mm0,mm1       // ���Ҫ��������� PUSBUSB �ĳ� PADDUSB
      MOVQ [EAX],mm0
      ADD EAX,8
      DEC EBX
      JNZ @@INLOOP
      POP EAX
      ADD EAX,Pitch
      DEC ECX
      JNZ @@OUTLOOP
          
      EMMS
    end;
  finally
    if Surface.Unlock(nil) <> DD_OK then raise exception.create('error');
  end;
end;

procedure BuildNearestIndex (const ColorTable: TRGBQuads);
var
   MinDif, ColDif: Integer;
   MatchColor: Byte;
   pal0, pal1, pal2: TRGBQuad;

    //��ɫ����256X256
   procedure BuildMix;
   var
      i, j, n: integer;
   begin
      for i:= 0 to 255 do begin
         pal0 := ColorTable[i];
         for j:=0 to 255 do begin
            pal1 := ColorTable[j];
            pal1.rgbRed := pal0.rgbRed div 2 + pal1.rgbRed div 2;
            pal1.rgbGreen := pal0.rgbGreen div 2 + pal1.rgbGreen div 2;
            pal1.rgbBlue := pal0.rgbBlue div 2 + pal1.rgbBlue div 2;
            MinDif := 768;
            MatchColor := 0;
            for n:=0 to 255 do begin
               pal2 := ColorTable[n];
               ColDif := Abs(pal2.rgbRed - pal1.rgbRed) +
                         Abs(pal2.rgbGreen - pal1.rgbGreen) +
                         Abs(pal2.rgbBlue - pal1.rgbBlue);
               if ColDif < MinDif then begin
                  MinDif := ColDif;
                  MatchColor := n;
               end;
            end;
            Color256Mix[i, j] := MatchColor;
         end;
      end;
   end;

   //��ɫ�嶯����ɫ��256X256
   procedure BuildAnti;
   var
      i, j, n: integer;
   begin
      for i:= 0 to 255 do begin
         pal0 := ColorTable[i];
         for j:= 0 to 255 do begin
            pal1 := ColorTable[j];
            pal1.rgbRed   := Min(255, Round(pal0.rgbRed   + (255-pal0.rgbRed)   / 255 * pal1.rgbRed));
            pal1.rgbGreen := Min(255, Round(pal0.rgbGreen + (255-pal0.rgbGreen) / 255 * pal1.rgbGreen));
            pal1.rgbBlue  := Min(255, Round(pal0.rgbBlue  + (255-pal0.rgbBlue)  / 255 * pal1.rgbBlue));
            MinDif := 768;
            MatchColor := 0;
            for n:=0 to 255 do begin
               pal2 := ColorTable[n];
               ColDif := Abs(pal2.rgbRed - pal1.rgbRed) +
                         Abs(pal2.rgbGreen - pal1.rgbGreen) +
                         Abs(pal2.rgbBlue - pal1.rgbBlue);
               if ColDif < MinDif then begin
                  MinDif := ColDif;
                  MatchColor := n;
               end;
            end;
            Color256Anti[i,j] := MatchColor;
         end;
      end;
   end;

   //�ҽ���ɫ��256X256
   procedure BuildColorLevels;
   var
      n, i, j, rr, gg, bb: integer;
   begin
      for n:= 0 to 30 do begin
         for i:=0 to 255 do begin
            pal1 := ColorTable[i];
            rr := Min(Round(pal1.rgbRed * (n+1) / 31) - 5, 255);      //(n + (n-1)*3) / 121);
            gg := Min(Round(pal1.rgbGreen * (n+1) / 31) - 5, 255);  //(n + (n-1)*3) / 121);
            bb := Min(Round(pal1.rgbBlue * (n+1) / 31) - 5, 255);    //(n + (n-1)*3) / 121);
            pal1.rgbRed := Max(0, rr);
            pal1.rgbGreen := Max(0, gg);
            pal1.rgbBlue := Max(0, bb);
            MinDif := 768;
            MatchColor := 0;
            for j:= 0 to 255 do begin
               pal2 := ColorTable[j];
               ColDif := Abs(pal2.rgbRed - pal1.rgbRed) +
                         Abs(pal2.rgbGreen - pal1.rgbGreen) +
                         Abs(pal2.rgbBlue - pal1.rgbBlue);
               if ColDif < MinDif then begin
                  MinDif := ColDif;
                  MatchColor := j;
               end;
            end;
            HeavyDarkColorLevel[n, i] := MatchColor;
         end;
      end;
      for n:=0 to 30 do begin
         for i:=0 to 255 do begin
            pal1 := ColorTable[i];
            pal1.rgbRed := Min(Round(pal1.rgbRed * (n*3+47) / 140), 255);
            pal1.rgbGreen := Min(Round(pal1.rgbGreen * (n*3+47) / 140), 255);
            pal1.rgbBlue := Min(Round(pal1.rgbBlue * (n*3+47) / 140), 255);
            MinDif := 768;
            MatchColor := 0;
            for j:=0 to 255 do begin
               pal2 := ColorTable[j];
               ColDif := Abs(pal2.rgbRed - pal1.rgbRed) +
                         Abs(pal2.rgbGreen - pal1.rgbGreen) +
                         Abs(pal2.rgbBlue - pal1.rgbBlue);
               if ColDif < MinDif then begin
                  MinDif := ColDif;
                  MatchColor := j;
               end;
            end;
            LightDarkColorLevel[n, i] := MatchColor;
         end;
      end;
      for n:=0 to 30 do begin
         for i:=0 to 255 do begin
            pal1 := ColorTable[i];
            pal1.rgbRed := Min(Round(pal1.rgbRed * (n*3+120) / 214), 255);
            pal1.rgbGreen := Min(Round(pal1.rgbGreen * (n*3+120) / 214), 255);
            pal1.rgbBlue := Min(Round(pal1.rgbBlue * (n*3+120) / 214), 255);
            MinDif := 768;
            MatchColor := 0;
            for j:=0 to 255 do begin
               pal2 := ColorTable[j];
               ColDif := Abs(pal2.rgbRed - pal1.rgbRed) +
                         Abs(pal2.rgbGreen - pal1.rgbGreen) +
                         Abs(pal2.rgbBlue - pal1.rgbBlue);
               if ColDif < MinDif then begin
                  MinDif := ColDif;
                  MatchColor := j;
               end;
            end;
            DengunColorLevel[n, i] := MatchColor;
         end;
      end;

      {for i:=0 to 255 do begin
         HeavyDarkColorLevel[0, i] := HeavyDarkColorLevel[1, i];
         LightDarkColorLevel[0, i] := LightDarkColorLevel[1, i];
         DengunColorLevel[0, i] := DengunColorLevel[1, i];
      end;}
      for n:=31 to 255 do
         for i:=0 to 255 do begin
            HeavyDarkColorLevel[n, i] := HeavyDarkColorLevel[30, i];
            LightDarkColorLevel[n, i] := LightDarkColorLevel[30, i];
            DengunColorLevel[n, i] := DengunColorLevel[30, i];
         end;

   end;
begin
   BuildMix;
   BuildAnti;
   BuildColorLevels;
end;


procedure SaveNearestIndex (flname: string);
var
   nih: TNearestIndexHeader;
   fhandle: integer;
begin
   nih.Title := 'WEMADE Entertainment Inc.';
   nih.IndexCount := Sizeof(Color256Mix);
   if FileExists (flname) then begin
      fhandle := FileOpen (flname, fmOpenWrite or fmShareDenyNone);
   end else
      fhandle := FileCreate (flname);
   if fhandle > 0 then begin
      FileWrite (fhandle, nih, sizeof(TNearestIndexHeader));
      FileWrite (fhandle, Color256Mix, sizeof(Color256Mix));
      FileWrite (fhandle, Color256Anti, sizeof(Color256Anti));
      FileWrite (fhandle, HeavyDarkColorLevel, sizeof(HeavyDarkColorLevel));
      FileWrite (fhandle, LightDarkColorLevel, sizeof(LightDarkColorLevel));
      FileWrite (fhandle, DengunColorLevel, sizeof(DengunColorLevel));
      FileClose (fhandle);
   end;
end;

function LoadNearestIndex (flname: string): Boolean;
var
   nih: TNearestIndexHeader;
   fhandle, rsize: integer;
begin
   Result := FALSE;
   if FileExists (flname) then begin
      fhandle := FileOpen (flname, fmOpenRead or fmShareDenyNone);
      if fhandle > 0 then begin
         FileRead (fhandle, nih, sizeof(TNearestIndexHeader));
         if nih.IndexCount = Sizeof(Color256Mix) then begin
            Result := TRUE;
            rsize := 256*256;
            if rsize <> FileRead (fhandle, Color256Mix, sizeof(Color256Mix)) then Result := FALSE;
            if rsize <> FileRead (fhandle, Color256Anti, sizeof(Color256Anti)) then Result := FALSE;
            if rsize <> FileRead (fhandle, HeavyDarkColorLevel, sizeof(HeavyDarkColorLevel)) then Result := FALSE;
            if rsize <> FileRead (fhandle, LightDarkColorLevel, sizeof(LightDarkColorLevel)) then Result := FALSE;
            if rsize <> FileRead (fhandle, DengunColorLevel, sizeof(DengunColorLevel)) then Result := FALSE;
         end;
         FileClose (fhandle);
      end;
   end;
end;



//�����ʾ:DayBright:ssurface + dsurface => dsurface
procedure DrawBlend(DstSurf: IDirectDrawSurface7; DstX, DstY, DstWidth,
  DstHeight: Integer; SrcSurf: IDirectDrawSurface7; SrcWidth, SrcHeight: Integer;
  BlendMode: Integer);
var
  SrcDDSD, DstDDSD: TDDSurfaceDesc2;
  SrcBits, DstBits, SrcP, DstP: PByte;
  X, Y: Integer;      // X/Y ����ļ�����
  SrcRect: TRect;     // Դ������Ҫ���Ƶ�����
begin
  if (DstSurf = nil) or (SrcSurf = nil) then Exit;

  // ���Ƶ㳬��Ŀ���������˳�
  if DstX >= DstWidth then Exit;
  if DstY >= DstHeight then Exit;

  // ������߲ü�
  if DstX >= 0 then
    SrcRect.Left := 0 else
    SrcRect.Left := -DstX;
  if SrcRect.Left >= SrcWidth then Exit;

  // �����Ϸ��ü�
  if DstY >= 0 then
    SrcRect.Top := 0 else
    SrcRect.Top := -DstY;
  if SrcRect.Top >= SrcHeight then Exit;

  // �����ҷ��ü�
  if (DstWidth - 1) - DstX >= SrcWidth then
    SrcRect.Right := SrcWidth else
    SrcRect.Right := (DstWidth - 1) - DstX;

  // �����·��ü�
  if (DstHeight - 1) - DstY >= SrcHeight then
    SrcRect.Bottom := SrcHeight else
    SrcRect.Bottom := (DstHeight - 1) - DstY;

  if (SrcRect.Left >= SrcRect.Right) or (SrcRect.Top >= SrcRect.Bottom) then
    Exit;
//    raise Exception.Create('SrcRect error');

  SrcDDSD.dwSize := SizeOf(SrcDDSD);
  DstDDSD.dwSize := SizeOf(DstDDSD);

  try
    if DstSurf.Lock(nil, DstDDSD, DDLOCK_WAIT, 0) <> DD_OK then Exit;
    if SrcSurf.Lock(nil, SrcDDSD, DDLOCK_WAIT, 0) <> DD_OK then Exit;

    SrcBits := SrcDDSD.lpSurface;
    DstBits := DstDDSD.lpSurface;

    for Y :=  SrcRect.Top to SrcRect.Bottom - 1 do
    begin
      DstP := PByte(Integer(DstBits) + DstDDSD.lPitch * (Y + DstY) + DstX + SrcRect.Left);
      SrcP := PByte(Integer(SrcBits) + SrcDDSD.lPitch * Y + SrcRect.Left);
      for X := SrcRect.Left to SrcRect.Right - 1 do
      begin
        DstP^ := Color256Anti[DstP^][SrcP^];
        Inc(DstP);
        Inc(SrcP);
      end;
    end;

  finally
    SrcSurf.UnLock(nil);
    DstSurf.UnLock(nil);
  end;
end;

end.
