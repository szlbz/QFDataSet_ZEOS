{
lazarus linux/windows简单实用的三层控件QFDataSet：
转到Lazarus后发现缺少delphi熟悉的三层控件，尝试过国产商业及网上的开源三层控件，
但存在或多或少的问题，始终找不到满意的三层控件（特别是linux aarch64下），决定
开发一个简单实用的lazarus三层控件（参考网上的相关代码）。
这个三层控件功能相对简单，只适合lazarus使用，但非常实用，编写的应用软件能在
windows和国产信创操作系统(linux)及CPU运行。 
2023.01.21 QQ：315175176 秋风 
}
unit QFDataSet;

{$mode ObjFPC}{$H+}
{.$DEFINE MemDataSet}
{$DEFINE BufDataset}
{.$DEFINE VirtualTable}
{.$DEFINE RTCMemdataset}

interface

uses
  Dialogs, DB,Classes, SysUtils,math, LCLType, LCLIntf, Graphics,
  rtcHttpCli, rtcCliModule, rtcDB, rtcFunction, rtcInfo, rtcConn
{$ifdef BufDataset}
  ,BufDataset
{$endif}
{$ifdef MemDataSet}
  ,memds
{$endif}
{$ifdef VirtualTable}
  ,VirtualTable
{$endif}
  ;


type

TQFConnection = class(TComponent)
private
  FSecureKey:string;
  FServerAddr: string ;
  FServerPort: string ;
  FHttpClient: TRtcHttpClient;
  FRtcClientModule: TRtcClientModule;
  FCompression:Boolean;
  FConnectionDefName: string;
  procedure SetServerAddr(const value: string);
  procedure SetServerPort(const value: string);
  procedure SetCompression(const value: Boolean);
  procedure SetSecureKey(const value: string);
  procedure SetDataPage(const FTableName,FKeyFields,PageSize,PageNo:string);//提交数据分页SQL
public
  constructor Create(AOwner: TComponent); override;
  destructor Destroy; override;
  procedure GetConnectionDefNames(var ADefNames: TStrings);
  function GetTableDataRecNo(TableName: string): int64; // 取表的记录总数
  function DateTime:TDateTime;
  function GeneratorID:string;
  function FileUpload(const filename:string):Boolean;
  function FileDownload(filename, path: string):Boolean;
  function VerifyCode(image:TBitmap;charType:Integer=1;vclen:Integer=10):string;
  procedure Connect;
  procedure Disconnect;
published
  property ConnectionDefName: string read FConnectionDefName write FConnectionDefName;
  property Compression: Boolean read FCompression write SetCompression;
  property SecureKey: String read FSecureKey write SetSecureKey;
  property ServerAddr: string read FServerAddr write SetServerAddr;
  property ServerPort: string read FServerPort write SetServerPort;
end;

{$ifdef MemDataSet}
TQFTable = class(TMemDataset)
{$endif}
{$ifdef bufdataset}
TQFTable = class(Tbufdataset)
{$endif}
{$ifdef VirtualTable}
TQFTable = class(TVirtualTable)
{$endif}
{$ifdef RTCMemdataset}
TQFTable = class(TRTCMemdataset)
{$endif}
private
  FTableName: string ;
  FKeyFields: string ;
  FpageSize: Integer; // 每页条数
  FPageMax: Integer; // 最大页码
  FCurPage:integer;//当前页
  FSQL: string ;
  FSData:integer;
  FDataPagination:Boolean;
  FAutoSaveData:Boolean;//自动保存数据
  FConnection:TQFConnection;
  FRtcDataSetMonitor:TRtcDataSetMonitor;
  procedure SetConnection(const Value: TQFConnection);
  procedure SetTableName(value: string);
  procedure SetKeyFields(value: string);
  procedure SetpageSize(Value: Integer);
  procedure SetPageMax(Value: Integer);
  procedure SetAutoSaveData(Value:Boolean);
  procedure SetSQL(value: string);
  procedure SetDataPagination(value:Boolean);
  procedure ExecuteReadRecord; //让服务端执行SQL并读取返回数据
  procedure AutoUpdaeData(Sender: TObject);
