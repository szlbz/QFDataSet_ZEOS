unit rtcDataSetChangeHelper;

interface

uses SysUtils, rtcInfo;

type
  TRtcDataSetChangesHelper = class helper for TRtcDataSetChanges
  public
    function GetActionSQL(const ATableName: RtcWideString;
      const AKeyFields: RtcWideString = ''): RtcWideString;
  end;

implementation

function TRtcDataSetChangesHelper.GetActionSQL(const ATableName
  : RtcWideString; const AKeyFields: RtcWideString = ''): RtcWideString;
var
  nFldOrder: integer;
  cFldName, s1, s2: RtcWideString;
  nrow, orow: TRtcDataRow;
  function SQLValue(const ARow: TRtcDataRow; AOrder: Integer): RtcWideString;
  var
    cName, cValue: RtcWideString;
    eType: TRtcFieldTypes;
  begin
    cName := ARow.FieldName[AOrder];
    eType := ARow.FieldType[cName];
    cValue := ARow.asText[cName];
    if eType in [ft_String, ft_Date, ft_Time, ft_DateTime,
      ft_FixedChar, ft_WideString, ft_OraTimeStamp] then
    begin
      Result := QuotedStr(cValue)
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
      if (cKeyFields = ',') or (Pos(cFldName + ',', cKeyFields) > 0) then
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

end.
