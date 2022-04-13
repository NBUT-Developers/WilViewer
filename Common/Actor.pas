{------------------------------------------------------------------------------}
{ 单元名称: Actor.pas                                                          }
{                                                                              }
{ 单元作者: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ 创建日期: 2005-01-03 20:30:00                                                }
{                                                                              }
{ 功能介绍:                                                                    }
{                                                                              }
{   传奇2 人物                                                                 }
{                                                                              }
{ 使用说明:                                                                    }
{                                                                              }
{   Hair       = [0:无头发/1:女红男棕/2:女蓝男红]                              }
{   Appearance = [0..8] [没穿衣服/初级/中级/高级(武/法/道)/最高级(武/法/道)]   }
{   Sex        = [0..1] [男/女]                                                }
{   Action     = [0..13] (Action 数量与总帧数无关, 并非每个 Action 都 8 帧)    }
{   Direction  = [0..7]                                                        }
{   Weapon     = [0..33]                                                       }
{                                                                              }
{   每个 Appearance 包含 14 种 Action                                          }
{   不同 Direction 的 Action = Action 的起始帧 * 8 * Direction                 }
{                                                                              }
{ 更新历史:                                                                    }
{                                                                              }
{ 尚存问题:                                                                    }
{------------------------------------------------------------------------------}
unit Actor;

interface

uses SysUtils, Windows, Math, DirectDraw, AdvDraw, Globals, MirWil, MirMap;


{------------------------------------------------------------------------------}
// 常量定义
{------------------------------------------------------------------------------}
const
  MAX_HUMANFRAME            = 600;        // 人类动画总帧数 [0..599]
  MAX_HAIR                  = 3;          // 头发种类数     [0..2]
  MAX_WEAPON                = 34;         // 武器种类数     [0..34]

  WEAPON_BREAKING_BASE      = 3750;       // 武器破碎效果索引基址,每个方向10帧,共80帧 (magic.wil)
  MAGIC_BUBBLE_BASE         = 3890;       // 魔法气泡效果索引基址 (magic.wil)

  STATE_BUBBLEDEFENCEUP     = $00100000;  // 魔法气泡

  // Actor 方向常量
  DIR_UP        = 0;
  DIR_UPRIGHT   = 1;
  DIR_RIGHT     = 2;
  DIR_DOWNRIGHT = 3;
  DIR_DOWN      = 4;
  DIR_DOWNLEFT  = 5;
  DIR_LEFT      = 6;
  DIR_UPLEFT    = 7;

  
{------------------------------------------------------------------------------}
// 数据结构定义
{------------------------------------------------------------------------------}
type

  // 动作定义
  PActionInfo = ^TActionInfo;
  TActionInfo = record
    start   : word;              // 开始帧
    frame   : word;              // 帧数
    skip    : word;              // 跳过的帧数
    ftime   : word;              // 每帧的延迟时间(毫秒)
    usetick : byte;              // (意义未知)
  end;

  // 玩家的动作定义
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
    FrameCount      : Word;       // 当前动作的总帧数
    FrameStart      : Word;       // 当前动作的开始帧索引
    FrameEnd        : Word;       // 当前动作的结束帧索引
    FrameTime       : Word;       // 当前动作每帧等待的时间

    FrameIndex      : Word;       // 当前帧索引
    FrameTick       : Cardinal;   // 当前帧显示时的 GetTickCount

  public
    CurrentMap      : TMirMap;    // 当前人物所在地图

    CurrentAction   : Byte;       // 当前动作
    Direction       : Byte;       // 当前方向
    Appearance      : Word;       // 外观显示(对 HumanActor 则相当于级别)
                                  // 对其它, 可用 GetOffset 获得

    IsInAction      : Boolean;    // 是否正处在一个 Action 事件中(ActStand 除外)

    MapX            : Word;       // 处于地图上的位置(以 MapPoint 为单位)
    MapY            : Word;
    ShiftX          : Integer;    // 当前位移(像素单位, 用于 Walk, Run)
    ShiftY          : Integer;
    MovX            : Integer;    // 上次 Walk, Run Action 的偏移值
    MovY            : Integer;

    constructor Create(Map: TMirMap); virtual; abstract;

    // 重新计算动画帧
    procedure ReCalcFrames; virtual; abstract;
    // 根据经过的时间处理下一帧
    procedure ProcessFrame; virtual; abstract;
  end;


