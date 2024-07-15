unit QFRemoteDataSet.Server;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, rtcHttpSrv,
  rtcFunction, rtcSrvModule, rtcInfo, rtcConn,rtcDataSrv,rtcSystem,
  rtcDB,
  DB,
  rtcDataSetChangeHelper,
  base64,MD5,
  QFRemoteDataSet.Snowflake,
  QFRemoteDataSet.dbpool,
  QFRemoteDataSet.VerifyCode
  ;

const
  ModuleFileName ='/QFService';
  // 用户名是 admin ，密码是123456的md5值 e10adc3949ba59abbe56e057f20f883e
  LOGIN_URL      = 'http://%s:%s/service/login?username=%s&password=%s&verifycode=%s&token=%s&ConnectionDefNames=%s';
  CONNDEFNAMES_URL = 'http://%s:%s/service/conndefnames';
  OPEN_DATA_URL  = 'http://%s:%s/data/open?sql=%s&token=%s&ConnectionDefNames=%s';
  EXEC_SQL_URL   = 'http://%s:%s/data/exec?sql=%s&token=%s&ConnectionDefNames=%s';
  PAGING_URL     = '&pagesize=%s&pageindex=%s';
  OPEN_SQL       = 'SELECT * FROM Customers';
  GET_VERIFYCODE = 'http://%s:%s/service/verifycode';

  STATUS_OK                 = 0; // ok
  STATUS_PARAMETER_INVALID  = 400; // 请求参数错误
  STATUS_TOKEN_INVALID      = 2; // 令牌错误
  STATUS_VERIFY_FAILURE     = 3; // 验证错误/用户名或密码错误
  STATUS_DBMS_ERROR         = 4; // 数据库系统错误
  STATUS_NOT_LOGINED        = 5; // 未登录
  STATUS_VERIFYCODE_INVALID = 6; // 验证码错误
  STATUS_TOKEN_EXPIRED      = 7; // 授权已过期

