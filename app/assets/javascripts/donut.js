function Donut(svg, index) {
  
	var self = this;
	var _svg, _container, _data, _width, _height, _radius, _pie, _color, _arc, _arcs, _index, _references, _highlight, _formatter;
	    
	self.render = function() {

		_svg.attr("width", _width)
	    	.attr("height", _height);
	  	
	  	_container.attr("transform", "translate(" + _width / 2 + "," + _height / 2 + ")");
	  	
	  	_arc.outerRadius(_radius)
    		.innerRadius(_radius - 30);
    	
    	_container.selectAll(".arc")
    		.transition()
    		.attrTween("d", arcTween)
      		.style("fill", function(d) { return _color(d.data[0]); });
	}

	self.data = function(value) {
		if(arguments.length) {
			var datum, t0, t1;

			_data = value;
			_container.selectAll(".arc")
      			.data(_pie(_data))
				.enter().append("path")
				.each(function(d) { this._current = d; })
				.attr("class", "arc")
				.style("fill", function(d) { return _color(d.data[0]); });

		  	datum = _data[_index];
		  	
		  	t0 = _highlight.select(".value")
		  		.transition();
		  		
		  	t0.attr("fill", _color(datum[0]))
				.attr("y", -30)
				.attr("opacity", 0)
				.each("end", function(d) { _highlight.select(".value").attr("y", 30) })

			t1 = t0.transition();

			t1.text(_formatter(datum[1]))
				.attr("y", 0)
				.attr("opacity", 1);
		  	
		  	_highlight.select(".label")
		  		.attr("fill", _color(datum[0]))
		  		.text(datum[0]);

		  	_references.selectAll(".reference")
		  		.data(_data)
		  		.enter()
		  		.append("g")
		  		.attr("class", "reference")
		  		.attr("transform", function (d, i) { return "translate(0, " + i * 45 + ")"; })
		  		.each(function (d) {
		  			d3.select(this).append("text")
		  				.attr("class", "value")
		  				.attr("fill", function (d) { return _color(d[0]); })
		  				
		  			d3.select(this).append("text")
		  				.attr("class", "label")
		  				.attr("fill", function (d) { return _color(d[0]); })
		  	})


		  	_references.selectAll(".reference")
		  		.each(function (d) {

					d3.select(this).select(".label")
						.text(d[0]);
					d3.select(this).select(".value")
						.text(_formatter(d[1]));

		  	})
		} else {
			return _data;
		}
	}

	self.setSize = function(width, height) {
		_width = width;
	    _height = height;
	    _radius = Math.min(_width, _height) / 2;
	}

	function arcTween(a) {
		var i = d3.interpolate(this._current, a);
		this._current = i(0);
		return function(t) {
			return _arc(i(t));
		};
	}

	function showReferences() {
		_highlight.transition()
			.attr("transform", "translate(0, -30)")
			.attr("opacity", 0);
		_references.transition()
			.attr("transform", "translate(0, " + (_references.node().getBBox().height / -2 + 15) + ")")
			.attr("opacity", 1);
	}

	function hideReferences() {
		_highlight.transition()
			.attr("transform", "translate(0, 0)")
			.attr("opacity", 1);
		_references.transition()
			.attr("transform", "translate(0, 30)")
			.attr("opacity", 0);
	}

 	function init(svg, index) {
		_svg = d3.select(svg);
		_svg.on("mouseover", showReferences);
		_svg.on("mouseout", hideReferences);
		_container = _svg.append("g");
		_pie = d3.layout.pie()
		    .sort(null)
		    .value(function(d) { return d[1]; });
		_arc = d3.svg.arc();
		_color = d3.scale.ordinal()
    		.range(["#4caf50", "#cddc39", "#424242", "#3f51b5"]);
    	_index = index;
		_references = _container.append("g")
			.attr("transform", "translate(0, 30)")
			.attr("opacity", 0);
		_highlight = _container.append("g");
		_highlight.append("text")
			.attr("class", "value");
		_highlight.append("text")
			.attr("class", "label");
		_formatter = d3.format(",");
		self.setSize(480, 480);
	};

	init(svg, index);
}
