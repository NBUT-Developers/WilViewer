{------------------------------------------------------------------------------}
{ ��Ԫ����: Actor.pas                                                          }
{                                                                              }
{ ��Ԫ����: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ ��������: 2005-01-03 20:30:00                                                }
{                                                                              }
{ ���ܽ���:                                                                    }
{                                                                              }
{   ����2 ����                                                                 }
{                                                                              }
{ ʹ��˵��:                                                                    }
{                                                                              }
{   Hair       = [0:��ͷ��/1:Ů������/2:Ů���к�]                              }
{   Appearance = [0..8] [û���·�/����/�м�/�߼�(��/��/��)/��߼�(��/��/��)]   }
{   Sex        = [0..1] [��/Ů]                                                }
{   Action     = [0..13] (Action ��������֡���޹�, ����ÿ�� Action �� 8 ֡)    }
{   Direction  = [0..7]                                                        }
{   Weapon     = [0..33]                                                       }
{                                                                              }
{   ÿ�� Appearance ���� 14 �� Action                                          }
{   ��ͬ Direction �� Action = Action ����ʼ֡ * 8 * Direction                 }
{                                                                              }
{ ������ʷ:                                                                    }
{                                                                              }
{ �д�����:                                                                    }
{------------------------------------------------------------------------------}
unit Actor;

interface

uses SysUtils, Windows, Math, DirectDraw, AdvDraw, Globals, MirWil, MirMap;


{------------------------------------------------------------------------------}
// ��������
{------------------------------------------------------------------------------}
const
  MAX_HUMANFRAME            = 600;        // ���ද����֡�� [0..599]
  MAX_HAIR                  = 3;          // ͷ��������     [0..2]
  MAX_WEAPON                = 34;         // ����������     [0..34]

  WEAPON_BREAKING_BASE      = 3750;       // ��������Ч��������ַ,ÿ������10֡,��80֡ (magic.wil)
  MAGIC_BUBBLE_BASE         = 3890;       // ħ������Ч��������ַ (magic.wil)

  STATE_BUBBLEDEFENCEUP     = $00100000;  // ħ������

  // Actor ������
  DIR_UP        = 0;
  DIR_UPRIGHT   = 1;
  DIR_RIGHT     = 2;
  DIR_DOWNRIGHT = 3;
  DIR_DOWN      = 4;
  DIR_DOWNLEFT  = 5;
  DIR_LEFT      = 6;
  DIR_UPLEFT    = 7;

  
{------------------------------------------------------------------------------}
// ���ݽṹ����
{------------------------------------------------------------------------------}
type

  // ��������
  PActionInfo = ^TActionInfo;
  TActionInfo = record
    start   : word;              // ��ʼ֡
    frame   : word;              // ֡��
    skip    : word;              // ������֡��
    ftime   : word;              // ÿ֡���ӳ�ʱ��(����)
    usetick : byte;              // (����δ֪)
  end;

  // ��ҵĶ�������
  PHumanAction = ^THumanAction;
  THumanAction = record
    ActStand       : TActionInfo;   //1
    ActWalk        : TActionInfo;   //8
    ActRun         : TActionInfo;   //8
    ActRushLeft    : TActionInfo;
    ActRushRight   : TActionInfo;
    ActWarMode     : TActionInfo;   //1
    ActHit         : TActionInfo;   //6
    ActHeavyHit    : TActionInfo;   //6
    ActBigHit      : TActionInfo;   //6
    ActFireHitReady: TActionInfo;   //6
    ActSpell       : TActionInfo;   //6
    ActSitdown     : TActionInfo;   //1
    ActStruck      : TActionInfo;   //3
    ActDie         : TActionInfo;   //4
  end;

