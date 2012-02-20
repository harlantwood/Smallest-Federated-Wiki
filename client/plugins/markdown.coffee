window.plugins.markdown =
  emit: (div, item) -> div.append "#{wiki.resolveLinks((new Markdown.Converter()).makeHtml(item.text))}"
  bind: (div, item) ->
    div.dblclick -> wiki.textEditor div, item
