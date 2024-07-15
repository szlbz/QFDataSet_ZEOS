{
lazarus linux/windows简单实用的三层控件QFRemoteDataSet：
转到Lazarus后发现缺少delphi熟悉的三层控件，尝试过国产商业及网上的开源三层控件，
但存在或多或少的问题，始终找不到满意的三层控件（特别是linux aarch64下），决定
开发一个简单实用的lazarus三层控件（参考网上的相关代码）。
这个三层控件功能相对简单，只适合lazarus使用，但非常实用，编写的应用软件能在
windows和国产信创操作系统(linux)及CPU运行。 
2023.01.21 QQ：315175176 秋风 
}
unit QFServerMainFrm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Buttons, StdCtrls,
  ExtCtrls, Menus, ComCtrls, Grids, inifiles,//ValEdit,
  QFRemoteDataSet.DataModule,
  //SQLDB, SQLDBLib,

  //SQLServerUniProvider,
  FileInfo, DB
  {$ifdef windows}
  ,Registry
  {$endif};

type

  { TServerMainFrm }

  TServerMainFrm = class(TForm)
    BitBtn1: TBitBtn;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    ComboBox1: TComboBox;
    Edit1: TEdit;
    Edit10: TEdit;
    Edit11: TEdit;
    Edit12: TEdit;
    Edit13: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    Edit8: TEdit;
    Edit9: TEdit;
    Edt_Port: TEdit;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    GroupBox3: TGroupBox;
    Image1: TImage;
    Label1: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    PopupMenu1: TPopupMenu;
    StatusBar1: TStatusBar;
    StringGrid1: TStringGrid;
    StringGrid2: TStringGrid;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TrayIcon1: TTrayIcon;
    //VirtualTable1: TVirtualTable;
{$ifdef windows}
    procedure Button1Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure setAutoRun(ok:Boolean);
    function readAutoRun:Boolean;
{$endif}
    procedure BitBtn1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MenuItem1Click(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure StringGrid2Click(Sender: TObject);
    procedure TrayIcon1Click(Sender: TObject);
    procedure WriteLog(const Str: String;const Logtype:String='');
    procedure savedbconfig;
  private

  public

  end;

var
  ServerMainFrm: TServerMainFrm;
  DBParams:TDBParams;
  ServerPort:string;
  QFDBType:string;
  MSSQLDirect:string;
  keys:string;
  dbhs, logrow: integer;
  rowno:integer;
  PoolSize:integer;
  login_username,login_password,libpath:string;
  showform,exits,LoginLog,SQLLog,cps:boolean;

implementation

uses QFRemoteDataSet.Snowflake,QFRemoteDataSet.VerifyCode,QFRemoteDataSet.Server,
  QFRemoteDataSet.dbpool;

{$R *.lfm}

{ TServerMainFrm }

procedure TServerMainFrm.savedbconfig;
var i:integer;
  myinifile:Tinifile;
begin
  DBParams[dbhs].dbType:=ComboBox1.Text;//MyIniFile.readstring('数据库', '类型', 'SQL Server');
  DBParams[dbhs].UserName:=Edit3.text ;//:= node.Values['用户名'];// MyIniFile.readstring('数据库', '用户名', '');
  DBParams[dbhs].password:=Edit4.text;// MyIniFile.readstring('数据库', '密码', '');
  DBParams[dbhs].ip:=Edit1.text;// MyIniFile.readstring('数据库', '服务器IP', '127.0.0.1');
  DBParams[dbhs].dbName:=Edit5.text;// MyIniFile.readstring('数据库', '数据库名称', '');
  DBParams[dbhs].port:=Edit2.text;// MyIniFile.readstring('数据库', '端口', '8829');
  DBParams[dbhs].ConnectionDefName:=Edit8.text; //连接名称

  StringGrid2.Cells[0,dbhs+1]:=DBParams[dbhs].ConnectionDefName;
  StringGrid2.Cells[1,dbhs+1]:=DBParams[dbhs].dbType;
  StringGrid2.Cells[2,dbhs+1]:=DBParams[dbhs].dbName;
  StringGrid2.Cells[3,dbhs+1]:=DBParams[dbhs].UserName;
  StringGrid2.Cells[4,dbhs+1]:=DBParams[dbhs].password;
  StringGrid2.Cells[5,dbhs+1]:=DBParams[dbhs].ip;
  StringGrid2.Cells[6,dbhs+1]:=DBParams[dbhs].port;

  DeleteFile(Extractfilepath(Paramstr(0)) + 'dbconfig.ini');
  MYIniFile := TIniFile.Create(Extractfilepath(Paramstr(0)) + 'dbconfig.ini');
  for i:=1 to length(DBParams) do
  begin
    MyIniFile.writestring('数据库'+i.ToString, '连接名称',DBParams[i-1].ConnectionDefName);
    MyIniFile.writestring('数据库'+i.ToString, '类型', DBParams[i-1].dbType);
    MyIniFile.writestring('数据库'+i.ToString, '用户名', DBParams[i-1].UserName);
    MyIniFile.writestring('数据库'+i.ToString, '密码', DBParams[i-1].password);
    MyIniFile.writestring('数据库'+i.ToString, '服务器IP',  DBParams[i-1].ip);
    MyIniFile.writestring('数据库'+i.ToString, '数据库名称', DBParams[i-1].dbName);
    MyIniFile.writestring('数据库'+i.ToString, '端口',DBParams[i-1].port);
  end;
  MYIniFile.Free;
end;

procedure TServerMainFrm.WriteLog(const Str: String;const Logtype:String='');
var
  FileName: String;
  FileHandle: TextFile;
  function GetLogFileName: String;
  var
    Logpath: String;
  begin
    Logpath := ExtractFilePath(ParamStr(0)) + 'log'+PathDelim;
    if not DirectoryExists(Logpath) then
      ForceDirectories(Logpath);
    if Logtype='' then
      Result := Logpath + 'SQL'+FormatDateTime('YYYYMMDD', Now) + '.log'
    else
      Result := Logpath + 'Login'+FormatDateTime('YYYYMMDD', Now) + '.log';
  end;
begin
  FileName := GetLogFileName;
  Assignfile(FileHandle, FileName);
  try
    if FileExists(FileName) then
      Append(FileHandle)
    else
      ReWrite(FileHandle);

    WriteLn(FileHandle, FormatDateTime('[HH:MM:SS]', Now) + '  ' + str);
  finally
    CloseFile(FileHandle);
  end;
end;

{$ifdef windows}
{ 设置开机自启动 }
procedure TServerMainFrm.setAutoRun(ok:Boolean);
var
reg: TRegistry;
begin
  reg := TRegistry.Create;
  try
   reg.RootKey := HKEY_CURRENT_USER; //将根键设置为  HKEY_LOCAL_MACHINE  权限不够用这个:HKEY_CURRENT_USER
   reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run',true); //打开一个键
   if ok then
   begin
     reg.WriteString('QFRemoteDataSet三层服务端',Application.ExeName); //reg这个键中写入数据名称和数据数值
   end
   else
   begin
     reg.DeleteValue('QFRemoteDataSet三层服务端');
   end;
  finally
    reg.CloseKey;
    reg.Free;
  end;
end;

procedure TServerMainFrm.Button1Click(Sender: TObject);
var
  NewDBParams:TDBParams;
  i,j:integer;
begin
  i:=length(DBParams);
  SetLength(NewDBParams,i);
  for j:=0 to i-1 do
  begin
    NewDBParams[j].ConnectionDefName:=DBParams[j].ConnectionDefName;
    NewDBParams[j].dbType := DBParams[j].dbType;
    NewDBParams[j].ip :=  DBParams[j].ip;
    NewDBParams[j].dbName := DBParams[j].dbName;
    NewDBParams[j].UserName := DBParams[j].UserName;
    NewDBParams[j].password := DBParams[j].password;
    NewDBParams[j].port := DBParams[j].port;
  end;
  if i<ConnectNameNumber then
  begin
    i:=i+1;
    dbhs:=i-1;
    DBParams:=nil;
    SetLength(DBParams,i);
    for j:=0 to i-2 do
    begin
      DBParams[j].ConnectionDefName:=NewDBParams[j].ConnectionDefName;
      DBParams[j].dbType := NewDBParams[j].dbType;
      DBParams[j].ip :=  NewDBParams[j].ip;
      DBParams[j].dbName := NewDBParams[j].dbName;
      DBParams[j].UserName := NewDBParams[j].UserName;
      DBParams[j].password := NewDBParams[j].password;
      DBParams[j].port := NewDBParams[j].port;
    end;
    StringGrid2.RowCount:=i+1;
    i:=i-1;
    DBParams[i].ConnectionDefName:='';
    DBParams[i].dbType :='';
    DBParams[i].ip := '';
    DBParams[i].dbName := '';
    DBParams[i].UserName := '';
    DBParams[i].password := '';
    DBParams[i].port := '';
    ComboBox1.Text:='';
    Edit3.text :='';
    Edit4.text :='';
    Edit1.text :='';
    Edit5.text :='';
    Edit2.text :='';
    Edit8.text:='';
    StringGrid2.Row:=StringGrid2.RowCount;
  end
  else Application.MessageBox( '已达最大连接名称数量，不能再添加！','提醒');
end;

procedure TServerMainFrm.Button6Click(Sender: TObject);
var
  NewDBParams:TDBParams;
  i,j,k,r:integer;
begin
  r:=StringGrid2.Row;
  i:=length(DBParams);
  SetLength(NewDBParams,i-1);
  k:=0;
  for j:=0 to i-1 do
  begin
    if r-1<>j then
    begin
      NewDBParams[k].ConnectionDefName:=DBParams[j].ConnectionDefName;
      NewDBParams[k].dbType := DBParams[j].dbType;
      NewDBParams[k].ip :=  DBParams[j].ip;
      NewDBParams[k].dbName := DBParams[j].dbName;
      NewDBParams[k].UserName := DBParams[j].UserName;
      NewDBParams[k].password := DBParams[j].password;
      NewDBParams[k].port := DBParams[j].port;
      inc(k);
    end;
  end;
  DBParams:=nil;
  SetLength(DBParams,i-1);
  for j:=0 to i-2 do
  begin
  DBParams[j].ConnectionDefName:=NewDBParams[j].ConnectionDefName;
  DBParams[j].dbType := NewDBParams[j].dbType;
  DBParams[j].ip :=  NewDBParams[j].ip;
  DBParams[j].dbName := NewDBParams[j].dbName;
  DBParams[j].UserName := NewDBParams[j].UserName;
  DBParams[j].password := NewDBParams[j].password;
  DBParams[j].port := NewDBParams[j].port;
  end;
  StringGrid2.DeleteRow(r);
//  StringGrid2.RowCount:=i-1;
  StringGrid2Click(self);
  savedbconfig;
end;

function TServerMainFrm.readAutoRun:Boolean;
var
reg: TRegistry;
begin
  Result:=False;
  reg := TRegistry.Create;
  try
   reg.RootKey := HKEY_CURRENT_USER; //将根键设置为  HKEY_LOCAL_MACHINE  权限不够用这个:HKEY_CURRENT_USER
   reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run',true); //打开一个键
    if reg.ReadString('QFRemoteDataSet三层服务端')<>'' then Result:=true
    else Result:=False;
  finally
    reg.CloseKey;
    reg.Free;
  end;
end;
{$endif}

procedure TServerMainFrm.FormCreate(Sender: TObject);
var myinifile:Tinifile;
  FileVerInfo: TFileVersionInfo;
var ini: TIniFile;
  nodes, node: TStringList;
  i,err: Integer;
  s: string;
begin
  //GetConnectionList(combobox1.Items);
  ini := TIniFile.Create(extractfilepath(paramstr(0)) + 'dbconfig.ini');
  nodes := TStringList.Create;
  node := TStringList.Create;
  ini.ReadSections(nodes);
  setlength(DBParams, nodes.Count);
  StringGrid2.RowCount:=nodes.Count+1;
  dbhs:=0;
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
    StringGrid2.Cells[0,i+1]:=DBParams[i].ConnectionDefName;
    StringGrid2.Cells[1,i+1]:=DBParams[i].dbType;
    StringGrid2.Cells[2,i+1]:=DBParams[i].dbName;
    StringGrid2.Cells[3,i+1]:=DBParams[i].UserName;
    StringGrid2.Cells[4,i+1]:=DBParams[i].password;
    StringGrid2.Cells[5,i+1]:=DBParams[i].ip;
    StringGrid2.Cells[6,i+1]:=DBParams[i].port;
  end;
  nodes.Free;
  node.Free;
  ini.Free;

  rowno:=1;
  PageControl1.ActivePageIndex:=0;
  exits := false;
  try
    MYIniFile := TIniFile.Create(Extractfilepath(Paramstr(0)) + 'config.ini');
    cps := MyIniFile.ReadBool('系统参数', '传输压缩', True);
    logrow := MyIniFile.ReadInteger('系统参数', '日志行数', 100);
    keys := MyIniFile.Readstring('系统参数', '连接密钥', '');
    ServerPort := MyIniFile.readstring('系统参数', '端口', '8112');
    LoginLog := MyIniFile.ReadBool('系统参数', '显示登陆日志', true);
    SQLLog := MyIniFile.ReadBool('系统参数', '显示SQL日志', true);
    edit9.Text:=MyIniFile.readstring('系统参数', '连接名称数量', '5');
    login_username := MyIniFile.readstring('系统参数', '登录名称', 'qf');
    login_password := MyIniFile.readstring('系统参数', '登录密码', 'qfadmin');
    PoolSize:= MyIniFile.readinteger('系统参数', '数据库连接池数', 5);
    Edit12.text:=PoolSize.ToString;
//    Edit12.text:=FPoolSize;
    edit10.text:=login_username;
    edit11.text:=login_password;
    MYIniFile.Free;
    if logrow<=0 then
    begin
      logrow:=100;
      Edit7.Text:=logrow.tostring;
    end;
    if trim(edit9.Text)='' then  edit9.Text:='5';
    if trim(ServerPort)=''  then
    begin
      ServerPort:='8112';
    end;
    Edt_Port.Text:=ServerPort;
  except
    cps := True;
    logrow := 100;
    ServerPort :='8112';
    LoginLog :=  true;
    SQLLog := true;
    Edit7.Text:=logrow.ToString;
    edit9.Text:='5';
    Edt_Port.Text:=ServerPort;
    edit10.text:=login_username;
    edit11.text:=login_password;
    keys := '';
    checkbox1.Checked:=LoginLog;
    checkbox2.checked:=SQLLog;
    checkbox3.checked:=cps;
  end;

  val(edit9.Text, ConnectNameNumber,err);
  Memo1.Lines.Clear;
  TQFdbPool.Start;   //unidac pool
  QFServer.Start(ServerPort,keys,cps);//端口号,连接密钥,传输压缩

  BitBtn1Click(self);
  FileVerInfo:=TFileVersionInfo.Create(nil);
  try
    FileVerInfo.ReadFileInfo;
    StatusBar1.Panels[1].Text:='Server version: '+FileVerInfo.VersionStrings.Values['FileVersion'];
  finally
    FileVerInfo.Free;
  end;
  showform:=false;
  {$ifdef windows}
  if readAutoRun then
  begin
    Button3.Enabled:=false;
    Button4.Enabled:=true;
  end
  else
  begin
    Button3.Enabled:=true;
    Button4.Enabled:=false;
  end;
  {$endif}
end;

procedure TServerMainFrm.FormShow(Sender: TObject);
begin
  if not showform then
  hide();
end;

procedure TServerMainFrm.MenuItem1Click(Sender: TObject);
begin
  showform:=true;
  ServerMainFrm.Show;
end;

procedure TServerMainFrm.MenuItem2Click(Sender: TObject);
begin
  exits := true;
  close;
end;

procedure TServerMainFrm.PageControl1Change(Sender: TObject);
var myinifile:Tinifile;
begin
  if PageControl1.ActivePageIndex=2 then
  begin
    if High(DBParams)>=0 then
    begin
      Edit8.Text:= DBParams[0].ConnectionDefName;// := node.Values['连接名称'];
      combobox1.Text:= DBParams[0].dbType ;//:= node.Values['类型'];
      Edit1.Text:= DBParams[0].ip ;//:= node.Values['服务器IP'];
      Edit5.Text:= DBParams[0].dbName ;//:= node.Values['数据库名称'];
      Edit3.Text:= DBParams[0].UserName ;//:= node.Values['用户名'];
      Edit4.Text:= DBParams[0].password ;//:= node.Values['密码'];
      Edit2.Text:= DBParams[0].port ;//:= node.Values['端口'];
    end;
  end;
  if PageControl1.ActivePageIndex=1 then
  begin
    MYIniFile := TIniFile.Create(Extractfilepath(Paramstr(0)) + 'config.ini');
    Edt_port.text := MyIniFile.readstring('系统参数', '端口', '8112');
    Edit7.Text := MyIniFile.readstring('系统参数', '日志行数', '100');
    LoginLog := MyIniFile.ReadBool('系统参数', '显示登陆日志', true);
    SQLLog := MyIniFile.ReadBool('系统参数', '显示SQL日志', true);
    cps := MyIniFile.ReadBool('系统参数', '传输压缩', true);
    keys := MyIniFile.ReadString('系统参数', '连接密钥', '');
    libpath:=MyIniFile.ReadString('系统参数', '动态库路径名称', '');
    //combobox2.text:= MyIniFile.readstring('数据库', 'MSSQL','直连'); //直连mssql解决MSSQL2000中文乱码的问题
    login_username := MyIniFile.readstring('系统参数', '登录名称', 'qf');
    login_password := MyIniFile.readstring('系统参数', '登录密码', 'qfadmin');
    PoolSize:= MyIniFile.readinteger('系统参数', '数据库连接池数', 5);
    edit13.Text:=libpath;
    edit12.Text:=PoolSize.ToString;
    edit10.text:=login_username;
    edit11.text:=login_password;
    MYIniFile.Free;
    checkbox1.Checked:=LoginLog;
    CheckBox2.Checked:=cps;
    CheckBox3.Checked:=SQLLog;
    Edit6.Text:=keys;
    {$ifdef linux}
    GroupBox3.Visible:=false;
    Button3.Visible:=false;
    Button4.Visible:=false;
    {$else}
    if readAutoRun then
    begin
      Button3.Enabled:=false;
      Button4.Enabled:=true;
    end
    else
    begin
      Button3.Enabled:=true;
      Button4.Enabled:=false;
    end;
    {$endif}
  end;
end;

procedure TServerMainFrm.StringGrid2Click(Sender: TObject);
var i:integer;
begin
  I:=StringGrid2.Row-1;
  dbhs:=i;
  ComboBox1.Text:=DBParams[i].dbType;//MyIniFile.readstring('数据库', '类型', 'SQL Server');
  Edit3.text :=DBParams[i].UserName ;//:= node.Values['用户名'];// MyIniFile.readstring('数据库', '用户名', '');
  Edit4.text :=DBParams[i].password;// MyIniFile.readstring('数据库', '密码', '');
  Edit1.text :=DBParams[i].ip;// MyIniFile.readstring('数据库', '服务器IP', '127.0.0.1');
  Edit5.text :=DBParams[i].dbName;// MyIniFile.readstring('数据库', '数据库名称', '');
  Edit2.text :=DBParams[i].port;// MyIniFile.readstring('数据库', '端口', '8829');
  Edit8.text:=DBParams[i].ConnectionDefName; //连接名称
end;

procedure TServerMainFrm.TrayIcon1Click(Sender: TObject);
begin
  showform:=true;
  ServerMainFrm.Show;
end;

procedure TServerMainFrm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if QFDataModule<>nil then
    QFDataModule.SQLConnector1.Disconnect;// .Close;
  QFServer.Stop;
end;

procedure TServerMainFrm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  if exits then
  begin
    CanClose := true;
  end
  else
  begin
    CanClose:=false;
    showform:=false;
    ServerMainFrm.Hide;
  end;
end;

procedure TServerMainFrm.BitBtn1Click(Sender: TObject);
begin
  if QFServer.isListening then
  begin
    QFDataModule.SQLConnector1.Disconnect;// .Close;
    QFServer.StopListen;
    BitBtn1.Caption := '启动服务';
    StatusBar1.Panels[2].Text:= '服务已停止('+FormatDateTime('yyyy-mm-dd h:mm:ss',now)+')';
    //VirtualTable1.Close;
    //VirtualTable1.Clear;
    exits:=true;
  end
  else
  begin
    exits:=false;
    StatusBar1.Panels[2].Text:= '服务已开启('+FormatDateTime('yyyy-mm-dd h:mm:ss',now)+')';
    QFServer.ServerPort := ServerPort;//服务端端口
    QFServer.Listen;
    //VirtualTable1.Close;
    //VirtualTable1.Clear;
    //if VirtualTable1.FieldDefs.Count=0 then
    //begin
    //  with VirtualTable1.FieldDefs do
    //  begin
    //    add('IP',ftstring,30);
    //    add('ID',ftstring,100);
    //    add('datetimes',ftstring,50);
    //    add('memo',ftstring,200);
    //  end;
    //end;
    //VirtualTable1.open;
    BitBtn1.Caption := '停止服务';
    StatusBar1.Panels[0].Text:= '监听端口:'+ServerPort;
  end;
end;

procedure TServerMainFrm.Button2Click(Sender: TObject);
var myinifile:Tinifile;
  DataPort,err:integer;
begin
  savedbconfig;

  val(Edit2.text,DataPort,err);
  MYIniFile := TIniFile.Create(Extractfilepath(Paramstr(0)) + 'config.ini');
  MyIniFile.writestring('系统参数', '登录名称', edit10.text);
  MyIniFile.writestring('系统参数', '登录密码', edit11.text);
  MyIniFile.writestring('系统参数', '日志行数', Edit7.Text);
  MyIniFile.writestring('系统参数', '端口', Edt_port.text);
  MyIniFile.WriteBool('系统参数', '显示登陆日志', checkbox1.Checked);
  MyIniFile.WriteBool('系统参数', '显示SQL日志', checkbox3.Checked);
  //MyIniFile.writestring('数据库', 'MSSQL',combobox2.text);
  MyIniFile.WriteBool('系统参数', '传输压缩', CheckBox2.Checked);
  MyIniFile.Writestring('系统参数', '连接密钥', edit6.Text);
  MyIniFile.Writestring('系统参数', '连接名称数量', edit9.Text);
  MyIniFile.Writestring('系统参数', '数据库连接池数', edit12.text);
  MyIniFile.Writestring('系统参数', '动态库路径名称', edit13.Text);
  MYIniFile.Free;
  val(edit9.Text, ConnectNameNumber,err);

  LoginLog:=CheckBox1.Checked;
  cps:=CheckBox2.Checked;
  SQLLog:=CheckBox2.Checked;
  libpath:=edit13.text;
  keys :=edit6.Text;
  QFDBType := ComboBox1.Text;
  ServerPort := Edt_port.text;//服务端端口
  if QFServer.isListening then
    QFServer.StopListen;
  QFServer.Compression:=cps;//传输压缩
  QFServer.SecureKey:=keys;//连接密钥
  QFServer.ServerPort := ServerPort;//服务端端口
  exits:=false;
  StatusBar1.Panels[2].Text:= '服务已开启('+FormatDateTime('yyyy-mm-dd h:mm:ss',now)+')';
  QFServer.Listen;
  BitBtn1.Caption := '停止服务';
  StatusBar1.Panels[0].Text:= '监听端口:'+ServerPort;
{
  unidm.UniConnection1.Close;
  unidm.UniConnection1.ProviderName:=ComboBox1.Text;
  if unidm.UniConnection1.ProviderName='SQL Server' then
  begin
    MSSQLDirect:=combobox2.text;
    if MSSQLDirect='直连' then
      unidm.UniConnection1.SpecificOptions.Add('SQL Server.Provider=prDirect') //直连mssql解决MSSQL2000中文乱码的问题
    else
      unidm.UniConnection1.SpecificOptions.Add('SQL Server.Provider=prAuto');
  end;
  unidm.UniConnection1.Username:= Edit3.text;
  unidm.UniConnection1.Password := Edit4.text;
  unidm.UniConnection1.Server := Edit1.text;
  unidm.UniConnection1.Database :=Edit5.text;
  unidm.UniConnection1.Port := DataPort;
  unidm.UniConnection1.Open;
}
//QFServer.Listen;
end;

procedure TServerMainFrm.Button3Click(Sender: TObject);
begin
  {$ifdef windows}
  setAutoRun(true);
  Button3.Enabled:=false;
  Button4.Enabled:=true;
  {$endif}
end;

procedure TServerMainFrm.Button4Click(Sender: TObject);
begin
  {$ifdef windows}
  setAutoRun(false);
  Button3.Enabled:=true;
  Button4.Enabled:=false;
  {$endif}
end;

end.

