program QFServer;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, Forms, QFRemoteDataSet.DBPool, QFServerMainFrm,
  QFRemoteDataSet.DataModule, QFRemoteDataSet.Server, QFRemoteDataSet.Snowflake,
  QFRemoteDataSet.VerifyCode;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TServerMainFrm, ServerMainFrm);
  Application.CreateForm(TQFDataModule, QFDataModule);
  Application.Run;
end.

