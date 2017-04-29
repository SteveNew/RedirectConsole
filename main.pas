unit main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls;

type
  TArg<T> = reference to procedure(const Arg: T);

  TForm1 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    Button2: TButton;
    Button3: TButton;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    { Private declarations }
    H: HWND;
    procedure CaptureConsoleOutput(const cmd, param: String; CallBackProc: TArg<PAnsiChar>);
    function AttachAndGetConsolewPipe(ProcessId: Cardinal): Cardinal;
    procedure DettachConsole;
    function ReadConsole(wPipe: Cardinal): TStringList;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

function AttachConsole(dwProcessId: DWORD): BOOL; stdcall; external kernel32 name 'AttachConsole';

function TForm1.AttachAndGetConsolewPipe(ProcessId: Cardinal): Cardinal;
begin
  if not AttachConsole(ProcessId) then
    raise Exception.Create('AttachConsole error: ' + IntToStr(GetLastError));
  Result := GetStdHandle(STD_OUTPUT_HANDLE);
  if Result = INVALID_HANDLE_VALUE then
    raise Exception.Create('GetStdHandle(STD_OUTPUT_HANDLE) error: ' + IntToStr(GetLastError));
end;

procedure TForm1.Button1Click(Sender: TObject);
var
  H: HWND;
begin
  H := FindWindow('ConsoleWindowClass', 'C:\Windows\system32\cmd.exe');
  if H<>0 then
  begin
    WinApi.Windows.SetParent(H, Memo1.Handle);
    SetWindowPos(H, 0, 0, 0, ClientWidth, ClientHeight, SWP_ASYNCWINDOWPOS);
  end;
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
  CaptureConsoleOutput('java','-version',
      procedure(const Line: PAnsiChar)
      begin
        Memo1.Clear;
        Memo1.Lines.Add(String(Line));
      end);
end;

procedure TForm1.Button3Click(Sender: TObject);
var
  pid: Cardinal;
  sout: Cardinal;
begin
  H := FindWindow('ConsoleWindowClass', 'ScummVM Status Window');
  if H<>0 then
  begin
    GetWindowThreadProcessId(H, pid);
    sout := AttachAndGetConsolewPipe(pid);
    Memo1.Lines := ReadConsole(sout);
    DettachConsole;
  end;
end;

procedure TForm1.CaptureConsoleOutput(const cmd, param: String; CallBackProc:
  TArg<PAnsiChar>);
const
  secAttr: TSecurityAttributes = (
    nLength: SizeOf(TSecurityAttributes);
    bInheritHandle: True);
  bufSize = 2400;
var
  rPipe: THandle;
  wPipe: THandle;
  suiRec: TStartupInfo;
  piRec: TProcessInformation;
  dRun, dAvail, dRead: DWORD;
  rBuf: array [0..bufSize] of AnsiChar;
begin
  if CreatePipe(rPipe, wPipe, @secAttr, 0) then
  try
    FillChar(suiRec, SizeOf(TStartupInfo), #0);
    suiRec.cb := SizeOf(TStartupInfo);
    suiRec.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    suiRec.wShowWindow := SW_HIDE;
    suiRec.hStdInput := rPipe;
    suiRec.hStdOutput := wPipe;
    suiRec.hStdError := wPipe;
    if CreateProcess(nil, PChar(cmd+' '+param), @secAttr, @secAttr, True,
      NORMAL_PRIORITY_CLASS, nil, nil, suiRec, piRec) then
    try
      repeat
        dRun := WaitForSingleObject(piRec.hProcess, 100);
        PeekNamedPipe(rPipe, nil, 0, nil, @dAvail, nil);
        if (dAvail > 0) then
        repeat
          dRead := 0;
          ReadFile(rPipe, rBuf[0], bufSize, dRead, nil);
          rBuf[dRead] := #0;
          OemToCharA(rBuf, rBuf);
          CallBackProc(rBuf);
        until (dRead < bufSize);
        Application.ProcessMessages;
      until (dRun <> WAIT_TIMEOUT);
    finally
      CloseHandle(piRec.hProcess);
      CloseHandle(piRec.hThread);
    end;
  finally
    CloseHandle(rPipe);
    CloseHandle(wPipe);
  end;
end;

procedure TForm1.DettachConsole;
begin
  if not FreeConsole then
    raise Exception.Create('FreeConsole error: ' + IntToStr(GetLastError));
end;

function TForm1.ReadConsole(wPipe: Cardinal): TStringList;
var
  BufInfo: _CONSOLE_SCREEN_BUFFER_INFO;
  BufSize, BufCoord: _COORD;
  ReadRegion: _SMALL_RECT;
  Buf: Array of _CHAR_INFO;
  I, J: Integer;
  Line: AnsiString;
begin
  Result := TStringList.Create;
  ZeroMemory(@BufInfo, SizeOf(BufInfo));
  if not GetConsoleScreenBufferInfo(wPipe, BufInfo) then
    raise Exception.Create('GetConsoleScreenBufferInfo error: ' + IntToStr(GetLastError));
  SetLength(Buf, BufInfo.dwSize.X * BufInfo.dwSize.Y);
  BufSize.X := BufInfo.dwSize.X;
  BufSize.Y := BufInfo.dwSize.Y;
  BufCoord.X := 0;
  BufCoord.Y := 0;
  ReadRegion.Left := 0;
  ReadRegion.Top := 0;
  ReadRegion.Right := BufInfo.dwSize.X;
  ReadRegion.Bottom := BufInfo.dwSize.Y;
  if ReadConsoleOutput(wPipe, Pointer(Buf), BufSize, BufCoord, ReadRegion) then
  begin
    for I := 0 to BufInfo.dwSize.Y - 1 do
    begin
      Line := '';
      for J := 0 to BufInfo.dwSize.X - 1 do
        Line := Line + Buf[I * BufInfo.dwSize.X + J].AsciiChar;
      Result.Add(Line)
    end
  end
  else
    raise Exception.Create('ReadConsoleOutput error: ' + IntToStr(GetLastError));
end;

end.
