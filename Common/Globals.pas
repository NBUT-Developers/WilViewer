{------------------------------------------------------------------------------}
{ 单元名称: Globals.pas                                                        }
{                                                                              }
{ 单元作者: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ 创建日期: 2005-01-02 20:30:00                                                }
{                                                                              }
{ 功能介绍:                                                                    }
{   传奇2 全局常量/变量                                                        }
{                                                                              }
{ 使用说明:                                                                    }
{                                                                              }
{ 更新历史:                                                                    }
{                                                                              }
{ 尚存问题:                                                                    }
{                                                                              }
{------------------------------------------------------------------------------}
unit Globals;

interface

uses MirWil;


{------------------------------------------------------------------------------}
// 全局常量
{------------------------------------------------------------------------------}
const
  // 屏幕大小
  CLIENT_WIDTH = 800;
  CLIENT_HEIGHT = 600;

  // 显示地图的大小
  MAPSURFACE_WIDTH = 800;
  MAPSURFACE_HEIGHT = 445;

  // 地图单位/背景图片尺寸
  MAPUNIT_WIDTH = 48;
  MAPUNIT_HEIGHT = 32;

  // 地图单位中心象素点
  MAPCENTER_X = (MAPSURFACE_WIDTH - MAPUNIT_WIDTH) div 2;
  MAPCENTER_Y = (MAPSURFACE_HEIGHT - MAPUNIT_HEIGHT) div 2;

  // 逻辑地图单位 (估计是微量屏幕移动的最小值)
  LOGICALMAPUNIT = 20;

var

{------------------------------------------------------------------------------}
// 全局变量
{------------------------------------------------------------------------------}

  // 路径定义
  G_MirPath   : string = 'F:\Games\Legend of Mir\';
  G_MirMapPath: string = 'F:\Games\Legend of Mir\Map\';
  G_MirWilPath: string = 'F:\Games\Legend of Mir\Data\';
  G_MirWavPath: string = 'F:\Games\Legend of Mir\Wave\';

var

{------------------------------------------------------------------------------}
// WIL 图片文件
{------------------------------------------------------------------------------}
  // 前景图片
  G_WilObjects: array[0..6] of TWilFile;
  // 背景图片
  G_WilTile     : TWilFile;
  G_WilTileSm   : TWilFile;
  // 人类角色图片
  G_WilHuman    : TWilFile;         // Human Actor 的身体图片文件 (hum.wil)
  G_WilHair     : TWilFile;         // Human Actor 的头发图片文件 (hair.wil)
  G_WilWeapon   : TWilFile;         // Human Actor 的武器图片文件 (weapon.wil)
  G_WilMagic    : TWilFile;         // Human Actor 的魔法图片文件 (magic.wil)
  // 游戏界面图片
  G_WilPrgUse   : TWilFile;

type

{------------------------------------------------------------------------------}
// 全局数据结构
{------------------------------------------------------------------------------}

  // 游戏状态
  TGameState = (gsLogin, gsSelChr, gsLogout, gsPlay);

implementation

end.