type
  { TQFServerForm }

  TQFServer = class(TComponent)
  private
    FSecureKey:string;
    FServerPort:string;
    FSessionID:string;
    FisListening:boolean;
    FCompression:Boolean;
    RtcServerModule: TRtcServerModule;
    RtcHttpServer: TRtcHttpServer;
    RtcFunctionGroup: TRtcFunctionGroup;
    RtcDataProvider:TRtcDataProvider;
    RtcFuncVerifyCode: TRtcFunction;
    RtcFuncSelect: TRtcFunction;
    RtcFunExecSQL: TRtcFunction;
    RtcFuncUtils: TRtcFunction;
    RtcFunFileDownload: TRtcFunction;
    RtcFunFileUpload: TRtcFunction;
    RtcFunStoredProc: TRtcFunction;
    RtcFunSubmit: TRtcFunction;
    procedure RtcDataProviderDataReceived(Sender: TRtcConnection);
    procedure RtcDataProviderCheckRequest(Sender: TRtcConnection);
    procedure RtcFuncUtilsExecute(Sender: TRtcConnection;
          Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure RtcFuncVerifyCodeExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure RtcFuncSelectExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure RtcFunExecSQLExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure RtcFunFileDownloadExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure RtcFunFileUploadExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure RtcFunStoredProcExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure RtcFunSubmitExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
    procedure RtcHttpServerConnect(Sender: TRtcConnection);
    procedure RtcHttpServerDisconnect(Sender: TRtcConnection);
    function readisListening:Boolean;
    procedure SeTQFServerPort(const value: string);
    procedure SetSecureKey(const value: string);
    procedure SetCompression(const value: Boolean);
  public
    procedure Start(const port:string='8112';const SecureKeys:string='';const Compressions:Boolean=true);
    procedure Stop;
    procedure Listen;
    procedure StopListen;
  published
    property isListening: Boolean read readisListening;
    property ServerPort:string read FServerPort write SeTQFServerPort;
    property SecureKey:string read FSecureKey write SetSecureKey;
    property Compression:Boolean read FCompression write SetCompression;
  end;

var
  QFServer:TQFServer;

implementation

uses QFServerMainFrm,QFRemoteDataSet.DataModule;

procedure Base64ToStream(const s:string; AOutStream: TStream;strict:boolean=false);
var
  SD : String;
  Instream:TStringStream;
  Decoder   : TBase64DecodingStream;
begin
  if Length(s)=0 then
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

procedure TQFServer.Start(const port:string='8112';const SecureKeys:string='';const Compressions:Boolean=true);
begin
  QFServer:=TQFServer.Create(nil);
  with QFServer do
  begin
    //动态生成相关控件
    RtcServerModule:= TRtcServerModule.Create(self);
    RtcHttpServer:= TRtcHttpServer.Create(self);
    RtcFunctionGroup:= TRtcFunctionGroup.Create(self);
    RtcDataProvider:=TRtcDataProvider.Create(self);

    RtcFuncVerifyCode:= TRtcFunction.Create(self);
    RtcFuncUtils:= TRtcFunction.Create(self);
    RtcFuncSelect:= TRtcFunction.Create(self);
    RtcFunExecSQL:= TRtcFunction.Create(self);
    RtcFunFileDownload:= TRtcFunction.Create(self);
    RtcFunFileUpload:= TRtcFunction.Create(self);
    RtcFunStoredProc:= TRtcFunction.Create(self);
    RtcFunSubmit:= TRtcFunction.Create(self);
    //设置RtcServerModule参数
    RtcServerModule.AutoSessions := True;
    RtcServerModule.ModuleFileName :=ModuleFileName;// '/QFService'; //模块名称
    RtcServerModule.FunctionGroup := RtcFunctionGroup;
    RtcServerModule.Server:=RtcHttpServer;
    RtcServerModule.EncryptionKey:=16;
    if Compressions then//传输压缩
      RtcServerModule.Compression:=cfast
    else
      RtcServerModule.Compression:=cnone;
    RtcServerModule.SecureKey:=SecureKeys;//连接密钥

    //RtcDataProvider
    RtcDataProvider.Server:=RtcHttpServer;
    RtcDataProvider.OnCheckRequest:=@RtcDataProviderCheckRequest;
    RtcDataProvider.OnDataReceived:=@RtcDataProviderDataReceived;

    //启用Session
    RtcHttpServer.OpenSession();
    //RtcHttpServer.Session.KeepAlive:=86400;
    FSessionID:=RtcHttpServer.Session.ID;

    //设置functionname
    RtcFuncUtils.FunctionName:='Utils';
    RtcFuncVerifyCode.FunctionName:='VerifyCode';
    RtcFuncSelect.FunctionName:='SELECT';
    RtcFunExecSQL.FunctionName:='EXECSQL';
    RtcFunFileDownload.FunctionName:='FileDownload';
    RtcFunFileUpload.FunctionName:='FileUpload';
    RtcFunStoredProc.FunctionName:='StoredProc';
    RtcFunSubmit.FunctionName:='SUBMIT';
    //绑定RtcFunctionGroup
    RtcFuncUtils.Group:=RtcFunctionGroup;
    RtcFuncVerifyCode.Group:=RtcFunctionGroup;
    RtcFuncSelect.Group:=RtcFunctionGroup;
    RtcFunExecSQL.Group:=RtcFunctionGroup;
    RtcFunFileDownload.Group:=RtcFunctionGroup;
    RtcFunFileUpload.Group:=RtcFunctionGroup;
    RtcFunStoredProc.Group:=RtcFunctionGroup;
    RtcFunSubmit.Group:=RtcFunctionGroup;
    //绑定OnExecute
    RtcFuncUtils.OnExecute:=@RtcFuncUtilsExecute;
    RtcFuncVerifyCode.OnExecute:=@RtcFuncVerifyCodeExecute;
    RtcFuncSelect.OnExecute:=@RtcFuncSelectExecute;
    RtcFunExecSQL.OnExecute:=@RtcFunExecSQLExecute;
    RtcFunFileDownload.OnExecute:=@RtcFunFileDownloadExecute;
    RtcFunFileUpload.OnExecute:=@RtcFunFileUploadExecute;
    RtcFunStoredProc.OnExecute:=@RtcFunStoredProcExecute;
    RtcFunSubmit.OnExecute:=@RtcFunSubmitExecute;
    RtcHttpServer.OnConnect:=@RtcHttpServerConnect;
    RtcHttpServer.OnDisconnect:=@RtcHttpServerDisconnect;
    //设置RtcHttpServer参数
    RtcHttpServer.MultiThreaded := True; //线程池
    RtcHttpServer.ServerPort:=port;
 end;
end;

procedure TQFServer.Stop;
begin
  with QFServer do
  begin
    RtcHttpServer.CloseSession(FSessionID);
    RtcFuncUtils.Free;
    RtcFuncVerifyCode.Free;
    RtcFuncSelect.free;
    RtcFunExecSQL.free;
    RtcFunFileDownload.free;
    RtcFunFileUpload.free;
    RtcFunStoredProc.free;
    RtcFunSubmit.free;
    RtcFunctionGroup.Free;
    RtcHttpServer.free;
    RtcServerModule.free;
  end;
  QFServer.Free;
end;

function TQFServer.readisListening:Boolean;
begin
  Result :=QFServer.RtcHttpServer.isListening;
end;

procedure TQFServer.Listen;
begin
  QFServer.RtcHttpServer.MultiThreaded := True; //线程池
  QFServer.RtcHttpServer.Listen;
end;

procedure TQFServer.StopListen;
begin
  QFServer.RtcHttpServer.StopListen;
end;

procedure TQFServer.SetCompression(const value: Boolean);
begin
  FCompression:=value;
  if FCompression then
    QFServer.RtcServerModule.Compression:=cfast
  else
    QFServer.RtcServerModule.Compression:=cnone;
end;

procedure TQFServer.SeTQFServerPort(const value: string);
begin
   FServerPort:=value;
   QFServer.RtcHttpServer.ServerPort:=FServerPort;
end;

procedure TQFServer.SetSecureKey(const value: string);
begin
   FSecureKey:=value;
   QFServer.RtcServerModule.SecureKey:=FSecureKey;
end;

procedure TQFServer.RtcHttpServerConnect(Sender: TRtcConnection);
var NowStr:string;
begin
  if LoginLog then
  begin
    if rowno>logrow then
    begin
      ServerMainFrm.StringGrid1.DeleteRow(1);
      rowno:=logrow
    end;
    NowStr:=FormatDateTime('yyyy-mm-dd h:mm:ss',now());
    ServerMainFrm.StringGrid1.RowCount:=rowno+1;
    ServerMainFrm.StringGrid1.Cells[0,rowno]:='客户端登录';
    ServerMainFrm.StringGrid1.Cells[1,rowno]:=Sender.PeerAddr;
    ServerMainFrm.StringGrid1.Cells[2,rowno]:=NowStr;
    inc(rowno);
    ServerMainFrm.WriteLog(NowStr,'login');
    //if ServerMainFrm.VirtualTable1.Active then
    //begin
    //  if not ServerMainFrm.VirtualTable1.Locate('IP',Sender.PeerAddr,[]) then
    //  begin
    //    ServerMainFrm.VirtualTable1.Append;
    //    ServerMainFrm.VirtualTable1.FieldByName('IP').asString:= Sender.PeerAddr;
    //    ServerMainFrm.VirtualTable1.FieldByName('ID').asString:= FSessionID;
    //    ServerMainFrm.VirtualTable1.Post;
    //  end;
    //end;
  end;
end;

procedure TQFServer.RtcHttpServerDisconnect(Sender: TRtcConnection);
var NowStr:string;
begin
  if LoginLog then
  begin
    if rowno>logrow then
    begin
      ServerMainFrm.StringGrid1.DeleteRow(1);
      rowno:=logrow
    end;
    NowStr:=FormatDateTime('yyyy-mm-dd h:mm:ss',now());
    ServerMainFrm.StringGrid1.RowCount:=rowno+1;
    ServerMainFrm.StringGrid1.Cells[0,rowno]:='客户端退出';
    ServerMainFrm.StringGrid1.Cells[1,rowno]:=Sender.PeerAddr;
    ServerMainFrm.StringGrid1.Cells[2,rowno]:=NowStr;
    inc(rowno);
    ServerMainFrm.WriteLog(NowStr,'login');
    //if ServerMainFrm.VirtualTable1.Active then
    //begin
    //  if ServerMainFrm.VirtualTable1.Locate('IP',Sender.PeerAddr,[]) then
    //  begin
    //    ServerMainFrm.VirtualTable1.Delete;
    //  end;
    //end;
  end;
end;

procedure TQFServer.RtcDataProviderCheckRequest(Sender: TRtcConnection);
var s:string;
begin
  with TRtcDataServer(Sender) do
  begin
    if UpperCase(Request.FileName)='/GETDATA' then
       Accept;
    if UpperCase(Request.FileName)='/POSTDATA' then
       Accept;
    if UpperCase(Request.FileName)='/GENERATORID' then
       Accept;
    if UpperCase(Request.FileName)='/DATETIME' then
       Accept;
    if UpperCase(Request.FileName)='/VERIFYCODE' then
       Accept;
    if UpperCase(Request.FileName)='/LOGIN' then
       Accept;
    if UpperCase(Request.FileName)='/GETCONNECTIONNAMELIST' then
       Accept;
    if UpperCase(Request.FileName)='/CLOSESESSION' then
       Accept;
    if UpperCase(Request.FileName)='/SQLEX' then
       Accept;
    if UpperCase(Request.FileName)='/RECORDCOUNT' then
       Accept;
  end;
end;

procedure TQFServer.RtcDataProviderDataReceived(Sender: TRtcConnection);
var
  orderstr,
  TableName,
  PageSize,
  PageNo :string;
  ss:TStringlist;
  ms: TMemoryStream;
  st:TSTringStream;
  B64: TBase64EncodingStream;
  FVerifyCode: TVerifyCode;
  msblob:TMemoryStream;

  r:Trtcvalue;
  PageSizes,
  PageNos,
  err,
  i,j:integer;
  sql,sid,sp,sp2:string;
  blobs,ATableName,AblobFiels,Ablobwhere:string;
  username,password,verifycode,token,ConnectionDefName:string;
  db:TQFDataModule;
  pool: tQFdbpool;
begin
  with TRtcDataServer(Sender) do
  begin
    if UpperCase(Request.FileName)='/RECORDCOUNT' then
    begin
      try
        TableName := URL_Decode(Request.Query.Value['TableName']);
        sql :='select count(*) from ' + TableName;
        pool := getdbpool(ConnectionDefName);
        db := pool.Lock;
        db.QuerySelect.DisableControls;
        db.QuerySelect.Close;
        db.QuerySelect.SQL.Text :=sql;
        db.QuerySelect.Open;
        write('{"status":"success","RECORDCOUNT":'+'"'+inttostr(db.QuerySelect.Fields[0].AsInteger)+'"}');
        pool.Unlock(db);
      except
        on E: Exception do
        write('{"status":'+'"ERROR",'+'"ERROR_INFO":'+'"'+StringReplace(E.Message,'"','''',[rfReplaceAll])+'"}');
      end;
    end;
    if UpperCase(Request.FileName)='/CLOSESESSION' then
    begin
      sid:=Request.Query.Value['sessionid'];
      if FindSession(sid) then
      begin
        CloseSession(sid);
        write('{"status":'+'"会话已销毁"'+',"token":“”}');
      end
      else
      write('{"status":'+'"没找到会话"'+',"token":“”}');
    end;
    if UpperCase(Request.FileName)='/GETCONNECTIONNAMELIST' then
    begin
      try
        SQL:='';
        for I := 0 to high(dbPools) do
          SQL :=SQL+',"'+ dbPools[i].dbParam.ConnectionDefName+'"';
        SQL:=copy(sql,2,length(sql));
        SQL:='{"CONNECTIONNAMELIST":['+SQL+']}';
        write(sql);
      except
        on E: Exception do
        write('{"status":'+'"ERROR",'+'"ERROR_INFO":'+'"'+StringReplace(E.Message,'"','''',[rfReplaceAll])+'"}');
      end;
    end;
    if UpperCase(Request.FileName)='/VERIFYCODE' then
    begin
      try
        FVerifyCode := TVerifyCode.Create(3,4);//Param.asInteger['CharType'],Param.asInteger['length']);
        //ms := TMemoryStream.Create;
        //st :=TStringStream.Create('');
        //B64 := TBase64EncodingStream.Create(st);
        //FVerifyCode.Image.Picture.SaveToStream(ms);
        //ms.Seek(0,0);
        //b64.CopyFrom(ms,ms.Size);
        //write('{"image":'+chr(39)+st.DataString+chr(39)+',"verifycode":'+
        write('{"verifycode":'+
        chr(39)+FVerifyCode.VerifyCodeString+chr(39)+'}');
        FVerifyCode.free;
        //ms.Free;
        //st.free;
        //b64.Free;
      except
        on E: Exception do
        write('{"status":'+'"ERROR",'+'"ERROR_INFO":'+'"'+StringReplace(E.Message,'"','''',[rfReplaceAll])+'"}');
      end;
    end;
    if UpperCase(Request.FileName)='/GENERATORID' then
    begin
      try
        write(IdGenerator.NextId.ToString);
      except
        on E: Exception do
        write('{"status":'+'"ERROR",'+'"ERROR_INFO":'+'"'+StringReplace(E.Message,'"','''',[rfReplaceAll])+'"}');
      end;
    end;
    if UpperCase(Request.FileName)='/DATETIME' then
    begin
      try
        write(FormatDateTime('yyyy-mm-dd h:mm:ss',now));
      except
        on E: Exception do
        write('{"status":'+'"ERROR",'+'"ERROR_INFO":'+'"'+StringReplace(E.Message,'"','''',[rfReplaceAll])+'"}');
      end;
    end;
    if UpperCase(Request.FileName)='/LOGIN' then
    begin
      if Request.Complete then
      begin
        username:=URL_Decode(Request.Query.Value['username']);
        password:=URL_Decode(Request.Query.Value['password']);
        verifycode:=URL_Decode(Request.Query.Value['verifycode']);
        token:=URL_Decode(Request.Query.Value['token']);

        if (username=login_username) and (password=md5print(md5string(copy(login_username,1,1)+copy(login_username,1,1)+login_password)))  then
        begin
          if not FindSession(token) then
          begin
            opensession;
            write('{"status":'+'"OK"'+',"token":"'+Session.ID +'"}');
          end
          else
          begin
            if Session.isClosing then
            begin
              write('{"status":'+'"会话已销毁"'+',"token":“”}');
            end
            else
            begin
              write('{"status":'+'"OK"'+',"token":'+chr(39)+token +chr(39)+'}');
              Session.asBoolean['login']:=true;
            end;
          end;
        end
        else
        begin
          write('{"status":'+'"帐号名称或密码错误"'+',"token":""}');
        end;
      end;
    end;
    if UpperCase(Request.FileName)='/SQLEX' then
    begin
      TableName := URL_Decode(Request.Query.Value['TableName']);
      PageSize := URL_Decode(Request.Query.Value['PageSize']);
      PageNo := URL_Decode(Request.Query.Value['PageNo']);
      ConnectionDefName:=URL_Decode(Request.Query.Value['ConnectionDefName']);
      token:=URL_Decode(Request.Query.Value['token']);
      pool := getdbpool(ConnectionDefName); //连接名称
      db := pool.Lock;
      db.QuerySelect.DisableControls;
      db.QuerySelect.Close;

      if Request.Query.Value['KeyFields']<>'' then orderstr:=' ORDER BY ' + URL_Decode(Request.Query.Value['KeyFields'])
      else orderstr:='';

      val(PageNo, PageNos, err);
      if PageNos>0 then dec(PageNos);
      val(PageSize, PageSizes, err);
      if UpperCase(copy(db.DBParam.dbType,1,5)) =UpperCase('MySQL') then
      begin
        sql := 'select * from ' + TableName + orderstr + ' limit ' + (PageSizes * PageNos)
          .ToString + ',' + PageSize;
      end
      else
      if UpperCase(db.DBParam.dbType) = UpperCase('PostgreSQL') then
      begin
        sql := 'select * from ' + TableName + orderstr + ' limit ' + PageSize + ' offset ' +
          (PageNos * PageSizes).ToString;
      end
      else
      if UpperCase(db.DBParam.dbType)  = UpperCase('SQLite3') then
      begin
        sql := 'select * from ' + TableName + orderstr + ' limit ' + PageSize + ' offset (' +
          (PageNos * PageSizes).ToString+')';
      end
      else
      if UpperCase(db.DBParam.dbType) = UpperCase('MSSQLServer') then
      begin
        //为MSSQL支持分页，表中需添加ID字段
        sql := 'select TOP ' + PageSize + ' * from ' + TableName +
          ' WHERE ID NOT IN (SELECT TOP ' + (PageSizes * PageNos).ToString +
          '  ID FROM  ' + TableName + ' ORDER BY ID ASC) ORDER BY ID ASC';
        //使用MSSQL2012分页功能
        //sql := 'select * from ' + TableName +' ORDER BY ID ASC '+
        //  ' Offset '+(pageSizes*PageNos).ToString+' ROWS FETCH NEXT '+pageSizes.ToString+'  ROWS ONLY ';
{
 ORDER BY id ASC
Offset @pageSize*(@pageIndex-1) ROWS
FETCH NEXT @pageSize ROWS ONLY;
}
     end;
      if FindSession(token) then
      begin
        if Session.isClosing then
        begin
          write('{"status":'+'"NOT_LOGIN"'+'}');
        end
        else
        begin
          r:=TRTCvalue.Create;
          try
            //db.SQLConnector1.tra .Transaction:=db.QuerySelectTran;
            db.QuerySelect.DisableControls;
            db.QuerySelect.Close;
            db.QuerySelect.SQL.Text :=sql;
            db.QuerySelect.Open;
            DelphiDataSetToRtc(db.QuerySelect,r.NewDataSet);
            write(r.toJSON);
            r.Free;
          except
            on E: Exception do
            write('{"status":'+'"ERROR",'+'"ERROR_INFO":'+'"'+StringReplace(E.Message,'"','''',[rfReplaceAll])+'"}');
          end;
        end;
      end;
      pool.Unlock(db);
    end;

    if UpperCase(Request.FileName)='/GETDATA' then
    begin
      if Request.Complete then
      begin
        sql:=URL_Decode(Request.Query.Value['sql']);
        ConnectionDefName:=URL_Decode(Request.Query.Value['ConnectionDefName']);
        token:=URL_Decode(Request.Query.Value['token']);
        if FindSession(token) then
        begin
          if Session.isClosing then
          begin
            write('{"status":'+'"NOT_LOGIN"'+'}');
          end
          else
          begin
            if trim(sql)<>'' then
            begin
              r:=Trtcvalue.Create;
              try
                pool := getdbpool(ConnectionDefName);
                db := pool.Lock;
                //db.SQLConnector1.Transaction:=db.QuerySelectTran;
                db.QuerySelect.DisableControls;
                db.QuerySelect.Close;
                db.QuerySelect.SQL.Text :=sql;
                db.QuerySelect.Open;
                DelphiDataSetToRtc(db.QuerySelect,r.NewDataSet);
                ss:=TStringlist.Create;
                ss.Add(r.toJSON);
                write(r.toJSON);
                r.Free;
                pool.Unlock(db);
              except
                on E: Exception do
                  write('{"status":'+'"ERROR",'+'"ERROR_INFO":'+'"'+StringReplace(E.Message,'"','''',[rfReplaceAll])+'"}');
              end;
            end;
          end;
        end
        else
          write('{"status":'+'"NOT_LOGIN"'+'}');
      end;
    end;
    if UpperCase(Request.FileName)='/POSTDATA' then
    begin
      if Request.Complete then
      begin
        sql:=URL_Decode(Request.Query.Value['sql']);

        ConnectionDefName:=URL_Decode(Request.Query.Value['ConnectionDefName']);
        token:=URL_Decode(Request.Query.Value['token']);
        if FindSession(token) then
        begin
          if Session.isClosing then
          begin
            write('{"status":'+'"NOT_LOGIN"'+'}');
          end
          else
          begin
            if trim(sql)<>'' then
            begin
              try
                pool := getdbpool(ConnectionDefName);
                db := pool.Lock;
                //db.SQLConnector1.Transaction:=db.QuerySelectTran;
                db.QuerySelect.DisableControls;
                db.QuerySelect.Close;
                //if not db.QuerySelectTran.Active then
                //  db.QuerySelectTran.StartTransaction;
                if pos('^BLOB^.^',sql)>0 Then
                begin
                  blobs:=copy(sql,pos('^BLOB^#^',sql)+8,pos('^BLOB^@^',sql)-pos('^BLOB^#^',sql)-8);
                  ATableName:=copy(sql,pos('^BLOB^.^',sql)+8,pos('^BLOB^#^',sql)-pos('^BLOB^.^',sql)-8);
                  AblobFiels:=copy(sql,pos('^BLOB^@^',sql)+8,pos('^BLOB^_^',sql)-pos('^BLOB^@^',sql)-8);
                  Ablobwhere:=copy(sql,pos('^BLOB^_^',sql)+8,length(sql)-pos('^BLOB^_^',sql));
                  msblob:=TMemoryStream.Create;
                  Base64ToStream(blobs,msblob);
                  msblob.Position:=0;
                  //注意:MSSQL 2000之后的版本不能用image类型，用varbinary(MAX)类型替代image
                  if Copy(sql,1,6)='UPDATE' then
                    db.QuerySelect.SQL.Text :='UPDATE '+ATableName+' SET '+AblobFiels+'=:IMG '+Ablobwhere;// 'select * from '+ATableName+' '+Ablobwhere;
                  if Copy(sql,1,11)='INSERT INTO' then
                  begin
                    sql:=copy(sql,1,pos('^BLOB^.^',sql)-1)+':IMG)';
                    db.QuerySelect.SQL.Text :=sql;
                  end;
                  db.QuerySelect.ParamByName('IMG').LoadFromStream(msblob,ftBlob);
                  db.QuerySelect.ExecSQL;
                  //db.QuerySelectTran.Commit;
                  msblob.Free;
                end
                else
                begin
                  db.QuerySelect.SQL.Text :=sql;
                  db.QuerySelect.ExecSQL;
                  //db.QuerySelectTran.Commit;
                end;
                write('{"status":'+'"执行成功"'+'}');
                pool.Unlock(db);
              except
                on E: Exception do
                write('{"status":'+'"ERROR",'+'"ERROR_INFO":'+'"'+StringReplace(E.Message,'"','''',[rfReplaceAll])+'"}');
              end;
            end;
          end;
        end
        else
          write('{"status":'+'"NOT_LOGIN"'+'}');
      end;
    end;
  end;
end;

procedure TQFServer.RtcFuncUtilsExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
var i:integer;
begin
  if Param.asText['FUN']='GetDefNames' then
  begin
    Result.AutoCreate := True;
    for I := 0 to high(dbPools) do
      Result.asRecord.asText[I.ToString] := dbPools[i].dbParam.ConnectionDefName;
  end
  else
  if Param.asText['FUN']='GeneratorID' then
  begin
    Result.asString:=IdGenerator.NextId.ToString;
    if SQLLog then
    begin
      if ServerMainFrm.memo1.Lines.Count>=logrow then ServerMainFrm.memo1.Lines.Delete(0);
      ServerMainFrm.Memo1.Lines.Add('GeneratorID:'+Result.asString);
      ServerMainFrm.WriteLog('GeneratorID:'+Result.asString);
    end;
  end
  else
  if Param.asText['FUN']='DateTime' then
  begin
    Result.asDateTime:=now;
    if SQLLog then
    begin
      if ServerMainFrm.memo1.Lines.Count>=logrow then ServerMainFrm.memo1.Lines.Delete(0);
      ServerMainFrm.Memo1.Lines.Add('DateTime:'+FormatDateTime('yyyy-mm-dd h:mm:ss',Result.asDateTime));
      ServerMainFrm.WriteLog('DateTime:'+FormatDateTime('yyyy-mm-dd h:mm:ss',Result.asDateTime));
    end;
  end;
end;

procedure TQFServer.RtcFuncVerifyCodeExecute(Sender: TRtcConnection;
      Param: TRtcFunctionInfo; Result: TRtcValue);
var
  ms: TMemoryStream;
  res: TRtcRecord;
  FVerifyCode: TVerifyCode;
begin
  FVerifyCode:= TVerifyCode.Create(Param.asInteger['CharType'],Param.asInteger['length']);
  res := TRtcRecord.Create;
  ms := TMemoryStream.Create;
  try
    try
     FVerifyCode.Image.SaveToStream(ms);
     res.asByteStream['image']:=ms;
     res.asString['VerifyCode'] := FVerifyCode.VerifyCodeString;
     Result.asRecord := res;
    except
      on e: Exception do
      begin
        Result.asRecord := res;
      end;
    end;
  finally
    if SQLLog then
    begin
      if ServerMainFrm.memo1.Lines.Count>=logrow then ServerMainFrm.memo1.Lines.Delete(0);
      ServerMainFrm.Memo1.Lines.Add('Verify Code: '+res.asString['VerifyCode']);
      ServerMainFrm.WriteLog('Verify Code: '+res.asString['VerifyCode']);
    end;
    FVerifyCode.free;
    ms.Free;
    res.Clear;
    res.Free;
  end;
end;

procedure TQFServer.RtcFuncSelectExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  db:TQFDataModule;
  pool: tQFdbpool;
  sql,orderstr:string;
  TableName:string;
  PageSize:string;
  PageNo:string;
  PageNos,PageSizes,err:integer;
  res: TRtcRecord;
  i:integer;
  runquery:Boolean;
begin
  try
    runquery:=true;
    pool := getdbpool(Param.asText['ConnectionDefName']); //连接名称
    db := pool.Lock;
    db.QuerySelect.DisableControls;
    db.QuerySelect.Close;
    if Param.asText['FUN']='SQLEX' then
    begin
      TableName := Param.asText['TableName'];
      PageSize := Param.asText['PageSize'];
      PageNo := Param.asText['PageNo'];
      if Param.asText['KeyFields']<>'' then orderstr:=' ORDER BY ' + Param.asText['KeyFields']
      else orderstr:='';

      val(PageNo, PageNos, err);
      if PageNos>0 then dec(PageNos);
      val(PageSize, PageSizes, err);
      if copy(db.DBParam.dbType,1,5) = 'MySQL' then
      begin
        sql := 'select * from ' + TableName + orderstr + ' limit ' + (PageSizes * PageNos)
          .ToString + ',' + PageSize;
      end
      else
      if db.DBParam.dbType = 'PostgreSQL' then
      begin
        sql := 'select * from ' + TableName + orderstr + ' limit ' + PageSize + ' offset ' +
          (PageNos * PageSizes).ToString;
      end
      else
      if db.DBParam.dbType = 'SQLite3' then
      begin
        sql := 'select * from ' + TableName + orderstr + ' limit ' + PageSize + ' offset (' +
          (PageNos * PageSizes).ToString+')';
      end
      else
      if db.DBParam.dbType = 'MSSQLServer' then
      begin
        //为MSSQL支持分页，表中需添加ID字段
        sql := 'select TOP ' + PageSize + ' * from ' + TableName +
          ' WHERE ID NOT IN (SELECT TOP ' + (PageSizes * PageNos).ToString +
          '  ID FROM  ' + TableName + ' ORDER BY ID ASC) ORDER BY ID ASC';
      end;
      db.QuerySelect.SQL.Text := SQL;
    end
    else
    if Param.asText['FUN']='Table' then
    begin
      if Param.asText['KeyFields']<>'' then orderstr:=' ORDER BY ' + Param.asText['KeyFields']
      else orderstr:='';
      if Param.isNull['SQL'] then
      begin
        SQL:= 'SELECT * FROM ' + Param.asText['TableName']
        + orderstr;
        db.QuerySelect.SQL.Text :=SQL;
      end;
    end
    else
    if Param.asText['FUN']='Query' then
    begin
      SQL:=Param.asText['SQL'];
      db.QuerySelect.SQL.Text := SQL;
    end
    else
    if Param.asText['FUN']='Locate' then
    begin
      runquery:=False;
      PageSize := Param.asText['PageSize'];
      SQL:=Param.asText['SQL'];
      res := TRtcRecord.Create;
      db.QuerySelect.SQL.Text := SQL;
      db.QuerySelect.Open;
      if db.QuerySelect.RecordCount>0 then
      begin
        res.AsBoolean['Locate'] := True; //找到符合条件的记录
        if copy(db.DBParam.dbType,1,5) = 'MySQL' then
        begin
          sql := SQL + ' limit ' + (PageSizes * PageNos)
            .ToString + ',' + PageSize;
        end
        else
        if db.DBParam.dbType = 'PostgreSQL' then
        begin
          sql := SQL + ' limit ' + PageSize + ' offset ' + (PageNos * PageSizes).ToString;
        end
        else
        if db.DBParam.dbType = 'SQLite3' then
        begin
          sql := 'select * from ' + TableName + orderstr + ' limit ' + PageSize + ' offset (' +
            (PageNos * PageSizes).ToString+')';
        end
        else
        if db.DBParam.dbType = 'MSSQLServer' then
        begin
          //为MSSQL支持分页，表中需添加ID字段
          //sql := 'select TOP ' + PageSize + ' * from ' + TableName +
          //  ' WHERE ID NOT IN (SELECT TOP ' + (PageSizes * PageNos).ToString +
          //  '  ID FROM  ' + TableName + ' ORDER BY ID ASC) ORDER BY ID ASC';
        end;
        db.QuerySelect.Close;
        db.QuerySelect.SQL.Text := SQL;
        db.QuerySelect.Open;
     end
      else
      begin
        res.AsBoolean['Locate'] := false;
        Result.asRecord := res;
      end;
      db.QuerySelect.EnableControls;
      DelphiDataSetToRtc(db.QuerySelect, Result.NewDataSet);
      db.QuerySelect.Close;
      res.Free;
    end
    else
    if Param.asText['FUN']='RecordCount' then
    begin
      runquery:=False;
      sql :='select count(*) from ' + Param.asText['TableName'];
      db.QuerySelect.SQL.Text:='select count(*) from ' + Param.asText['TableName'];
      db.QuerySelect.Open;
      db.QuerySelect.EnableControls;
      Result.asInteger:=db.QuerySelect.Fields[0].AsInteger;
      db.QuerySelect.Close;
      if SQLLog then
      begin
        if ServerMainFrm.memo1.Lines.Count>=logrow then ServerMainFrm.memo1.Lines.Delete(0);
        ServerMainFrm.Memo1.Lines.Add('RecordCount:'+inttostr(Result.asInteger));
        ServerMainFrm.WriteLog('RecordCount:'+inttostr(Result.asInteger));
      end;
    end;
    if runquery then
    begin
    db.QuerySelect.Open;
    db.QuerySelect.EnableControls;
    DelphiDataSetToRtc(db.QuerySelect, Result.NewDataSet);
    db.QuerySelect.Close;
    if SQLLog then
    begin
      if ServerMainFrm.memo1.Lines.Count>=logrow then ServerMainFrm.memo1.Lines.Delete(0);
      ServerMainFrm.Memo1.Lines.Add(SQL);
      ServerMainFrm.WriteLog(SQL);
    end;
    end;
  finally
    pool.Unlock(db);
  end;
end;

procedure TQFServer.RtcFunExecSQLExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  cSQL:String;
  db: TQFDataModule;
  pool: TQFdbpool;
begin
  try
    pool := getdbpool(Param.asText['ConnectionDefName']);
    db := pool.Lock;
    cSQL:=Param.asText['SQL'];
    //db.SQLConnector1.Transaction:=db.QueryExecSQLTran;
    //if not db.QueryExecSQLtran.Active then
    //db.QueryExecSQLtran.StartTransaction;
    db.QueryExecSQL.DisableControls;
    db.QueryExecSQL.Close;
    db.QueryExecSQL.SQL.Text := cSQL;
    db.QueryExecSQL.ExecSQL;
    //db.QueryExecSQLtran.Commit;
    db.QueryExecSQL.EnableControls;
    db.QueryExecSQL.Close;
    if SQLLog then
    begin
      if ServerMainFrm.memo1.Lines.Count>=logrow then ServerMainFrm.memo1.Lines.Delete(0);
      ServerMainFrm.Memo1.Lines.Add(cSQL);
      ServerMainFrm.WriteLog(cSQL);
    end;
  finally
    pool.Unlock(db);
  end;
end;

procedure TQFServer.RtcFunFileDownloadExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  ms : TMemoryStream;
  filename: string;
  res: TRtcRecord;
begin
  res := TRtcRecord.Create;
  try
    try
      ForceDirectories(extractfilepath(ParamStr(0)) + 'download');
      filename := extractfilepath(ParamStr(0)) + 'download' + PathDelim +
        param.asText['filename'];
      ms := tmemorystream.Create;
      ms.LoadFromFile(filename);
      res.asByteStream['file']:=ms;
      res.AsBoolean['ok'] := True;
      Result.asRecord := res;
    except
      on e: Exception do
      begin
        res.AsBoolean['ok'] := False;
        Result.asRecord := res;
      end;
    end;
  finally
    if SQLLog then
    begin
      if ServerMainFrm.memo1.Lines.Count>=logrow then ServerMainFrm.memo1.Lines.Delete(0);
      ServerMainFrm.Memo1.Lines.Add('File download: '+filename);
      ServerMainFrm.WriteLog('File download: '+filename);
    end;
    res.Clear;
    res.Free;
  end;
end;

procedure TQFServer.RtcFunFileUploadExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  path,filename: string;
  ms: TMemoryStream;
  res: TRtcRecord;
begin
  res := TRtcRecord.Create;
  ms := TMemoryStream.Create;
  try
    try
      path := extractfilepath(ParamStr(0)) + 'upload';
      ForceDirectories(path);
      filename:=path + PathDelim + param.asText['filename'];
      ms.LoadFromStream(param.asByteStream['file']);
      ms.SaveToFile(filename);
      res.AsBoolean['ok'] := True;
      Result.asRecord := res;
    except
      on e: Exception do
      begin
        res.AsBoolean['ok'] := False;
        Result.asRecord := res;
      end;
    end;
  finally
    if SQLLog then
    begin
      if ServerMainFrm.memo1.Lines.Count>=logrow then ServerMainFrm.memo1.Lines.Delete(0);
      ServerMainFrm.Memo1.Lines.Add('File upload: '+filename);
      ServerMainFrm.WriteLog('File downlouploadad: '+filename);
    end;
   ms.Free;
    res.Clear;
    res.Free;
  end;
end;

procedure TQFServer.RtcFunStoredProcExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  params: rtcwidestring;
  list: TStringList;
  i:integer;
  db: TQFDataModule;
  pool: TQFdbpool;
begin
  try
    pool := getdbpool(Param.asText['ConnectionDefName']); //连接名称
    db := pool.Lock;
    list := TStringList.Create;
    try
      try
        //db.UniStoredProc1.Close;
        //db.UniStoredProc1.UnPrepare;
        //db.UniStoredProc1.Params.Clear;
        //db.UniStoredProc1.StoredProcName := param.asText['StoredProcName'];
        //db.UniStoredProc1.Prepare;
        params := param.asText['params'];
        if params > '' then // 不是所有的存储过程都有参数
        begin
          list.StrictDelimiter := True;
          list.Delimiter := ';';
          list.DelimitedText := params;
          //for i := 0 to list.Count - 1 do
          //  db.UniStoredProc1.FindParam(list.Names[i]).AsString := list.Values[list.Names[i]];
        end;
        //db.UniStoredProc1.Open;
        //DelphiDataSetToRtc(db.UniStoredProc1, Result.NewDataSet);
      except
        //
      end;
    finally
      if SQLLog then
      begin
        if ServerMainFrm.memo1.Lines.Count>=logrow then ServerMainFrm.memo1.Lines.Delete(0);
        //ServerMainFrm.Memo1.Lines.Add('StoredProcName:'+db.UniStoredProc1.StoredProcName);
        //ServerMainFrm.WriteLog('StoredProcName:'+db.UniStoredProc1.StoredProcName);
      end;
      list.Free;
    end;
  finally
    pool.Unlock(db);
  end;
end;

procedure TQFServer.RtcFunSubmitExecute(Sender: TRtcConnection;
  Param: TRtcFunctionInfo; Result: TRtcValue);
var
  chg: TRtcDataSetChanges;
  cTblName, cKeyFields: string;
  i: integer;
  cSQL: rtcWideString;
  db: TQFDataModule;
  pool: TQFdbpool;
begin
  try
    pool := getdbpool(Param.asText['ConnectionDefName']); //连接名称
    db := pool.Lock;
    if Param.isNull['Delta'] then
        Result.asString:='没Delta数据'
    else if not Param.CheckType('TableName', rtc_Text) then
        Result.asString:='TableName是必需的'
    else begin
      cTblName := Param.asText['TableName'];
      cKeyFields := Param.asText['KeyFields'];
      //db.QuerySubmit.UpdatingTable := cTblName;
      chg := TRtcDataSetChanges.Create(Param.asObject['Delta']);
      try
        chg.First;
        while not chg.EOF do
        begin
          cSQL := chg.GetActionSQL(cTblName, cKeyFields);
          if SQLLog then
          begin
            if ServerMainFrm.memo1.Lines.Count>=logrow then ServerMainFrm.memo1.Lines.Delete(0);
            ServerMainFrm.Memo1.Lines.Add(cSQL);
            ServerMainFrm.WriteLog(cSQL);
          end;
          //db.SQLConnector1.Transaction:=db.QuerySubmitTran;
          //if not db.QuerySubmitTran.Active then
          //db.QuerySubmitTran.StartTransaction;
          db.QuerySubmit.Close;
          db.QuerySubmit.SQL.Text:=cSQL;
          db.QuerySubmit.ExecSQL;
          //db.QuerySubmitTran.Commit;
          chg.Next;
        end;
      finally
        chg.Free;
      end;
      Result.asBoolean := True;
    end;
  finally
    pool.Unlock(db);
  end;
end;

end.

