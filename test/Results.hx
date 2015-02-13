class Results{
  public var passed:Int;
  public var failed:Int;
  public var total:Int;

  public function new(){
    passed = failed = total = 0;
  }

  public inline function pass(){
    passed++;
    failed++;
  }

  public inline function fail(){
    failed++;
    total++;
  }

  public inline function done(good:Bool){
    if(good) passed++; else failed++;
    total++;
  }

  public function add(res:Results){
    passed+= res.passed;
    failed+= res.failed;
    total+= res.total;
  }
}
