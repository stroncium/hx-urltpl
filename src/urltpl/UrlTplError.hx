package urltpl;

class UrlTplError{
  var tpl:UrlTpl;
  var txt:String;
  public function new(tpl, txt){
    this.tpl = tpl;
    this.txt = txt;
  }

  public function toString() return 'UrlTpl Error: $txt in "${tpl.src}"';
}

