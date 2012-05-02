(function() {
  var formatTime;

  formatTime = function(time) {
    var am, d, h, mi, mo;
    d = new Date((time > 10000000000 ? time : time * 1000));
    mo = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'][d.getMonth()];
    h = d.getHours();
    am = h < 12 ? 'AM' : 'PM';
    h = h === 0 ? 12 : h > 12 ? h - 12 : h;
    mi = (d.getMinutes() < 10 ? "0" : "") + d.getMinutes();
    return "" + h + ":" + mi + " " + am + "<br>" + (d.getDate()) + " " + mo + " " + (d.getFullYear());
  };

  window.plugins.chart = {
    emit: function(div, item) {
      var captionElement, chartElement;
      chartElement = $('<p />').addClass('readout').appendTo(div).text(item.data.last().last());
      return captionElement = $('<p />').html(wiki.resolveLinks(item.caption)).appendTo(div);
    },
    bind: function(div, item) {
      return div.find('p:first').mousemove(function(e) {
        var sample, time, _ref;
        _ref = item.data[Math.floor(item.data.length * e.offsetX / e.target.offsetWidth)], time = _ref[0], sample = _ref[1];
        $(e.target).text(sample.toFixed(1));
        return $(e.target).siblings("p").last().html(formatTime(time));
      }).dblclick(function() {
        return wiki.dialog("JSON for " + item.caption, $('<pre/>').text(JSON.stringify(item.data, null, 2)));
      });
    }
  };

}).call(this);
