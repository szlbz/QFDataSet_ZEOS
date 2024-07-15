{ Implements VerifyCode

Copyright (c) 2021 Gustavo Carreno <guscarreno@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

}
unit QFRemoteDataSet.VerifyCode;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Classes
, SysUtils
, Extctrls
, LCLType
, LCLIntf
, Graphics
;

type
  TVerifyCode = class(TObject)
  type
    TCharCase = (Lower, Upper, Number);
    TCharCases = set of TCharCase;

  const
    cWidth = 300;
    cHeight = 75;
    cCharCaseAll = [Lower, Upper, Number];
    cCharCaseLetter = [Lower, Upper];

  private
    FVerifyCodeBitmap: TBitmap;
    FCharCase: TCharCases;
    FNoOfChars: integer;

    function GenerateVerifyCodeString: string;
    procedure DrawLetter(ch: Char; angle, nextPos: Integer);
    procedure DrawLines(aLineCount: Integer = 15);
    function GetImageVerifycode(LPNGImage:TImage): TBytes;
  protected
  public
    VerifyCodeString: string;
    constructor Create(ACharCase: integer=1;CharLen:Integer=10);
    destructor Destroy; override;

    procedure RefreshBitmap;
    function Validate(const AValue: string;
      ACaseSensetive: Boolean = True): Boolean;
    property Image: TBitmap read FVerifyCodeBitmap;
  published
  end;

implementation

uses
  GraphType,QFServerMainFrm
;

{ TVerifyCode }

function TVerifyCode.GenerateVerifyCodeString: string;
var
  validChar: String;
  i: Integer;
begin
  Result:= EmptyStr;
  validChar:= EmptyStr;
  if TCharCase.Number in FCharCase then
    validChar:= validChar + '123456789';

  if TCharCase.Lower in FCharCase then
    validChar:= validChar + 'abcdefghijklmnopqrstuvwxyz';

  if TCharCase.Upper in FCharCase then
    validChar:= validChar + 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';

  SetLength(Result, FNoOfChars);

  Randomize;
  for i:= 1 to FNoOfChars do
  begin
    Result[i]:= validChar[Random(Length(validChar)) +1];
  end;
end;

procedure TVerifyCode.DrawLetter(ch: Char; angle, nextPos: Integer);
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
  SelectObject(FVerifyCodeBitmap.Canvas.Handle, fontHandle);

  SetTextColor(FVerifyCodeBitmap.Canvas.Handle, rgb(0, 180, 0));
  SetBKmode(FVerifyCodeBitmap.Canvas.Handle, TRANSPARENT);

  SetTextColor(FVerifyCodeBitmap.Canvas.Handle, Random(MAXWORD));
  FVerifyCodeBitmap.Canvas.TextOut(nextPos, FVerifyCodeBitmap.Height div 3, ch);
  DeleteObject(fontHandle);
end;

procedure TVerifyCode.DrawLines(aLineCount: Integer);
var
  i: Integer;
begin
  for i:= 0 to aLineCount do
  begin
    FVerifyCodeBitmap.Canvas.Pen.Color:= Random(MAXWORD);
    FVerifyCodeBitmap.Canvas.MoveTo(Random(FVerifyCodeBitmap.Width), Random(FVerifyCodeBitmap.Height));
    FVerifyCodeBitmap.Canvas.LineTo(Random(FVerifyCodeBitmap.Width), Random(FVerifyCodeBitmap.Height));
  end;
end;

function TVerifyCode.GetImageVerifycode(LPNGImage:TImage): TBytes;
const
  IMAGE_HEIGHT      = 25;
  IMAGE_WIDTH       = 65;
  NOISE_POINT_COUNT = 50;
var
  I: Integer;
  LPoint: TPoint;
  //LPNGImage:TBitmap;// TPortableNetworkGraphic;
  LStream: TBytesStream;
  LOffsetX: Integer;
  Value:string;