public
  constructor Create(AOwner: TComponent);override;
  destructor Destroy; override;
  procedure open;
  procedure ApplyUpdates;
  function GetPageMax: int64; // 返回最大页数
  function FirstPage:Int64;
  function PriorPage:int64;
  function NextPage:int64;
  function LastPage:int64;
published
  property Connection: TQFConnection read FConnection write SetConnection;
  property TableName: string read FTableName write FTableName;//SetTableName;
  property KeyFields: string read FKeyFields write FKeyFields;//SetKeyFields;
  property PageSize: Integer Read FpageSize Write FpageSize Default 100;//SetpageSize Default 100;
  property CurPage: Integer Read FCurPage;
  property PageNoMax: Integer Read FPageMax Write FPageMax Default 0;// SetPageMax Default 0;
  property SQL: string read FSQL write SetSQL;
  property DataPagination:Boolean Read FDataPagination Write FDataPagination;//SetDataPagination;
  property AutoSaveData:Boolean Read FAutoSaveData Write FAutoSaveData Default true;
  property Filter;
  property Filtered;
  property FilterOptions;
  property Active;
  property AutoCalcFields;
  property BeforeOpen;
  property AfterOpen;
  property BeforeClose;
  property AfterClose;
  property BeforeInsert;
  property AfterInsert;
  property BeforeEdit;
  property AfterEdit;
  property BeforePost;
  property AfterPost;
  property BeforeCancel;
  property AfterCancel;
  property BeforeDelete;
  property AfterDelete;
  property BeforeScroll;
  property AfterScroll;
  property BeforeRefresh;
  property AfterRefresh;
  property OnCalcFields;
  property OnDeleteError;
  property OnEditError;
  property OnFilterRecord;
  property OnNewRecord;
  property OnPostError;
protected
  //procedure DoAfterScroll; override;
  //procedure DoBeforeScroll;override;
  //property AfterScroll;
  //property BeforeScroll;
end;

{$ifdef bufdataset}
TQFQuery = class(Tbufdataset)
{$endif}
{$ifdef MemDataSet}
TQFQuery = class(TMemDataset)
{$endif}
{$ifdef VirtualTable}
TQFQuery = class(TVirtualTable)
{$endif}
{$ifdef RTCMemdataset}
TQFQuery = class(TRTCMemdataset)
{$endif}
private
  FConnection:TQFConnection;
  FSQL: string ;
  FTableName: string ;
  FKeyFields: string ;
  FpageSize: Integer; // 每页条数
  FPageMax: Integer; // 最大页码
  FCurPage:integer;//当前页
  FAutoSaveData:Boolean;//自动保存数据
  FRtcDataSetMonitor:TRtcDataSetMonitor;
  procedure SetSQL(value: string);
  procedure SetTableName(value: string);
  procedure SetKeyFields(value: string);
  procedure GetTableName;
  procedure SetpageSize(Value: Integer);
  procedure SetPageMax(Value: Integer);
  procedure ExecuteReadRecord; //让服务端执行SQL并读取返回数据
  procedure AutoUpdaeData(Sender: TObject);
public
  constructor Create(AOwner: TComponent);override;
  destructor Destroy; override;
  procedure open;
  procedure ExecSQL;
  procedure ApplyUpdates;
  function GetPageMax: int64; // 返回最大页数
  function FirstPage:Int64;
  function PriorPage:int64;
  function NextPage:int64;
  function LastPage:int64;
published
  property Connection: TQFConnection read FConnection write FConnection;
  property SQL: string read FSQL write SetSQL;
  property TableName: string read FTableName write FTableName;//SetTableName;
  property KeyFields: string read FKeyFields write FKeyFields;//SetKeyFields;
  property PageSize: Integer Read FpageSize Write FpageSize Default 100;// SetpageSize Default 100;
  property CurPage: Integer Read FCurPage;
  property PageNoMax: Integer Read FPageMax Write FPageMax Default 0;//SetPageMax Default 0;
  property AutoSaveData:Boolean Read FAutoSaveData Write FAutoSaveData Default true;
