window.plugins.markdown =
  bind: (div, item) ->
    div.dblclick -> wiki.textEditor div, item
  emit: (div, item) ->
    wiki.getScript '/js/Markdown.Converter.js', ->
      div.append '''
	<style>
	  .markdown ul {
	  margin: 0px;
	  list-style-position: inside;
	  padding:0px;
	}
	</style>
      '''
      div.append "<div class='markdown'>
      #{wiki.resolveLinks((new Markdown.Converter()).makeHtml(item.text))}</div>"
