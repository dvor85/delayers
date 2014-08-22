unit Updater;

interface

uses Classes, SysUtils, ExtCtrls, IdBaseComponent, IdComponent,
  IdTCPConnection, IdTCPClient, IdHTTP;

type

  TStrArray = array of string;

  TUpdater = class
  private
    IdHTTP: TIdHttp;
    FCurVersion: string;
    FNewVersion: string;
    FVersionIndexURI: string;
    FFilesList: TStringList;
    FLogFile: string;
    FUserName: string;
    FPassword: string;
    FTimer: TTimer;
    FUpdateInterval: cardinal;
    FSelfTimer: boolean;
    FChecked: boolean;
    procedure TimerProc(Sender: TObject);
    procedure AddLog(LogString: string);
    procedure SplitStr(const Str: string; const Sym: string; var Data: TstrArray);
    function ProcessMessage: boolean;
    function UpdateSelfExe: integer;
    procedure SetUserName(const Value: string);
    procedure SetPassword(const Value: string);
    procedure SetUpdateInterval(const Value: cardinal);
    procedure SetSelfTimer(const Value: boolean);
    procedure SetCurrentVersion(const Value: string);
    procedure SetVersionIndexURI(const Value: string);
    function GetNewVersionNo: string;
    function GetEnvironmentString(Str: string): string;

  public
    constructor Create;
    destructor Destroy; override;
    function UpdateFiles: integer;
    property LogFilename: string read FLogFile write FLogFile;
    property VersionIndexURI: string read FVersionIndexURI write SetVersionIndexURI;
    property FilesList: TStringList read FFilesList;
    property Username: string read FUserName write SetUserName;
    property Password: string read FPassword write SetPassword;
    property CurrentVersion: string read FCurVersion write SetCurrentVersion;
    property NewVersion: string read GetNewVersionNo write FNewVersion;
    property SelfTimer: boolean read FSelfTimer write SetSelfTimer;
    property Checked: boolean read FChecked;
    property UpdateInterval: cardinal read FUpdateInterval write SetUpdateInterval;
  end;

implementation

uses StrUtils, ShellProcess, ShellApi, Windows, Messages;

constructor TUpdater.Create;
var
  tmp_exe: string;
begin
  FLogFile := ChangeFileExt(ParamStr(0), '.log');
  UpdateSelfExe;

  tmp_exe := ExtractFilePath(ParamStr(0)) + 'tmp_' + ExtractFileName(ParamStr(0));
  if FileExists(tmp_exe) then
  begin
    Sleep(2000);
    DeleteFile(PChar(tmp_exe));
  end;

  FCurVersion := '';
  FNewVersion := '';
  FVersionIndexURI := '';
  IdHTTP := TIdHTTP.Create;
  IdHTTP.Request.UserAgent := ExtractFileName(ParamStr(0));
  FFilesList := TStringList.Create;
  FTimer := TTimer.Create(nil);
  FUpdateInterval := 1000;
  FTimer.Interval := FUpdateInterval;
  FSelfTimer := False;
  FChecked := False;
  FTimer.Enabled := FSelfTimer;
  FTimer.OnTimer := TimerProc;
end;

function TUpdater.GetEnvironmentString(Str: string): string;
var
  dest: PChar;
begin
  dest := AllocMem(1024);
  ExpandEnvironmentStrings(PChar(Str), dest, 1024);
  result := dest;
end;

procedure TUpdater.SetCurrentVersion(const Value: string);
begin
  FCurVersion := Value;
  IdHTTP.Request.UserAgent := ExtractFileName(ParamStr(0)) + ' v.' + FCurVersion;
end;

procedure TUpdater.SetVersionIndexURI(const Value: string);
begin
  FVersionIndexURI := Value;
  IdHTTP.URL.URI := FVersionIndexURI;
end;

destructor TUpdater.Destroy;
begin
  inherited;
  FFilesList.Free;
  IdHTTP.Free;
  FTimer.Free;
end;

procedure TUpdater.SetSelfTimer(const Value: boolean);
begin
  FSelfTimer := Value;
  FTimer.Enabled := FSelfTimer;
