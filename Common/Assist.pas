{------------------------------------------------------------------------------}
{ ��Ԫ����: Assist.pas                                                         }
{                                                                              }
{ ��Ԫ����: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ ��������: 2005-01-03 20:30:00                                                }
{                                                                              }
{ ���ܽ���:                                                                    }
{                                                                              }
{   ���ú�������                                                               }
{                                                                              }
{ ʹ��˵��:                                                                    }
{                                                                              }
{ ������ʷ:                                                                    }
{                                                                              }
{ �д�����:                                                                    }
{------------------------------------------------------------------------------}

unit Assist;

interface

  // ����ָ���������ָ��
  function IncPointer(const P: Pointer; IncSize: Integer): Pointer;
  // ����ָ��������ָ��
  function DecPointer(const Pd: Pointer; IncSized: Integer): Pointer;



implementation

  function IncPointer(const P: Pointer; IncSize: Integer): Pointer;
  begin
    Result := Pointer(Integer(P) + IncSize);
  end;

    function DecPointer(const Pd: Pointer; IncSized: Integer): Pointer;
  begin
    Result := Pointer(Integer(Pd) - IncSized);
  end;

end.
