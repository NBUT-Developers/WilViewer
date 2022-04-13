unit MainFrm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, XPMan, Grids, MirWil, FileCtrl, ComCtrls, ToolWin, ExtCtrls,
  StdCtrls, SUIDlg, SUIMgr, Menus, SUIPopupMenu, ImgList,
  SUIMainMenu, SUIScrollBar, SUIImagePanel, SUIButton, CheckLst,
  SUICheckListBox, SUIToolBar, SUIForm, SUIEdit, SUIGrid,Assist, DirectDraw, AdvDraw, Wooolsgl;

type
  TMainForm = class(TForm)
    suiForm1: TsuiForm;
    suiMainMenu1: TsuiMainMenu;
    A2: TMenuItem;
    Bevel1: TBevel;
    BFT: TsuiBuiltInFileTheme;
    F1: TMenuItem;
    H1: TMenuItem;
    H3: TMenuItem;
    Image32: TImageList;
    N10: TMenuItem;
    N11: TMenuItem;
    N6: TMenuItem;
    N7: TMenuItem;
    O2: TMenuItem;
    Q1: TMenuItem;
    R1: TMenuItem;
    T1: TMenuItem;
    V1: TMenuItem;
    TB: TsuiToolBar;
    TipP: TsuiPanel;
    ToolButton1: TToolButton;
    ToolButton2: TToolButton;
    ToolButton3: TToolButton;
    ToolButton4: TToolButton;
    ToolButton5: TToolButton;
    ToolButton6: TToolButton;
    suiButton3: TsuiButton;
    suiThemeManager1: TsuiThemeManager;
    suiDrawGrid1: TsuiDrawGrid;
    suiButton1: TsuiButton;
    SaveDialog1: TSaveDialog;
    SaveDialog2: TSaveDialog;
    OpenDialog1: TOpenDialog;
    PaintBox1: TPaintBox;
    suiEdit1: TsuiEdit;
    suiEdit2: TsuiEdit;
    Label1: TLabel;
    Label2: TLabel;
    suiMessageDialog1: TsuiMessageDialog;

    procedure ToolButton1Click(Sender: TObject);
    procedure suiDrawGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure suiDrawGrid1SelectCell(Sender: TObject; ACol, ARow: Integer;
      var CanSelect: Boolean);
 //   procedure Splitter1Moved(Sender: TObject);
    procedure ToolButton2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure suiDrawGrid1DblClick(Sender: TObject);
    procedure ToolButton4Click(Sender: TObject);
    procedure ToolButton5Click(Sender: TObject);
    procedure ToolButton3Click(Sender: TObject);
//    procedure ToolButton6Click(Sender: TObject);
    procedure makewilxfile(headidx: Integer; tailidx: Integer; const sharefilename: string);
    procedure H3Click(Sender: TObject);
   //1，(判断是否打开)利用tailidx-headdex制造wilx文件头makewilxhead()，2，在一个循环里读入tailidx-headdex+1张图象的bits，
   //3, 还是内存+指针直接操作
  private
    { Private declarations }
    CurrWilFile: TWilFile;
    bStop: Boolean;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.ToolButton1Click(Sender: TObject);
var
  ShortName: string;
begin

  if OpenDialog1.Execute and (OpenDialog1.FileName <> '') then
  begin
    FreeAndNil(CurrWilFile);

    ShortName := Copy(OpenDialog1.FileName, 1, Length(OpenDialog1.FileName) - 4);
    CurrWilFile := TWilFile.Create(ShortName);

    suiDrawGrid1.RowCount := CurrWilFile.ImageCount div suiDrawGrid1.ColCount + 1;

    suiDrawGrid1.Invalidate;
    PaintBox1.Invalidate;

    TipP.Caption := '文件位置:'+OpenDialog1.FileName + ', 图片总数:' + IntTosTr(CurrWilFile.ImageCount);
  end;
end;

procedure TMainForm.suiDrawGrid1DrawCell(Sender: TObject; ACol, ARow: Integer;
  Rect: TRect; State: TGridDrawState);