end;

{$ifdef bufdataset}
TQFStoredProc = class(Tbufdataset)     //存储过程
{$endif}
{$ifdef MemDataSet}
TQFStoredProc = class(TMemDataset)     //存储过程
{$endif}
{$ifdef VirtualTable}
TQFStoredProc = class(TVirtualTable) //存储过程
{$endif}
{$ifdef RTCMemdataset}
TQFStoredProc = class(TRTCMemdataset)//存储过程
{$endif}
private
  FConnection:TQFConnection;
  FStoredProcName:string;
  FParam:string;
  FRtcDataSetMonitor:TRtcDataSetMonitor;
  procedure SetStoredProcName(value: string);
  procedure SetParam(value: string);
public
  constructor Create(AOwner: TComponent);
  destructor Destroy; override;
  procedure open;
published
  property Connection: TQFConnection read FConnection write FConnection;
  property StoredProcName:string read FStoredProcName write SetStoredProcName;
  property Param:String read FParam write SetParam;
end;

procedure Register;

implementation

{$R QFDataSet.res}

procedure Register;
begin
  RegisterComponents('QFDataSet', [TQFConnection,TQFTable,TQFQuery,TQFStoredProc]);
end;

{$ifdef bufdataset}
procedure RtcDataSetToFPC(rtcDS:TRtcDataSet; DS:Tbufdataset);
{$endif}
{$ifdef MemDataSet}
procedure RtcDataSetToFPC(rtcDS:TRtcDataSet; DS:TMemDataset);
{$endif}
{$ifdef RTCMemdataset}
procedure RtcDataSetToFPC(rtcDS:TRtcDataSet; DS:TRTCMemdataset);
{$endif}
{$ifdef VirtualTable}
procedure RtcDataSetToFPC(rtcDS:TRtcDataSet; DS:TVirtualTable);
{$endif}
begin
  DS.Close;    //VirtualTable必须在DisableControls前close,否则再次open时出现记录不全的问题
  DS.DisableControls;
  DS.Clear;
  RtcDataSetFieldsToDelphi(rtcDS,DS); //生成数据集前添加字段
  {$ifdef bufdataset}
  DS.CreateDataset;  //使用bufdataset时，必须CreateDataset才能生成数据集
  {$endif}
  RtcDataSetRowsToDelphi(rtcDS,DS);   //添加接收到的全部记录
  DS.First;
  DS.EnableControls;
end;

//设置数据分页参数
procedure TQFConnection.SetDataPage(const FTableName,FKeyFields,PageSize,PageNo:string);
begin
  FRtcClientModule.Prepare('SELECT');
  FRtcClientModule.Param.asText['FUN'] := 'SQLEX';
  FRtcClientModule.Param.asText['ConnectionDefName'] := ConnectionDefName;
  FRtcClientModule.Param.asText['TableName'] := FTableName;
  FRtcClientModule.Param.asText['KeyFields'] := FKeyFields;
  FRtcClientModule.Param.asText['PageSize']:=PageSize;
  FRtcClientModule.Param.asText['PageNo']:=PageNo;
end;

procedure TQFConnection.SetServerPort(const value: string);
begin
  if value <> FServerPort then
  begin
    FServerPort := value;
    FHttpClient.ServerPort := FServerPort;
  end;
end;

procedure TQFConnection.SetSecureKey(const value: string);
begin
  if value <> FSecureKey then
  begin
    FSecureKey := value;
    FRtcClientModule.SecureKey:=value;
  end;
end;

procedure TQFConnection.SetCompression(const value: Boolean);
begin
  if value <> FCompression then
  begin
    FCompression := value;
    if value then
      FRtcClientModule.Compression:=cfast
    else
      FRtcClientModule.Compression:= cnone;
  end;
end;