{------------------------------------------------------------------------------}
// THumanActor class
{------------------------------------------------------------------------------}
  THumanActor = class(TActor)
  private
  protected
    BodyOffset          : Word;       // 身体图片索引的主偏移
    HairOffset          : Word;       // 头发图片索引的主偏移
    WeaponOffset        : Word;       // 武器图片索引的主偏移

    WeaponOrder         : Byte;       // 武器绘制顺序(是否先于身体绘制)

    IsWeaponBreaking    : Boolean;    // 是否显示武器破碎效果
    WeaponBreakingFrame : Word;       // 武器破碎效果当前帧

  public
    Sex                 : Byte;       // 性别
    Job                 : Byte;       // 职业
    Hair                : Byte;       // 发型
    Weapon              : Byte;       // 武器

    constructor Create(Map: TMirMap); override;

    procedure ReCalcFrames; override;
    procedure ProcessFrame; override;
    procedure Draw(Surface: IDirectDrawSurface7; X, Y, Width, Height: Integer);

    function CalcNextDirection: Boolean;
    // 移动至 MapPoint, 虽然 MapPoint 坐标定义为 Word, 这里必须用 Integer 代替
    // 因为玩家可以点击至 Map 坐标负方向进行转向
    procedure Walk(X, Y: Integer);
    procedure Run(X, Y: Integer);
    procedure Hit(X, Y: Integer);
  end;


const

{------------------------------------------------------------------------------}
// 人物动作图片索引
{------------------------------------------------------------------------------}
  // 以下二项数据组成 9 * 2 * 600 = 10800 幅图片
  // Appearance = [0..8] [没穿衣服/初级/中级/高级(武/法/道)/最高级(武/法/道)]
  // Sex        = [0..1] [男/女]

  // 每个 Appearance 包含 14 种 Action
  // 不同 Direction 的 Action = Action 的起始帧 * 8 * Direction  
  // Action     = [0 - 13] (Action 数量与总帧数无关, 并非每个 Action 都 8 帧)
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
    //                开始帧      有效帧    跳过帧   每帧延迟    (意义未知)
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
    //                开始帧      有效帧    跳过帧   每帧延迟    (意义未知)
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
// 武器绘制顺序 (是否先于身体绘制: 0是/1否)
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
      0:    Result := npos * 280;  //8橇贰烙
      1:    Result := npos * 230;
      2, 3, 7..16:    Result := npos * 360;  //10橇贰烙 扁夯
      4:    begin
               Result := npos * 360;        //
               if npos = 1 then Result := 600;  //厚阜盔面
            end;
      5:    Result := npos * 430;   //粱厚
      6:    Result := npos * 440;   //林付脚厘,龋过,空
      17:   Result := npos * 350;   //脚荐
      90:   case npos of
               0: Result := 80;   //己巩
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
  // 绘制武器,允许的范围 [0..33] (WeaponOrder = 0)
  if (WeaponOrder = 0) and (Weapon > 0) and (Weapon < MAX_WEAPON) then
    G_WilWeapon.DrawEx(WeaponOffset + FrameIndex, Surface, X, Y,
      CLIENT_WIDTH, CLIENT_HEIGHT, True);

  // 绘制身体
  G_WilHuman.DrawEx(BodyOffset + FrameIndex, Surface, X, Y,
    CLIENT_WIDTH, CLIENT_HEIGHT, True);

  // 绘制头发,允许的范围 [0..2]
  if (Hair > 0) and (Hair < MAX_HAIR) then
    G_WilHair.DrawEx(HairOffset + FrameIndex, Surface, X, Y,
      CLIENT_WIDTH, CLIENT_HEIGHT, True);

  // 绘制武器,允许的范围 [0..33] (WeaponOrder = 1)
  if (WeaponOrder = 1) and (Weapon > 0) and (Weapon < MAX_WEAPON) then
    G_WilWeapon.DrawEx(WeaponOffset + FrameIndex, Surface, X, Y,
      CLIENT_WIDTH, CLIENT_HEIGHT, True);

  // TODO: 以下绘制都需用 DrawBlend 效果, 暂用 Blt 代替

// 绘制魔法气泡
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

  // 绘制武器破碎效果
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
  if NewIndex = FrameIndex then Exit;   // 判断是否需要计算帧

  FrameIndex := NewIndex;
  // TODO: 可能 GetTickCount 会在 49 天内循环回来
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

  // 计算武器绘制顺序
  WeaponOrder := WEAPONORDERS[Sex, FrameIndex];

  // 计算武器破碎效果帧
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

  // 身体图片偏移值
  BodyOffset := MAX_HUMANFRAME * (Appearance * 2 + Sex) + Direction * 8;
  // 头发图片偏移值
  if (Hair > 0) and (Hair < MAX_HAIR) then
    HairOffset := MAX_HUMANFRAME * (Hair * 2 + Sex) + Direction * 8;
  // 武器图片偏移值
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
