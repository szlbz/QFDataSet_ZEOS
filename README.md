# QFRemoteDataSet三层控件使用说明

转到Lazarus后发现缺少delphi熟悉的三层控件，尝试过国产商业及网上的开源三层控件，但存在或多或少的问题，始终找不到满意的三层控件（特别是linux aarch64下），决定开发一个简单实用的lazarus三层控件（参考网上的相关代码）。这个三层控件功能相对简单，只适合lazarus使用，但非常实用，编写的应用软件能在windows和国产信创操作系统(linux)及CPU运行。   
2023.01.21 QQ：315175176 秋风  

一、QFRemoteDataSet三层控件使用说明目录结构：  
QFRemoteDataSet  
|----Client_demo  //客户端Demo  
|----Components   //QFRemoteDataSet客户端控件  
|----server       //服务端  
|----RealThinClientSDK_v952  

二、需要安装的支持控件：  
1、RealThinClient SDK-->RealThinClientSDK_v952\Lib\rtcsdk_fpc.lpk  
2、unidac-->\UniDAC\Source\Lazarus1\dclunidac10.lpk,pgprovider10.lpk,myprovider10.lpk,msprovider10.lpk  
3、QFRemoteDataSet-->Components\QFRemoteDataSetPack.lpk  

三、QFRemoteDataSet  
QFRemoteDataSetPack封装了TQFRemoteConnection、TQFRemoteTable、TQFRemoteQuery和TQFRemoteStoredProc等4个控件：  
1.QFRemoteConnection连接控件  
   QFRemoteConnection.Compression:boolean;//=true传输时压缩数据,=false传输时不压缩数据  
   QFRemoteConnection.SecureKey//连接密钥，要与服务端的连接密钥匹配  
   QFRemoteConnection.Server_ip//服务端IP  
   QFRemoteConnection.Server_port//服务端端口号，如在linux运行，建议要>1024  
   QFRemoteConnection.DateTime:TDateTime;//取服务端的时间  
   QFRemoteConnection.GeneratorID:string;//取服务端用雪花算法生成的唯一ID  
   QFRemoteConnection.FileUpload(const filename:string):Boolean;//上传文件到服务端的upload文件夹  
   QFRemoteConnection.FileDownload(filename, path: string):Boolean;//从服务端download文件夹下载指定文件  

2.TQFRemoteTable支持分页功能。  
   QFRemoteTable.KeyFields//主键  
   QFRemoteTable.TableName//表名  
   QFRemoteTable.DataPagination;//=true数据分页  
   QFRemoteTable.open;//DataPagination=true时，支持分页功能  
   QFRemoteTable.Locate(const AKeyFields: String; const AKeyValues: Variant; AOptions: TLocateOptions): Boolean;  
   QFRemoteTable.ApplyUpdates;//将数据提交到服务端的数据库  
   QFRemoteTable.AutoUpdaeData:Boolean;//=true时，自动保存变更的数据，请不要使用OnDataChange,否则自动保存将失效  
   QFRemoteTable.PageSize//数据页的大小  
   QFRemoteTable.FirstPage;  
   QFRemoteTable.PriorPage;  
   QFRemoteTable.NextPage;  
   QFRemoteTable.LastPage;  

3.TQFRemoteQuery  
   TQFRemoteQuery.KeyFields//主键  
   TQFRemoteQuery.SQL//SQL语句  
   TQFRemoteQuery.open  
   TQFRemoteQuery.ExecSQL  
   TQFRemoteQuery.ApplyUpdates//将数据提交到服务端的数据库  
   TQFRemoteQuery.AutoUpdaeData:Boolean;//=true时，自动保存变更的数据，请不要使用OnDataChange,否则自动保存将失效  
4.TQFRemoteStoredProc  
   TQFRemoteStoredProc.StoredProcName  
   TQFRemoteStoredProc.Param  
   TQFRemoteStoredProc.open  
   
四、数据库选择：  
QFRemoteDataSet三层控件已适配MSSQL2000、MySQL和PostgreSQL数据库，其中MSSQL为支持分页，表需添加ID字段。如果服务端在Linux运行，建议使用MySQL和PostgreSQL。  

五、服务端：  
服务端需要先安装RealThinClient SDK和UNIDAC控件，打开server\server.lpr编译就可以。  

六、客户端Demo：  
打开Client_json\Client.lpr。  
