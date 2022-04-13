program WilViewer;

uses
  Forms,
  MainFrm in 'MainFrm.pas' {MainForm},
  MirWil in '..\Common\MirWil.pas',
  Globals in '..\Common\Globals.pas',
  Assist in '..\Common\Assist.pas',
  AdvDraw in '..\Common\AdvDraw.pas',
  DebugUnit in '..\Common\DebugUnit.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