{------------------------------------------------------------------------------}
// TActor class 
{------------------------------------------------------------------------------}
  TActor = class(TObject)
  protected
    FrameCount      : Word;       // ��ǰ��������֡��
    FrameStart      : Word;       // ��ǰ�����Ŀ�ʼ֡����
    FrameEnd        : Word;       // ��ǰ�����Ľ���֡����
    FrameTime       : Word;       // ��ǰ����ÿ֡�ȴ���ʱ��

    FrameIndex      : Word;       // ��ǰ֡����
    FrameTick       : Cardinal;   // ��ǰ֡��ʾʱ�� GetTickCount

  public
    CurrentMap      : TMirMap;    // ��ǰ�������ڵ�ͼ

    CurrentAction   : Byte;       // ��ǰ����
    Direction       : Byte;       // ��ǰ����
    Appearance      : Word;       // �����ʾ(�� HumanActor ���൱�ڼ���)
                                  // ������, ���� GetOffset ���

    IsInAction      : Boolean;    // �Ƿ�������һ�� Action �¼���(ActStand ����)

    MapX            : Word;       // ���ڵ�ͼ�ϵ�λ��(�� MapPoint Ϊ��λ)
    MapY            : Word;
    ShiftX          : Integer;    // ��ǰλ��(���ص�λ, ���� Walk, Run)
    ShiftY          : Integer;
    MovX            : Integer;    // �ϴ� Walk, Run Action ��ƫ��ֵ
    MovY            : Integer;

    constructor Create(Map: TMirMap); virtual; abstract;

    // ���¼��㶯��֡
    procedure ReCalcFrames; virtual; abstract;
    // ���ݾ�����ʱ�䴦����һ֡
    procedure ProcessFrame; virtual; abstract;
  end;


{------------------------------------------------------------------------------}
// THumanActor class
{------------------------------------------------------------------------------}
  THumanActor = class(TActor)
  private
  protected
    BodyOffset          : Word;       // ����ͼƬ��������ƫ��
    HairOffset          : Word;       // ͷ��ͼƬ��������ƫ��
    WeaponOffset        : Word;       // ����ͼƬ��������ƫ��

    WeaponOrder         : Byte;       // ��������˳��(�Ƿ������������)

    IsWeaponBreaking    : Boolean;    // �Ƿ���ʾ��������Ч��
    WeaponBreakingFrame : Word;       // ��������Ч����ǰ֡

  public
    Sex                 : Byte;       // �Ա�
    Job                 : Byte;       // ְҵ
    Hair                : Byte;       // ����
    Weapon              : Byte;       // ����

    constructor Create(Map: TMirMap); override;

    procedure ReCalcFrames; override;
    procedure ProcessFrame; override;
    procedure Draw(Surface: IDirectDrawSurface7; X, Y, Width, Height: Integer);

    function CalcNextDirection: Boolean;
    // �ƶ��� MapPoint, ��Ȼ MapPoint ���궨��Ϊ Word, ��������� Integer ����
    // ��Ϊ��ҿ��Ե���� Map ���긺�������ת��
    procedure Walk(X, Y: Integer);
    procedure Run(X, Y: Integer);
    procedure Hit(X, Y: Integer);
  end;


const

