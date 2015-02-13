package urltpl;

class IntProcessor implements Processor<Int>{
  static var RE = ~/^-?[0-9]+$/m;
  public function new(){}
  public function isValid(str:String) return RE.match(str);
  public function fromString(str:String):Int return Std.parseInt(str);
  public function toString(v:Int) return ''+v;
}

class UIntProcessor implements Processor<Int>{
  static var RE = ~/^[0-9]+$/m;
  public function new(){}
  public function isValid(str:String) return RE.match(str);
  public function fromString(str:String):Int return Std.parseInt(str);
  public function toString(v:Int) return ''+v;
}

class ProcessorExtension{
  var processors:Map<String, Processor<Dynamic>>;
  public function new(){
    processors = [
      'int' => new IntProcessor(),
      'uint' => new UIntProcessor(),

    ];
  }

  public function register(name:String, proc:Processor<Dynamic>){
    processors[name] = proc;
  }

  public function get(name:String):Processor<Dynamic>{
    var p = processors[name];
    if(p == null) throw 'Processor "$name" was not registered';
    return p;
  }
}
