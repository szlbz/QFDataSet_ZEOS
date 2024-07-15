{ *
  * Twitter_Snowflake https://github.com/twitter-archive/snowflake
  * SnowFlake的结构如下(每部分用-分开):
  * 0 - 0000000000 0000000000 0000000000 0000000000 0 - 00000 - 00000 - 000000000000
  * 1位标识，由于long基本类型在Java中是带符号的，最高位是符号位，正数是0，负数是1，所以id一般是正数，最高位是0
  * 41位时间截(毫秒级)，注意，41位时间截不是存储当前时间的时间截，而是存储时间截的差值（当前时间截 - 开始时间截)
  * 得到的值），这里的的开始时间截，一般是我们的id生成器开始使用的时间，由我们程序来指定的（如下下面程序IdWorker类的startTime属性）。41位的时间截，可以使用69年，年T = (1L << 41) / (1000L * 60 * 60 * 24 * 365) = 69
  * 10位的数据机器位，可以部署在1024个节点，包括5位datacenterId和5位workerId
  * 12位序列，毫秒内的计数，12位的计数顺序号支持每个节点每毫秒(同一机器，同一时间截)产生4096个ID序号
  * 加起来刚好64位，为一个Long型。
  * SnowFlake的优点是，整体上按照时间自增排序，并且整个分布式系统内不会产生ID碰撞(由数据中心ID和机器ID作区分)，并且效率较高，经测试，SnowFlake每秒能够产生26万ID左右。
  * }
unit QFRemoteDataSet.Snowflake;

interface

uses SysUtils, DateUtils;

type
  // https://blog.csdn.net/yangding_/article/details/52768906
  // https://juejin.im/post/5a7f9176f265da4e721c73a8
  TSnowflakeIdWorker = class
  strict private
  const
    /// <summary> 机器id所占的位数 </summary>
    WorkerIdBits: Int64 = 5;
    /// <summary> 数据标识id所占的位数 </summary>
    DatacenterIdBits: Int64 = 5;
    /// <summary> 序列在id中占的位数 </summary>
    SequenceBits: Int64 = 12;
    /// <summary> 支持的最大机器id，</summary>
    MaxWorkerId: Int64 = 31;
    /// <summary> 支持的最大数据标识id</summary>
    MaxDatacenterId: Int64 = 31;
    /// <summary> 机器ID向左移12位 </summary>
    WorkerIdShift: Int64 = 12;
    /// <summary> 数据标识id向左移17位(12+5) </summary>
    DatacenterIdShift: Int64 = 17;
    /// <summary> 时间截向左移22位(5+5+12) </summary>
    TimestampLeftShift: Int64 = 22;
    /// <summary> 生成序列的掩码</summary>
    SequenceMask: Int64 = 4095;
  strict private
    twepoch: Int64; // = 1543051834000; // 1288834974657;
    /// <summary> 工作机器ID(0~31) </summary>
    FWorkerID: Int64;
    /// <summary> 数据中心ID(0~31) </summary>
    FDatacenterId: Int64;
    /// <summary> 毫秒内序列(0~4095) </summary>
    FSequence: Int64;
    /// <summary> 上次生成ID的时间截 </summary>
    FLastTimestamp: Int64;
    /// <summary>
    /// 阻塞到下一个毫秒，直到获得新的时间戳
    /// </summary>
    /// <param name="ATimestamp ">上次生成ID的时间截</param>
    /// <returns>当前时间戳 </returns>
    function NextMilliseconds(ATimestamp: Int64): Int64;
    /// <summary>
    /// 返回以毫秒为单位的当前时间
    /// </summary>
    function TimestampGen: Int64;
  private
  class var
    FLock: TObject;
    FInstance: TSnowflakeIdWorker;
    class function GetInstance: TSnowflakeIdWorker; static;
    class constructor Create;
    class destructor Destroy;
  protected
    function GetWorkerID: Int64;
    procedure SetWorkerID(const Value: Int64);
    function GetDatacenterId: Int64;
    procedure SetDatacenterId(const Value: Int64);

    constructor Create;
  public
    function NextId(): Int64;

    property WorkerID: Int64 read GetWorkerID write SetWorkerID;
    property DatacenterId: Int64 read GetDatacenterId write SetDatacenterId;
  end;

function IdGenerator: TSnowflakeIdWorker;

const
  GenerateIdRefused = 'Clock moved backwards. Refusing to generate id for %d milliseconds';

