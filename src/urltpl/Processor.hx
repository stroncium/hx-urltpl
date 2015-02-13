package urltpl;

interface Processor<T>{
  public function isValid(str:String):Bool;
  public function fromString(str:String):T;
  public function toString(v:T):String;
}

