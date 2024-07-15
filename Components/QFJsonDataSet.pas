unit QFJsonDataSet;

{$mode objfpc}{$H+}

{$DEFINE ZMemTable} //ZEOS
{.$DEFINE BufDataSet}
{.$DEFINE MemDataSet}
{.$DEFINE VirtualTable}
{.$DEFINE RTCMemDataSet}
{.$DEFINE RXMemDataSet}
{.$DEFINE DataType_AI_TO_I}

interface

uses
  Classes,
  SysUtils,
  math,
  DB,
  Graphics,
  StdCtrls,
  ExtCtrls,
  rtcDB,
  rtcInfo,
  rtcSystem,
  lazutf8,
  base64,
  fpjson,
  jsonparser,
  MD5,
  FPHttpClient,
  LCLType,
  LCLIntf,
  GraphType
  {$ifdef ZMemTable}
  ,ZDataset
  {$endif}
  {$ifdef RXMemDataSet}
    ,rxmemds
  {$endif}
  {$ifdef BufDataSet}
    ,BufDataSet
  {$endif}
  {$ifdef MemDataSet}
    ,memds
  {$endif}
  {$ifdef VirtualTable}
    ,VirtualTable
  {$endif}
  ;

type

  TDatasetHelper = class helper for TDataset
  public
    function GetRecordCount:Longint;
  end;

  TRtcDataSetChangesHelper = class helper for TRtcDataSetChanges
  public
    function GetActionSQL(const ATableName: RtcWideString;
      const AKeyFields: RtcWideString = ''): RtcWideString;
  end;

  TQFJsonConnection = class(TComponent)
  private
    FServerAddr: string ;
    FServerPort: string ;
    FUserName:string;
    FPassWord:string;
    Ftoken:string;
    FIsLogin:string;
    FConnectionDefName: string;
    FConnectionList:TStringList;
    procedure SetServerAddr(const value: string);
    procedure SetServerPort(const value: string);
    {$ifdef ZMemTable}
    function SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TZMemTable;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
    {$endif}
    {$ifdef RXMemDataSet}
    function SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRxMemoryData;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
    {$endif}
    {$ifdef MemDataSet}
    function SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TMemDataSet;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
    {$endif}
    {$ifdef BufDataSet}
    function SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TBufDataSet;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
    {$endif}
    {$ifdef VirtualTable}
    function SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TVirtualTable;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
    {$endif}
    {$ifdef RTCMemDataSet}
    function SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRTCMemDataSet;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
    {$endif}
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure GetConnectionDefNames;
    function GetTableDataRecNo(TableName: string): int64; // 取表的记录总数
    function DateTime:string;
    function GetID:string;
    function VerifyCode(image:Timage;charType:Integer=1;vclen:Integer=10):string;
    function Connect:string;
    procedure Disconnect;
  published
    property UserName: string read FUserName write FUserName;
    property PassWord: string read FPassWord write FPassWord;
    property ConnectionList:TStringList read FConnectionList;
    property ConnectionDefName: string read FConnectionDefName write FConnectionDefName;
    property ServerAddr: string read FServerAddr write SetServerAddr;
    property ServerPort: string read FServerPort write SetServerPort;
    property IsLogin: string read FIsLogin;
  end;

  {$ifdef ZMemTable}
  TQFJSONTable = class(TZMemTable)
  {$endif}
  {$ifdef RXMemDataSet}
  TQFJSONTable = class(TRxMemoryData)
  {$endif}
  {$ifdef MemDataSet}
  TQFJSONTable = class(TMemDataset)
  {$endif}
  {$ifdef BufDataSet}
  TQFJSONTable = class(TBufDataSet)
  {$endif}
  {$ifdef VirtualTable}
  TQFJSONTable = class(TVirtualTable)
  {$endif}
  {$ifdef RTCMemDataSet}
  TQFJSONTable = class(TRTCMemDataSet)
  {$endif}
  private
    FQFJsonConnection:TQFJsonConnection;
    FFetchAll:Boolean;
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
    procedure AutoUpdaeData(Sender: TObject);
  public
    constructor Create(AOwner: TComponent);override;
    destructor Destroy; override;
    function open:string;
    function ExecSQL:string;
    function ApplyUpdates:string;
    function GetPageMax: int64; // 返回最大页数
    function FirstPage:string;
    function PriorPage:string;
    function NextPage:string;
    function LastPage:string;
  published
    property Connection: TQFJsonConnection read FQFJsonConnection write FQFJsonConnection;
    property FetchAll:Boolean read FFetchAll write FFetchAll Default True;
    property SQL: string read FSQL write SetSQL;
    property TableName: string read FTableName write FTableName;
    property KeyFields: string read FKeyFields write FKeyFields;
    property PageSize: Integer Read FpageSize Write FpageSize Default 100;
    property CurPage: Integer Read FCurPage;
    property PageNoMax: Integer Read FPageMax Write FPageMax Default 0;
    property AutoSaveData:Boolean Read FAutoSaveData Write FAutoSaveData Default true;
  end;

  {$ifdef ZMemTable}
  TQFJSONQuery = class(TZMemTable)
  {$endif}
  {$ifdef RXMemDataSet}
  TQFJSONQuery = class(TRxMemoryData)
  {$endif}
  {$ifdef MemDataSet}
  TQFJSONQuery = class(TMemDataset)
  {$endif}
  {$ifdef BufDataSet}
  TQFJSONQuery = class(TBufDataSet)
  {$endif}
  {$ifdef VirtualTable}
  TQFJSONQuery = class(TVirtualTable)
  {$endif}
  {$ifdef RTCMemDataSet}
  TQFJSONQuery = class(TRTCMemdataset)
  {$endif}
  private
    FQFJsonConnection:TQFJsonConnection;
    FFetchAll:Boolean;
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
    procedure AutoUpdaeData(Sender: TObject);
  public
    constructor Create(AOwner: TComponent);override;
    destructor Destroy; override;
    function open:string;
    function ExecSQL:string;
    function ApplyUpdates:string;
    function GetPageMax: int64; // 返回最大页数
    function FirstPage:string;
    function PriorPage:string;
    function NextPage:string;
    function LastPage:string;
  published
    property Connection: TQFJsonConnection read FQFJsonConnection write FQFJsonConnection;
    property FetchAll:Boolean read FFetchAll write FFetchAll Default True;
    property SQL: string read FSQL write SetSQL;
    property TableName: string read FTableName write FTableName;
    property KeyFields: string read FKeyFields write FKeyFields;
    property PageSize: Integer Read FpageSize Write FpageSize Default 100;
    property CurPage: Integer Read FCurPage;
    property PageNoMax: Integer Read FPageMax Write FPageMax Default 0;
    property AutoSaveData:Boolean Read FAutoSaveData Write FAutoSaveData Default true;
  end;

  function HttpGetString(AURL:string):string;
  function HttpPostString(AURL:string):string;
  procedure DrawLetter(ch: Char; angle, nextPos: Integer;image1:Timage);
  procedure DrawLines(aLineCount: Integer;image1:Timage);
  {$ifdef ZMemTable}
  function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TZMemTable;sql:string;QFJsonConnection:TQFJsonConnection):string;
  function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TZMemTable;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
  function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TZMemTable;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
  {$endif}
  {$ifdef RXMemDataSet}
  function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRxMemoryData;sql:string;QFJsonConnection:TQFJsonConnection):string;
  function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRxMemoryData;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
  function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TRxMemoryData;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
  {$endif}
  {$ifdef MemDataSet}
  function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TMemDataSet;sql:string;QFJsonConnection:TQFJsonConnection):string;
  function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TMemDataSet;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
  function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TMemDataSet;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
  {$endif}
  {$ifdef RTCMemDataSet}
  function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRTCMemDataSet;sql:string;QFJsonConnection:TQFJsonConnection):string;
  function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRTCMemDataSet;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
  function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TRTCMemDataSet;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
  {$endif}
  {$ifdef BufDataSet}
  function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TBufDataSet;sql:string;QFJsonConnection:TQFJsonConnection):string;
  function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TBufDataSet;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
  function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TBufDataSet;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
  {$endif}
  {$ifdef VirtualTable}
  function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TVirtualTable;sql:string;QFJsonConnection:TQFJsonConnection):string;
  function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TVirtualTable;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
  function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TVirtualTable;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
  {$endif}
  function ExecSQLS(sql:string;QFJsonConnection:TQFJsonConnection):string;
  function login(QFJsonConnection:TQFJsonConnection;username,password,ip,port:string):string;
  function Closesession(QFJsonConnection:TQFJsonConnection):string;
  function GeneratorID(QFJsonConnection:TQFJsonConnection):string;
  function GetVerifycode(image1:Timage;QFJsonConnection:TQFJsonConnection):string;
  function GetDatetime(QFJsonConnection:TQFJsonConnection):string;

  procedure Register;

  implementation

