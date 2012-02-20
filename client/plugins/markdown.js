(function() {

  window.plugins.markdown = {
    emit: function(div, item) {
      return div.append("" + (wiki.resolveLinks((new Markdown.Converter()).makeHtml(item.text))));
    },
    bind: function(div, item) {
      return div.dblclick(function() {
        return wiki.textEditor(div, item);
      });
    }
  };

}).call(this);
