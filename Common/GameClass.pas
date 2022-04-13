{------------------------------------------------------------------------------}
{ 单元名称: GameClass.pas                                                      }
{                                                                              }
{ 单元作者: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ 创建日期: 2004-12-30 20:30:00                                                }
{                                                                              }
{ 功能介绍:                                                                    }
{   2D 游戏引擎，封装 DirectDraw 7                                             }
{                                                                              }
{ 使用说明:                                                                    }
{                                                                              }
{ 更新历史:                                                                    }
{                                                                              }
{ 尚存问题:                                                                    }
{   最小化停止绘图                                                             }
{------------------------------------------------------------------------------}
unit GameClass;

interface

uses SysUtils, DirectDraw, Windows, Messages, ClassCallback;

const
  // MainWindow Class
  APPNAME = 'APPLICATION';

  // 全屏/窗口模式的窗口风格
  FULLSCREEN_WINDOWSTYLE = WS_VISIBLE or WS_POPUP;
  WINDOWMODE_WINDOWSTYLE = WS_VISIBLE or WS_SYSMENU or WS_MINIMIZEBOX or
    WS_POPUP or WS_DLGFRAME or WS_CAPTION;

type

  TGame = class(TObject)
  private
    FTerminated: Boolean;                 // 程序已终止(用于主窗口 Destroy)

    FDirectDraw: IDirectDraw7;            // DirectDraw 句柄
    FPrimarySurface: IDirectDrawSurface7; // 主表面
    FBufferSurface: IDirectDrawSurface7;  // 缓冲表面
    FClipper: IDirectDrawClipper;         // 裁剪器

    FFullScreen: Boolean;                 // 全屏模式

    FCallbackInstance: TCallbackInstance; // 窗口回调转换代码
    FMainWindow: HWND;            // 主窗口句柄
    FClientRect: TRect;           // 主客户区矩形(屏幕坐标,用于 Blt)
    FActive: Boolean;             // 窗口是否激活
    FCaption: string;             // 窗口标题
    FWidth: Integer;              // 客户区宽度
    FHeight: Integer;             // 客户区高度
    FBackgroundColor: TColorRef;  // 窗口背景色
    FBackgroundBrush: HBrush;
    FIsShowFPS: Boolean;     // 背景画刷

    procedure SetCaption(const Value: string);
    procedure SetHeight(const Value: Integer);
    procedure SetWidth(const Value: Integer);
    procedure SetFullScreen(const Value: Boolean);
    procedure SetBackgroundColor(const Value: TColorRef);

  protected
    // 注意: WndProc 不能为虚函数,详见 ClassCallback
    function WndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM;
      lParam: LPARAM): LResult; stdcall;

    function WMMouseMove(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; virtual; abstract;
    function WMLButtonDown(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; virtual; abstract;
    function WMLButtonUp(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; virtual; abstract;
    function WMRButtonDown(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; virtual; abstract;
    function WMRButtonUp(hWnd: HWND; uMsg: UINT; wParam: WPARAM; lParam: LPARAM): LRESULT; virtual; abstract;

    procedure OnIdle;

    procedure RegisterMainWindowClass;
    procedure CreateMainWindow;

    procedure InitDirectDraw;
    procedure FreeDirectDraw;

    procedure UpdateBounds;

    function ReloadAllSurfaceImages: Boolean; virtual; abstract;
    function ProcessNextFrame: Boolean; virtual; abstract;


  public
    constructor Create(ACaption: string; AFullScreen: Boolean;
      AWidth, AHeight: Integer; ABackgroundColor: TColorRef); virtual;
    destructor Destory; virtual;

    procedure Init;
    procedure Run;
    procedure Flip;
    function ClearBufferSurface: Boolean;

    function CreateSurfaceFromText(const AText: string; AFont: HFont = 0): IDirectDrawSurface7;
    function CreateSurfaceFromBitmap(const ABitmapName: string; AColorKey: TColorRef): IDirectDrawSurface7;

    property MainDirectDraw: IDirectDraw7 read FDirectDraw;
    property PrimarySurface: IDirectDrawSurface7 read FPrimarySurface;
    property BufferSurface: IDirectDrawSurface7 read FBufferSurface;

    property FullScreen: Boolean read FFullScreen write SetFullScreen;

    property MainWindow: HWND read FMainWindow;
    property Caption: string read FCaption write SetCaption;
    property Height: Integer read FHeight write SetHeight;
    property Width: Integer read FWidth write SetWidth;
    property BackgroundColor: TColorRef read FBackgroundColor write SetBackgroundColor;
  end;

  // 检查 DirectDraw 执行结果
  procedure CheckResult(Result: HRESULT; Info: string);

implementation

procedure CheckResult(Result: HRESULT; Info: string);
var
  F: TextFile;
begin
  if Result <> DD_OK then
  begin
//    raise Exception.Create('DirectDraw Error');
//    Halt;
    FileMode := fmOpenWrite;
    AssignFile(F, ChangeFileExt(ParamStr(0), '.err'));
    Rewrite(F);
    WriteLn(F, Info);
    CloseFile(F);
    Halt;
  end;
end;

{ TGame }

constructor TGame.Create(ACaption: string; AFullScreen: Boolean;
  AWidth, AHeight: Integer; ABackgroundColor: TColorRef);
begin
  FCaption := ACaption;
  FFullScreen := AFullScreen;
  FWidth := AWidth;
  FHeight := AHeight;
  FBackgroundColor := ABackgroundColor;
  FBackgroundBrush := CreateSolidBrush(FBackgroundColor);

  FIsShowFPS := True;

  // 生成类回调函数
  MakeCallbackInstance(FCallbackInstance, Self, @TGame.WndProc);

  // 注册主窗口类
  RegisterMainWindowClass;

  // 初始化 DirectDraw
  InitDirectDraw;
end;

destructor TGame.Destory;
begin
  // 清除 DirectDraw 对象
  FreeDirectDraw;
  // 清除 背景画刷
  DeleteObject(FBackgroundBrush);
end;

procedure TGame.InitDirectDraw;
var
  DDSD: TDDSurfaceDesc2;
begin
  // 删除原来的窗口，由 WM_DESTROY 负责删除原 DirectDraw 对象
  if IsWindow(FMainWindow) then DestroyWindow(FMainWindow);

  // 创建主窗口    
  CreateMainWindow;

  // 创建 FDirectDraw
  CheckResult(DirectDrawCreateEx(nil, FDirectDraw, IID_IDirectDraw7, nil),
    'DirectDrawCreateEx');

  // 根据全屏或窗口模式创建表面
  // 全屏模式
  if FFullScreen then
  begin
    CheckResult(FDirectDraw.SetCooperativeLevel(FMainWindow, DDSCL_EXCLUSIVE or
      DDSCL_FULLSCREEN), ' SetCooperativeLevel');

    CheckResult(FDirectDraw.SetDisplayMode(FWidth, FHeight, 8, 0, 0),
      'SetDisplayMode');

    FillChar(DDSD, SizeOf(DDSD), #0);
    DDSD.dwSize := SizeOf(DDSD);
    DDSD.dwFlags := DDSD_CAPS{ or DDSD_BACKBUFFERCOUNT};
//  DirectX 例子中的写法
//    DDSD.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE or DDSCAPS_FLIP or
//      DDSCAPS_COMPLEX or DDSCAPS_3DDEVICE;
    DDSD.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE {or DDSCAPS_FLIP or DDSCAPS_COMPLEX};
//    DDSD.dwBackBufferCount := 1;
    CheckResult(FDirectDraw.CreateSurface(DDSD, FPrimarySurface, nil),
      'CreateSurface: FPrimarySurface');

//    FillChar(DDSCaps, SizeOf(DDSCaps), #0);
//    DDSCaps.dwCaps := DDSCAPS_BACKBUFFER;
//    CheckResult(FPrimarySurface.GetAttachedSurface(DDSCaps, FBufferSurface),
//      'FPrimarySurface.GetAttachedSurface');
    DDSD.dwFlags := DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH;
    DDSD.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_SYSTEMMEMORY; //or DDSCAPS_3DDEVICE;
    DDSD.dwHeight := FHeight;
    DDSD.dwWidth := FWidth;
    CheckResult(FDirectDraw.CreateSurface(DDSD, FBufferSurface, nil),
      'CreateSurface(CreateSurface(FBufferSurface in Window Mode)');

  end
  // 窗口模式
  else begin
    CheckResult(FDirectDraw.SetCooperativeLevel(FMainWindow, DDSCL_NORMAL),
      'SetCooperativeLevel(FMainWindow, DDSCL_NORMAL)');

    // TODO: 修正
    CheckResult(FDirectDraw.SetDisplayMode(1024, 768, 8, 0, 0),
      'SetDisplayMode');

    FillChar(DDSD, SizeOf(DDSD), #0);
    DDSD.dwSize := SizeOf(DDSD);
    DDSD.dwFlags := DDSD_CAPS;
    DDSD.ddsCaps.dwCaps := DDSCAPS_PRIMARYSURFACE;
    CheckResult(FDirectDraw.CreateSurface(DDSD, FPrimarySurface, nil),
      'CreateSurface(FPrimarySurface in Window Mode)');

    DDSD.dwFlags := DDSD_CAPS or DDSD_HEIGHT or DDSD_WIDTH;
    DDSD.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN or DDSCAPS_SYSTEMMEMORY; //or DDSCAPS_3DDEVICE;
    DDSD.dwHeight := FHeight;
    DDSD.dwWidth := FWidth;
    CheckResult(FDirectDraw.CreateSurface(DDSD, FBufferSurface, nil),
      'CreateSurface(CreateSurface(FBufferSurface in Window Mode)');

    CheckResult(FDirectDraw.CreateClipper(0, FClipper, nil),
      'CreateClipper in Window Mode');
    CheckResult(FClipper.SetHWnd(0, FMainWindow), 'FClipper.SetHWnd');
    CheckResult(FPrimarySurface.SetClipper(FClipper), 'FPrimarySurface.SetClipper');
    FClipper := nil;
  end;
end;

procedure TGame.RegisterMainWindowClass;
var
  AWndClass: TWndClassEx;
begin
  FillChar(AWndClass, SizeOf(AWndClass), #0);
  AWndClass.cbSize          := SizeOf(AWndClass);
  AWndClass.style           := 0;
  AWndClass.lpfnWndProc     := @FCallbackInstance;
  AWndClass.cbClsExtra      := 0;
  AWndClass.cbWndExtra      := 0;
  AWndClass.hInstance       := HInstance;
  AWndClass.hIcon           := LoadIcon(HInstance, 'MAINICON');
  AWndClass.hIconSm         := AWndClass.hIcon;
  AWndClass.hCursor         := LoadCursor(0, IDI_APPLICATION);
  AWndClass.hbrBackground   := FBackgroundBrush;
  AWndClass.lpszMenuName    := nil;
  AWndClass.lpszClassName   := APPNAME;

  //TODO: exception handler
  if RegisterClassEx(AWndClass) = INVALID_ATOM then
    raise Exception.Create('Can not register window class!');
end;

procedure TGame.CreateMainWindow;
var
  Style: Cardinal;
  BorderX, BorderY, CaptionY: Integer;
  ALeft, ATop, AWidth, AHeight: Integer;
begin
  if FFullScreen then
  begin
    Style := FULLSCREEN_WINDOWSTYLE;

    ALeft := 0;
    ATop := 0;
    AWidth := GetSystemMetrics(SM_CXSCREEN);
    AHeight := GetSystemMetrics(SM_CYSCREEN);
  end
  else begin
    Style := WINDOWMODE_WINDOWSTYLE;

    BorderX := GetSystemMetrics(SM_CXDLGFRAME);
    BorderY := GetSystemMetrics(SM_CYDLGFRAME);
    CaptionY := GetSystemMetrics(SM_CYCAPTION);
    AWidth := FWidth + BorderX * 2;
    AHeight := FHeight + BorderY * 2 + CaptionY;

    ALeft := (GetSystemMetrics(SM_CXSCREEN) - AWidth) div 2;
    ATop := (GetSystemMetrics(SM_CYSCREEN) - AHeight) div 2;
  end;

  FMainWindow := CreateWindow(APPNAME, PChar(FCaption), Style,
    ALeft, ATop, AWidth, AHeight, 0, 0, HInstance, nil);

  // TODO: Exception
  if not IsWindow(FMainWindow) then
    raise Exception.Create('Can not create window!');

  UpdateBounds;
end;

procedure TGame.Flip;
var
  Result: HRESULT;
begin
  // 检查指针合法性
  // if (FPrimarySurface = nil) or (FBufferSurface = nil) then Exit;

  // 全屏模式
  // TODO: 为什么全屏模式下 flip 比 blt 更慢？
//  if FFullScreen then
//    Result := FPrimarySurface.Flip(nil, DDFLIP_WAIT)
//  else
    Result := FPrimarySurface.Blt(@FClientRect, FBufferSurface, nil, DDBLT_WAIT, nil);

  if Result = DDERR_SURFACELOST then
  begin
    // 重新生成主表面和缓冲表面
    if FDirectDraw.RestoreAllSurfaces <> DD_OK then Exit;
    // 重新载入所有表面图像(由用户处理)
    if not ReloadAllSurfaceImages then Exit;
  end;

  // 应该可以不需要(注:原来此句在 while (True) 循环中
  //    if Result <> DDERR_WASSTILLDRAWING then Break;
end;

procedure TGame.Init;
begin
  InitDirectDraw;
end;

procedure TGame.OnIdle;
begin
  // 处理下一Frame(由用户设计)
  if ProcessNextFrame then
  begin
    // 刷新至主表面
    Flip;
  end;
end;

procedure TGame.Run;
var
  AMsg: MSG;
begin
  while True do
  begin
    if PeekMessage(AMsg, 0, 0, 0, PM_REMOVE) then
    begin
      if AMsg.message = WM_QUIT then
        Break
      else begin
        TranslateMessage(AMsg);
        DispatchMessage(AMsg);
      end;
    end
    else OnIdle;
  end;
end;

procedure TGame.SetCaption(const Value: string);
begin
  FCaption := Value;
end;

function TGame.WndProc(hWnd: HWND; uMsg: UINT; wParam: WPARAM;
  lParam: LPARAM): LResult;
begin
  case uMsg of

    // 不需要处理的消息列表:
    // WM_CREATE
    // WM_GETMINMAXINFO   :
    // WM_SIZE            : 如果创建固定大小的窗口, 则不会产生 WM_SIZE 消息
    // WM_SETCURSOR       : 需要隐藏鼠标时

    WM_MOUSEMOVE:
      begin
        Result := WMMouseMove(hWnd, uMsg, wParam, lParam);
        Exit;
      end;

    WM_LBUTTONDOWN:
      begin
        Result := WMLButtonDown(hWnd, uMsg, wParam, lParam);
        Exit;
      end;

    WM_LBUTTONUP:
      begin
        Result := WMLButtonUp(hWnd, uMsg, wParam, lParam);
        Exit;
      end;

    WM_RBUTTONDOWN:
      begin
        Result := WMRButtonDown(hWnd, uMsg, wParam, lParam);
        Exit;
      end;

    WM_RBUTTONUP:
      begin
        Result := WMRButtonUp(hWnd, uMsg, wParam, lParam);
        Exit;
      end;

    WM_SIZE:
      begin
        UpdateBounds;
      end;

    WM_MOVE:
      begin
        // 窗口移动后重新找回窗口位置
        UpdateBounds;
        Result := 0;
        Exit;
      end;

    WM_ACTIVATE:
      begin
        // 设置窗口的激活状态
        // TODO: 是否需要处理 WM_ACTIVATEAPP
        FActive := LoWord(wParam) <> WA_INACTIVE;
        Result := 0;
        Exit;
      end;

    WM_QUERYNEWPALETTE :
      begin
        // TODO: WM_QUERYNEWPALETTE
        
        {if ( g_pDisplay <> nil ) and ( g_pDisplay.GetFrontBuffer <> nil ) then
        begin
        // If we are in windowed mode with a desktop resolution in 8 bit
        // color, then the palette we created during init has changed
        // since then.  So get the palette back from the primary
        // DirectDraw surface, and set it again so that DirectDraw
        // realises the palette, then release it again.
          pDDPal := nil;
          g_pDisplay.GetFrontBuffer.GetPalette( pDDPal );
          g_pDisplay.GetFrontBuffer.SetPalette( pDDPal );
          pDDPal := nil;
        end;}
      end;

    WM_EXITMENULOOP:
      begin
        // TODO: Ignore time spent in menu
        // g_dwLastTick := GetTickCount;
      end;

    WM_EXITSIZEMOVE:
      begin
        // TODO: Ignore time spent resizing
        // g_dwLastTick := GetTickCount;
      end;

{    WM_SYSCOMMAND:
      begin
        // 在全屏模式下禁止移动/调整大小/显示器节能
        // TODO: 是不是要加入更多控制？
        if FFullScreen then
          case wParam of
            SC_MOVE, SC_SIZE, SC_MAXIMIZE, SC_MONITORPOWER:
            begin
              // 也许不需要设置为 1
              Result := 1;
              Exit;
            end;
          end;
      end;}

    WM_CLOSE:
      begin
        FTerminated := True;        // 设置终止标志
        DestroyWindow(FMainWindow); // 删除窗口
        Result := 0;
        Exit;
      end;

    WM_DESTROY:
      begin
        if FTerminated then   // 如果应用程序终止标志设置
        begin
          PostQuitMessage(0); // 终止消息循环
          Self.Free;          // 清除自己
        end
        else FreeDirectDraw;  // 否则仅清除 DirectDraw 对象

        Result := 0;
        Exit;
      end;
  end;
  Result := DefWindowProc(hWnd, uMsg, wParam, lParam);
end;

procedure TGame.SetHeight(const Value: Integer);
begin
  FHeight := Value;
end;

procedure TGame.SetWidth(const Value: Integer);
begin
  FWidth := Value;
end;

procedure TGame.SetFullScreen(const Value: Boolean);
begin
  FFullScreen := Value;
end;

function TGame.ClearBufferSurface: Boolean;
var
  BltFx: TDDBltFX;
begin
  FillChar(BltFx, SizeOf(BltFx), #0);
  BltFx.dwSize := SizeOf(BltFx);
  BltFx.dwFillColor := FBackgroundColor;

  Result := BufferSurface.Blt(nil, nil, nil, DDBLT_COLORFILL, @BltFx) = DD_OK;
end;

procedure TGame.SetBackgroundColor(const Value: TColorRef);
begin
  FBackgroundColor := Value;
end;

procedure TGame.FreeDirectDraw;
begin
  FBufferSurface := nil;
  FPrimarySurface := nil;
  FDirectDraw := nil;
end;

procedure TGame.UpdateBounds;
begin
  // 全屏模式下, 主窗口坐标和客户区坐标同为屏幕大小
  if FFullScreen then
  begin
    SetRect(FClientRect, 0, 0, GetSystemMetrics(SM_CXSCREEN),
      GetSystemMetrics(SM_CYSCREEN));
  end
  // 窗口模式下, 主窗口坐标
  else begin
    GetClientRect(FMainWindow, FClientRect);
    ClientToScreen(FMainWindow, FClientRect.TopLeft);
    ClientToScreen(FMainWindow, FClientRect.BottomRight);
  end;
end;

function TGame.CreateSurfaceFromText(const AText: string;
  AFont: HFont): IDirectDrawSurface7;
var
  TextSize: TSize;
  TextLen: Integer;
  DDSD: TDDSurfaceDesc2;
  DC: HDC;
begin
  if (FDirectDraw = nil) or (AText = '') then Exit;

  TextLen := Length(AText);

  DC := GetDC(0);
  if AFont <> 0 then SelectObject(DC, AFont);
  GetTextExtentPoint32(DC,PChar(AText), TextLen, TextSize);
  ReleaseDC(0, DC);

  FillChar(DDSD, SizeOf(DDSD), #0);
  DDSD.dwSize := SizeOf(DDSD);
  DDSD.dwFlags := DDSD_CAPS or DDSD_WIDTH or DDSD_HEIGHT;
  DDSD.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN;
  DDSD.dwWidth := TextSize.cx;
  DDSD.dwHeight := TextSize.cy;

  if FDirectDraw.CreateSurface(DDSD, Result, nil) <> DD_OK then Exit;
  if Result.GetDC(DC) <> DD_OK then Exit;

  if AFont <> 0 then SelectObject(DC, AFont);

  TextOut(DC, 0, 0, PChar(AText), TextLen);

  Result.ReleaseDC(DC);
end;

function TGame.CreateSurfaceFromBitmap(const ABitmapName: string;
  AColorKey: TColorRef): IDirectDrawSurface7;
var
  Bmp: BITMAP;
  hBmp: HBITMAP;
  DDSD: TDDSurfaceDesc2;
  DC, MemDC: HDC;
begin
  if FDirectDraw = nil then Exit;
  if ABitmapName = '' then Exit;

  hBmp := LoadImage(0, PChar(ABitmapName), IMAGE_BITMAP, 0, 0,
    LR_LOADFROMFILE or LR_CREATEDIBSECTION);

  if hBmp = 0 then Exit;

  GetObject(hBmp, SizeOf(Bmp), @Bmp);

  FillChar(DDSD, SizeOf(DDSD), #0);
  DDSD.dwSize := SizeOf(DDSD);
  DDSD.dwFlags := DDSD_CAPS or DDSD_WIDTH or DDSD_HEIGHT;
  DDSD.ddsCaps.dwCaps := DDSCAPS_OFFSCREENPLAIN;
  DDSD.dwWidth := Bmp.bmWidth;
  DDSD.dwHeight := Bmp.bmHeight;

  if FDirectDraw.CreateSurface(DDSD, Result, nil) <> DD_OK then Exit;

  if Result.GetDC(DC) <> DD_OK then Exit;

  MemDC := CreateCompatibleDC(DC);
  if MemDC = 0 then Exit;

  SelectObject(MemDC, hBmp);

  BitBlt(DC, 0, 0, Bmp.bmWidth, Bmp.bmHeight, MemDC, 0, 0, SRCCOPY);

  DeleteObject(hBmp);

  Result.ReleaseDC(DC);

  DeleteDC(MemDC);
end;

end.
