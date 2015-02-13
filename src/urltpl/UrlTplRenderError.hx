package urltpl;

class UrlTplRenderError extends UrlTplError{
  override public function toString() return 'UrlTpl RenderError: $txt in "${tpl.src}"';
}