var
  Grid: TsuiDrawGrid;
  Index: Integer;
  InfoPtr: PImageInfo;
begin
  if not Assigned(CurrWilFile) then Exit;

  Grid := Sender as TsuiDrawGrid;
  Index := ARow * Grid.ColCount + ACol;

  if Index < CurrWilFile.ImageCount then
  begin
    InfoPtr := CurrWilFile.ImageInfo[Index];

    CurrWilFile.StretchBlt(Index, Grid.Canvas.Handle, Rect.Left, Rect.Top,
      Rect.Right - Rect.Left, Rect.Bottom - Rect.Top, SRCCOPY);

    Grid.Canvas.TextOut(Rect.left, Rect.top, Format('%d,    [%d %d]', [Index, InfoPtr.px,
      InfoPtr.py]));
   // Grid.Canvas.TextOut(Rect.Right, Rect.Bottom, Format('%d, [%dx%d]', [Index, InfoPtr.px,
   //   InfoPtr.py]));

  end;
end;

procedure TMainForm.suiDrawGrid1SelectCell(Sender: TObject; ACol,
  ARow: Integer; var CanSelect: Boolean);
var
  Index: Integer;
begin
  if not Assigned(CurrWilFile) then Exit;

  Index := ARow * suiDrawGrid1.ColCount + ACol;

  if Index < CurrWilFile.ImageCount then
  begin
    PaintBox1.Canvas.FillRect(PaintBox1.ClientRect);
    CurrWilFile.BitBlt(Index, PaintBox1.Canvas.Handle, 0, 0);
  end;
end;

//procedure TMainForm.Splitter1Moved(Sender: TObject);
//var
 // OldColCount: Integer;
//begin
 // OldColCount := suiDrawGrid1.ColCount;
 // suiDrawGrid1.ColCount := suiDrawGrid1.Width div 80;
 // if OldColCount <> suiDrawGrid1.ColCount then
 // begin
  //  suiDrawGrid1.Invalidate;
  //  PaintBox1.Invalidate;
  //  suiDrawGrid1.RowCount := CurrWilFile.ImageCount div suiDrawGrid1.ColCount + 1;
 // end;
//end;

procedure TMainForm.ToolButton2Click(Sender: TObject);
begin
  FreeAndNil(CurrWilFile);

  suiDrawGrid1.Invalidate;
  PaintBox1.Invalidate;
end;

procedure TMainForm.Button1Click(Sender: TObject);
var
kaishiidx:integer;
jieshuidx:integer;

begin
if not Assigned(CurrWilFile) then
begin
suiMessageDialog1.IconType:= suiWarning;
//suiMessageDialog1.Text:= '还没有Wil文件被打开';
suiMessageDialog1.ShowModal();
end;
//初始化
//suiSpinEdit1.
kaishiidx:=strtoint(suiedit1.Text);
jieshuidx:=strtoint(suiedit2.Text);
    with SaveDialog2 do
    begin
      InitialDir := ExtractFilePath(FileName);
      FileName := ExtractFileName(CurrWilFile.FileName);
      if Execute and (filename<>'') and (suiedit1.Text <> '') and (suiedit2.Text <> '') and (Kaishiidx<jieshuidx)then
     makewilxfile(kaishiidx, jieshuidx, filename)
    end;
end;

procedure TMainForm.FormResize(Sender: TObject);
begin
 // Splitter1.OnMoved(Splitter1);
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Font := Screen.IconFont;
end;

procedure TMainForm.suiDrawGrid1DblClick(Sender: TObject);
var
  Index: Integer;
begin
  if not Assigned(CurrWilFile) then Exit;

  Index := suiDrawGrid1.Row * suiDrawGrid1.ColCount + suiDrawGrid1.Col;

  if Index < CurrWilFile.ImageCount then
  begin
    with SaveDialog1 do
    begin
      InitialDir := ExtractFilePath(FileName);
      FileName := ExtractFileName(CurrWilFile.FileName) + '_' + IntToStr(Index) + '.BMP';
    //  if Execute {and (FileName <> '') and (FiletxtName <> '')} then
    //  CurrWilFile.SaveToFile(Index, FileName,FiletxtName);
    end;
  end;
