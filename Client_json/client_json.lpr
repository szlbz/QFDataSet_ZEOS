program Client_json;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  SysUtils,//要加这个单元
  Interfaces, // this includes the LCL widgetset
  Forms, Unit1, QFDataSetPack;

{$R *.res}

begin
  DefaultFormatSettings.ShortDateFormat:='yyyy-mm-dd';
  DefaultFormatSettings.ShortTimeFormat:='hh:NN:ss';
  DefaultFormatSettings.LongDateFormat:='yyyy-mm-dd';
  DefaultFormatSettings.LongTimeFormat:='hh:NN:ss';
  DefaultFormatSettings.DateSeparator:='-';
  DefaultFormatSettings.TimeSeparator:=':';
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

