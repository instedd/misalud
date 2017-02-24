function Linechart(svg) {
  
	var self = this;
	var _svg, _container, _data, _width, _height, _color, _formatter, _x, _y, _line, _path, _axis, _highlight
		_margin = {top: 6, right: 60, bottom: 72, left: 60};
	    
	self.render = function() {
		_svg.attr("width", _width + _margin.left + _margin.right)
	    	.attr("height", _height + _margin.top + _margin.bottom)
	  	
	  	_container.attr("transform", "translate(" + _margin.left + "," + _margin.top + ")");

	  	_x.rangePoints([0, _width]);

    	_y.rangeRound([_height, 0]);

    	_path.transition()
    		.attr("d", _line);

      	_highlight.attr("transform", "translate(" + (_margin.left + _width / 2) + "," + (_margin.top + _height / 2) + ")");

      	_axis.attr("transform", function(d) { return "translate(0, " + _height + ")"; });

      	_axis.selectAll(".step")
      		.attr("transform", function(d) { return "translate(" + _x(d[1]) + ", 0)"; });

      	_axis.selectAll("line")
      		.attr("x1", function(d, i) { return _x(_data.samples[Math.max(0, i - 1)][1]); })
      		.attr("x2", function(d, i, array) { return _x(d[1]); })
      		.style("stroke", function(d) { return _color(d[1]); });

      	_axis.selectAll("circle")
      		.attr("r", 6)
      		.style("fill", function(d) { return _color(d[1]); });

	}

	self.data = function(value) {
		if(arguments.length) {
			_data = value;
  			_x.domain(_data.samples.map(function(d) { return d[1]; }));
  			_y.domain([0, d3.max(_data.samples, function(d) { return d[2]; })]);
  			
  			_path.datum(_data.samples);
  			
  			_highlight.select(".label")
  				.text(_data.total[0]);

  			_highlight.select(".value")
  				.text(_formatter(_data.total[1]));

  			_axis.selectAll("line")
  				.data(_data.samples)
  				.enter()
  				.append("line")
  				.attr("y1", 0)
				.attr("y2", 0);

  			_axis.selectAll(".step")
  				.data(_data.samples)
  				.enter()
  				.append("g")
  				.attr("class", "step")
  				.each(function (d) {

  					d3.select(this).append("text")
  						.attr("class", "icon");

  					d3.select(this).append("text")
  						.attr("class", "label");

  					d3.select(this).append("circle");
  				})

  			_axis.selectAll(".icon")
	      		.text(function(d) { return d[0]})
	      		.style("fill", function(d) { return _color(d[1]); });

	      	_axis.selectAll(".label")
	      		.data(_data.samples)
	      		.text(function(d) { return _formatter(d[2]) + " " + d[1]})
	      		.style("fill", function(d) { return _color(d[1]); });

		} else {
			return _data;
		}
	}

	self.setSize = function(width, height) {
		_width = width - _margin.left - _margin.right;
	    _height = height - _margin.top - _margin.bottom;
	}

 	function init(svg) {
		_svg = d3.select(svg);
		_container = _svg.append("g");
		_color = d3.scale.ordinal()
    		.range(["#424242", "#3f51b5", "#3f51b5", "#4caf50"]);
		_formatter = d3.format(",");
		_x = d3.scale.ordinal();
    	_y = d3.scale.linear();
    	_line = d3.svg.line()
    		.interpolate("basis")
		    .x(function(d) { return _x(d[1]); })
		    .y(function(d) { return _y(d[2]); });
		_path = _container.append("path")
			.attr("class", "line");
		_axis = _container.append("g");
      	_highlight = _container.append("g")
      	_highlight.append("text")
      		.attr("class", "value");
      	_highlight.append("text")
      		.attr("class", "label");
		self.setSize(960, 480);
	};

	init(svg);
}