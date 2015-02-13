package urltpl;

import haxe.ds.StringMap;

private typedef Bind = {name:String, flags:{opt:Bool, add:String, arr:Bool, hash:Bool, notEmpty:Bool}};

enum UTExp{
  Lit(str:String);
  Simple(binds:Array<Bind>);
  Query(binds:Array<Bind>);
}


class UrlTpl{
  public var src:String;
  public var exprs:Array<UTExp>;

  static inline var BR_OPN = '[';
  static inline var BR_CLS = ']';

  static inline var TYPE_SIMPLE = 1;
  static inline var TYPE_QUERY = 2;
  public function new(src:String){
    this.src = src;

    var exprs = exprs = [];
    var firstPos = 0;
    var pos;
    while((pos = src.indexOf(BR_OPN, firstPos)) != -1){
      if(pos > firstPos){
        var litStr = src.substr(firstPos, pos - firstPos);
        if(litStr.indexOf(BR_CLS) != -1) throw new UrlTplParseError(this, '"$BR_CLS" out of place', -1);
        exprs.push(Lit(urlEncode(litStr)));
      }
      var endPos = src.indexOf(BR_CLS, pos+1);
      if(endPos == -1) throw new UrlTplParseError(this,'"$BR_OPN" out of place', endPos);
      var expStr = src.substr(pos+1, endPos - pos - 1);
      if(expStr.indexOf(BR_OPN) != -1) throw new UrlTplParseError(this, '"$BR_OPN" out of place', -1);
      var type;
      switch(expStr.charCodeAt(0)){
        case '?'.code:
          //TODO
          expStr = expStr.substr(1);
          type = TYPE_QUERY;
        case _:
          type = TYPE_SIMPLE;
      }

      var binds = [];
      var parts = expStr.split(',');
      for(part in parts){
        var idx = part.indexOf(':');
        var add = idx == -1 ? null : part.substr(idx + 1);
        var endPos = part.length;
        if(idx != -1) endPos = idx;

        var opt = false, arr = false, hash = false,  notEmpty = false;
        var endNotFound = true;
        do{
          switch(part.charCodeAt(endPos-1)){
            case '?'.code:
              opt = true;
              endPos--;
            case '*'.code:
              arr = true;
              if(hash) throw 'array when hash';
              endPos--;
            case '+'.code:
              arr = true;
              notEmpty = true;
              if(opt) throw 'not empty array when optional';
              if(hash) throw 'array when hash';
              endPos--;
            case '%'.code:
              hash = true;
              if(type == TYPE_SIMPLE) throw 'hash in simple';
              if(arr) throw 'hash when array';
              endPos--;
            case _: endNotFound = false;
          }
        }while(endNotFound);
        if(endPos != part.length) part = part.substr(0, endPos);
        binds.push({name:part, flags:{arr:arr, opt:opt, add:add, hash:hash, notEmpty:notEmpty}});
      }
      switch(type){
        case TYPE_QUERY:
          exprs.push(Query(binds));
        case TYPE_SIMPLE:
          exprs.push(Simple(binds));
      }
      // exprs.push(Exp(expStr));
      firstPos = endPos+1;
    }
    if(firstPos < src.length){
      var litStr = src.substr(firstPos);
      if(litStr.indexOf(BR_CLS) != -1) throw new UrlTplParseError(this, '"$BR_CLS" out of place', -1);
      exprs.push(Lit(urlEncode(litStr)));
    }
  }

  public function render(vars:Dynamic){
    var vars:haxe.DynamicAccess<Dynamic> = vars;
    var b = new StringBuf();
    for(expr in exprs) switch(expr){
      case Lit(str):
        b.add(str);
      // case Exp(str):
      //   b.add(BR_OPN);
      //   b.add(specialEncode(Std.string(vars[str])));
      //   b.add(BR_CLS);
      case Simple(binds):
        var first = true;
        for(bind in binds){
          var val = vars[bind.name];
          if(val != null){
            var str;
            if(bind.flags.arr){
              if(Std.is(val, Array)){
                if(bind.flags.notEmpty && (val:Array<Dynamic>).length == 0) throw 'empty array';
                for(e in (val:Array<Dynamic>)){
                  if(first) first = false;
                  else b.add(',');
                  b.add(specialEncode(Std.string(e)));
                }
              }
              else throw 'not array';
            }
            else{
              if(first) first = false;
              else b.add(',');
              b.add(specialEncode(Std.string(val)));
            }
          }
          else if(!bind.flags.opt) throw 'Missing bind "${bind.name}" in $vars';
        }
      case Query(binds):
        var first = true;
        for(bind in binds){
          var val = vars[bind.name];
          if(val != null){
            var bindNameEnc = specialEncode(bind.name);
            if(bind.flags.arr){
              if(!Std.is(val, Array)) throw 'not array';
              if(bind.flags.notEmpty && (val:Array<Dynamic>).length == 0) throw 'empty array';
              for(e in (val:Array<Dynamic>)){
                if(first){
                  b.add('?');
                  first = false;
                }
                else b.add('&');

                b.add(bindNameEnc);
                b.add('=');
                b.add(specialEncode(Std.string(e)));
              }
            }
            else if(bind.flags.hash){
              for(k in Reflect.fields(val)){
                if(first){
                  b.add('?');
                  first = false;
                }
                else b.add('&');

                b.add(specialEncode(k));
                b.add('=');
                b.add(specialEncode(Std.string(Reflect.field(val, k))));
              }
            }
            else{
              if(first){
                b.add('?');
                first = false;
              }
              else b.add('&');

              b.add(bindNameEnc);
              b.add('=');
              b.add(specialEncode(Std.string(val)));
            }
          }
          else if(!bind.flags.opt) throw 'Binding "${bind.name}" not defined';
        }
    }
    return b.toString();
  }


  static var CACHE = new Map<String, UrlTpl>();

  public static function compile(src:String, ?cache=true){
    var tpl = CACHE[src];
    if(tpl == null){
      tpl = new UrlTpl(src);
      if(cache) CACHE[src] = tpl;
    }
    return tpl;
  }


  static var CHAR_MAP = [for(char in ' ":?#[]@!$&\'()*+,;=/%<>{}\n\t'.split('')) char => '%'+hex(char.charCodeAt(0))];
    
  static inline function urlEncode(str:String):String{
    return (~/[ %\t\n]/g).map(str, reMapper);
  }

  static function reMapper(re:EReg) return CHAR_MAP[re.matched(0)];

  static function specialEncode(str:String){
    return (~/[ ":?#@!$&'()*+,;=\[\]\/%<>\{\}\t\n]/g).map(str, reMapper);
  }

  public static function run(src:String, vars:Dynamic):String{
    return compile(src).render(vars);
  }

  static inline function hex(num:Int) return StringTools.hex(num, 2);
}
