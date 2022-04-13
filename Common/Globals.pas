{------------------------------------------------------------------------------}
{ ��Ԫ����: Globals.pas                                                        }
{                                                                              }
{ ��Ԫ����: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ ��������: 2005-01-02 20:30:00                                                }
{                                                                              }
{ ���ܽ���:                                                                    }
{   ����2 ȫ�ֳ���/����                                                        }
{                                                                              }
{ ʹ��˵��:                                                                    }
{                                                                              }
{ ������ʷ:                                                                    }
{                                                                              }
{ �д�����:                                                                    }
{                                                                              }
{------------------------------------------------------------------------------}
unit Globals;

interface

uses MirWil;


{------------------------------------------------------------------------------}
// ȫ�ֳ���
{------------------------------------------------------------------------------}
const
  // ��Ļ��С
  CLIENT_WIDTH = 800;
  CLIENT_HEIGHT = 600;

  // ��ʾ��ͼ�Ĵ�С
  MAPSURFACE_WIDTH = 800;
  MAPSURFACE_HEIGHT = 445;

  // ��ͼ��λ/����ͼƬ�ߴ�
  MAPUNIT_WIDTH = 48;
  MAPUNIT_HEIGHT = 32;

  // ��ͼ��λ�������ص�
  MAPCENTER_X = (MAPSURFACE_WIDTH - MAPUNIT_WIDTH) div 2;
  MAPCENTER_Y = (MAPSURFACE_HEIGHT - MAPUNIT_HEIGHT) div 2;

  // �߼���ͼ��λ (������΢����Ļ�ƶ�����Сֵ)
  LOGICALMAPUNIT = 20;

var

{------------------------------------------------------------------------------}
// ȫ�ֱ���
{------------------------------------------------------------------------------}

  // ·������
  G_MirPath   : string = 'F:\Games\Legend of Mir\';
  G_MirMapPath: string = 'F:\Games\Legend of Mir\Map\';
  G_MirWilPath: string = 'F:\Games\Legend of Mir\Data\';
  G_MirWavPath: string = 'F:\Games\Legend of Mir\Wave\';

var

{------------------------------------------------------------------------------}
// WIL ͼƬ�ļ�
{------------------------------------------------------------------------------}
  // ǰ��ͼƬ
  G_WilObjects: array[0..6] of TWilFile;
  // ����ͼƬ
  G_WilTile     : TWilFile;
  G_WilTileSm   : TWilFile;
  // �����ɫͼƬ
  G_WilHuman    : TWilFile;         // Human Actor ������ͼƬ�ļ� (hum.wil)
  G_WilHair     : TWilFile;         // Human Actor ��ͷ��ͼƬ�ļ� (hair.wil)
  G_WilWeapon   : TWilFile;         // Human Actor ������ͼƬ�ļ� (weapon.wil)
  G_WilMagic    : TWilFile;         // Human Actor ��ħ��ͼƬ�ļ� (magic.wil)
  // ��Ϸ����ͼƬ
  G_WilPrgUse   : TWilFile;

type

{------------------------------------------------------------------------------}
// ȫ�����ݽṹ
{------------------------------------------------------------------------------}

  // ��Ϸ״̬
  TGameState = (gsLogin, gsSelChr, gsLogout, gsPlay);

implementation

end.
