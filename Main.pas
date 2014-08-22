unit Main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, hwid_impl, winioctl, crtdll_wrapper, StdCtrls, ExtCtrls, Buttons,
  sSkinManager, acMagn, sPanel, sBitBtn, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP, DateUtils, IniFiles, EncdDecd, StrUtils,
  sComboBox, sGroupBox, sMemo, sLabel, sEdit, sSkinProvider, sAlphaListBox, ShellAPI, ShellProcess, Updater;

type

  TBaseData = packed record
    is_getdata: Integer;
    is_early: Integer;
    is_delay: Integer;
    early_days: Integer;
    early: Integer;
    delay: Integer;
    is_reg_early: Integer;
    is_reg_delay: Integer;
    id: Integer;
    name: string;
    effect: Integer;
  end;

  TForm1 = class(TForm)
    mmo1: TsMemo;
    lbledt1: TsEdit;
    grp1: TsGroupBox;
    sknmngr1: TsSkinManager;
    sBitBtn1: TsBitBtn;
    sPanel1: TsPanel;
    tmr1: TTimer;
    IdHTTP1: TIdHTTP;
    sLabel1: TsLabel;
    sSkinProvider1: TsSkinProvider;
    sGroupBox1: TsGroupBox;
    sPanel2: TsPanel;
    sGroupBox2: TsGroupBox;
    spnl1: TsPanel;
    procedure FormCreate(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
    procedure sBitBtn1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);

    procedure ApplicationException(Sender: TObject; E: Exception);
    procedure lbledt1DblClick(Sender: TObject);
    procedure mmo1KeyPress(Sender: TObject; var Key: Char);
  private
    { Private declarations }
    procedure WMQueryEndSession(var Message: TWMQueryEndSession); message WM_QUERYENDSESSION;
  public
    { Public declarations }
    Act: Integer;
    function GetBaseData: Integer;
    function SetDelay(reason: string; type_reason: Integer = -1): Integer;
    function SetEarly(reason: string; IsClosing: Integer; type_reason: Integer = -1): Integer;
    function GetPredefinedReasons: string;
    function InstallSrv: Integer;
    procedure CloseApp;
  end;

function getHardDriveId: Integer;
function MinutesBetween(dt1, dt2: TDateTime): Cardinal;



var
  Form1: TForm1;
  basedata: TBaseData;
  ini: TIniFile;
  iniPath: string;
  LogFile: string;
  TmpFile: string;
  AUrl: string;
  Interval: Integer;
  bTime, eTime: TDateTime;
  sb_Time, se_Time: TDateTime;
  delta: Integer;
  UpdUrl: string;
  updater: TUpdater;

implementation
uses
  IdHTTPHeaderInfo;

{$R *.dfm}

function getHardDriveId: Integer;
var
  r: tresults_array_dv;
begin
  SetPrintDebugInfo(ParamCount <> 0);
  result := getHardDriveComputerID(r);
end;

function GetEnvironmentString(Str: string): string;
var
  dest: PChar;
begin
  dest := AllocMem(1024);
  ExpandEnvironmentStrings(PChar(Str), dest, 1024);
  result := dest;
end;

function TForm1.InstallSrv: Integer;
begin
  //ShellExecute(0, 'open', 'NETSH', PChar('firewall add allowedprogram program="' + Application.exeName + '" name=' + MForm1.Caption + ' mode=enable scope=all profile=all'), '', SW_HIDE);
  ShellExecute(0, 'open', 'REG', PChar('ADD HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v ' + ChangeFileExt(ExtractFileName(Application.ExeName), '') + ' /t REG_SZ /d "' + Application.exeName + '" /f'), '', SW_HIDE);
end;

function MinutesBetween(dt1, dt2: TDateTime): Cardinal;
begin
  result := Round((double(dt1) - double(dt2)) * 24.0 * 60.0);
end;

procedure AddLog(LogString: string; LogFileName: string);
var
  F: TFileStream;
  PStr: PChar;
  Str: string;
  LengthLogString: Cardinal;
begin
  Str := DateTimeToStr(Now()) + ': ' + LogString + #13#10;
  LengthLogString := Length(Str);
  try
    if FileExists(LogFileName) then
      F := TFileStream.Create(LogFileName, fmOpenWrite)
    else
    begin
      ForceDirectories(ExtractFilePath(LogFileName));
      F := TFileStream.Create(LogFileName, fmCreate);
    end;
  except
    Exit;
  end;
  PStr := StrAlloc(LengthLogString + 1);
  try
    try
      StrPCopy(PStr, Str);
      F.Position := F.Size;
      F.Write(PStr^, LengthLogString);
    except
      Exit;
    end;
  finally
    StrDispose(PStr);
    F.Free;
  end;
