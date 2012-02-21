window.plugins.markdown =
  emit: (div, item) -> div.append "<div class='markdown'>
    #{wiki.resolveLinks((new Markdown.Converter()).makeHtml(item.text))}</div>"
  bind: (div, item) ->
    div.dblclick -> wiki.textEditor div, item