{.$R QFDataSet.res}

procedure Register;
begin
  RegisterComponents('QFJsonDataSet', [TQFJsonConnection,TQFJsonTable,TQFJsonQuery]);
end;

function TDatasetHelper.GetRecordCount:Longint;
var
  prevRecNo: Longint;
begin
  //if self.Active then
  //begin
  // if self.Filtered then
  // begin
     DisableControls;
     prevRecNo := RecNo;
     Result := 0;
     First;
     while not(EOF) do
     begin
       Inc(Result);
       Next;
     end;
     RecNo := prevRecNo;
     EnableControls;
  // end
  // else
  //  Result:=RecordCount;
  //end;
end;

//根据数据集变化(update,Insert和delete)生成相应的SQL
function TRtcDataSetChangesHelper.GetActionSQL(const ATableName
  : RtcWideString; const AKeyFields: RtcWideString = ''): RtcWideString;
var
  nFldOrder: integer;
  cFldName, s1, s2: RtcWideString;
  nrow, orow: TRtcDataRow;

  function StreamToBase64(const Outstream:TStream):String;
  var
    Encoder   : TBase64EncodingStream;
    sm: TStringStream;
    Buffer: Pointer;
    BufferSize, i,Count: LongInt;
  begin
    sm:=TStringStream.Create('');
    Outstream.Position:=0;
    Encoder:=TBase64EncodingStream.create(sm);
    Encoder.CopyFrom(Outstream,Outstream.Size);
    Result:=sm.DataString;
    Encoder.Free;
    sm.Free;
  end;

  function SQLValue(const ARow: TRtcDataRow; AOrder: Integer): RtcWideString;
  var
    cName, cValue: RtcWideString;
    eType: TRtcFieldTypes;
    sm:TStream;
  begin
    cName := ARow.FieldName[AOrder];
    eType := ARow.FieldType[cName];
    cValue := ARow.asText[cName];
    if eType in [ft_Blob] then   //将blob转为base64
    begin
      sm:=TStream.Create;
      sm:=ARow.asByteStream[cName];
      Result :='^BLOB^.^'+ATableName+'^BLOB^#^'+StreamToBase64(sm)+'^BLOB^@^'+cName+'^BLOB^_^';
      sm.Free;
    end
    else
    if eType in [ft_String, ft_Date, ft_Time, ft_DateTime,
      ft_FixedChar, ft_WideString, ft_OraTimeStamp] then
    begin
      Result := QuotedStr(trim(cValue))
    end
    else
    if eType in [ft_Boolean] then
    begin
      if SameText(cValue, 'True') then
          Result := '1'
      else
          Result := '0';
    end
    else
        Result := cValue;
  end;

  function MakeWhere(const ARow: TRtcDataRow): RtcWideString;
  var
    cKeyFields: RtcWideString;
    i: Integer;
  begin
    cKeyFields := AKeyFields + ',';
    Result := '';
    for i := 0 to ARow.FieldCount - 1 do
    begin
      cFldName := ARow.FieldName[i];
      if ARow.FieldType[cFldName] in [ft_Blob] then
      begin
         //不生成blob字段
      end
      else
      begin
        if (cKeyFields = ',') or (Pos(cFldName + ',', cKeyFields) > 0)  then
        begin
          if Result <> '' then
              Result := Result + ' AND ';
          if ARow.isNull[cFldName] then
              Result := Result + cFldName + ' IS NULL'
          else
              Result := Result + cFldName + ' = ' + SQLValue(ARow, i);
        end;
      end;
    end;
  end;
