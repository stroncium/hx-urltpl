package urltpl;

class UrlTplParseError extends UrlTplError{
  public var pos(default, null):Int;
  public function new(tpl, txt, pos){
    super(tpl, txt);
    this.pos = pos;
  }

  override public function toString() return pos == -1 ? 'UrlTpl ParseError: $txt in "${tpl.src}"' : 'UrlTplParseError: $txt in "${tpl.src}" at pos $pos';
}

