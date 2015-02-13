class Suite{
  var name:String;
  public function new(name){
    this.name = name;
  }

  var groups:Array<Group<Dynamic>> = [];
  public function add<CT>(g:Group<CT>){
    groups.push(g);
    return this;
  }

  public function run():Results{
    Test.write('Suite "$name"\n');

    var res = new Results();

    for(g in groups){
      var groupRes:Results = g.run();
      res.add(groupRes);
    }

    Test.write('== ${res.passed}/${res.total}\n');
    
    return res;
  }

}