{------------------------------------------------------------------------------}
// ���ﶯ��ͼƬ����
{------------------------------------------------------------------------------}
  // ���¶���������� 9 * 2 * 600 = 10800 ��ͼƬ
  // Appearance = [0..8] [û���·�/����/�м�/�߼�(��/��/��)/��߼�(��/��/��)]
  // Sex        = [0..1] [��/Ů]

  // ÿ�� Appearance ���� 14 �� Action
  // ��ͬ Direction �� Action = Action ����ʼ֡ * 8 * Direction  
  // Action     = [0 - 13] (Action ��������֡���޹�, ����ÿ�� Action �� 8 ֡)
  // Direction  = [0 - 7]

  HUMANACTION_STAND         = 0;
  HUMANACTION_WALK          = 1;
  HUMANACTION_RUN           = 2;
  HUMANACTION_RUSHLEFT      = 3;
  HUMANACTION_RUSHRIGHT     = 4;
  HUMANACTION_WARMODE       = 5;
  HUMANACTION_HIT           = 6;
  HUMANACTION_HEAVYHIT      = 7;
  HUMANACTION_BIGHIT        = 8;
  HUMANACTION_FIREHITREADY  = 9;
  HUMANACTION_SPELL         = 10;
  HUMANACTION_SITDOWN       = 11;
  HUMANACTION_STRUCK        = 12;
  HUMANACTION_DIE           = 13;

  HUMANACTIONS: THumanAction =
  (
    //                ��ʼ֡      ��Ч֡    ����֡   ÿ֡�ӳ�    (����δ֪)
    ActStand:        (start: 0;   frame: 4; skip: 4; ftime: 200; usetick: 0);
    ActWalk:         (start: 64;  frame: 6; skip: 2; ftime: 80;  usetick: 2);
    ActRun:          (start: 128; frame: 6; skip: 2; ftime: 90; usetick: 3);
    ActRushLeft:     (start: 128; frame: 3; skip: 5; ftime: 120; usetick: 3);
    ActRushRight:    (start: 131; frame: 3; skip: 5; ftime: 120; usetick: 3);
    ActWarMode:      (start: 192; frame: 1; skip: 0; ftime: 200; usetick: 0);
    //ActHit:        (start: 200; frame: 5; skip: 3; ftime: 140; usetick: 0);
    ActHit:          (start: 200; frame: 6; skip: 2; ftime: 85;  usetick: 0);
    ActHeavyHit:     (start: 264; frame: 6; skip: 2; ftime: 90;  usetick: 0);
    ActBigHit:       (start: 328; frame: 8; skip: 0; ftime: 70;  usetick: 0);
    ActFireHitReady: (start: 192; frame: 6; skip: 4; ftime: 70;  usetick: 0);
    ActSpell:        (start: 392; frame: 6; skip: 2; ftime: 60;  usetick: 0);
    ActSitdown:      (start: 456; frame: 2; skip: 0; ftime: 300; usetick: 0);
    ActStruck:       (start: 472; frame: 3; skip: 5; ftime: 70;  usetick: 0);
    ActDie:          (start: 536; frame: 4; skip: 4; ftime: 120; usetick: 0);
  );

{  HUMANACTIONS: THumanAction =
  (
    //                ��ʼ֡      ��Ч֡    ����֡   ÿ֡�ӳ�    (����δ֪)
    ActStand:        (start: 0;   frame: 4; skip: 4; ftime: 200; usetick: 0);
    ActWalk:         (start: 64;  frame: 6; skip: 2; ftime: 90;  usetick: 2);
    ActRun:          (start: 128; frame: 6; skip: 2; ftime: 120; usetick: 3);
    ActRushLeft:     (start: 128; frame: 3; skip: 5; ftime: 120; usetick: 3);
    ActRushRight:    (start: 131; frame: 3; skip: 5; ftime: 120; usetick: 3);
    ActWarMode:      (start: 192; frame: 1; skip: 0; ftime: 200; usetick: 0);
    //ActHit:        (start: 200; frame: 5; skip: 3; ftime: 140; usetick: 0);
    ActHit:          (start: 200; frame: 6; skip: 2; ftime: 85;  usetick: 0);
    ActHeavyHit:     (start: 264; frame: 6; skip: 2; ftime: 90;  usetick: 0);
    ActBigHit:       (start: 328; frame: 8; skip: 0; ftime: 70;  usetick: 0);
    ActFireHitReady: (start: 192; frame: 6; skip: 4; ftime: 70;  usetick: 0);
    ActSpell:        (start: 392; frame: 6; skip: 2; ftime: 60;  usetick: 0);
    ActSitdown:      (start: 456; frame: 2; skip: 0; ftime: 300; usetick: 0);
    ActStruck:       (start: 472; frame: 3; skip: 5; ftime: 70;  usetick: 0);
    ActDie:          (start: 536; frame: 4; skip: 4; ftime: 120; usetick: 0);
  );
}

