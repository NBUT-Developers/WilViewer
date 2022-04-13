{------------------------------------------------------------------------------}
{ 单元名称: ClassCallback.pas                                                  }
{                                                                              }
{ 单元作者: savetime (savetime2k@hotmail.com, http://savetime.delphibbs.com)   }
{ 创建日期: 2004-06-21 13:58:43                                                }
{                                                                              }
{ 功能介绍:                                                                    }
{ A generic solution of make class method to windows callback function         }
{                                                                              }
{ 使用说明:                                                                    }
{   1. Include this unit to your delphi project.                               }
{   2. Declare the class callback function same as the corresponding windows   }
{      callback function, notice that must be 'stdcall' function.              }
{   3. Declare an TCallbackInstance field in the class.                        }
{   4. Use MakeCallbackInstance function to make the FCallbackInstance.        }
{   5. Now you can use FCallbackInstance as the windows callback function      }
{                                                                              }
{ Discussion:                                                                  }
{   http://www.delphibbs.com/delphibbs/dispq.asp?lid=2672562                   }
{                                                                              }
{ 更新历史:                                                                    }
{                                                                              }
{ 尚存问题:                                                                    }
{                                                                              }
{------------------------------------------------------------------------------}

unit ClassCallback;

interface

  type TCallbackInstance = array [1..18] of Byte;
  procedure MakeCallbackInstance(var Instance: TCallbackInstance;
    ObjectAddr: Pointer; FunctionAddr: Pointer);

implementation

  {----------------------------}
  { CallbackCode DASM          }
  {----------------------------}
  {    MOV EAX, [ESP];         }
  {    PUSH EAX;               }
  {    MOV EAX, ObjectAddr;    }
  {    MOV [ESP+4], EAX;       }
  {    JMP FunctionAddr;       }
  {----------------------------}
  procedure MakeCallbackInstance(var Instance: TCallbackInstance;
    ObjectAddr: Pointer; FunctionAddr: Pointer);
  const CallbackCode: TCallbackInstance =
    ($8B,$04,$24,$50,$B8,$00,$00,$00,$00,$89,$44,$24,$04,$E9,$00,$00,$00,$00);
  begin
    Move(CallbackCode, Instance, SizeOf(TCallbackInstance));
    PInteger(@Instance[6])^ := Integer(ObjectAddr);
    PInteger(@Instance[15])^ := Integer(Integer(FunctionAddr) - Integer(@Instance) - 18);
  end;
  
end.

