unit ShellProcess;

interface
uses TlHelp32, Windows, Classes, Sysutils, Messages;

procedure GetProcessList(List: TStrings);
procedure GetModuleList(List: TStrings);
function GetProcessHandle(ProcessID: integer): THandle;
procedure GetParentProcessInfo(var ID: Integer; var Path: string);
function ProcessTerminate(dwPID: Cardinal): Boolean;
function TerminateTask(PID: integer): integer;
function KillTask(ExeFileName: string): integer;
function ProcessMessage: Boolean;

const

  PROCESS_TERMINATE = $0001;
  PROCESS_CREATE_THREAD = $0002;
  PROCESS_VM_OPERATION = $0008;
  PROCESS_VM_READ = $0010;
  PROCESS_VM_WRITE = $0020;
  PROCESS_DUP_HANDLE = $0040;
  PROCESS_CREATE_PROCESS = $0080;
  PROCESS_SET_QUOTA = $0100;
  PROCESS_SET_INFORMATION = $0200;
  PROCESS_QUERY_INFORMATION = $0400;

  PROCESS_ALL_ACCESS =
    STANDARD_RIGHTS_REQUIRED or SYNCHRONIZE or $0FFF;


implementation



function ProcessMessage: Boolean;
  function IsKeyMsg(var Msg: TMsg): Boolean;
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
          if (LongWord(GetWindowLong(Wnd, GWL_HINSTANCE)) = HInstance) then
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

procedure GetProcessList(List: TStrings);
var
  I: Integer;
  hSnapshoot: THandle;
  pe32: TProcessEntry32;
begin
  List.Clear;
  hSnapshoot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

  if (hSnapshoot = -1) then
    Exit;
  pe32.dwSize := SizeOf(TProcessEntry32);
  if (Process32First(hSnapshoot, pe32)) then
    repeat
      I := List.Add(LowerCase(pe32.szExeFile));
      List.Objects[I] := Pointer(pe32.th32ProcessID);
      ProcessMessage;
    until not Process32Next(hSnapshoot, pe32);

  CloseHandle(hSnapshoot);
end;

procedure GetModuleList(List: TStrings);
var
  I: Integer;
  hSnapshoot: THandle;
  me32: TModuleEntry32;
begin
  List.Clear;
  hSnapshoot := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, 0);

  if (hSnapshoot = -1) then
    Exit;
  me32.dwSize := SizeOf(TModuleEntry32);
  if (Module32First(hSnapshoot, me32)) then
    repeat
      I := List.Add(me32.szModule);
      List.Objects[I] := Pointer(me32.th32ModuleID);
      ProcessMessage;
    until not Module32Next(hSnapshoot, me32);

  CloseHandle(hSnapshoot);
end;

procedure GetParentProcessInfo(var ID: Integer; var Path: string);
var
  ProcessID: Integer;
  hSnapshoot: THandle;
  pe32: TProcessEntry32;
begin
  ProcessID := GetCurrentProcessID;
  ID := -1;
  Path := '';

  hSnapshoot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);

  if (hSnapshoot = -1) then
    Exit;

  pe32.dwSize := SizeOf(TProcessEntry32);
  if (Process32First(hSnapshoot, pe32)) then
    repeat
      if pe32.th32ProcessID = ProcessID then
      begin
        ID := pe32.th32ParentProcessID;

        Break;
      end;
      ProcessMessage;
    until not Process32Next(hSnapshoot, pe32);

  if ID <> -1 then
  begin
    if (Process32First(hSnapshoot, pe32)) then
      repeat
        if pe32.th32ProcessID = ID then
        begin
          Path := pe32.szExeFile;
          Break;
        end;
        ProcessMessage;
      until not Process32Next(hSnapshoot, pe32);
  end;
  CloseHandle(hSnapshoot);
end;

function GetProcessHandle(ProcessID: Integer): THandle;
begin
  Result := OpenProcess(PROCESS_ALL_ACCESS, True, ProcessID);
end;

function TerminateTask(PID: integer): integer;
var
  process_handle: integer;
  lpExitCode: Cardinal;
begin
  process_handle := openprocess(PROCESS_ALL_ACCESS, true, pid);
  GetExitCodeProcess(process_handle, lpExitCode);
  if (process_handle = 0) then
    TerminateTask := GetLastError
  else if terminateprocess(process_handle, lpExitCode) then
  begin
    TerminateTask := 0;
    CloseHandle(process_handle);
  end
  else
  begin
    TerminateTask := GetLastError;
    CloseHandle(process_handle);
  end;
end;

function KillTask(ExeFileName: string): integer;
var
  list: TStringList;
  k: integer;
  trys: Integer;
begin
  list := TStringList.Create;
  try
    GetProcessList(List);
    trys := 0;
    repeat
      k := List.IndexOf(ExeFileName);
      result := 1;
      if k > -1 then
      begin
        result := TerminateTask(Integer(List.Objects[k]));
        if (result <> 0) then
          result := Integer(not processTerminate(Integer(List.Objects[k])));
        if Result = 0 then
          list.Delete(k);
      end
      else
        result := 0;
      Inc(trys);
      ProcessMessage;
    until (k = -1) or (trys > 20);
  finally
    list.Free;
  end;
end;


// Включение, приминение и отключения привилегии.
 // Для примера возьмем привилегию отладки приложений 'SeDebugPrivilege'
 // необходимую для завершения ЛЮБЫХ процессов в системе (завершение процесов
 // созданных текущим пользователем привилегия не нужна.

function ProcessTerminate(dwPID: Cardinal): Boolean;
var
  hToken: THandle;
  SeDebugNameValue: Int64;
  tkp: TOKEN_PRIVILEGES;
  ReturnLength: Cardinal;
  hProcess: THandle;
begin
  Result := false;
  if TerminateTask(dwPid) = 0 then
  begin
    result := true;
    exit;
  end
  else
  begin
 // Добавляем привилегию SeDebugPrivilege
 // Для начала получаем токен нашего процесса
    if not OpenProcessToken(GetCurrentProcess(), TOKEN_ADJUST_PRIVILEGES
      or TOKEN_QUERY, hToken) then
      exit;

 // Получаем LUID привилегии
    if not LookupPrivilegeValue(nil, 'SeDebugPrivilege', SeDebugNameValue)
      then begin
      CloseHandle(hToken);
      exit;
    end;

    tkp.PrivilegeCount := 1;
    tkp.Privileges[0].Luid := SeDebugNameValue;
    tkp.Privileges[0].Attributes := SE_PRIVILEGE_ENABLED;

 // Добавляем привилегию к нашему процессу
    AdjustTokenPrivileges(hToken, false, tkp, SizeOf(tkp), tkp, ReturnLength);
    if GetLastError() <> ERROR_SUCCESS then exit;

 // Завершаем процесс. Если у нас есть SeDebugPrivilege, то мы можем
 // завершить и системный процесс
 // Получаем дескриптор процесса для его завершения
    hProcess := OpenProcess(PROCESS_TERMINATE, FALSE, dwPID);
    if hProcess = 0 then exit;
  // Завершаем процесс
    if not TerminateProcess(hProcess, DWORD(-1))
      then exit;
    CloseHandle(hProcess);

 // Удаляем привилегию
    tkp.Privileges[0].Attributes := 0;
    AdjustTokenPrivileges(hToken, FALSE, tkp, SizeOf(tkp), tkp, ReturnLength);
    if GetLastError() <> ERROR_SUCCESS
      then exit;

    Result := true;
  end;
end;


end.