{------------------------------------------------------------------------------}
// ��������˳�� (�Ƿ������������: 0��/1��)
// WEAPONORDERS: array [Sex, FrameIndex] of Byte
{------------------------------------------------------------------------------}
  WEAPONORDERS: array[0..1, 0..MAX_HUMANFRAME - 1] of Byte =
  (
    (
      //
      0,0,0,0,0,0,0,0,    1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,    0,0,0,0,0,0,0,0,    0,0,0,0,1,1,1,1,
      0,0,0,0,1,1,1,1,    0,0,0,0,1,1,1,1,
      //
      0,0,0,0,0,0,0,0,    1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,    0,0,0,0,0,0,0,0,    0,0,0,0,0,0,0,1,
      0,0,0,0,0,0,0,1,    0,0,0,0,0,0,0,1,
      //
      0,0,0,0,0,0,0,0,    1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,    0,0,1,1,1,1,1,1,    0,0,1,1,1,0,0,1,
      0,0,0,0,0,0,0,1,    0,0,0,0,0,0,0,1,
      //
      0,1,1,1,0,0,0,0,
      //
      1,1,1,0,0,0,1,1,    1,1,1,0,0,0,0,0,    1,1,1,0,0,0,0,0,
      1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,    1,1,1,0,0,0,0,0,
      0,0,0,0,0,0,0,0,    1,1,1,1,0,0,1,1,
      //
      0,1,1,0,0,0,1,1,    0,1,1,0,0,0,1,1,    1,1,1,0,0,0,0,0,
      1,1,1,0,0,1,1,1,    1,1,1,1,1,1,1,1,    0,1,1,1,1,1,1,1,
      0,0,0,1,1,1,0,0,    0,1,1,1,1,0,1,1,
      //
      1,1,0,1,0,0,0,0,    1,1,0,0,0,0,0,0,    1,1,1,1,1,0,0,0,
      1,1,0,0,1,0,0,0,    1,1,1,0,0,0,0,1,    0,1,1,0,0,0,0,0,
      0,0,0,0,1,1,1,0,    1,1,1,1,1,0,0,0,
      //
      0,0,0,0,0,0,1,1,    0,0,0,0,0,0,1,1,    0,0,0,0,0,0,1,1,
      1,0,0,0,0,1,1,1,    1,1,1,1,1,1,1,1,    0,1,1,1,1,1,1,1,
      0,0,1,1,0,0,1,1,    0,0,0,1,0,0,1,1,
      //
      0,0,1,0,1,1,1,1,    1,1,0,0,0,1,0,0,
      //
      0,0,0,1,1,1,1,1,    1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,    0,0,0,1,1,1,1,1,    0,0,0,1,1,1,1,1,
      0,0,0,1,1,1,1,1,    0,0,0,1,1,1,1,1,
      //
      0,0,1,1,1,1,1,1,    0,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,    0,0,0,1,1,1,1,1,    0,0,0,1,1,1,1,1,
      0,0,0,1,1,1,1,1,    0,0,0,1,1,1,1,1
    ),

    (
      //
      0,0,0,0,0,0,0,0,    1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,    0,0,0,0,0,0,0,0,    0,0,0,0,1,1,1,1,
      0,0,0,0,1,1,1,1,    0,0,0,0,1,1,1,1,
      //
      0,0,0,0,0,0,0,0,    1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,    0,0,0,0,0,0,0,0,    0,0,0,0,0,0,0,1,
      0,0,0,0,0,0,0,1,    0,0,0,0,0,0,0,1,
      //
      0,0,0,0,0,0,0,0,    1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,    0,0,1,1,1,1,1,1,    0,0,1,1,1,0,0,1,
      0,0,0,0,0,0,0,1,    0,0,0,0,0,0,0,1,
      //
      1,1,1,1,0,0,0,0,
      //
      1,1,1,0,0,0,1,1,    1,1,1,0,0,0,0,0,    1,1,1,0,0,0,0,0,
      1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,    1,1,1,0,0,0,0,0,
      0,0,0,0,0,0,0,0,    1,1,1,1,0,0,1,1,
      //
      0,1,1,0,0,0,1,1,    0,1,1,0,0,0,1,1,    1,1,1,0,0,0,0,0,
      1,1,1,0,0,1,1,1,    1,1,1,1,1,1,1,1,    0,1,1,1,1,1,1,1,
      0,0,0,1,1,1,0,0,    0,1,1,1,1,0,1,1,
      //
      1,1,0,1,0,0,0,0,    1,1,0,0,0,0,0,0,    1,1,1,1,1,0,0,0,
      1,1,0,0,1,0,0,0,    1,1,1,0,0,0,0,1,    0,1,1,0,0,0,0,0,
      0,0,0,0,1,1,1,0,    1,1,1,1,1,0,0,0,
      //
      0,0,0,0,0,0,1,1,    0,0,0,0,0,0,1,1,    0,0,0,0,0,0,1,1,
      1,0,0,0,0,1,1,1,    1,1,1,1,1,1,1,1,    0,1,1,1,1,1,1,1,
      0,0,1,1,0,0,1,1,    0,0,0,1,0,0,1,1,
      //
      0,0,1,0,1,1,1,1,    1,1,0,0,0,1,0,0,
      //
      0,0,0,1,1,1,1,1,    1,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,    0,0,0,1,1,1,1,1,    0,0,0,1,1,1,1,1,
      0,0,0,1,1,1,1,1,    0,0,0,1,1,1,1,1,
      //
      0,0,1,1,1,1,1,1,    0,1,1,1,1,1,1,1,    1,1,1,1,1,1,1,1,
      1,1,1,1,1,1,1,1,    0,0,0,1,1,1,1,1,    0,0,0,1,1,1,1,1,
      0,0,0,1,1,1,1,1,    0,0,0,1,1,1,1,1
    )
  );


