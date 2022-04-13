{------------------------------------------------------------------------------}
{ 单元名称: Assist.pas                                                         }
{                                                                              }
{ 单元作者: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ 创建日期: 2005-01-03 20:30:00                                                }
{                                                                              }
{ 功能介绍:                                                                    }
{                                                                              }
{   常用函数定义                                                               }
{                                                                              }
{ 使用说明:                                                                    }
{                                                                              }
{ 更新历史:                                                                    }
{                                                                              }
{ 尚存问题:                                                                    }
{------------------------------------------------------------------------------}

unit Assist;

interface

  // 返回指针增量后的指针
  function IncPointer(const P: Pointer; IncSize: Integer): Pointer;
  // 返回指针间量后的指针
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