begin
  Result := '';
  case self.Action of
    rds_Insert:
      begin
        s1 := '';
        s2 := '';
        nrow := self.NewRow;
        for nFldOrder := 0 to nrow.FieldCount - 1 do
        begin
          cFldName := nrow.FieldName[nFldOrder];
          if UpperCase (cFldName)<>'ID' then //不生成ID字段
          begin
            if not nrow.isNull[cFldName] then
            begin
              if s1 <> '' then
                  s1 := s1 + ',';
              if s2 <> '' then
                  s2 := s2 + ',';
              s1 := s1 + cFldName;
              s2 := s2 + SQLValue(nrow, nFldOrder);
            end;
          end;
        end;
        Result := 'INSERT INTO ' + ATableName + ' (' + s1 + ')' +
          ' VALUES (' + s2 + ')';
      end;
    rds_Update:
      begin
        s2 := '';
        nrow := self.NewRow;
        orow := self.OldRow;
        for nFldOrder := 0 to nrow.FieldCount - 1 do
        begin
          cFldName := nrow.FieldName[nFldOrder];
          if UpperCase (cFldName)<>'ID' then  //不生成ID字段
          begin
            if orow.asCode[cFldName] <> nrow.asCode[cFldName] then
            begin
              if s2 <> '' then
                  s2 := s2 + ', ';
              if nrow.isNull[cFldName] then
                  s2 := s2 + cFldName + ' = NULL'
              else
                  s2 := s2 + cFldName + ' = ' + SQLValue(nrow, nFldOrder);
            end;
          end;
        end;
        Result := 'UPDATE ' + ATableName + ' SET ' + s2 +
          ' WHERE ' + MakeWhere(orow);
      end;
    rds_Delete:
      begin
        orow := self.OldRow;
        Result := 'DELETE FROM ' + ATableName + ' WHERE ' + MakeWhere(orow);
      end;
  end;
end;

procedure Base64ToStream(const s:string; AOutStream: TStream;strict:boolean=false);
var
  SD : String;
  Instream:TStringStream;
  Decoder   : TBase64DecodingStream;
begin
  if (Length(s)=0) or (s='""') then
    Exit;
  SD:=S;
  while Length(Sd) mod 4 > 0 do
    SD := SD + '=';
  Instream:=TStringStream.Create(SD);
  try
    if strict then
      Decoder:=TBase64DecodingStream.Create(Instream,bdmStrict)
    else
      Decoder:=TBase64DecodingStream.Create(Instream,bdmMIME);
    try
       AOutStream.CopyFrom(Decoder,Decoder.Size);
       AOutStream.Position:=0;
    finally
      Decoder.Free;
    end;
  finally
    Instream.Free;
  end;
end;

{$ifdef ZMemTable}
procedure DataSet_Blob_Base64ToStream(const RtcData:TRtcDataSet;rmdataset:TZMemTable);
{$endif}
{$ifdef RXMemDataSet}
procedure DataSet_Blob_Base64ToStream(const RtcData:TRtcDataSet;rmdataset:TRxMemoryData);
{$endif}
{$ifdef MemDataSet}
procedure DataSet_Blob_Base64ToStream(const RtcData:TRtcDataSet;rmdataset:TMemDataSet);
{$endif}
{$ifdef BufDataSet}
procedure DataSet_Blob_Base64ToStream(const RtcData:TRtcDataSet;rmdataset:TBufDataSet);
{$endif}
{$ifdef VirtualTable}
procedure DataSet_Blob_Base64ToStream(const RtcData:TRtcDataSet;rmdataset:TVirtualTable);
{$endif}
{$ifdef RTCMemDataSet}
procedure DataSet_Blob_Base64ToStream(const RtcData:TRtcDataSet;rmdataset:TRTCMemDataSet);
{$endif}
var
  flds:integer;
  fldname:RtcWideString;
  field:TField;
  ms:TMemoryStream;
begin
  while not RtcData.Eof do
  begin
    for flds:=0 to RtcData.FieldCount-1 do
    begin
      fldname:=RtcData.FieldName[flds];
      field:=rmdataset.FindField(String(fldname));
      if assigned(field) then
      begin
        if field.isBlob then
        begin
          if not RtcData.isNull[fldname] then
          Begin
            ms:=TMemoryStream.Create;
            Base64ToStream(RtcData.asJSON[fldname],ms);
            RtcData.asByteStream[fldname]:= ms;
            ms.Free;
          end
          else
            RtcData.asByteStream[fldname]:=nil;
        end;
      end;
    end;
    RtcData.Next;
  end;
  RtcData.First;
end;

function HttpGetString(AURL:string):string;
var ResponseContent:TStringstream;
  HttpClient:TFPHttpClient;
  url:string;
begin
   HttpClient:=TFPHttpClient.Create(nil);
   ResponseContent:= TStringstream.Create();
   try
      url:=URL_Encode(AURL,true);
      HttpClient.Get(url,ResponseContent);
      Result:=ResponseContent.DataString;
   finally
      freeandnil(HttpClient);
      freeandnil(ResponseContent);
   end;
end;

function HttpPostString(AURL:string):string;
var
  HttpClient:TFPHttpClient;
  url:string;
begin
   HttpClient:=TFPHttpClient.Create(nil);
   try
     url:=URL_Encode(AURL,true);
     Result:=HttpClient.Post(url);
   finally
     freeandnil(HttpClient);
   end;
end;