implementation

function GetBodyImageOffset(appr: integer): integer;
var
   nrace, npos: integer;
begin
   Result := 0;
   nrace := appr div 10;
   npos := appr mod 10;
   case nrace of
      0:    Result := npos * 280;  //8������
      1:    Result := npos * 230;
      2, 3, 7..16:    Result := npos * 360;  //10������ �⺻
      4:    begin
               Result := npos * 360;        //
               if npos = 1 then Result := 600;  //�񸷿���
            end;
      5:    Result := npos * 430;   //����
      6:    Result := npos * 440;   //�ָ�����,ȣ��,��
      17:   Result := npos * 350;   //�ż�
      90:   case npos of
               0: Result := 80;   //����
               1: Result := 168;
               2: Result := 184;
               3: Result := 200;
            end;
   end;
end;


{ THumanActor }

procedure THumanActor.Draw(Surface: IDirectDrawSurface7; X, Y, Width, Height: Integer);
var
  Index: Word;
begin
  // ��������,����ķ�Χ [0..33] (WeaponOrder = 0)
  if (WeaponOrder = 0) and (Weapon > 0) and (Weapon < MAX_WEAPON) then
    G_WilWeapon.DrawEx(WeaponOffset + FrameIndex, Surface, X, Y,
      CLIENT_WIDTH, CLIENT_HEIGHT, True);

  // ��������
  G_WilHuman.DrawEx(BodyOffset + FrameIndex, Surface, X, Y,
    CLIENT_WIDTH, CLIENT_HEIGHT, True);

  // ����ͷ��,����ķ�Χ [0..2]
  if (Hair > 0) and (Hair < MAX_HAIR) then
    G_WilHair.DrawEx(HairOffset + FrameIndex, Surface, X, Y,
      CLIENT_WIDTH, CLIENT_HEIGHT, True);

  // ��������,����ķ�Χ [0..33] (WeaponOrder = 1)
  if (WeaponOrder = 1) and (Weapon > 0) and (Weapon < MAX_WEAPON) then
    G_WilWeapon.DrawEx(WeaponOffset + FrameIndex, Surface, X, Y,
      CLIENT_WIDTH, CLIENT_HEIGHT, True);

  // TODO: ���»��ƶ����� DrawBlend Ч��, ���� Blt ����

