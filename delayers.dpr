program delayers;

uses
  Windows,
  Forms,
  Main in 'Main.pas' {Form1};



begin
  Application.Initialize;
  Application.ShowMainForm := false;
  Application.Title := 'delayers';
  Application.CreateForm(TForm1, Form1);
  ShowWindow(Application.Handle, SW_HIDE);
  Application.Run;
end.