end;

procedure TForm1.ApplicationException(Sender: TObject; E: Exception);
begin
  AddLog(E.Message, LogFile);
end;

function TForm1.GetBaseData: Integer;
var
  data: TStringList;
  response: TStringList;
begin
  result := basedata.is_getdata;
  data := TStringList.Create;
  response := TStringList.Create;

  if result = 1 then
    Exit;

  try
    try
      data.Add('id=' + IntToStr(basedata.id));
      data.Add('get_basedata=1');
      response.Text := IdHTTP1.Post(AUrl, data);
      result := 1;
      basedata.is_early := StrToInt(response.Values['is_early']);
      basedata.early_days := StrToInt(response.Values['early_days']);
      basedata.is_reg_early := StrToInt(response.Values['is_reg_early']);
      basedata.early := StrToInt(response.Values['early']);
      basedata.is_delay := StrToInt(response.Values['is_delay']);
      basedata.is_reg_delay := StrToInt(response.Values['is_reg_delay']);
      basedata.name := response.Values['name'];
      basedata.effect := StrToInt(response.Values['effect']);
      //sListBox1.Items.Text := GetPredefinedReasons;
    except
      on e: Exception do
      begin
        result := 0;
        AddLog(E.Message + ' in function "GetBaseData"', LogFile);
      end;
    end;
  finally
    begin
      data.Free;
      response.Free;
      basedata.is_getdata := Result;
      IdHTTP1.Disconnect;
    end;
  end;
end;

function TForm1.GetPredefinedReasons: string;
var
  data: TStringList;
  response: TStringList;
begin
  Result := '';
  data := TStringList.Create;
  response := TStringList.Create;

  try
    try
      data.Add('get_predefinedreasons=1');
      response.Text := IdHTTP1.Post(AUrl, data);
      result := response.Text;
    except
      on e: Exception do
      begin
        result := '';
        AddLog(E.Message + ' in function "Getpredefinedreasons"', LogFile);
      end;
    end;
  finally
    begin
      data.Free;
      response.Free;
      IdHTTP1.Disconnect;
    end;
  end;
end;

function TForm1.SetDelay(reason: string; type_reason: Integer = -1): Integer;
var
  data: TStringList;
  response: TStringList;
begin
  result := 0;
  data := TStringList.Create;
  response := TStringList.Create;
  try
    try
      data.Add('id=' + IntToStr(basedata.id));
      data.Add('name=' + lbledt1.Text);
      data.Add('reason=' + reason);
      data.Add('type_reason=' + IntToStr(type_reason));
      data.Add('is_delay=' + IntToStr(basedata.is_delay));
      data.Add('delay=' + IntToStr(basedata.delay));
      response.Text := IdHTTP1.Post(AUrl, data);
      result := 1;
    except
      on e: Exception do
      begin
        result := 0;
        AddLog(E.Message + ' in function "SetDelay"', LogFile);
      end;
    end;
  finally
    begin
      data.Free;
      response.Free;
      IdHTTP1.Disconnect;
    end;
  end;
end;

function TForm1.SetEarly(reason: string; IsClosing: Integer; type_reason: Integer = -1): Integer;
var
  data: TStringList;
  response: TStringList;
begin
  result := 0;
  data := TStringList.Create;
  response := TStringList.Create;
  try
    try
      if (IsClosing = 0) and (TmpFile <> '') and (FileExists(TmpFile)) then
      begin
        data.LoadFromFile(TmpFile);
      end
      else
      begin
        data.Add('id=' + IntToStr(basedata.id));
        data.Add('name=' + lbledt1.Text);
        data.Add('reason=' + reason);
        data.Add('type_reason=' + IntToStr(type_reason));
        data.Add('is_early=' + IntToStr(basedata.is_early));
        data.Add('early=' + IntToStr(basedata.early));
      end;
      if (IsClosing = 0) or (TmpFile = '') then
      begin
        response.Text := IdHTTP1.Post(AUrl, data);
        if (TmpFile <> '') and (FileExists(TmpFile)) then
          DeleteFile(TmpFile);
      end
      else if TmpFile <> '' then
        data.SaveToFile(TmpFile);
      result := 1;
    except
      on e: Exception do
      begin
        result := 0;
        AddLog(E.Message + ' in function "SetEarly"', LogFile);
      end;
    end;
  finally
    begin
      data.Free;
      response.Free;
      IdHTTP1.Disconnect;
    end;
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  i, p: Integer;
  pass: string;