// ����ħ������
//  if (State and STATE_BUBBLEDEFENCEUP) <> 0 then
//    if (Action = SM_STRUCK) and (CurBubbleStruck < 3) then
//      Index := MAGBUBBLESTRUCKBASE + CurBubbleStruck
//    else

  if Job = 1  then
  begin
    Index := MAGIC_BUBBLE_BASE + (FrameIndex mod 3);
    DrawBlend(Surface, X + G_WilMagic.ImageInfo[Index]^.PX,
      Y + G_WilMagic.ImageInfo[Index]^.PY, Width, Height,
      G_WilMagic.Surfaces[Index],
      G_WilMagic.ImageInfo[Index]^.Width,
      G_WilMagic.ImageInfo[Index]^.Height,
      0);
  end;

  // ������������Ч��
  if IsWeaponBreaking then
  begin
    Index := WEAPON_BREAKING_BASE + Direction * 10 + WeaponBreakingFrame;
    G_WilMagic.DrawEx(Index, Surface, X, Y, CLIENT_WIDTH, CLIENT_HEIGHT, True);
  end;

end;

procedure THumanActor.ProcessFrame;
var
  CurrTick: Cardinal;
  NewIndex: Integer;
begin
  inherited;

  CurrTick := GetTickCount;

  case CurrentAction of
    HUMANACTION_WALK:
      begin
        ShiftX := MovX * MAPUNIT_WIDTH  * Integer((CurrTick - FrameTick)) div (FrameTime * FrameCount);
        ShiftY := MovY * MAPUNIT_HEIGHT * Integer((CurrTick - FrameTick)) div (FrameTime * FrameCount);
      end;

    HUMANACTION_RUN:
      begin
        ShiftX := MovX * 2 * MAPUNIT_WIDTH  * Integer((CurrTick - FrameTick)) div (FrameTime * FrameCount);
        ShiftY := MovY * 2 * MAPUNIT_HEIGHT * Integer((CurrTick - FrameTick)) div (FrameTime * FrameCount);
      end;
  end;

  NewIndex := FrameStart + (CurrTick - FrameTick) div (FrameTime);
  if NewIndex = FrameIndex then Exit;   // �ж��Ƿ���Ҫ����֡

  FrameIndex := NewIndex;
  // TODO: ���� GetTickCount ���� 49 ����ѭ������
  if FrameIndex < FrameStart then FrameIndex := FrameStart;

  if FrameIndex > FrameEnd then
  begin
    case CurrentAction of
      HUMANACTION_WALK:
        begin
          Inc(MapX, MovX);
          Inc(MapY, MovY);
        end;

      HUMANACTION_RUN:
        begin
          Inc(MapX, MovX * 2);
          Inc(MapY, MovY * 2);
        end;
    end;
    CurrentAction := HUMANACTION_STAND;
    ReCalcFrames;
  end;

  // ������������˳��
  WeaponOrder := WEAPONORDERS[Sex, FrameIndex];

  // ������������Ч��֡
  Inc(WeaponBreakingFrame);
  if WeaponBreakingFrame >= 10 then WeaponBreakingFrame := 0;
end;

constructor THumanActor.Create(Map: TMirMap);
begin
  inherited;
  Appearance := 7;
  Job := 1;
  Sex := 1;
  Hair := 2;
  Direction := 5;
  Weapon := 31;
  IsWeaponBreaking := False;
  CurrentAction := HUMANACTION_STAND;
  MapX := 300;
  MapY := 300;

  CurrentMap := Map;
end;

procedure THumanActor.ReCalcFrames;
var
  InfoPtr: PActionInfo;
