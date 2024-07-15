unit QFRemoteDataSet.DBPool;

interface

uses
  IniFiles, QFRemoteDataSet.DataModule, Classes,
  SyncObjs,
  SysUtils, DateUtils;

const
QFPoolCreate=5;

type
  TQFDBPool = class
  private
    FCS: TCriticalSection;
    FList: tlist;
    FDBParam: TDBParam;
    FPoolSize: Integer;
  public
    constructor Create; overload;
    destructor Destroy; override;
    class procedure Start;
    procedure Init;
    function Lock: TQFDataModule;
    procedure Unlock(Value: TQFDataModule);
    function NewDBConnect(owner: TComponent = nil): TQFDataModule;
    property DBParam: TDBParam read FdbParam write FdbParam;
  end;

var
  DBPools: array of TQFDBPool;
  ConnectNameNumber :Integer;  //最多n个连接名称

function GetDBPool(const ConnectionDefName: string): TQFDBPool;

implementation
uses QFServerMainFrm;

function GetDBPool(const ConnectionDefName: string): TQFDBPool;
var i: integer;
begin
  Result := nil;
  if ConnectionDefName = '' then
  begin
    Result := dbPools[0];
    Exit;
  end;
  for i := 0 to High(dbPools) do
  begin
    if dbPools[i].dbParam.ConnectionDefName = ConnectionDefName then
    begin
      Result := dbPools[i];
      exit;
    end;
  end;
end;

constructor TQFDBPool.Create;
var ini: TIniFile;
begin
  FList := tlist.create;
  FCS := TCriticalSection.Create;
  ini := TIniFile.Create(extractfilepath(paramstr(0)) + 'config.ini');
  Self.FPoolSize := ini.ReadInteger('系统参数', '数据库连接池大小', 1);
  ini.WriteInteger('系统参数', '数据库连接池大小', Self.FPoolSize);
  ini.Free;
end;

destructor TQFDBPool.Destroy;
begin
  FList.Clear;
  FreeAndNil(FList);
  FreeAndNil(FCS);
  inherited Destroy;
end;

procedure TQFDBPool.Init;
begin
  while FList.Count < Self.FPoolSize do
    FList.Add(NewDBConnect(nil));
end;

function TQFDBPool.Lock: TQFDataModule;
begin
  FCS.Enter;
  try
    if FList.Count > 0 then
    begin
      Result := TQFDataModule(FList.Last);
      FList.Delete(FList.Count -1);
    end
    else
    begin
      Result := NewDBConnect;
      Result.Tag := QFPoolCreate;
    end;
  finally
    FCS.Leave;
  end;
end;

function TQFDBPool.NewDBConnect(owner: TComponent = nil): TQFDataModule;
begin
  Result := TQFDataModule.Create(owner);
  Result.dbParam := Self.FdbParam;
  Result.ConnectDB;
end;

class procedure TQFDBPool.Start;
var ini: TIniFile;
  nodes, node: TStringList;
  i: Integer;
  pool: TQFDBPool;
  s: string;
begin
  ini := TIniFile.Create(extractfilepath(paramstr(0)) + 'dbconfig.ini');
  nodes := TStringList.Create;
  node := TStringList.Create;
  try
    ini.ReadSections(nodes);
    SetLength(DBParams, nodes.Count);
    for i := 0 to nodes.Count - 1 do
    begin
      ini.ReadSectionValues(nodes[i], node);
      DBParams[i].ConnectionDefName := node.Values['连接名称'];
      DBParams[i].dbType := node.Values['类型'];
      DBParams[i].ip := node.Values['服务器IP'];
      DBParams[i].dbName := node.Values['数据库名称'];
      DBParams[i].UserName := node.Values['用户名'];
      DBParams[i].password := node.Values['密码'];
      DBParams[i].port := node.Values['端口'];
    end;

    SetLength(dbPools, High(DBParams) + 1);
    for i := Low(dbPools) to High(dbPools) do
    begin
      pool := TQFDBPool.Create;
      pool.dbParam := DBParams[i];
      pool.Init;
      dbPools[i] := pool;
      s := '数据连接池'+(i+1).ToString+': ';
      s := s +chr(13)+chr(10)+  '    连接名称:' + pool.dbParam.ConnectionDefName;
      s := s +chr(13)+chr(10)+  '    数据库类型:' + pool.dbParam.dbType;
      s := s +chr(13)+chr(10)+  '    数据库名称:' + pool.dbParam.dbName;
      s := s +chr(13)+chr(10)+  '    服务器IP:' + pool.dbParam.ip;
      s := s +chr(13)+chr(10)+  '    数据库端口:' + pool.dbParam.port;
      ServerMainFrm.memo1.Lines.Add(s);
    end;
  finally
    nodes.Free;
    node.Free;
    ini.Free;
  end;
end;

procedure TQFDBPool.Unlock(Value: TQFDataModule);

  procedure _Free;
  begin
    Value.DisConnectDB;
    FreeAndNil(Value);
  end;

begin
  FCS.Enter;
  try
    if Value.Tag = QFPoolCreate then
      _Free
    else
    begin
      Value.QuerySubmit.Close;
      //Value.QueryStoredProc.Close;
      Value.QueryExecSQL.Close;
      Value.QuerySelect.Close;
      Value.SQLConnector1.Connected:=false;// .Disconnect;
      FList.Add(Value);
    end;
  finally
    FCS.Leave;
  end;
end;

end.

