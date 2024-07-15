{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit QFDataSetPack;

{$warn 5023 off : no warning about unused units}
interface

uses
  QFDataSet, QFJsonDataSet, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('QFDataSet', @QFDataSet.Register);
  RegisterUnit('QFJsonDataSet', @QFJsonDataSet.Register);
end;

initialization
  RegisterPackage('QFDataSetPack', @Register);
end.