end;

procedure TMainForm.ToolButton4Click(Sender: TObject);
var
  Dir: string;
  I: Integer;
begin
  if not Assigned(CurrWilFile) then Exit;

  try
    if SelectDirectory('选择要保存到哪个目录', '', Dir) then
    begin
      bStop := False;
      ToolButton4.Enabled := False;
      ToolButton5.Visible := True;

      if Dir[Length(Dir)] <> '\' then Dir := Dir + '\';

      for I := 0 to CurrWilFile.ImageCount - 1 do
      begin
        Application.ProcessMessages;
        if bStop then Break;
        CurrWilFile.SaveToFile(I, Dir + IntToStr(I) + '.BMP',Dir + IntToStr(I) + '.txt');
        ToolButton4.Caption := IntToStr(I + 1);
      end;
      if I > 0 then ShowMessage(IntToStr(I) + '个文件已被保存到"' + Dir + '"');
    end;
  finally
   // ToolButton5.Click;
  ToolButton4.Caption := '全 部';
  ToolButton4.Enabled := True;
 // ToolButton5.Visible := False;
  end;
end;

procedure TMainForm.ToolButton5Click(Sender: TObject);
begin
 // bStop := False;
  ToolButton4.Caption := 'Save &All to BMP ...';
  ToolButton4.Enabled := True;
  ToolButton5.Visible := False;
end;

procedure TMainForm.ToolButton3Click(Sender: TObject);
begin
  suiDrawGrid1.OnDblClick(suiDrawGrid1);
end;

