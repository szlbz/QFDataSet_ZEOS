unit QFRemoteDataSet.DataModule;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Forms, ZConnection, ZDataset, SysUtils, IniFiles, LConvEncoding, DB;

type
  TDBParam = record
    ConnectionDefName, dbType, ip, dbName, UserName, password, port: string;
  end;

  TDBParams = array of TDBParam;

type

  { TQFdbdm }

  { TQFDataModule }

  TQFDataModule = class(TDataModule)
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private

  public
    SQLConnector1: TZConnection;
    QuerySubmit: TZQuery;
    QueryStoreProc: TZQuery;
    QueryExecSQL: TZQuery;
    QuerySelect: TZQuery;
    DBParam: TDBParam;
    NoSaveFields: string;
    procedure ConnectDB;
    procedure DisConnectDB;
  end;

var
  QFDataModule: TQFDataModule;
  DBParams: TDBParams;

implementation

{$R *.lfm}

{ TQFDataModule }

//procedure TQFDataModule.UniConnection1ConnectionLost(Sender: TObject;
//  Component: TComponent; ConnLostCause: TConnLostCause;
//  var RetryMode: TRetryMode);
//begin
//  RetryMode := rmReconnectExecute; //执行重新连接并重新执行中止的操作。不引发异常
//end;

procedure TQFDataModule.DataModuleCreate(Sender: TObject);
//var myinifile:Tinifile;
begin
  SQLConnector1:= TZConnection.Create(self);
  QuerySubmit:= TZQuery.Create(self);
  QuerySubmit.Connection:=SQLConnector1;
  QueryStoreProc:= TZQuery.Create(self);
  QueryStoreProc.Connection:=SQLConnector1;
  QueryExecSQL:= TZQuery.Create(self);
  QueryExecSQL.Connection:=SQLConnector1;
  QuerySelect:= TZQuery.Create(self);
  QuerySelect.Connection:= SQLConnector1;
end;

procedure TQFDataModule.DataModuleDestroy(Sender: TObject);
begin
  FreeAndNil(QuerySubmit);
  FreeAndNil(QueryStoreProc);
  FreeAndNil(QueryExecSQL);
  FreeAndNil(QuerySelect);
  FreeAndNil(SQLConnector1);
end;

procedure TQFDataModule.ConnectDB;
var
  port: integer;
begin
  SQLConnector1.Disconnect;
  SQLConnector1.Protocol:= DBParam.dbType;
  if UpperCase(DBParam.dbType)<>UpperCase('SQLite3') then
  begin
    SQLConnector1.Database := DBParam.dbName;
    SQLConnector1.HostName := DBParam.ip;
    SQLConnector1.Hostname := DBParam.UserName;
    SQLConnector1.Password := DBParam.password;
  end
  else
  begin
    SQLConnector1.Protocol:= 'SQLite';
    //SQLite3
    SQLConnector1.Database := ExtractFilePath(Application.ExeName)+DirectorySeparator+'data'+DirectorySeparator+DBParam.dbName;
    {$ifdef linux}
      {$if defined(cpuloongarch64)}
        SQLConnector1.LibraryLocation:=ExtractFilePath(Application.ExeName)+DirectorySeparator+'SQLite3/libsqlite3_loongarch64.so';
      {$endif}
      {$if defined(cpux86_64)}
        SQLConnector1.LibraryLocation:=ExtractFilePath(Application.ExeName)+DirectorySeparator+'SQLite3/libsqlite3_x86_64.so';
      {$endif}
      {$if defined(cpuaarch64)}
        SQLConnector1.LibraryLocation:=ExtractFilePath(Application.ExeName)+DirectorySeparator+'SQLite3/libsqlite3_aarch64.so';
      {$endif}
    {$else}
      SQLConnector1.LibraryLocation:=UTF8ToCP936(ExtractFilePath(Application.ExeName))+'\SQLite3\sqlite3.dll';
       //SQLiteLibraryName:=ExtractFilePath(Application.ExeName)+DirectorySeparator+'SQLite3\sqlite3.dll';
    {$endif}
    SQLConnector1.Properties.Add('encrypted=yes');
    SQLConnector1.Properties.Add('controls_cp=CP_UTF8');
    SQLConnector1.Properties.Add('AutoEncodeStrings=True');
  end;
  try
    SQLConnector1.Connect;// .Connected:=true;
  except
    //on E: Exception do
    //  WriteLog('TUnidac.ConnectDB ' + E.Message);
  end;
end;

procedure TQFDataModule.DisConnectDB;
begin
  SQLConnector1.Disconnect;// .Close;
end;


end.