function Closesession(QFJsonConnection:TQFJsonConnection):string;
begin
  Result:='用户未登录';
  if assigned(QFJsonConnection) then
  begin
    if QFJsonConnection.FIsLogin<>'' then
    begin
      HttpGetString('http://'+QFJsonConnection.FServerAddr+':'+QFJsonConnection.ServerPort+
      '/closesession?sessionid='+QFJsonConnection.Ftoken);
      Result:='会话结束';
      QFJsonConnection.FPassWord:='';
      QFJsonConnection.FServerAddr:='';
      QFJsonConnection.FIsLogin:='';
      QFJsonConnection.Ftoken:='';
    end;
  end;
end;

function login(QFJsonConnection:TQFJsonConnection;username,password,ip,port:string):string;
var
  jdata:TJsondata;
  JObject:TJsonObject;
  data:string;
  i,j:integer;
begin
  data:=HttpGetString('http://'+QFJsonConnection.FServerAddr+':'+QFJsonConnection.ServerPort+
    '/login?username='+username+
    '&password='+md5print(md5string(copy(username,1,1)+copy(username,1,1)+ password))+
    '&token='+QFJsonConnection.Ftoken);
  try
    JData:=GetJSON(Data);
    JOBJect:=TJSONOBJECT(jdata);
    QFJsonConnection.FIsLogin:='';
    if jobject.Get('status',data)='OK' then
    begin
      QFJsonConnection.Ftoken:=jobject.Get('token',data);
      QFJsonConnection.Fislogin:='已登录';
      Result:='登录成功';
    end
    else
      Result:='登录失败';
  finally
    JData.Free;
  end;
end;

{$ifdef ZMemTable}
function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TZMemTable;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
{$endif}
{$ifdef RXMemDataSet}
function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TRxMemoryData;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
{$endif}
{$ifdef MemDataSet}
function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TMemDataSet;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
{$endif}
{$ifdef BufDataSet}
function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TBufDataSet;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
{$endif}
{$ifdef VirtualTable}
function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TVirtualTable;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
{$endif}
{$ifdef RTCMemDataSet}
function DataChanges(RM:TRtcDataSetMonitor;rmdataset:TRTCMemDataSet;QFJsonConnection:TQFJsonConnection;TableName,KeyFields:string):string;
{$endif}
var
  jdata:TJsondata;
  JObject:TJsonObject;
  chg: TRtcDataSetChanges;
  sql,s:string;
  data:TRtcValue;
begin
  Result:='用户未登录';
  if assigned(QFJsonConnection) then
  begin
    if QFJsonConnection.Fislogin<>'' then
    begin
      if trim(TableName)<>'' then
      begin
        if rmdataset.State in [dsEdit, dsInsert,dsNewValue] then
        begin
          rmdataset.post;
        end;
        data:=rm.ExtractChanges;
        if assigned(data) then
        begin
          chg:=TRtcDataSetChanges.Create(data);
          chg.First;
          Result:='';
          while not chg.Eof do
          begin
            sql:= chg.GetActionSQL(TableName,KeyFields);
            s:=HttpPostString('http://'+QFJsonConnection.FServerAddr+':'+QFJsonConnection.FServerPort+'/postdata?sql='+sql+'&token='+
                 QFJsonConnection.Ftoken+'&ConnectionDefName='+QFJsonConnection.FConnectionDefName);
            if trim(s)<>'' then
            begin
              JData:=GetJSON(s);
              JOBJect:=TJSONOBJECT(JData);
              if jobject.Get('status',s)<>'NOT_LOGIN' then
              begin
                Result:='更新成功';
              end
              else
                Result:='更新失败';
              JData.Free;
            end;
            chg.Next;
          end;
          chg.Free;
        end;
        data:=nil;
      end
      else Result:='必须要有TableName才能更新'
    end;
  end;
end;

function ExecSQLS(sql:string;QFJsonConnection:TQFJsonConnection):string;
var
  jdata:TJsondata;
  JObject:TJsonObject;
  Data:string;
begin
  Result:='用户未登录';
  if assigned(QFJsonConnection) then
  begin
    if QFJsonConnection.Fislogin<>'' then
    begin
      Data:=HttpPostString('http://'+QFJsonConnection.FServerAddr+':'+QFJsonConnection.FServerPort+'/postdata?sql='+sql+'&token='+
           QFJsonConnection.Ftoken+'&ConnectionDefName='+QFJsonConnection.FConnectionDefName);
      if trim(Data)<>'' then
      begin
        JData:=GetJSON(Data);
        JOBJect:=TJSONOBJECT(JData);
        if jobject.Get('status',Data)='NOT_LOGIN' then
          Result:='用户未登录'
        else
        if jobject.Get('status',Data)='ERROR' then
          Result:=jobject.Get('ERROR_INFO',Data)
        else
          Result:='SQL执行成功';
        JData.Free;
      end
      else Result:='返回出错';
    end;
  end;
end;