procedure TMainForm.H3Click(Sender: TObject);
begin
  Application.MessageBox(PChar(
    '创建WIL文件时务必保证:' + #13#10 + '1，已打开一个WIL文件;' + #13#10 + '2，二个文本框内有数且都为数字;'+ #13#10 + '3，数字前不须带0且起始号必须小于结束号.'), '使用帮助', MB_OK);
end;

//序号为headidx到tailidx,,创建到以sharefilename(+wil,,或wix)为文件名的文件
procedure TMainForm.makewilxfile(headidx: Integer; tailidx:Integer; const sharefilename: string);

var
myMainColorTable:TRGBQuads;
myfilepoint:Pointer;
myidxheadbak:TIndexHeader;
myimgheadbak:TImageHeader;
wilf: file;
wilfilename:string;
wixfilename:string;
wixf: file;
imgcount:integer;

InfoPtr: PImageInfo;
PBits: PByte;
I:integer;
myIndexArr: array of Integer;
begin

//1，(判断currentwilfie是否打开并载入,,wil打开，，wix必被打开)
if not Assigned(CurrWilFile) then Exit;
if (headidx < CurrWilFile.ImageCount) and (tailidx < currwilfile.ImageCount ) then
begin

//初始化

//index:=1;  index的原值是0还是1？

imgcount:=(tailidx-headidx)+1;
SetLength(myIndexArr, imgcount);

//****************************************************************
//制造wil文件头 ,,,1title,, 2,,

//myfilepoint:= decpointer(currwilfile.FilePointersaved,SizeOf(TImageInfo)-4);
//myfilepoint:= decpointer(currwilfile.FilePointersaved,SizeOf(currwilfile.MainColorTable));
//myfilepoint:= decpointer(currwilfile.FilePointersaved,SizeOf(TImageInfo)-4);
  myfilepoint:= currwilfile.FilePointersaved;
  myIndexArr[0]:= currwilfile.IndexArrbak[0];
 
//制造wix文件头

//****************************************************************
 // 开始保存wil文件
 wilfilename:=sharefilename+'.wil';
 wixfilename:=sharefilename+'.wix';

 FileMode := fmOpenWrite;
 AssignFile(wilf,wilfilename);
 Rewrite(wilf, 1);

  try
  // 写入wil文件头,,先定位指针再写数据，，指针在数据之后
   //1,  title
   myimgheadbak.Title:=currwilfile.imgheadbak.Title;
   myimgheadbak.ImageCount:=imgcount;
   myimgheadbak.ColorCount:=currwilfile.imgheadbak.ColorCount;
   myimgheadbak.PaletteSize:=currwilfile.imgheadbak.PaletteSize;
   
   BlockWrite(wilf, myimgheadbak, SizeOf(TImageHeader));

   //add:一个奇怪的东西
 //BlockWrite(wilf, ')=@ ', SizeOf(PImageHeader(currwilfile.FilePointersaved)^.ImageCount));
   //2,  imagecount  //3，4，5可以合并其实
  // BlockWrite(wilf, imgcount, SizeOf(PImageHeader(currwilfile.FilePointersaved)^.ImageCount));
   //3,  colorcount
  // myfilepoint := IncPointer(myfilepoint,SizeOf(PImageHeader(currwilfile.FilePointersaved)^.Title)+ SizeOf(PImageHeader(currwilfile.FilePointersaved)^.ImageCount) + SizeOf(PImageHeader(currwilfile.FilePointersaved)^.ColorCount));
  // BlockWrite(wilf, myfilepoint^,SizeOf(PImageHeader(currwilfile.FilePointersaved)^.ColorCount));
   //4,  palettesize
   //myfilepoint := IncPointer(myfilepoint,SizeOf(PImageHeader(currwilfile.FilePointersaved)^.PaletteSize));
 //  BlockWrite(wilf, myfilepoint^, SizeOf(PImageHeader(currwilfile.FilePointersaved)^.PaletteSize));
  // 5,,palette
  myMainColorTable:= currwilfile.MainColorTablebak;
 // myfilepoint:= IncPointer(myfilepoint,sizeof(TImageInfo));
   BlockWrite(wilf, myMainColorTable, sizeof(currwilfile.MainColorTablebak));
 //制造wil数据体  在一个循环里制造

 for I := 1 to imgcount do
  begin
     //记的释放哦 //sizeof()??
   InfoPtr:= currwilfile.ImageInfo[headidx];                      //1
   BlockWrite(wilf, InfoPtr^, sizeof(TImageInfo));
  // ImageInfo := IncPointer(FFilePointer, FIndexArr[Index]);
   PBits := IncPointer(InfoPtr, SizeOf(TImageInfo));          //2
   BlockWrite(wilf, PBits^, InfoPtr^.Width * InfoPtr^.Height);

   //先保存一个pbits指针列表,,,,(以形成wix数据体)
//pinteger(myindexarr)^:=pinteger(currwilfile.indexarrbak)^;
  myIndexArr[I] :=myIndexArr[I-1]+sizeof(TImageInfo)+InfoPtr^.Width * InfoPtr^.Height;




  headidx:= headidx+1; //headidx<tailidx已经经过了判断;
  end;

   finally
    CloseFile(wilf);
  end;
 
end;


begin


 // 开始创建wix文件
  FileMode := fmOpenWrite;
  AssignFile(wixf, wixfilename);
  Rewrite(wixf, 1);


  try
  // 写入wix文件头
  //1,title
  myidxheadbak.Title:=currwilfile.idxheadbak.Title;  //记得释放myidxheadbak这个结构哦
  myidxheadbak.IndexCount:=imgcount;
  BlockWrite(wixf,myidxheadbak, SizeOf(TIndexHeader));
  //2,,idxcount
 // BlockWrite(wixf,imgcount, SizeOf(PIndexHeader(currwilfile.FilePointersaved)^.IndexCount));
  //制造wix数组(wix文件体)
 BlockWrite(wixf, PInteger(myIndexArr)^, imgcount*4);


  finally
    CloseFile(wixf);
  //  SetLength(myIndexArr, 0);
  end;
 
end;

end;

end.
