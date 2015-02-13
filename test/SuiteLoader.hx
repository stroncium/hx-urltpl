private typedef GroupDef<D> = {
  name:String,
  ?type:String,
  cases:Array<D>,
}

private typedef SuiteDef = {
  name:String,
  ?type:String,
  groups:Array<GroupDef<Dynamic>>,
}

class SuiteLoader{
  public var defType:String = '';
  public function new(){
  }

  var parsers:Map<String, Dynamic->Dynamic> = new Map();

  public function addType<D,G:Group<Dynamic>>(type:String, parser:D->G){
    parsers[type] = parser;
  }

  public function load(sd:SuiteDef){
    var suite = new Suite(sd.name);
    var suiteType = sd.type == null ? defType : sd.type;
    for(gd in sd.groups){
      var groupType = gd.type == null ? suiteType : gd.type;
      var parser = parsers[groupType];
      if(parser == null) throw 'No test parser for type "$groupType"';
      var g = parser(gd);
      suite.add(g);
    }
    return suite;
  }
}
