import yaml.Yaml;
private typedef Vars = haxe.DynamicAccess<Dynamic>;

class RouteTestGroup extends Group<UrlTplRouter<String>>{
  var router:UrlTplRouter<String>;
  public function new(name, routes:Array<String>){
    super(name);
    var router = router = new UrlTplRouter();
    for(route in routes) router.addRoute(route, route);
  }

  override function prepareContext() return router;
}

class RouteTest extends Case<UrlTplRouter<String>>{
  var str:String;
  var tgt:String;
  var caps:haxe.DynamicAccess<Dynamic>;
  public function new(name, str, tgt, caps:Dynamic){
    super(name);
    this.str = str;
    this.tgt = tgt;
    this.caps = caps;
  }

  override function run(router:UrlTplRouter<String>){
    var res = null, err = null;
    try{
      res = router.route(str);
    }
    catch(e:Dynamic){
      err = e;
    }
    var good = err == null && res != null;
    if(good) good = res.tgt == tgt;
    if(good){
      var expKeys = caps.keys();
      var gotKeys = [for(k in res.caps.keys()) k];

      good = gotKeys.length == expKeys.length;
      if(good){
        for(k in expKeys){
          if(caps[k] != res.caps[k]){
            good = false;
            break;
          }
        }
      }
    }
    if(!good){
      log('    "$str" =>');
      log('      $tgt\t${haxe.Json.stringify(caps)}');
      if(err == null && res != null){
        log('      ${res.tgt}\t${haxe.Json.stringify(res.caps)}');
      }
      else{
        log('      error $err');
      }
    }
    return good;
  }
}

class RenderTestGroup extends Group<Vars>{
  var vars:Vars;
  public function new(name, vars){
    super(name);
    this.vars = vars;
  }

  override function prepareContext() return vars;
}


class RenderTest extends Case<Vars>{
  var tpl:String;
  var exp:Null<Array<String>>;
  public function new(name, tpl, exp){
    super(name);
    this.tpl = tpl;
    this.exp = exp;
  }

  override function run(vars:Vars){
    var out = null, err = null;

    try{
      out = UrlTpl.run(tpl, vars);
    }
    catch(e:Dynamic){
      err = e;
    }

    var good = if(exp == null) err != null; else err == null && exp.indexOf(out) != -1;
    if(!good){
      var expPrint;
      if(exp == null) expPrint = 'error';
      else expPrint = '"'+exp.join('" | "')+'"';
      if(err == null){
        log('    "$tpl" =>');
        log('      $expPrint');
        log('      "$out"');
      }
      else{
        log('    "$tpl" =>');
        log('      $expPrint');
        log('      error ${Std.string(err)}');
      }
    }

    return good;
  }
}

class Test{
  static function readFile(path:String){
    #if js
      return (untyped __js__('require'))('fs').readFileSync(path, 'utf8');
    #else
      #error 'Not implemented for platform'
    #end
  }

  static inline var TESTS_DIR = 'test';
  static function getSuiteDef(name:String){
    var file = readFile('$TESTS_DIR/$name.yaml');
    var sd = Yaml.parse(file, new yaml.Parser.ParserOptions().useObjects());
    return sd;
  }

  static function parseParseRenderGroup(gd:{
    name:String, 
    vars:haxe.DynamicAccess<Dynamic>,
    cases:Array<Array<Dynamic>>,
  }){
    var g = new RenderTestGroup(gd.name, gd.vars);
    for(cd in gd.cases) g.add(new RenderTest(cd[0], cd[0], cd[1]));
    return g;
  }

  static function parseRouteGroup(gd:{
    name:String, 
    routes:Array<String>,
    cases:Array<Array<Dynamic>>,
  }){
    var routes = gd.routes == null ? [] : gd.routes.slice(0);
    var routeMap = new Map();
    for(route in routes) routeMap[route] = true;

    var cases = [];
    for(cd in gd.cases){
      var route = cd[1];
      if(routeMap[route] != true){
        routeMap[route] = true;
        routes.push(route);
      }
      cases.push(new RouteTest('${cd[0]} to ${cd[1]}', cd[0], cd[1], cd[2]));
    }
    var g = new RouteTestGroup(gd.name, routes);
    for(c in cases) g.add(c);
    return g;
  }

  static var loader:SuiteLoader;
  public static function main(){
    loader = new SuiteLoader();
    loader.addType('parse/render', parseParseRenderGroup);
    loader.addType('route', parseRouteGroup);
    loader.defType = 'parse/render';
    var suiteNames = [
      'base',
      'negative',
      'routing',
      'belbeit-client-routing',
    ];

    var suites = [for(suiteName in suiteNames) loader.load(getSuiteDef(suiteName))];

    var all = new Results();
    
    for(suite in suites) all.add(suite.run());

    write('\n  TOTAL: ${all.total}\n  PASSED: ${all.passed}\n  FAILED: ${all.failed}\n\n');

    exit(all.failed == 0 ? 0 : 1);
  }

  public static function write(str:String){
    #if js
      (untyped __js__('process')).stdout.write(str, 'utf8');
    #end
  }

  static function exit(status:Int){
    #if js
      (untyped __js__('process')).exit(status);
    #end
  }
}