procedure TQFConnection.SetServerAddr(const value: string);
begin
  if value <> FServerAddr then
  begin
    FServerAddr := value;
    FHttpClient.ServerAddr := FServerAddr;
  end;
end;

function TQFConnection.DateTime:TDateTime;
var
  Resultdata: TRtcValue;
begin
  FRtcClientModule.Prepare('Utils');
  FRtcClientModule.Param.asText['FUN'] := 'DateTime';
  Resultdata := FRtcClientModule.Execute(False);
  Result:=Resultdata.AsDateTime;
end;

function TQFConnection.FileUpload(const filename:string):boolean;
var
  ResultData: TRtcValue;
  res: TRtcRecord;
  ms:TMemoryStream;
begin
  FRtcClientModule.Prepare('FileUpload');
  FRtcClientModule.param.asText['filename'] := ExtractFileName(filename);
  ms := TMemoryStream.Create;
  ms.LoadFromFile(filename);
  FRtcClientModule.param.asByteStream['file']:=ms;
  ms.free;
  ResultData := FRtcClientModule.Execute(False);
  res := ResultData.asRecord;
  if res.AsBoolean['ok'] then
    Result:=true
  else
    Result:=false;
  ResultData.Extract;
  ResultData.Free;
end;

function TQFConnection.VerifyCode(image:TBitmap;charType:Integer=1; vclen:Integer=10):string;
var
  ms: TMemoryStream;
  ResultData: TRTCValue;
  res: TRtcRecord;
begin
  FRtcClientModule.Prepare('VerifyCode');
  if vclen<1 then vclen:=10;
  FRtcClientModule.param.asInteger['CharType'] :=charType ;//chartype=1：大写+数字 =2：大写 =3：数字
  FRtcClientModule.param.asInteger['length'] :=vclen ;
  ResultData := FRtcClientModule.Execute(False);
  res := ResultData.asRecord;
  ms := TMemoryStream.Create;
  ms.LoadFromStream(res.asByteStream['image']);
  image.LoadFromStream(ms);
  ms.Free;
  Result:=res.asString['VerifyCode'];
  ResultData.Extract;
  ResultData.Free;
end;

procedure TQFConnection.GetConnectionDefNames(var ADefNames: TStrings);
var
  I: Integer;
  ResultData: TRTCValue;
  res: TRtcRecord;
begin
  with FRtcClientModule do
  begin
    Prepare('Utils');
    Param.asText['FUN'] := 'GetDefNames';
    ResultData:=Execute(false);
    ADefNames.Clear;
    res := ResultData.asRecord;
    for I := 0 to Res.Count - 1 do
      ADefNames.Add(res.asText[I.ToString]);
  end;
end;

function TQFConnection.FileDownload(filename, path: string):boolean;
var
  ms: TMemoryStream;
  ResultData: TRTCValue;
  res: TRtcRecord;
begin
  if (path<>'') and (path[Length(path)]<>PathDelim) then
  begin
    path:=path+PathDelim;
    ForceDirectories(path);
  end;
  FRtcClientModule.Prepare('FileDownload');
  FRtcClientModule.param.asText['filename'] := filename;
  ResultData := FRtcClientModule.Execute(False);
  res := ResultData.asRecord;
  if res.AsBoolean['ok'] then
  begin
    ms := TMemoryStream.Create;
    ms.LoadFromStream(res.asByteStream['file']);
    ms.SaveToFile(path + filename);
    ms.Free;
    Result:=true;
  end
  else
    Result:=false;
  ResultData.Extract;
  ResultData.Free;
end;

procedure TQFConnection.Connect;
begin
   FHttpClient.Disconnect;
   FHttpClient.Connect();
end;

procedure TQFConnection.Disconnect;
begin
   FHttpClient.Disconnect;
end;

function TQFConnection.GeneratorID:string;
var
  Resultdata: TRtcValue;
begin
  FRtcClientModule.Prepare('Utils');
  FRtcClientModule.Param.asText['FUN'] := 'GeneratorID';
  Resultdata := FRtcClientModule.Execute(False);
  Result:=Resultdata.AsString;