end;

procedure TUpdater.TimerProc(Sender: TObject);
begin
  if GetNewVersionNo > FCurVersion then
    UpdateFiles;
end;

procedure TUpdater.SplitStr(const Str: string; const Sym: string; var Data: TStrArray);
var
  s: string;
  p, l: integer;
  tmp: string;
begin
  l := length(Sym);
  SetLength(Data, 0);
  s := lowercase(trim(str));
  while (length(s) > 0) do
  begin
    p := pos(sym, s);
    if (p > 0) then
    begin
      tmp := trim(copy(s, 1, p + l - 2));
      if length(tmp) > 0 then
      begin
        SetLength(Data, Length(Data) + 1);
        Data[length(Data) - 1] := Tmp;
      end;
      Delete(s, 1, p);
    end
    else
    begin
      if length(s) > 0 then
      begin
        SetLength(Data, Length(Data) + 1);
        Data[length(Data) - 1] := s;
        s := '';
      end;
    end;
  end;
end;

procedure TUpdater.SetUpdateInterval(const Value: cardinal);
begin
  FUpdateInterval := Value;
  FTimer.Interval := FUpdateInterval;
end;

procedure TUpdater.SetUserName(const Value: string);
begin
  FUserName := Value;
  IdHTTP.Request.BasicAuthentication := True;
  IdHTTP.Request.Username := FUserName;

end;

procedure TUpdater.SetPassword(const Value: string);
begin
  FPassword := Value;
  IdHTTP.Request.BasicAuthentication := True;
  IdHTTP.Request.Password := FPassword;
end;

function TUpdater.GetNewVersionNo: string;
begin
  try
    try
      FFilesList.Text := IdHTTP.Get(FVersionIndexURI);
      Result := FFilesList[0];
      FFilesList.Delete(0);
      FChecked := True;
    except
      Result := '';
      FFilesList.Clear;
      Exit;
    end;
  finally
    IdHTTP.Disconnect;
  end;
end;

function TUpdater.UpdateFiles: integer;
var
  response: TMemoryStream;
  i, j, k: integer;
  fileDir: string;
  dfile, sfile, param, new_exe, new_exe_param: string;
  depended: TStrArray;
  ASource: TMemoryStream;
