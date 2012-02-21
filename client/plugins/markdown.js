(function() {

  window.plugins.markdown = {
    emit: function(div, item) {
      return div.append("<div class='markdown'>    " + (wiki.resolveLinks((new Markdown.Converter()).makeHtml(item.text))) + "</div>");
    },
    bind: function(div, item) {
      return div.dblclick(function() {
        return wiki.textEditor(div, item);
      });
    }
  };

}).call(this);
