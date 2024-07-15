unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, Forms, Controls, Graphics, Dialogs, StdCtrls, DBGrids,
  ExtCtrls, DBCtrls, ExtDlgs, ComCtrls, QFJsonDataSet, ZConnection, frxClass,
  frxDesgn, inifiles;

type
  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    Button13: TButton;
    Button14: TButton;
    Button15: TButton;
    Button16: TButton;
    Button17: TButton;
    Button18: TButton;
    Button19: TButton;
    Button2: TButton;
    Button20: TButton;
    Button21: TButton;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    Button9: TButton;
    ComboBox1: TComboBox;
    DataSource1: TDataSource;
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    Edit5: TEdit;
    Edit6: TEdit;
    Edit7: TEdit;
    frReport1: TfrxReport;
    frxDesigner1: TfrxDesigner;
    frxUserDataSet1: TfrxUserDataSet;
    GroupBox1: TGroupBox;
    GroupBox2: TGroupBox;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Memo1: TMemo;
    PageControl1: TPageControl;
    Panel1: TPanel;
    SavePictureDialog1: TSavePictureDialog;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    procedure Button10Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure Button14Click(Sender: TObject);
    procedure Button15Click(Sender: TObject);
    procedure Button16Click(Sender: TObject);
    procedure Button17Click(Sender: TObject);
    procedure Button18Click(Sender: TObject);
    procedure Button19Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button20Click(Sender: TObject);
    procedure Button21Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure ComboBox1Change(Sender: TObject);
    procedure DBGrid1CellClick(Column: TColumn);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure frxUserDataSet1CheckEOF(Sender: TObject; var Eof: Boolean);
    procedure frxUserDataSet1First(Sender: TObject);
    procedure frxUserDataSet1GetValue(const VarName: String; var Value: Variant
      );
    procedure frxUserDataSet1Next(Sender: TObject);
    procedure frxUserDataSet1Prior(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
  private
  public
    jc:TQFJsonConnection;
    ja:TQFJsonTable;
    jq:TQFJsonQuery;
    jq2:TQFJsonQuery;
    FTimeUsed: DWORD;
    md:integer;
    SORT: string;
    Maxrecno: integer;
    recno: integer;
  end;

type
  k = array [1 .. 8] of string;

var
  Form1: TForm1;
  temp: array of k;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.Button1Click(Sender: TObject);
begin
  md:=2;
  Image1.Picture.Clear;
  //if assigned(jc) then
  begin
    if not assigned(jq) then
     jq:=TQFJSONQuery.Create(nil)
    else
    begin
      if jq.State in [dsEdit, dsInsert] then jq.Post;
    end;
    jq.Connection:=jc;
    DataSource1.DataSet:=jq;
//    jq.TableName:='power';
    jq.SQL:=edit1.Text;
    FTimeUsed := GetTickCount;
    memo1.Lines.Add(jq.open);
    Memo1.Lines.Add(IntToStr(GetTickCount - FTimeUsed) + '毫秒');
    //Label7.Caption:= jq.RecordCount.ToString;
  end;
end;

procedure TForm1.Button20Click(Sender: TObject);
begin
  if assigned(jq2) then
  begin
    jq2.Connection:=jc;
    jq2.LastPage;
  end;
end;

procedure TForm1.Button21Click(Sender: TObject);
begin
  if md=1 then
  begin
    if assigned(ja) then
    begin
      ja.FindNext;
    end;
  end;
  if md=2 then
  begin
    if assigned(jq) then
    begin
      jq.FindNext;
    end;
  end;

end;

procedure TForm1.Button11Click(Sender: TObject);
begin
  Image1.Picture.Clear;
  if assigned(ja) then
  begin
    ja.Connection:=jc;
   FTimeUsed := GetTickCount;
   memo1.Lines.Add(ja.FirstPage);
   Memo1.Lines.Add(IntToStr(GetTickCount - FTimeUsed) + '毫秒');
  end;
end;

procedure TForm1.Button12Click(Sender: TObject);
begin
  if assigned(ja) then
  begin
  if ja.Active then
    begin
      ja.Locate('报告编号', edit6.text, []);
    end;
  end;
end;

procedure TForm1.Button13Click(Sender: TObject);
var s:String;
  i:integer;
begin
  if md=1 then
  begin
    if assigned(ja) then
    begin
      ja.Filtered:=false;
      ja.Filter:=edit7.text;
//      ja.Filtered:=true;
      //Label7.Caption:= ja.RecordCount.ToString;
      ja.FindFirst;
    end;
  end;
  if md=2 then
  begin
    if assigned(jq) then
    begin
      jq.Filtered:=false;
      jq.Filter:=edit7.text;
      //jq.Filtered:=true;
      i:=jq.RecordCount;
      //Label7.Caption:= i.ToString;
      jq.FindFirst;
    end;
  end;
end;

procedure TForm1.Button14Click(Sender: TObject);
begin
  if assigned(jq) and (jq.Active) then
  begin
    if jq.FindField('电子签名')<>nil then
    begin
      if jq.FindField('电子签名').IsBlob then
      begin
        SavePictureDialog1.InitialDir := '';
        if SavePictureDialog1.Execute then
        begin
          Image1.Picture.LoadFromFile(SavePictureDialog1.FileName);
          jq.Edit;
          (jq.FieldByName('电子签名') as TBlobField).LoadFromFile(SavePictureDialog1.FileName);
          jq.Post;
        end;
      end;
    end;
  end;
end;

procedure TForm1.Button15Click(Sender: TObject);
var
  i, j: integer;
begin
  i := DBGrid2.SelectedRows.Count;
  if i <> 0 then
  begin
    DBGrid2.Visible := false;
    Maxrecno := i;
    j := 0;
    setlength(temp, i);
    jq2.First;
    jq2.DisableControls;
    while not jq2.Eof do
    begin
      if DBGrid2.SelectedRows.CurrentRowSelected then
      begin
        temp[j, 1] := jq2.FieldByName('编号').asstring;
        temp[j, 2] := jq2.FieldByName('见证人姓名').asstring;
        temp[j, 3] := jq2.FieldByName('监理公司').asstring;
        temp[j, 4] := jq2.FieldByName('工程名称').asstring;
        temp[j, 5] := jq2.FieldByName('竣工日期').asstring;
        temp[j, 6] := jq2.FieldByName('办理日期').asstring;
        temp[j, 7] := jq2.FieldByName('监督编号').asstring;
        inc(j);
      end;
      jq2.Next;
    end;
    frReport1.ShowReport;
    DBGrid2.Visible := true;
    jq2.EnableControls;
    jq2.First;
  end;
end;

procedure TForm1.Button16Click(Sender: TObject);
begin
  frReport1.DesignReport;
end;

procedure TForm1.Button17Click(Sender: TObject);
begin
  if assigned(jq2) then
  begin
    jq2.Connection:=jc;
    jq2.FirstPage;
  end;
end;

procedure TForm1.Button18Click(Sender: TObject);
begin
  if assigned(jq2) then
  begin
    jq2.Connection:=jc;
    jq2.PriorPage;
  end;
end;

procedure TForm1.Button19Click(Sender: TObject);
begin
  if assigned(jq2) then
  begin
    jq2.Connection:=jc;
    jq2.NextPage;
  end;
end;

procedure TForm1.Button10Click(Sender: TObject);
begin
  Image1.Picture.Clear;
  if assigned(ja) then
  begin
    ja.Connection:=jc;
    FTimeUsed := GetTickCount;
    memo1.Lines.Add(ja.LastPage);
    Memo1.Lines.Add(IntToStr(GetTickCount - FTimeUsed) + '毫秒');
  end
end;

procedure TForm1.Button2Click(Sender: TObject);
begin
   Image1.Picture.Clear;
   if assigned(ja) then
   begin
     ja.Connection:=jc;
     FTimeUsed := GetTickCount;
     memo1.Lines.Add(ja.PriorPage);
     Memo1.Lines.Add(IntToStr(GetTickCount - FTimeUsed) + '毫秒');
   end;
end;

procedure TForm1.Button3Click(Sender: TObject);
begin
   FTimeUsed := GetTickCount;
   memo1.Lines.Add(jc.GeTID);
   Memo1.Lines.Add(IntToStr(GetTickCount - FTimeUsed) + '毫秒');
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  FTimeUsed := GetTickCount;
  memo1.Lines.Add(jc.DateTime);
  Memo1.Lines.Add(IntToStr(GetTickCount - FTimeUsed) + '毫秒');
end;

procedure TForm1.Button5Click(Sender: TObject);
begin
  FTimeUsed := GetTickCount;
  memo1.Lines.Add('校验码:'+jc.VerifyCode(image1));
  Memo1.Lines.Add(IntToStr(GetTickCount - FTimeUsed) + '毫秒');
end;

procedure TForm1.Button6Click(Sender: TObject);
var MYIniFile:Tinifile;
begin
  MYIniFile := TIniFile.Create(Extractfilepath(Paramstr(0)) + 'config.ini');
  MyIniFile.writestring('系统参数', '服务端IP', edit4.text);
  MyIniFile.writestring('系统参数', '端口', edit5.text);
  MyIniFile.writestring('系统参数', '登录名称', edit2.text);
  MyIniFile.writestring('系统参数', '登录密码', edit3.text);
  MYIniFile.Free;
  if not assigned(jc) then
   jc:=TQFJsonConnection.Create(nil);
  jc.ServerAddr:=edit4.text;
  jc.ServerPort:=edit5.text;
  jc.UserName:=edit2.text;
  jc.PassWord:=edit3.text;
  FTimeUsed := GetTickCount;
  memo1.Lines.Add(jc.Connect);
  Memo1.Lines.Add(IntToStr(GetTickCount - FTimeUsed) + '毫秒');
  if jc.ConnectionList.Count>0 then
  begin
    combobox1.Items.Assign(jc.ConnectionList);
    combobox1.ItemIndex:=0;
  end;
  //memo1.Lines.Add(login(edit2.text,edit3.text,edit4.text,edit5.text,combobox1));
end;

procedure TForm1.Button7Click(Sender: TObject);
begin
  memo1.Lines.Add(closesession(jc));
end;

procedure TForm1.Button8Click(Sender: TObject);
begin
   Image1.Picture.Clear;
   md:=1;
   if not assigned(ja) then
   ja:=TQFJsonTable.Create(nil);
   ja.Connection:=jc;
   ja.TableName:='混凝土试块';
   ja.KeyFields:='报告编号';
   ja.PageSize:=100;
   DataSource1.DataSet:=ja;
   FTimeUsed := GetTickCount;
   Memo1.Lines.Add(ja.open);
   Memo1.Lines.Add(IntToStr(GetTickCount - FTimeUsed) + '毫秒');
end;

procedure TForm1.Button9Click(Sender: TObject);
begin
   Image1.Picture.Clear;
   if assigned(ja) then
   begin
     ja.Connection:=jc;
     FTimeUsed := GetTickCount;
     memo1.Lines.Add(ja.NextPage);
     Memo1.Lines.Add(IntToStr(GetTickCount - FTimeUsed) + '毫秒');
   end;
end;

procedure TForm1.ComboBox1Change(Sender: TObject);
begin
  jc.ConnectionDefName:=combobox1.Text;
end;

procedure TForm1.DBGrid1CellClick(Column: TColumn);
var
  S : TMemoryStream;
begin
  if md=2 Then
  begin
    if assigned(jq) and (jq.Active) then
    begin
      if jq.FindField('电子签名')<>nil then
      begin
        if jq.FindField('电子签名').IsBlob then
        begin
          if not jq.FieldByName('电子签名').IsNull Then
          begin
            S:=TMemoryStream.Create;
            S.Clear;
            TBlobField(jq.FieldByName('电子签名')).SaveToStream(S);
            s.Position:=0;
            Image1.Picture.LoadFromStream(s);
            s.Free;
          end
          else Image1.Picture.Clear;
        end;
        end;
    end;
  end;
end;

procedure TForm1.FormClose(Sender: TObject; var CloseAction: TCloseAction);
var MYIniFile:Tinifile;
begin
  MYIniFile := TIniFile.Create(Extractfilepath(Paramstr(0)) + 'config.ini');
  MyIniFile.writestring('系统参数', '服务端IP', edit4.text);
  MyIniFile.writestring('系统参数', '端口', edit5.text);
  MyIniFile.writestring('系统参数', '登录名称', edit2.text);
  MyIniFile.writestring('系统参数', '登录密码', edit3.text);
  MYIniFile.Free;
  //memo1.Lines.Add(Closesession);
  if assigned(ja) then
    ja.Free;;
  if assigned(jq) then
    jq.Free;;
  if assigned(jq2) then
    jq2.Free;;
  if assigned(jc) then
    jc.Free;;
end;

procedure TForm1.FormCreate(Sender: TObject);
var MYIniFile:Tinifile;
begin
  md:=0;
  MYIniFile := TIniFile.Create(Extractfilepath(Paramstr(0)) + 'config.ini');
  edit4.text := MyIniFile.readstring('系统参数', '服务端IP', '127.0.0.1');
  edit5.text := MyIniFile.readstring('系统参数', '端口', '8112');
  edit2.text := MyIniFile.readstring('系统参数', '登录名称', 'qf');
  edit3.text := MyIniFile.readstring('系统参数', '登录密码', 'qfadmin');
  MYIniFile.Free;
end;

procedure TForm1.frxUserDataSet1CheckEOF(Sender: TObject; var Eof: Boolean);
begin
  if recno >= Maxrecno then
     Eof := true
   else
     Eof := false;
end;

procedure TForm1.frxUserDataset1First(Sender: TObject);
begin
  recno := 0;
end;

procedure TForm1.frxUserDataset1Next(Sender: TObject);
begin
  inc(recno);
end;

procedure TForm1.frxUserDataset1Prior(Sender: TObject);
begin
  dec(recno);
end;

procedure TForm1.frxUserDataSet1GetValue(const VarName: String;
  var Value: Variant);
begin
  if VarName.ToUpper = 'A1' then Value := temp[recno, 1];
  if VarName.ToUpper = 'A2' then Value := temp[recno, 2];
  if VarName.ToUpper = 'A3' then Value := temp[recno, 3];
  if VarName.ToUpper = 'A4' then Value := temp[recno, 4];
  if VarName.ToUpper = 'A5' then Value := temp[recno, 5];
  if VarName.ToUpper = 'A6' then Value := temp[recno, 6];
  if VarName.ToUpper = 'A7' then Value := temp[recno, 7];
end;


procedure TForm1.PageControl1Change(Sender: TObject);
begin
  if PageControl1.ActivePageIndex=1 then
  begin
    if not assigned(jq2) then
     jq2:=TQFJsonQuery.Create(nil);
    jq2.Connection:=jc;
    jq2.SQL:='select * from 见证资料';
    jq2.Open;
    DataSource1.DataSet:=jq2;
    DBGrid2.DataSource:= DataSource1;
    frReport1.LoadFromFile(extractfilepath(paramstr(0)) + '见证资料.fr3');
    Maxrecno:=-1;
  end
  else
  DataSource1.DataSet:=nil;
end;

end.