{$ifdef ZMemTable}
function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TZMemTable;sql:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
{$ifdef RXMemDataSet}
function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRxMemoryData;sql:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
{$ifdef MemDataSet}
function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TMemDataSet;sql:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
{$ifdef BufDataSet}
function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TBufDataSet;sql:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
{$ifdef VirtualTable}
function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TVirtualTable;sql:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
{$ifdef RTCMemDataSet}
function OpenSQL(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRTCMemDataSet;sql:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
var
  data:ansistring;
  RtcData:TRtcDataSet;
  jdata:TJsondata;
  JObject:TJsonObject;
  i:integer;
begin
  Result:='用户未登录';
  if assigned(QFJsonConnection) then
  begin
    if QFJsonConnection.Fislogin<>'' then
    begin
      data:=HttpGetString('http://'+QFJsonConnection.FServerAddr+':'+QFJsonConnection.FServerPort+
      '/getdata?sql='+ sql+
      '&token='+QFJsonConnection.Ftoken+
      '&ConnectionDefName='+QFJsonConnection.FConnectionDefName);
      if trim(data)<>'' then
      begin
        {$ifdef DataType_AI_TO_I}
        if pos('"type":"AI"',data)>1 Then
        begin
          data:=StringReplace(data,'"type":"AI"','"type":"I"',[rfReplaceAll]);
        end;
        {$endif}
        try
          JData:=GetJSON(data);
          JOBJect:=TJSONOBJECT(JData);
          if jobject.Get('status',data)='NOT_LOGIN' then
            Result:='用户未登录'
          else
          if jobject.Get('status',data)='ERROR' then
            Result:=jobject.Get('ERROR_INFO',data)
          else
          begin
            RtcData:=TRtcDataSet.Create;
            RtcData:=TRtcDataSet.FromJSON(data);
            //VirtualTable必须在DisableControls前close,否则再次open时出现记录不全的问题
            //或更换表后字段名称不变等问题
            rmdataset.Close;
            rmdataset.DisableControls;
            {$ifdef RTCMemDataSet}
            //rmdataset.ClearFields;
            {$else}
            rmdataset.Clear;
            {$endif}
            FRtcDataSetMonitor.Active:=false;
            RtcDataSetFieldsToDelphi(RtcData,rmdataset); //生成数据集前添加字段
            {$ifdef BufDataSet}
            rmdataset.CreateDataset;  //使用BufDataSet时，必须CreateDataset才能生成数据集
            {$endif}
            {$ifdef ZMemTable}
            rmdataset.Open; //使用ZMemTable必须open才可以，否则打开Blob类型时出错。
            {$endif}
            DataSet_Blob_Base64ToStream(RtcData,rmdataset);//将RTCData Blob字段的base64转为Stream
            RtcDataSetRowsToDelphi(RtcData,rmdataset);   //添加接收到的全部记录
            rmdataset.First;
            rmdataset.EnableControls;
            FRtcDataSetMonitor.Active:=true;
            RtcData.Free;
            Result:='SQL执行完成';
          end;
        finally
          jdata.free;
        end;
      end
      else Result:='返回出错';
    end;
  end;
end;

{$ifdef ZMemTable}
function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TZMemTable;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
{$ifdef RXMemDataSet}
function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRxMemoryData;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
{$ifdef MemDataSet}
function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TMemDataSet;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
{$ifdef BufDataSet}
function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TBufDataSet;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
{$ifdef VirtualTable}
function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TVirtualTable;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
{$ifdef RTCMemDataSet}
function OpenSQLEx(FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRTCMemDataSet;TableName,PageSize,PageNo,KeyFields:string;QFJsonConnection:TQFJsonConnection):string;
{$endif}
var
  data,sql:ansistring;
  RtcData:TRtcDataSet;
  jdata:TJsondata;
  JObject:TJsonObject;
begin
  if assigned(QFJsonConnection) then
  begin
    if QFJsonConnection.Fislogin<>'' then
    begin
      sql:='http://'+QFJsonConnection.FServerAddr+':'+QFJsonConnection.FServerPort+
         '/SQLEX?'+
         'TableName='+ TableName+
         '&PageSize='+PageSize+
         '&PageNo='+PageNo+
         '&KeyFields='+KeyFields+
         '&token='+QFJsonConnection.Ftoken+
         '&ConnectionDefName='+QFJsonConnection.FConnectionDefName;
      data:=HttpGetString(sql);
      if trim(data)<>'' then
      begin
        {$ifdef DataType_AI_TO_I}
        if pos('"type":"AI"',data)>1 Then
        begin
          data:=StringReplace(data,'"type":"AI"','"type":"I"',[rfReplaceAll]);
        end;
        {$endif}
        try
          JData:=GetJSON(data);
          JOBJect:=TJSONOBJECT(JData);
          if jobject.Get('status',data)='NOT_LOGIN' then
            Result:='用户未登录'
          else
          if jobject.Get('status',data)='ERROR' then
            Result:=jobject.Get('ERROR_INFO',data)
          else
          begin
            //RTC JSONToDataset必须使用下面2行代码才能正确将JSON数据集转为DataSet
            RtcData:=TRtcDataSet.Create;      //RTC JSONToDataset
            RtcData:=TRtcDataSet.FromJSON(data); //RTC JSONToDataset
            FRtcDataSetMonitor.Active:=false;
            //VirtualTable必须在DisableControls前close,否则再次open时出现记录不全的问题
            //或更换表后字段名称不变等问题
            rmdataset.Close;
            rmdataset.DisableControls;
            {$ifdef RTCMemDataSet}
            //rmdataset.ClearFields;
            {$else}
            rmdataset.Clear;
            {$endif}
            RtcDataSetFieldsToDelphi(RtcData,rmdataset); //生成数据集前添加字段
            {$ifdef BufDataSet}
            rmdataset.CreateDataset;  //使用BufDataSet时，必须CreateDataset才能生成数据集
            {$endif}
            {$ifdef ZMemTable}
            rmdataset.Open;//使用ZMemTable必须open才可以，否则打开Blob类型时出错。
            {$endif}
            DataSet_Blob_Base64ToStream(RtcData,rmdataset);//将RTCData Blob字段的base64转为Stream
            RtcDataSetRowsToDelphi(RtcData,rmdataset);   //添加接收到的全部记录
            rmdataset.First;
            rmdataset.EnableControls;
            FRtcDataSetMonitor.Active:=true;
            RtcData.Free;
            Result:='SQL执行完成';
          end;
        finally
          jdata.free;
        end;
      end
      else Result:='返回出错';
    end
    else Result:='用户未登录';
  end
  else
    Result:='用户未登录';
end;

procedure DrawLetter(ch: Char; angle, nextPos: Integer;image1:Timage);
var
  logFont: TLogFont;
  fontHandle: THandle;
begin
  logFont.lfHeight:= 40;
  logFont.lfWidth:= 20;
  logFont.lfWeight:= 900;

  logFont.lfEscapement:= angle;
  logFont.lfCharSet:= 1;
  logFont.lfOutPrecision:= OUT_TT_ONLY_PRECIS;
  logFont.lfQuality:= DEFAULT_QUALITY;
  logFont.lfPitchAndFamily:= FF_SWISS;
  logFont.lfUnderline:= 0;
  logFont.lfStrikeOut:= 0;

  fontHandle:= CreateFontIndirect(logFont);
  SelectObject(image1.Canvas.Handle, fontHandle);

  SetTextColor(image1.Canvas.Handle, rgb(0, 180, 0));
  SetBKmode(image1.Canvas.Handle, TRANSPARENT);

  SetTextColor(image1.Canvas.Handle, Random(MAXWORD));
  image1.Canvas.TextOut(nextPos, image1.Height div 3, ch);
  DeleteObject(fontHandle);
end;

procedure DrawLines(aLineCount: Integer;image1:Timage);
var
  i: Integer;
begin
  for i:= 0 to aLineCount do
  begin
    image1.Canvas.Pen.Color:= Random(MAXWORD);
    image1.Canvas.MoveTo(Random(image1.Width), Random(image1.Height));
    image1.Canvas.LineTo(Random(image1.Width), Random(image1.Height));
  end;
end;

function GeneratorID(QFJsonConnection:TQFJsonConnection):string;
begin
  Result:='用户未登录';
  if assigned(QFJsonConnection) then
  begin
    if QFJsonConnection.Fislogin<>'' then
      Result:=HttpGetString('http://'+QFJsonConnection.FServerAddr+':'+QFJsonConnection.FServerPort+'/GeneratorID');
  end;
end;

function GetDatetime(QFJsonConnection:TQFJsonConnection):string;
begin
  Result:='用户未登录';
  if assigned(QFJsonConnection) then
  begin
  if QFJsonConnection.Fislogin<>'' then
    Result:=HttpGetString('http://'+QFJsonConnection.FServerAddr+':'+QFJsonConnection.FServerPort+'/datetime');
  end;
end;

function Getverifycode(image1:Timage;QFJsonConnection:TQFJsonConnection):string;
var
  data,VerifyCodes:string;
  jdata:TJsondata;
  JObject:TJsonObject;
  i:integer;
begin
  Result:='用户未登录';
  if assigned(QFJsonConnection) then
  begin
    if QFJsonConnection.Fislogin<>'' then
    begin
      data:=HttpGetString('http://'+QFJsonConnection.FServerAddr+':'+QFJsonConnection.FServerPort+'/VERIFYCODE');
      if trim(data)<>'' then
      begin
        try
          JData:=GetJSON(Data);
          JOBJect:=TJSONOBJECT(jdata);
          VerifyCodes:=jobject.Get('verifycode',data);
          image1.Canvas.Brush.Color:= clWhite;
          image1.Canvas.FillRect(0,0,image1.Width,image1.Height);
          for i:= 1 to Length(VerifyCodes) do
            DrawLetter(VerifyCodes[i], Random(600) + 1, 25 * i - 15,image1);
          DrawLines(15,image1);
        finally
          JData.Free;
          Result:=VerifyCodes;
        end;
      end
      else Result:='返回出错';
    end;
  end;
end;

//设置数据分页参数
{$ifdef ZMemTable}
function TQFJsonConnection.SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TZMemTable;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
{$endif}
{$ifdef RXMemDataSet}
function TQFJsonConnection.SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRxMemoryData;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
{$endif}
{$ifdef MemDataSet}
function TQFJsonConnection.SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TMemDataSet;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
{$endif}
{$ifdef BufDataSet}
function TQFJsonConnection.SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TBufDataSet;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
{$endif}
{$ifdef VirtualTable}
function TQFJsonConnection.SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TVirtualTable;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
{$endif}
{$ifdef RTCMemDataSet}
function TQFJsonConnection.SetDataPage(const FRtcDataSetMonitor:TRtcDataSetMonitor;rmdataset:TRTCMemDataSet;FTableName,FKeyFields,PageSize,PageNo:string):string;//提交数据分页SQL
{$endif}
begin
  Result:=OpenSQLEx(FRtcDataSetMonitor,rmdataset,FTableName,PageSize,PageNo,FKeyFields,self);
end;

procedure TQFJsonConnection.SetServerPort(const value: string);
begin
  if value <> FServerPort then
  begin
    FServerPort := value;
  end;
end;

procedure TQFJsonConnection.SetServerAddr(const value: string);
begin
  if value <> FServerAddr then
  begin
    FServerAddr := value;
  end;
end;

function TQFJsonConnection.DateTime:string;
begin
  Result:='用户未登录';
  if assigned(self) then
  begin
    Result:=GetDatetime(self) ;
  end;
end;

function TQFJsonConnection.VerifyCode(image:Timage;charType:Integer=1; vclen:Integer=10):string;
begin
  if assigned(self) then
   Result:=GetVerifyCode(image,self)
  else Result:='用户未登录';
end;

procedure TQFJsonConnection.GetConnectionDefNames;
var
  jdata,item1:TJsondata;
  data,s:string;
  i,j:integer;
begin
  data:=HttpGetString('http://'+FServeraddr+':'+FServerPort+'/GETCONNECTIONNAMELIST');
  if data<>'' then
  begin
    try
    JData:=GetJSON(data);//'{"CONNECTIONNAMELIST":["测试1","测试2"]}');
    Item1 := JData.Items[0];
    i:=Item1.Count;
    FConnectionList.Clear;
    for j := 0 to i - 1 do
    begin
      s:=(item1.Items[j].Asstring);
      FConnectionList.Add(s);
    end;
    if trim(FConnectionDefName)='' then
      FConnectionDefName:=FConnectionList[0];
    finally
      JData.Free;
    end;
  end;
end;

function TQFJsonConnection.Connect:string;
var
  jdata:TJsondata;
  JObject:TJsonObject;
  data,token:string;
  j:integer;
begin
  Ftoken:='';
  Result:='用户未登录';
  data:=HttpGetString('http://'+FServerAddr+':'+FServerPort+'/login?username='+Fusername+
  '&password='+md5print(md5string(copy(Fusername,1,1)+copy(Fusername,1,1)+ Fpassword))+
  '&token='+Ftoken);
  if trim(data)<>'' then
  begin
    try
      JData:=GetJSON(Data);
      JOBJect:=TJSONOBJECT(jdata);
      Fislogin:='';
      if jobject.Get('status',data)='OK' then
      begin
        GetConnectionDefNames;
        Ftoken:=jobject.Get('token',data);
        Fislogin:='已登录';
        Result:='已登录';
      end
      else
      begin
        Ftoken:='';
        Fislogin:='';
        Result:=jobject.Get('status',data);
      end;
    finally
      JData.Free;
    end;
  end;
end;

procedure TQFJsonConnection.Disconnect;
begin
  Closesession(self);
end;

function TQFJsonConnection.GetID:string;
begin
  Result:=GeneratorID(self);
end;

function TQFJsonConnection.GetTableDataRecNo(TableName: string): int64;
var
  jdata:TJsondata;
  JObject:TJsonObject;
  data,rc:string;
  e:integer;
begin
  if Fislogin<>'' then
  begin
    data:=HttpGetString('http://'+FServerAddr+':'+FServerPort+'/RecordCount?'+
       'TableName='+ TableName+
       '&token='+Ftoken+'&ConnectionDefName='+FConnectionDefName);
    if trim(data)<>'' then
    begin
      try
        JData:=GetJSON(data);
        JOBJect:=TJSONOBJECT(JData);
        if jobject.Get('status',data)<>'NOT_LOGIN' then
        begin
          rc:=jobject.Get('RECORDCOUNT',data);
          val(rc,Result,e);
        end
        else
        begin
          Result:=0;
        end;
      finally
        jdata.free;
      end;
    end
    else Result:=0;
  end
  else Result:=0;
end;

constructor TQFJsonConnection.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FServerAddr:='localhost';
  FServerPort:='8112';
  FUserName:='qf';
  FPassword:='qfadmin';
  FConnectionDefName:='';
  Ftoken:='';
  FIsLogin:='';
  FConnectionList:=TStringList.Create;
end;

destructor TQFJsonConnection.Destroy;
begin
  inherited Destroy;
  Ftoken:='';
  FIsLogin:='';
  FConnectionList.Free;
end;

constructor TQFJsonQuery.Create(AOwner: TComponent);
begin
  inherited ;
  FSQL := '';
  FTableName :='';
  FKeyFields :='';
  FPageSize :=100;   //
  FPageMax :=0; // 最大页码
  FCurPage:=1;//当前页
  FAutoSaveData:=true;//设置自动保存数据
  FFetchAll:=true;//数据分页
  FRtcDataSetMonitor:=TRtcDataSetMonitor.Create(nil);
  FRtcDataSetMonitor.DataSet:=self;
  FRtcDataSetMonitor.Active:=false;
  FRtcDataSetMonitor.OnDataChange:=@AutoUpdaeData; //自动保存数据
//  self.OnDataChange:=@AutoUpdaeData; //自动保存数据
end;

destructor TQFJsonQuery.Destroy;
begin
  FRtcDataSetMonitor.OnDataChange:=nil;
  FRtcDataSetMonitor.free;
//  self.OnDataChange:=nil;
  inherited Destroy;
end;

procedure TQFJsonQuery.AutoUpdaeData(Sender: TObject);
begin
  if FAutoSaveData then
    self.ApplyUpdates;
end;

procedure TQFJsonQuery.SetSQL(value: string);
begin
  if value <> FSQL then
  begin
    FSQL := value;
  end;
end;

procedure TQFJsonQuery.SetpageSize(Value: Integer);
begin
  if Value <> FpageSize then
  begin
    if Active then
      close;
    FpageSize := Value;
  end;
end;

procedure TQFJsonQuery.SetPageMax(Value: Integer);
begin
  if Value <> FPageMax then
  begin
    FPageMax := Value;
  end;
end;

procedure TQFJsonQuery.SetTableName(value: string);
begin
  if value <> FTableName then
  begin
    FTableName := value;
  end;
end;

procedure TQFJsonQuery.SetKeyFields(value: string);
begin
  if value <> FKeyFields then
  begin
    FKeyFields := value;
  end;
end;

procedure TQFJsonQuery.GetTableName;
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
  WPS := Pos(' ', SUBSQL);
  if WPS = 0 then
    FTableName := SUBSQL2
  else
    FTableName :=trim(Copy(SUBSQL2, 1, WPS - 1));
end;

function TQFJsonQuery.open:string;
var k:string;
begin
  //if assigned(FQFJsonConnection) then
  //begin
    k:='';
    Result:='';
    GetTableName;
    if trim(FKeyFields)<>'' then k:=' order by '+FKeyFields;
    if trim(FSQL)='' then
      FSQL:='select * from '+FTableName +k;

    //Result:= OpenSQL(FRtcDataSetMonitor,self,FSQL,FQFJsonConnection);

    FCurPage:=1;
    if FFetchAll then //数据分页
    begin
      //设置数据分页参数
      Result:= FQFJsonConnection.SetDataPage(FRtcDataSetMonitor,self,FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
    end
    else
    begin
      k:='';
      if trim(FKeyFields)<>'' then k:=' order by '+FKeyFields;
      if trim(FSQL)='' then
        FSQL:='select * from '+FTableName +k;
      Result:=OpenSQL(FRtcDataSetMonitor,self,FSQL,FQFJsonConnection);
    end;
  //end;
end;

function TQFJsonQuery.ExecSQL:string;
begin
  Result:= EXECSQLS(FSQL,FQFJsonConnection);
end;

function TQFJsonQuery.FirstPage:string;
begin
  if FPageMax=0 then GetPageMax;
  FCurPage:=1;
  //设置数据分页参数
  Result:=FQFJsonConnection.SetDataPage(FRtcDataSetMonitor,self,FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
end;

function TQFJsonQuery.PriorPage:string;
begin
  if FPageMax=0 then GetPageMax;
  if (FCurPage<=FPageMax) and (FCurPage>1) then dec(FCurPage);
  //设置数据分页参数
  Result:=FQFJsonConnection.SetDataPage(FRtcDataSetMonitor,self,FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
end;

function TQFJsonQuery.NextPage:string;
begin
  if FPageMax=0 then GetPageMax;
  if (FCurPage<FPageMax) then inc(FCurPage);
  //设置数据分页参数
  Result:=FQFJsonConnection.SetDataPage(FRtcDataSetMonitor,self,FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
end;

function TQFJsonQuery.LastPage:string;
begin
  if FPageMax=0 then GetPageMax;
  FCurPage:=FPageMax;
  //设置数据分页参数
  Result:=FQFJsonConnection.SetDataPage(FRtcDataSetMonitor,self,FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
 end;

function TQFJsonQuery.GetPageMax: int64;
begin
  if FPageSize = 0 then
     FPageSize := 100;
  if assigned(FQFJsonConnection) then
   FPageMax :=Ceil (FQFJsonConnection.GetTableDataRecNo(FTableName) / FPageSize)
  else FPageMax:=0;
  Result := FPageMax;
end;

function TQFJsonQuery.ApplyUpdates:string;
begin
  Result:='数据集未打开';
  if self.Active then
  begin
    Result:= DataChanges(FRtcDataSetMonitor, self,FQFJsonConnection,FTableName,FKeyFields);
  end;
end;

constructor TQFJsonTable.Create(AOwner: TComponent);
begin
  inherited ;
  FSQL := '';
  FTableName :='';
  FKeyFields :='';
  FPageSize :=100;   //
  FPageMax :=0; // 最大页码
  FCurPage:=1;//当前页
  FAutoSaveData:=true;//设置自动保存数据
  //FDataPagination:=True;//默认数据分页
  FFetchAll:=true;//数据分页
  FRtcDataSetMonitor:=TRtcDataSetMonitor.Create(nil);
  FRtcDataSetMonitor.DataSet:=self;
  FRtcDataSetMonitor.Active:=false;
  FRtcDataSetMonitor.OnDataChange:=@AutoUpdaeData;//自动保存数据
  //self.OnDataChange:=@AutoUpdaeData; //自动保存数据
end;

destructor TQFJsonTable.Destroy;
begin
  FRtcDataSetMonitor.OnDataChange:=nil;
  FRtcDataSetMonitor.Free;
//  self.OnDataChange:=nil;
  inherited Destroy;
end;

procedure TQFJsonTable.AutoUpdaeData(Sender: TObject);
begin
  if FAutoSaveData then
    self.ApplyUpdates;
end;

procedure TQFJsonTable.SetSQL(value: string);
begin
  if value <> FSQL then
  begin
    FSQL := value;
  end;
end;

procedure TQFJsonTable.SetpageSize(Value: Integer);
begin
  if Value <> FpageSize then
  begin
    if Active then
      close;
    FpageSize := Value;
  end;
end;

procedure TQFJsonTable.SetPageMax(Value: Integer);
begin
  if Value <> FPageMax then
  begin
    FPageMax := Value;
  end;
end;

procedure TQFJsonTable.SetTableName(value: string);
begin
  if value <> FTableName then
  begin
    FTableName := value;
  end;
end;

procedure TQFJsonTable.SetKeyFields(value: string);
begin
  if value <> FKeyFields then
  begin
    FKeyFields := value;
  end;
end;

procedure TQFJsonTable.GetTableName;
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
  WPS := Pos(' ', SUBSQL);
  if WPS = 0 then
    FTableName := SUBSQL2
  else
    FTableName :=trim(Copy(SUBSQL2, 1, WPS - 1));
end;

function TQFJsonTable.open:string;
var k:string;
begin
  Result:='';
  if FPageMax=0 then GetPageMax;
  FCurPage:=1;
  if FFetchAll then //数据分页
//  if FDataPagination then //数据分页
  begin
    //设置数据分页参数
    Result:= FQFJsonConnection.SetDataPage(FRtcDataSetMonitor,self,FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
  end
  else
  begin
    k:='';
    if trim(FKeyFields)<>'' then k:=' order by '+FKeyFields;
    FSQL:='select * from '+FTableName +k;
    Result:=OpenSQL(FRtcDataSetMonitor,self,FSQL,FQFJsonConnection);
  end;
end;

function TQFJsonTable.ExecSQL:string;
begin
  Result:= EXECSQLS(FSQL,FQFJsonConnection);
end;

function TQFJsonTable.FirstPage:string;
begin
  if FPageMax=0 then GetPageMax;
  FCurPage:=1;
  //设置数据分页参数
  Result:= FQFJsonConnection.SetDataPage(FRtcDataSetMonitor,self,FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
end;

function TQFJsonTable.PriorPage:string;
begin
  if FPageMax=0 then GetPageMax;
  if (FCurPage<=FPageMax) and (FCurPage>1) then dec(FCurPage);
  //设置数据分页参数
  Result:=FQFJsonConnection.SetDataPage(FRtcDataSetMonitor,self,FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
end;

function TQFJsonTable.NextPage:string;
begin
  if FPageMax=0 then GetPageMax;
  if (FCurPage<FPageMax) then inc(FCurPage);
  //设置数据分页参数
  Result:=FQFJsonConnection.SetDataPage(FRtcDataSetMonitor,self,FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
end;

function TQFJsonTable.LastPage:string;
begin
  if FPageMax=0 then GetPageMax;
  FCurPage:=FPageMax;
  //设置数据分页参数
  Result:=FQFJsonConnection.SetDataPage(FRtcDataSetMonitor,self,FTableName,FKeyFields,FpageSize.ToString,FCurPage.ToString);
 end;

function TQFJsonTable.GetPageMax: int64;
begin
  if FPageSize = 0 then
     FPageSize := 100;
  if assigned(FQFJsonConnection) then
  FPageMax :=Ceil (FQFJsonConnection.GetTableDataRecNo(FTableName) / FPageSize)
  else FPageMax:=0;
  Result := FPageMax;
end;

function TQFJsonTable.ApplyUpdates:string;
begin
  Result:='数据集未打开';
  if self.Active then
  begin
    Result:= DataChanges(FRtcDataSetMonitor,self,FQFJsonConnection,FTableName,FKeyFields);
  end;
end;

initialization

end.

