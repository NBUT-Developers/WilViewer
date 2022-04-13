unit DebugUnit;

interface

  procedure DebugOut(FileName: string; Text: string);

implementation

  procedure DebugOut(FileName: string; Text: string);
  var
    F: TextFile;
  begin
    FileMode := 2;
    AssignFile(F, FileName);
    Rewrite(F);
    try
      WriteLn(F, Text);
    finally
      CloseFile(F);
    end;
  end;

end.
