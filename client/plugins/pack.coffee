window.plugins.line =
  bind: (div, item) ->
  emit: (div, item) ->
    wiki.getScript '/js/d3/d3.js', ->
      wiki.getScript '/js/d3/d3.time.js', ->
        div.append '''
          <style>
            circle {
              fill: rgb(31, 119, 180);
              fill-opacity: .25;
              stroke: rgb(31, 119, 180);
              stroke-width: 1px;
            }

            .leaf circle {
              fill: #ff7f0e;
              fill-opacity: 1;
            }

            text {
              font: 10px sans-serif;
            }
          </style>
        '''
        series = wiki.getData()

        width = 960
        height = 960
        format = d3.format(",d")

        pack = d3.layout.pack()
          .size([ width - 4, height - 4 ])
          .value((d) -> d.size)

        vis = d3.select("#chart")
          .append("svg")
            .attr("width", width)
            .attr("height", height)
            .attr("class", "pack")
          .append("g")
            .attr("transform", "translate(2, 2)")

        d3.json "../data/flare.json", (json) ->
          node = vis.data([ json ]).selectAll("g.node")
            .data(pack.nodes)
            .enter()
            .append("g")
            .attr("class", (d) -> (if d.children then "node" else "leaf node"))
            .attr("transform", (d) -> "translate(" + d.x + "," + d.y + ")")

          node.append("title")
            .text (d) -> d.name + (if d.children then "" else ": " + format(d.size))

          node.append("circle")
            .attr "r", (d) -> d.r

          node.filter((d) -> not d.children)
            .append("text")
            .attr("text-anchor", "middle")
            .attr("dy", ".3em")
            .text (d) -> d.name.substring 0, d.r / 3
