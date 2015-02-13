class Case<Context>{
  var name:String;
  public function new(name:String){
    this.name = name;
  }

  public function run(context:Context):Bool{
    throw 'not implemented';
  }

  public var logs:Null<StringBuf>;
  inline function log(str:String){
    if(logs == null) logs = new StringBuf();
    logs.add(str);
    logs.add('\n');
  }
}