begin
  Application.OnException := ApplicationException;
  Form1.Visible := false;
  Updater := TUpdater.Create;

  basedata.id := getHardDriveId;
  basedata.is_getdata := 0;


  pass := '';
  iniPath := '';
  LogFile := '';
  TmpFile := '';
  UpdUrl := '';
  for i := 1 to ParamCount do
  begin
    if Pos('log=', ParamStr(i)) <> 0 then
      LogFile := Copy(ParamStr(i), Length('log=') + 1, Length(ParamStr(i)) - Length('log='))
    else if Pos('tmp=', ParamStr(i)) <> 0 then
      TmpFile := Copy(ParamStr(i), Length('tmp=') + 1, Length(ParamStr(i)) - Length('tmp='))
    else if Pos('pass=', ParamStr(i)) <> 0 then
      pass := Copy(ParamStr(i), Length('pass=') + 1, Length(ParamStr(i)) - Length('pass='))
    else if Pos('config=', ParamStr(i)) <> 0 then
      iniPath := Copy(ParamStr(i), Length('config=') + 1, Length(ParamStr(i)) - Length('config='))
    else if ParamStr(i) = '/install' then
      InstallSrv
    else if Pos('help', ParamStr(i)) <> 0 then
    begin
      MessageBox(Handle, PChar('Usage: [log=logFile] | [pass=pass] - SetHashPassToConfigFile | [config=configFile] | [/install] | [help]'), PChar(ExtractFileName(Application.ExeName) + ' v. ' + Form1.Caption), MB_ICONQUESTION);
      Application.Terminate;
      Exit;
    end;
  end;

  tmr1.Enabled := False;

  if iniPath = '' then
    iniPath := ChangeFileExt(ParamStr(0), '.ini');
  iniPath := GetEnvironmentString(iniPath);

  ini := TIniFile.Create(IniPath);
  try
    AUrl := ini.ReadString('Global', 'AUrl', 'localhost');
    UpdUrl := ini.ReadString('Global', 'UpdUrl', 'localhost');

    sb_Time := StrToTime(ini.ReadString('Global', 'bTime', '8:00:00'));
    se_Time := StrToTime(ini.ReadString('Global', 'eTime', '17:00:00'));
    Interval := ini.ReadInteger('Global', 'Interval', 60 * 1000);
    delta := ini.ReadInteger('Global', 'delta', 0);
    if LogFile = '' then
      LogFile := ini.ReadString('Global', 'LogFile', '');
    LogFile := GetEnvironmentString(LogFile);
    if TmpFile = '' then


      if pass <> '' then
        ini.WriteString('Global', 'Password', EncodeString(pass))
      else
        pass := DecodeString(ini.ReadString('Global', 'Password', ''));

    IdHTTP1.Request.Password := pass;
    IdHTTP1.Request.BasicAuthentication := True;
    IdHTTP1.Request.UserAgent := ExtractFileName(ParamStr(0)) + ' v.' + Caption;


    Updater.CurrentVersion := Caption;
    Updater.VersionIndexURI := UpdUrl;
    Updater.LogFilename := LogFile;
    Updater.Username := IdHTTP1.Request.Username;
    Updater.Password := IdHTTP1.Request.Password;
    Updater.SelfTimer := False;


    basedata.id := getHardDriveId;
    bTime := EncodeDateTime(YearOf(Now), MonthOf(Now), DayOf(Now), HourOf(sb_Time), MinuteOf(sb_Time), SecondOf(sb_Time), 0);
    eTime := EncodeDateTime(YearOf(Now), MonthOf(Now), DayOf(Now), HourOf(se_Time), MinuteOf(se_Time), SecondOf(se_Time), 0);
    basedata.delay := MinutesBetween(Now, btime);



    if GetBaseData = 1 then
    begin
      if Updater.NewVersion > Updater.CurrentVersion then
        Updater.UpdateFiles;
    end;
    lbledt1.Text := basedata.name;
    tmr1.Enabled := True;
  finally
    ini.Free;
  end;
end;

procedure TForm1.tmr1Timer(Sender: TObject);
var
  diffdays: Integer;
