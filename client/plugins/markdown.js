(function() {

  window.plugins.markdown = {
    bind: function(div, item) {
      return div.dblclick(function() {
        return wiki.textEditor(div, item);
      });
    },
    emit: function(div, item) {
      return wiki.getScript('/js/Markdown.Converter.js', function() {
        div.append('<style>\n  .markdown ul {\n  margin: 0px;\n  list-style-position: inside;\n  padding:0px;\n}\n</style>');
        return div.append("<div class='markdown'>      " + (wiki.resolveLinks((new Markdown.Converter()).makeHtml(item.text))) + "</div>");
      });
    }
  };

}).call(this);