begin
  if FFilesList.Count = 0 then
    Exit;
  fileDir := ExtractFilePath(ParamStr(0));
  new_exe := '';
  Result := 0;
  response := TMemoryStream.Create;
  ASource := TMemoryStream.Create;
  try
    for i := 0 to FFilesList.Count - 1 do
    begin
      SplitStr(FFilesList[i], ';', depended);
      try
        for j := 0 to Length(depended) - 1 do
        begin
          param := '';
          sfile := Trim(depended[j]);
          k := Pos(' ', sfile);
          if k > 0 then
          begin
            param := Copy(sfile, k + 1, Length(sfile) - k);
            sfile := Copy(sfile, 1, k - 1);
          end;
          dfile := filedir + AnsiReplaceStr(sfile, '/', '\');


          AddLog('Try to update file: ' + dfile);
          try
            try
              IdHTTP.Post('http://' + IdHTTP.URL.Host + ':' +
                IdHTTP.URL.Port + IdHTTP.URL.Path + sfile, ASource, response);
              Inc(Result);
            except
              AddLog('Error get file: ' + dfile);
              Continue;
            end;
            try
              if LowerCase(ExtractFileName(dfile)) =
                LowerCase(ExtractFileName(ParamStr(0))) then
              begin
                dfile := ExtractFilePath(dfile) + 'tmp_' + ExtractFileName(dfile);
                new_exe := dfile;
                new_exe_param := param;
              end
              else if (Pos('.exe', dfile) <> 0) then
              begin
                if KillTask(LowerCase(ExtractFileName(dfile))) = 0 then
                  Sleep(1000);
              end;
              response.SaveToFile(dfile);
            except
              AddLog('Error create file: ' + dfile);
              Dec(Result);
              Continue;
            end
          finally
            response.Clear;
            IdHTTP.Disconnect;
            ProcessMessage;
          end;

        end;
        for j := 0 to Length(depended) - 1 do
        begin
          param := '';
          sfile := Trim(depended[j]);
          k := Pos(' ', sfile);
          if k > 0 then
          begin
            param := Copy(sfile, k + 1, Length(sfile) - k);
            sfile := Copy(sfile, 1, k - 1);
          end;
          dfile := filedir + AnsiReplaceStr(sfile, '/', '\');

          if (Pos('.exe', dfile) <> 0) and (LowerCase(ExtractFileName(dfile)) <>
            LowerCase(ExtractFileName(ParamStr(0)))) or (LowerCase(param) = 'exec') then
          begin
            ShellExecute(0, 'open', PChar(dfile), PChar(Param),
              PChar(ExtractFilePath(dfile)), SW_HIDE);
          end;
        end;
      except
        AddLog('Error create files');
        Dec(Result);
        Continue;
      end;
      if LowerCase(ExtractFileName(new_exe)) = LowerCase('tmp_' +
        ExtractFileName(ParamStr(0))) then
      begin
        ShellExecute(0, 'open', PChar(new_exe), PChar(new_exe_param),
          PChar(ExtractFilePath(new_exe)), SW_HIDE);
        ProcessTerminate(GetCurrentProcessId);
      end;
    end;
  finally
    ASource.Free;
    response.Free;
    SetLength(depended, 0);
  end;
end;

function TUpdater.UpdateSelfExe: integer;
var
  p, i: integer;
  apName: string;
  params: string;
begin
  p := Pos('tmp_', LowerCase(ExtractFileName(ParamStr(0))));
  if p <> 0 then
  begin
    Params := '';
    for i := 1 to ParamCount do
      Params := ParamStr(i) + ' ';
    apName := copy(ExtractFileName(ParamStr(0)), p + length('tmp_'),
      Length(ExtractFileName(ParamStr(0))) - (p + length('tmp_')) + 1);
    if KillTask(LowerCase(apname)) = 0 then
      Sleep(1000);
    CopyFile(PChar(ParamStr(0)), PChar(ExtractFilePath(ParamStr(0)) + apname), False);

    ShellExecute(0, 'open', PChar(ExtractFilePath(ParamStr(0)) + apname),
      PChar(params), PChar(ExtractFilePath(ParamStr(0))), SW_HIDE);
    ProcessTerminate(GetCurrentProcessId);
  end;
end;

procedure TUpdater.AddLog(LogString: string);
var
  F: TFileStream;
  PStr: PChar;
  Str: string;
  LengthLogString: cardinal;
begin
  Str := DateTimeToStr(Now()) + ': ' + LogString + #13#10;
  LengthLogString := Length(Str);
  try
    if FileExists(FLogFile) then
      F := TFileStream.Create(FLogFile, fmOpenWrite)
    else
    begin
      ForceDirectories(ExtractFileDir(FLogFile));
      F := TFileStream.Create(FLogFile, fmCreate);
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

function TUpdater.ProcessMessage: boolean;

  function IsKeyMsg(var Msg: TMsg): boolean;
  const
    CN_BASE = $BC00;
  var
    Wnd: HWND;
  begin
    Result := False;
    with Msg do
      if (Message >= WM_KEYFIRST) and (Message <= WM_KEYLAST) then
      begin
        Wnd := GetCapture;
        if Wnd = 0 then
        begin
          Wnd := HWnd;
          if SendMessage(Wnd, CN_BASE + Message, WParam, LParam) <> 0 then
            Result := True;
        end
        else
        if (longword(GetWindowLong(Wnd, GWL_HINSTANCE)) = HInstance) then
          if SendMessage(Wnd, CN_BASE + Message, WParam, LParam) <> 0 then
            Result := True;
      end;
  end;

var
  Msg: TMsg;
begin
  Result := False;
  if PeekMessage(Msg, 0, 0, 0, PM_REMOVE) then
  begin
    Result := True;
    if Msg.Message <> WM_QUIT then
      if not IsKeyMsg(Msg) then
      begin
        TranslateMessage(Msg);
        DispatchMessage(Msg);
      end;
  end;
end;


end.