end;

function TQFConnection.GetTableDataRecNo(TableName: string): int64;
var
  Resultdata: TRtcValue;
begin
  FRtcClientModule.Prepare('SELECT');
  FRtcClientModule.Param.asText['ConnectionDefName'] := ConnectionDefName;
  FRtcClientModule.Param.asText['FUN'] := 'RecordCount';
  FRtcClientModule.Param.asText['TableName'] := TableName;
  Resultdata := FRtcClientModule.Execute(False);
  Result:=Resultdata.AsInteger;
  Resultdata.Free;
end;

constructor TQFConnection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCompression:=True;
  FSecureKey:='';
  FServerAddr:='localhost';
  FServerPort:='8112';
  FHttpClient := TRtcHttpClient.Create(nil);
  FRtcClientModule := TRtcClientModule.Create(nil);
  FHttpClient.ReconnectOn.ConnectLost := True;
  FHttpClient.AutoConnect := True;
  FHttpClient.UseProxy := false;//设为True时，第一连接时约需要2-3秒，设为False则马上连接
  FHttpClient.ServerAddr := FServerAddr;
  FHttpClient.ServerPort := FServerPort;

  FRtcClientModule.Client := fHttpClient;
  FRtcClientModule.Compression := cFast; //压缩选项:cNone cFast cDefault cMax  uses添加rtcinfo
  FRtcClientModule.HyperThreading := True;
  FRtcClientModule.EncryptionKey := 16;    //加密key =0不加密 key不能是负数
  FRtcClientModule.ForceEncryption:=True;
  FRtcClientModule.AutoSessions := True;
  FRtcClientModule.SecureKey:='';
  FRtcClientModule.ModuleFileName := '/QFService';
end;

destructor TQFConnection.Destroy;
begin
  FRtcClientModule.Free;
  fHttpClient.Free;
 inherited Destroy;
end;

constructor TQFTable.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FTableName := '';
  FKeyFields := '';
  FPageSize :=100;   //每页默认记录行数
  FPageMax :=0; // 最大页码
  FCurPage:=1;//当前页
  FDataPagination:=True;//默认数据分页
  FAutoSaveData:=true;//设置自动保存数据
  FRtcDataSetMonitor:=TRtcDataSetMonitor.Create(nil);
  FRtcDataSetMonitor.DataSet:=self;
  FRtcDataSetMonitor.Active:=false;
  FRtcDataSetMonitor.OnDataChange:=@AutoUpdaeData;//自动保存数据
end;

destructor TQFTable.Destroy;
begin
  FRtcDataSetMonitor.OnDataChange:=nil;
  FRtcDataSetMonitor.Free;
  inherited Destroy;
end;