begin
  inherited;

  case CurrentAction of
    0: InfoPtr := @HUMANACTIONS.ActStand;
    1: InfoPtr := @HUMANACTIONS.ActWalk;
    2: InfoPtr := @HUMANACTIONS.ActRun;
    3: InfoPtr := @HUMANACTIONS.ActRushLeft;
    4: InfoPtr := @HUMANACTIONS.ActRushRight;
    5: InfoPtr := @HUMANACTIONS.ActWarMode;
    6: InfoPtr := @HUMANACTIONS.ActHit;
    7: InfoPtr := @HUMANACTIONS.ActHeavyHit;
    8: InfoPtr := @HUMANACTIONS.ActBigHit;
    9: InfoPtr := @HUMANACTIONS.ActFireHitReady;
   10: InfoPtr := @HUMANACTIONS.ActSpell;
   11: InfoPtr := @HUMANACTIONS.ActSitdown;
   12: InfoPtr := @HUMANACTIONS.ActStruck;
   13: InfoPtr := @HUMANACTIONS.ActDie;
  else
    raise Exception.CreateFmt('Unknown Human Action : %d', [CurrentAction]);
  end;

  // ����ͼƬƫ��ֵ
  BodyOffset := MAX_HUMANFRAME * (Appearance * 2 + Sex) + Direction * 8;
  // ͷ��ͼƬƫ��ֵ
  if (Hair > 0) and (Hair < MAX_HAIR) then
    HairOffset := MAX_HUMANFRAME * (Hair * 2 + Sex) + Direction * 8;
  // ����ͼƬƫ��ֵ
  if (Weapon > 0) and (Weapon < MAX_WEAPON) then
    WeaponOffset := MAX_HUMANFRAME * (Weapon * 2 + Sex) + Direction * 8;

  FrameCount := InfoPtr^.frame;
  FrameStart := InfoPtr^.start;
  FrameEnd   := FrameStart + FrameCount - 1;
  FrameTime  := InfoPtr^.ftime;
  FrameIndex := FrameStart;
  FrameTick  := GetTickCount;

  ShiftX := 0;
  ShiftY := 0;
end;

function THumanActor.CalcNextDirection: Boolean;
var
  NewDir: Byte;
begin
  if (MovX = -1) and (MovY = -1) then NewDir := DIR_UPLEFT    else
  if (MovX = -1) and (MovY =  0) then NewDir := DIR_LEFT      else
  if (MovX = -1) and (MovY =  1) then NewDir := DIR_DOWNLEFT  else
  if (MovX =  0) and (MovY = -1) then NewDir := DIR_UP        else
  if (MovX =  0) and (MovY =  1) then NewDir := DIR_DOWN      else
  if (MovX =  1) and (MovY = -1) then NewDir := DIR_UPRIGHT   else
  if (MovX =  1) and (MovY =  0) then NewDir := DIR_RIGHT     else
  if (MovX =  1) and (MovY =  1) then NewDir := DIR_DOWNRIGHT else
    raise Exception.Create('CalcNextDirection');

  Result := NewDir <> Direction;
  if Result then Direction := NewDir;
end;

procedure THumanActor.Walk(X, Y: Integer);
begin
  if CurrentAction <> HUMANACTION_STAND then Exit;

  MovX := Min(1, Max(-1, X - MapX));
  MovY := Min(1, Max(-1, Y - MapY));
  if (MovX = 0) and (MovY = 0) then Exit;

  if CalcNextDirection then ReCalcFrames;

  if not CurrentMap.CanMove(MapX + MovX, MapY + MovY) then Exit;
  CurrentAction := HUMANACTION_WALK;
  ReCalcFrames;
end;

procedure THumanActor.Run(X, Y: Integer);
begin
  if CurrentAction <> HUMANACTION_STAND then Exit;

  MovX := Min(1, Max(-1, X - MapX));
  MovY := Min(1, Max(-1, Y - MapY));
  if (MovX = 0) and (MovY = 0) then Exit;

  if CalcNextDirection then ReCalcFrames;

  if not CurrentMap.CanMove(MapX + MovX, MapY + MovY) then Exit;
  if not CurrentMap.CanMove(MapX + MovX * 2, MapY + MovY * 2) then
  begin
    Walk(X, Y);
    Exit;
  end;
  CurrentAction := HUMANACTION_RUN;
  ReCalcFrames;
end;

procedure THumanActor.Hit(X, Y: Integer);
begin
  if CurrentAction <> HUMANACTION_STAND then Exit;

  MovX := Min(1, Max(-1, X - MapX));
  MovY := Min(1, Max(-1, Y - MapY));
  if (MovX = 0) and (MovY = 0) then Exit;

  CalcNextDirection;
  CurrentAction := HUMANACTION_HIT;
  ReCalcFrames;
end;

end.
