class Group<Context>{
  var name:String;
  public function new(name:String){
    this.name = name;
  }

  var cases:Array<Case<Context>> = [];

  var context:Context;

  function prepareContext():Context{
    return null;
  }

  public function add(c){
    cases.push(c);
    return this;
  }

  public function run():Results{
    Test.write('  Group "$name": ');
    context = prepareContext();
    var res = new Results();

    var fails = [];
    for(c in cases){
      var good = c.run(context);
      Test.write(good ? '+' : '-');
      res.done(good);
      if(!good) fails.push(c);
    }

    Test.write(' ${res.passed}/${res.total}\n');

    for(fail in fails){
      Test.write(fail.logs.toString());
    }

    return res;
  }
}