begin
  //LPNGImage.Assign(ServerMainFrm.Image1);// .Images;
  //LPNGImage :=TPortableNetworkGraphic.Create;
  //LPNGImage.BeginUpdate();
  LPNGImage.Canvas.Lock;
  LPNGImage.Width:= cWidth;
  LPNGImage.Height:= cHeight;
  try
    with LPNGImage do
    begin
      Canvas.FillRect(Canvas.ClipRect);
      Randomize;
      LOffsetX := 0;
      Value := Format('%.4d', [Random(9999)]);
      VerifyCodeString:=Value;
      for I := 1 to Length(Value) do
      begin
        // 设置字体大小、颜色
        Canvas.Font.Name:='宋体';
        Canvas.Font.Size := Random(3) + 13;
        Canvas.Font.Color := RGB(Random(256) and $C0, Random(256) and $C0, Random(256) and $C0);
        // 设置字体样式

        // 设置文字间距
        LPoint.X := Random(1) + 4 + LOffsetX;
        LPoint.Y := Random(1) + 1;
        Canvas.TextOut(LPoint.X, LPoint.Y, Value[I]);
        LOffsetX := LPoint.X + Canvas.TextWidth(Value[I]);
      end;

      // 添加噪点
      for I := 0 to NOISE_POINT_COUNT - 1 do
        Canvas.Pixels[Random(IMAGE_WIDTH), Random(IMAGE_HEIGHT)] := Random($6FFFFFFF);

      // 画边框
      Canvas.MoveTo(0, 0);
      Canvas.LineTo(0, IMAGE_HEIGHT);

      Canvas.MoveTo(0, 0);
      Canvas.LineTo(IMAGE_WIDTH, 0);

      Canvas.MoveTo(IMAGE_WIDTH - 1, 0);
      Canvas.LineTo(IMAGE_WIDTH - 1, IMAGE_HEIGHT);

      Canvas.MoveTo(IMAGE_WIDTH - 1, IMAGE_HEIGHT - 1);
      Canvas.LineTo(0, IMAGE_HEIGHT - 1);

      LPNGImage.Canvas.Unlock;
      //LPNGImage.EndUpdate();

      //LStream := TBytesStream.Create();
      //SaveToStream(LStream);
      //Result := LStream.Bytes;
      //SetLength(Result, LStream.Size);
    end;
  finally
    //FreeAndNil(LStream);
    //FreeAndNil(LPNGImage);
  end;
end;

procedure TVerifyCode.RefreshBitmap;
var
  i: Integer;
begin
  Randomize;

  //VerifyCodeString:=Format('%.4d', [Random(9999)]);

  VerifyCodeString:= GenerateVerifyCodeString;
  //GetImageVerifycode(ServerMainFrm.Image1);
  //FVerifyCodeBitmap:=TImage.Create(nil);//  TBitmap.Create;
  //FVerifyCodeBitmap.BeginUpdate();
  //FVerifyCodeBitmap.Canvas.Lock;
  //FVerifyCodeBitmap.PixelFormat:= pf24bit;
  //FVerifyCodeBitmap.Width:= cWidth;
  //FVerifyCodeBitmap.Height:= cHeight;
  //FVerifyCodeBitmap.Canvas.Brush.Color:= clWhite;
  //FVerifyCodeBitmap.Canvas.FillRect(0,0,cWidth,cHeight);
  //for i:= 1 to Length(VerifyCodeString) do
  //  DrawLetter(VerifyCodeString[i], Random(600) + 1, 25 * i - 15);
  //DrawLines;
  //FVerifyCodeBitmap.Canvas.Unlock;
  //FVerifyCodeBitmap.EndUpdate();
end;

function TVerifyCode.Validate(const AValue: string;
  ACaseSensetive: Boolean): Boolean;
begin
  if ACaseSensetive then
    Result:= AValue = VerifyCodeString
  else
    Result:= SameText(AValue, VerifyCodeString);
end;

constructor TVerifyCode.Create(ACharCase,CharLen:Integer);
begin
  if ACharCase=1 then FCharCase := [Upper, Number]
  else
  if ACharCase=2 then FCharCase := [Upper]
  else
  if ACharCase=3 then FCharCase := [Number]
  else FCharCase := [Upper, Number];
  if charlen<1 then CharLen:=10;
  //FVerifyCodeBitmap:= ServerMainFrm.Image1;
  FNoOfChars:=CharLen;
  Randomize;
  RefreshBitmap;

end;


destructor TVerifyCode.Destroy;
begin
  FreeAndNil(FVerifyCodeBitmap);
  inherited Destroy;
end;

end.

