unit ucurtime;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Buttons, sBitBtn, ExtCtrls, sPanel,DateUtils;

type
  TForm2 = class(TForm)
    tmr1: TTimer;
    sPanel1: TsPanel;
    sBitBtn1: TsBitBtn;
    procedure sBitBtn1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure tmr1Timer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation
uses
  Main;

{$R *.dfm}

procedure TForm2.sBitBtn1Click(Sender: TObject);
begin
  tmr1.Enabled:=False;
  bTime := EncodeDateTime(YearOf(Now), MonthOf(Now), DayOf(Now), HourOf(sb_Time), MinuteOf(sb_Time), SecondOf(sb_Time), 0);
  eTime := EncodeDateTime(YearOf(Now), MonthOf(Now), DayOf(Now), HourOf(se_Time), MinuteOf(se_Time), SecondOf(se_Time), 0);
  basedata.delay := MinutesBetween(Now, btime);
  Form1.tmr1.Enabled:=True;
  Hide;
end;

procedure TForm2.FormShow(Sender: TObject);
begin
  sPanel1.Caption:=TimeToStr(Now);
  tmr1.Enabled:=True;
end;

procedure TForm2.tmr1Timer(Sender: TObject);
begin
  sPanel1.Caption:=TimeToStr(Now);
end;

end.
