package urltpl;

using StringTools;

class BasicUrlTplRouter<Target>{
  var pairs:Array<{tpl:UrlTpl, tgt:Target}> = [];
  public function new(){
  }


  public function addRoute(tplSrc:String, tgt:Target){
    var tpl = new UrlTpl(tplSrc);
    pairs.push({tpl:tpl, tgt:tgt});
  }

  public function route(str:String):{caps:Map<String, String>, tgt:Target}{
    for(pair in pairs){
      var caps = new Map<String, String>();
      if(testTpl(pair.tpl, str, caps)){
        return {
          caps:caps,
          tgt:pair.tgt,
        };
      }
    }
    return null;
  }

  static function testTpl(tpl:UrlTpl, str:String, cap:Map<String,String>){
    var pos = 0;
    for(expr in tpl.exprs){
      switch(expr){
        case Lit(pat):
          if(!substrEq(str, pos, pat)) return false;
          pos+= pat.length;
        case Simple(binds):
          var first = true;
          for(bind in binds){
            var part;
            if(first){
              first = false;
            }
            else if(str.charCodeAt(pos) == ','.code){
              pos++;
            }
            part = getSimple(str, pos);
            if(part != null){
              pos+= part.length;
            }
            else if(!bind.flags.opt) return false;
            cap[bind.name] = part;
          }
        case Query(binds):
          throw 'not implemented';
      }
    }
    return pos == str.length;
  }

  static var RE_SIMPLE = ~/^((?:[a-z0-9-+_.@]|%[0-9]{2})+)/;

  static inline function getSimple(str:String, pos:Int){
    return RE_SIMPLE.matchSub(str, pos) ? RE_SIMPLE.matched(1).urlDecode(): null;
  }

  static inline function substrEq(str:String, pos:Int, pattern:String){
    return str.substr(pos, pattern.length) == pattern;
  }
}