procedure TQFTable.open;
begin
  if FPageMax=0 then GetPageMax;
  FCurPage:=1;
  FSData:=1;
  if FSQL<>'' then
  begin
    FConnection.FRtcClientModule.Prepare('SELECT');
    FConnection.FRtcClientModule.Param.asText['ConnectionDefName'] := FConnection.ConnectionDefName;
    FConnection.FRtcClientModule.Param.asText['FUN'] := 'Query';
    FConnection.FRtcClientModule.Param.asText['SQL'] := FSQL;
  end
  else
  begin
    if FDataPagination then //数据分页
    begin
      //设置数据分页参数
      FConnection.SetDataPage(FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
    end
    else
    begin
      FConnection.FRtcClientModule.Prepare('SELECT');
      FConnection.FRtcClientModule.Param.asText['ConnectionDefName'] := FConnection.ConnectionDefName;
      FConnection.FRtcClientModule.Param.asText['FUN'] := 'Table';
      FConnection.FRtcClientModule.Param.asText['TableName'] := FTableName;
      FConnection.FRtcClientModule.Param.asText['KeyFields'] := FKeyFields;
    end;
  end;
  ExecuteReadRecord; //让服务端执行SQL并读取返回数据
  GetPageMax;
end;

procedure TQFTable.AutoUpdaeData(Sender: TObject);
begin
  if FAutoSaveData then
  begin
     self.ApplyUpdates;
  end;
end;

procedure TQFTable.ExecuteReadRecord; //让服务端执行SQL并读取返回数据
var
  Resultdata: TRtcValue;
begin
  FRtcDataSetMonitor.Active:=false;
  Resultdata := FConnection.FRtcClientModule.Execute(False);
  RtcDataSetToFPC(Resultdata.asDataSet,self);
  Resultdata.Extract;
  Resultdata.Free;
  FRtcDataSetMonitor.Active:=True;
end;

procedure TQFTable.SetConnection(const Value: TQFConnection);
begin
  if FConnection=Value then exit;
  FConnection := Value;
end;

procedure TQFTable.SetDataPagination(value:Boolean);
begin
  if Value <> FDataPagination then
  FDataPagination := Value;
end;

procedure TQFTable.SetpageSize(Value: Integer);
begin
  if Value <> FpageSize then
  begin
    if Active then
      close;
    FpageSize := Value;
  end;
end;

procedure TQFTable.SetAutoSaveData(Value:Boolean);
begin
   FAutoSaveData:=Value;
end;

procedure TQFTable.SetPageMax(Value: Integer);
begin
  if Value <> FPageMax then
  begin
    FPageMax := Value;
  end;
end;

procedure TQFTable.SetTableName(value: string);
begin
  if value <> FTableName then
  begin
    FTableName := value;
  end;
end;

procedure TQFTable.SetKeyFields(value: string);
begin
  if value <> FKeyFields then
  begin
    FKeyFields := value;
  end;
end;

procedure TQFTable.SetSQL(value: string);
begin
  if value <> FSQL then
  begin
    FSQL := value;
  end;
end;

function TQFTable.FirstPage:Int64;
begin
  FSData:=1;
  if FPageMax=0 then GetPageMax;
  FCurPage:=1;
  //设置数据分页参数
  FConnection.SetDataPage(FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
  ExecuteReadRecord; //让服务端执行SQL并读取返回数据
end;

function TQFTable.PriorPage:int64;
begin
  FSData:=1;
  if FPageMax=0 then GetPageMax;
  if (FCurPage<=FPageMax) and (FCurPage>1) then dec(FCurPage);
  //设置数据分页参数
  FConnection.SetDataPage(FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
  ExecuteReadRecord; //让服务端执行SQL并读取返回数据
end;

function TQFTable.NextPage:int64;
begin
  FSData:=1;
  if FPageMax=0 then GetPageMax;
  if (FCurPage<FPageMax) then inc(FCurPage);
  //设置数据分页参数
  FConnection.SetDataPage(FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
  ExecuteReadRecord; //让服务端执行SQL并读取返回数据
end;

function TQFTable.LastPage:int64;
begin
  FSData:=1;
  if FPageMax=0 then GetPageMax;
  FCurPage:=FPageMax;
  //设置数据分页参数
  FConnection.SetDataPage(FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
  ExecuteReadRecord; //让服务端执行SQL并读取返回数据
end;

function TQFTable.GetPageMax: int64;
begin
  if FPageSize = 0 then
     FPageSize := 100;
  FPageMax :=Ceil (FConnection.GetTableDataRecNo(FTableName) / FPageSize);
  Result := FPageMax;
end;

procedure TQFTable.ApplyUpdates;
var
  Resultdata: TRtcValue;
begin
  if self.State in [dsinsert, dsedit] then
    self.Post;
  FConnection.FRtcClientModule.Prepare('SUBMIT');
  FConnection.FRtcClientModule.Param.asText['ConnectionDefName'] := FConnection.ConnectionDefName;
  FConnection.FRtcClientModule.Param.asText['TableName'] := FTableName;
  FConnection.FRtcClientModule.Param.asText['KeyFields'] := FKeyFields;
  FConnection.FRtcClientModule.Param.asObject['Delta'] :=FRtcDataSetMonitor.ExtractChanges;//; self.ExtractChanges;
  Resultdata := FConnection.FRtcClientModule.Execute(False);
  Resultdata.Free;
end;


constructor TQFQuery.Create(AOwner: TComponent);
begin
  inherited ;
  FSQL := '';
  FTableName :='';
  FKeyFields :='';
  FPageSize :=100;   //
  FPageMax :=0; // 最大页码
  FCurPage:=1;//当前页
  FAutoSaveData:=true;//设置自动保存数据
  FRtcDataSetMonitor:=TRtcDataSetMonitor.Create(nil);
  FRtcDataSetMonitor.DataSet:=self;
  FRtcDataSetMonitor.Active:=false;
  FRtcDataSetMonitor.OnDataChange:=@AutoUpdaeData; //自动保存数据
end;

destructor TQFQuery.Destroy;
begin
  FRtcDataSetMonitor.OnDataChange:=nil;
  FRtcDataSetMonitor.free;
  inherited Destroy;
end;

procedure TQFQuery.AutoUpdaeData(Sender: TObject);
begin
  if FAutoSaveData then
    self.ApplyUpdates;
end;

procedure TQFQuery.ExecuteReadRecord; //让服务端执行SQL并读取返回数据
var
  Resultdata: TRtcValue;
begin
  FRtcDataSetMonitor.Active:=false;
  Resultdata := FConnection.FRtcClientModule.Execute(False);
  RtcDataSetToFPC(Resultdata.asDataSet,self);
  Resultdata.Extract;
  Resultdata.Free;
  FRtcDataSetMonitor.Active:=True;
end;

procedure TQFQuery.SetSQL(value: string);
begin
  if value <> FSQL then
  begin
    FSQL := value;
  end;
end;

procedure TQFQuery.SetpageSize(Value: Integer);
begin
  if Value <> FpageSize then
  begin
    if Active then
      close;
    FpageSize := Value;
  end;
end;

procedure TQFQuery.SetPageMax(Value: Integer);
begin
  if Value <> FPageMax then
  begin
    FPageMax := Value;
  end;
end;

procedure TQFQuery.SetTableName(value: string);
begin
  if value <> FTableName then
  begin
    FTableName := value;
  end;
end;

procedure TQFQuery.SetKeyFields(value: string);
begin
  if value <> FKeyFields then
  begin
    FKeyFields := value;
  end;
end;

procedure TQFQuery.GetTableName;
var
  SQLText,TempSQL, SUBSQL,SUBSQL2: String;
  WPS, SLen,i: integer;
begin
  TempSQL := UpperCase(SQL);
  SQLText:=TempSQL;
  SLen := Length(SQLText);
  i:=Pos('FROM ', TempSQL);
  SUBSQL :=  Trim(Copy(SQLText, i + 5, SLen)).ToUpper;
  SUBSQL2 :=  Trim(Copy(SQL, i + 5, SLen));
  WPS := Pos('WHERE', SUBSQL);
  if WPS = 0 then
  begin
    if pos(' ',SUBSQL2)>0 then
       SUBSQL:=trim(copy(SUBSQL2,1,pos(' ',SUBSQL2)));
    FTableName := SUBSQL2;
  end
  else
    FTableName :=trim(Copy(SUBSQL2, 1, WPS - 1));
end;

procedure TQFQuery.open;
begin
  FConnection.FRtcClientModule.Prepare('SELECT');
  FConnection.FRtcClientModule.Param.asText['ConnectionDefName'] := FConnection.ConnectionDefName;
  FConnection.FRtcClientModule.Param.asText['FUN'] := 'Query';
  FConnection.FRtcClientModule.Param.asText['SQL'] := FSQL;
  GetTableName;
  ExecuteReadRecord; //让服务端执行SQL并读取返回数据
end;

procedure TQFQuery.ExecSQL;
var
  Resultdata: TRtcValue;
begin
  FConnection.FRtcClientModule.Prepare('EXECSQL');
  FConnection.FRtcClientModule.Param.asText['ConnectionDefName'] := FConnection.ConnectionDefName;
  FConnection.FRtcClientModule.Param.asText['SQL'] := FSQL;
  Resultdata := FConnection.FRtcClientModule.Execute(False);
  Resultdata.Extract;
  Resultdata.Free;
end;

function TQFQuery.FirstPage:Int64;
begin
  if FPageMax=0 then GetPageMax;
  FCurPage:=1;
  //设置数据分页参数
  FConnection.SetDataPage(FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
  ExecuteReadRecord; //让服务端执行SQL并读取返回数据
end;

function TQFQuery.PriorPage:int64;
begin
  if FPageMax=0 then GetPageMax;
  if (FCurPage<=FPageMax) and (FCurPage>1) then dec(FCurPage);
  //设置数据分页参数
  FConnection.SetDataPage(FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
  ExecuteReadRecord; //让服务端执行SQL并读取返回数据
end;

function TQFQuery.NextPage:int64;
begin
  if FPageMax=0 then GetPageMax;
  if (FCurPage<FPageMax) then inc(FCurPage);
  //设置数据分页参数
  FConnection.SetDataPage(FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
  ExecuteReadRecord; //让服务端执行SQL并读取返回数据
end;

function TQFQuery.LastPage:int64;
begin
  if FPageMax=0 then GetPageMax;
  FCurPage:=FPageMax;
  //设置数据分页参数
  FConnection.SetDataPage(FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
  ExecuteReadRecord; //让服务端执行SQL并读取返回数据
 end;

function TQFQuery.GetPageMax: int64;
begin
  if FPageSize = 0 then
     FPageSize := 100;
  FPageMax :=Ceil (FConnection.GetTableDataRecNo(FTableName) / FPageSize);
  Result := FPageMax;
end;

procedure TQFQuery.ApplyUpdates;
var
  Resultdata: TRtcValue;
begin
  if self.Active then
  begin
    if self.State in [dsinsert, dsedit] then
      self.Post;
    GetTablename;
    FConnection.FRtcClientModule.Prepare('SUBMIT');
    FConnection.FRtcClientModule.Param.asText['ConnectionDefName'] := FConnection.ConnectionDefName;
    FConnection.FRtcClientModule.Param.asText['TableName'] := FTableName;
    FConnection.FRtcClientModule.Param.asText['KeyFields'] := FKeyFields;
    FConnection.FRtcClientModule.Param.asObject['Delta'] :=FRtcDataSetMonitor.ExtractChanges;//;self.ExtractChanges;
    Resultdata := FConnection.FRtcClientModule.Execute(False);
    Resultdata.Free;
  end;
end;

constructor TQFStoredProc.Create(AOwner: TComponent);
begin
  inherited ;
  FRtcDataSetMonitor:=TRtcDataSetMonitor.Create(nil);
  FRtcDataSetMonitor.DataSet:=self;
  FRtcDataSetMonitor.Active:=false;
end;

destructor TQFStoredProc.Destroy;
begin
  FRtcDataSetMonitor.free;
  inherited Destroy;
end;

procedure TQFStoredProc.SetStoredProcName(value: string);
begin
  FStoredProcName := value;
end;

procedure TQFStoredProc.SetParam(value: string);
begin
  FParam := value;
end;

procedure TQFStoredProc.open;
var
  Resultdata: TRtcValue;
begin
  FRtcDataSetMonitor.Active:=false;
  FConnection.FRtcClientModule.Prepare('StoredProc');
  FConnection.FRtcClientModule.Param.asText['ConnectionDefName'] := FConnection.ConnectionDefName;
  FConnection.FRtcClientModule.Param.asText['StoredProcName'] := FStoredProcName;
  FConnection.FRtcClientModule.Param.asText['params'] := FParam;
  Resultdata := FConnection.FRtcClientModule.Execute(False);
  RtcDataSetToFPC(Resultdata.asDataSet,self);
  Resultdata.Extract;
  Resultdata.Free;
  FRtcDataSetMonitor.Active:=true;
end;

end.