begin
  if GetBaseData = 1 then
  begin
    if Updater.NewVersion > Updater.CurrentVersion then
      Updater.UpdateFiles;

    diffdays := DaysBetween(Now, bTime);
    if diffdays > 0 then
    begin
      tmr1.Enabled := False;
      basedata.is_getdata := 0;
      basedata.is_reg_early := 0;
      basedata.is_early := 1;
      basedata.early := 0;
       //Form2.Show;
      //Exit;
    end;
    if basedata.is_reg_early = 0 then
    begin
      if (basedata.is_early = 1) then
      begin
        Form1.Act := 1;
        mmo1.Clear;
        if (basedata.early = 0) then
          if (TmpFile <> '') and (FileExists(TmpFile)) then
          begin
            SetEarly('', 0);
            basedata.is_getdata := 0;
            Exit;
          end
          else
          begin
            if diffdays > 0 then
            begin
              Form1.Act := 3;
              sPanel1.Caption := Format('%s Вы некорректно завершили работу.', [DateToStr(bTime)]);
            end
            else
            begin
              Form1.Act := 1;
              sPanel1.Caption := Format('%s Вы некорректно завершили работу.', [DateToStr(IncDay(Date(), -basedata.early_days))]);
            end;
          end
        else if (basedata.early < -delta) then
        begin
          Form1.Act := 1;
          sPanel1.Caption := Format('%s Вы ушли раньше на %d мин.', [DateToStr(IncDay(Date(), -basedata.early_days)), -basedata.early]);
        end
        else
        begin
          basedata.is_reg_early := 1;
          Exit;
        end;

        Form1.Show;
        ShowWindow(Application.Handle, SW_HIDE);
      end;
    end
    else //////////////////////////////////////////
      if basedata.is_reg_delay = 0 then
      begin
        if basedata.delay > delta then
        begin
          basedata.is_delay := 1;
          Form1.Act := 2;
          mmo1.Clear;
          sPanel1.Caption := Format('Вы опоздали на %d мин.', [basedata.delay]);
          Form1.Show;
          ShowWindow(Application.Handle, SW_HIDE);
        end
        else
        begin
          basedata.is_delay := 0;
          if SetDelay('') = 1 then
            basedata.is_reg_delay := 1;
        end;
      end;
  end;
end;

procedure TForm1.sBitBtn1Click(Sender: TObject);

begin
  mmo1.Text := Trim(mmo1.Text);
  if (mmo1.Text = '') or (mmo1.Text[1] in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) then
  begin
    Exit;
  end;
  Form1.Hide;

  tmr1.Enabled := true;
  case Act of
    1: begin
        if SetEarly(mmo1.Text, -1, 0) = 1 then
        begin
          basedata.is_reg_early := 1;
        end;
      end;

    2: begin
        if SetDelay(mmo1.Text, -1) = 1 then
        begin
          basedata.is_reg_delay := 1;
        end;
      end;

    3: begin
        bTime := EncodeDateTime(YearOf(Now), MonthOf(Now), DayOf(Now), HourOf(sb_Time), MinuteOf(sb_Time), SecondOf(sb_Time), 0);
        eTime := EncodeDateTime(YearOf(Now), MonthOf(Now), DayOf(Now), HourOf(se_Time), MinuteOf(se_Time), SecondOf(se_Time), 0);
        basedata.delay := MinutesBetween(Now, btime);
        if SetEarly(mmo1.Text, -1, 0) = 1 then
        begin
          basedata.is_reg_early := 1;
        end;
      end;
  end;
  lbledt1.ReadOnly := true;
end;



procedure TForm1.FormShow(Sender: TObject);
begin
  tmr1.Enabled := false;
  lbledt1.Text := basedata.name;
  if basedata.effect < 0 then
    spnl1.Caption := '%%'
  else
    spnl1.Caption := IntToStr(basedata.effect) + '%';
  //sListBox1.ItemIndex := 0;
end;

procedure TForm1.lbledt1DblClick(Sender: TObject);
begin
  lbledt1.ReadOnly := False;
end;

procedure TForm1.mmo1KeyPress(Sender: TObject; var Key: Char);
var
  ckey: Integer;
begin
  ckey := ord(key);
  if ((cKey >= 65) and (cKey <= 90)) or ((cKey >= 97) and (cKey <= 122)) then
    Key := chr(27);
end;

procedure TForm1.CloseApp;
begin
  basedata.early := MinutesBetween(Now(), eTime);
  if basedata.early < -delta then
    basedata.is_early := 1
  else
    basedata.is_early := 0;
  SetEarly('', 1);
end;

procedure TForm1.WMQueryEndSession(var Message: TWMQueryEndSession);
begin
  CloseApp;
  Message.Result := 1;
  inherited;
end;








end.