implementation

uses Math;

function IdGenerator: TSnowflakeIdWorker;
begin
  Result := TSnowflakeIdWorker.GetInstance;
end;
{ TSnowflakeIdWorker }

constructor TSnowflakeIdWorker.Create;
begin
  // 支持的最大机器id，结果是31
  { MaxWorkerId := -1 xor (-1 shl WorkerIdBits);
    // 支持的最大数据标识id，结果是31
    MaxDatacenterId := -1 xor (-1 shl DatacenterIdBits);
    // 机器ID向左移12位
    WorkerIdShift := SequenceBits;
    // 数据标识id向左移17位(12+5)
    DatacenterIdShift := SequenceBits + WorkerIdBits;
    // 时间截向左移22位(5+5+12)
    TimestampLeftShift := SequenceBits + WorkerIdBits + DatacenterIdBits;
    // 生成序列的掩码，这里为4095 (0b111111111111=0xfff=4095)
    SequenceMask := -1 xor (-1 shl SequenceBits);
  }
  FSequence := 0;
  FLastTimestamp := -1;
end;

class destructor TSnowflakeIdWorker.Destroy;
begin
  FreeAndNil(FInstance);
  FreeAndNil(FLock);
end;

class constructor TSnowflakeIdWorker.Create;
begin
  FInstance := nil;
  FLock := TObject.Create;
end;

function TSnowflakeIdWorker.GetDatacenterId: Int64;
begin
  Result := FDatacenterId;
end;

class function TSnowflakeIdWorker.GetInstance: TSnowflakeIdWorker;
begin
  try
    if FInstance = nil then
    begin
      FInstance := TSnowflakeIdWorker.Create;
      Randomize();
      FInstance.DatacenterId := RandomRange(1, 31);
      FInstance.WorkerID := RandomRange(1, 31);
      FInstance.twepoch := DateTimeToUnix(EncodeDate(2021, 1, 1));
    end;
    Result := FInstance;
  finally
  end;
end;

function TSnowflakeIdWorker.GetWorkerID: Int64;
begin
  Result := FWorkerID;
end;

function TSnowflakeIdWorker.NextId: Int64;
var
  Timestamp: Int64;
begin
  try
    Timestamp := TimestampGen();

    // 如果当前时间小于上一次ID生成的时间戳，说明系统时钟回退过这个时候应当抛出异常
    if (Timestamp < FLastTimestamp) then
      raise Exception.CreateFmt(GenerateIdRefused, [FLastTimestamp - Timestamp]);

    // 如果是同一时间生成的，则进行毫秒内序列
    if (FLastTimestamp = Timestamp) then
    begin
      FSequence := (FSequence + 1) and SequenceMask;
      // 毫秒内序列溢出
      if (FSequence = 0) then
        // 阻塞到下一个毫秒,获得新的时间戳
        Timestamp := NextMilliseconds(FLastTimestamp);
    end
    // 时间戳改变，毫秒内序列重置
    else
      FSequence := 0;

    // 上次生成ID的时间截
    FLastTimestamp := Timestamp;

    // 移位并通过或运算拼到一起组成64位的ID
    Result := ((Timestamp - twepoch) shl TimestampLeftShift)
      or (DatacenterId shl DatacenterIdShift)
      or (WorkerID shl WorkerIdShift)
      or FSequence;

  finally
  end;
end;

function TSnowflakeIdWorker.NextMilliseconds(ATimestamp: Int64): Int64;
var
  Timestamp: Int64;
begin
  Timestamp := TimestampGen();
  while (Timestamp <= ATimestamp) do
    Timestamp := TimestampGen();

  Result := Timestamp;
end;

procedure TSnowflakeIdWorker.SetDatacenterId(const Value: Int64);
begin
  if (Value > MaxDatacenterId) or (Value < 0) then
    raise Exception.CreateFmt('datacenter Id can not be greater than % d or less than 0 ', [MaxDatacenterId]);

  FDatacenterId := Value;
end;

procedure TSnowflakeIdWorker.SetWorkerID(const Value: Int64);
begin
  if (Value > MaxWorkerId) or (Value < 0) then
    raise Exception.CreateFmt('worker Id can not be greater than %d or less than 0', [MaxWorkerId]);

  FWorkerID := Value;
end;

function TSnowflakeIdWorker.TimestampGen: Int64;
begin
  Result := DateTimeToUnix(Now) * 1000;
end;

end.

