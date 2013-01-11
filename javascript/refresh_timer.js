function refreshTimer() {
    var radius = 20;
    var counts = [1,0];
    var colors = ["grey", "white"];

    var pie = d3.layout.pie()
	.sort(null);

    var arc = d3.svg.arc()
	.innerRadius(0)
	.outerRadius(radius);

    var r = function(g) {

	g.attr("transform", "translate(" + radius + "," + radius + ")");
	var paths = g.selectAll("path").data(pie(counts))
	    .enter().append("path")
	    .attr("d", arc)
	    .each(function(d) { this._current = d; });

	paths
	    .attr("fill", function(d,i) {return colors[i]});

	r.transition = function() {
	    var delay = 0;
	    var duration = 1000;
	    var newR = function(path) {
		path.attr("fill", function(d,i) { return colors[i] });
		path.transition().delay(delay).duration(duration).attrTween("d", r.arcTween);
	    };

	    newR.delay = function(value) {
		if (!arguments.length) return delay;
		delay = value;
		return r;
	    };

	    newR.duration = function(value) {
		if (!arguments.length) return duration;
		duration = value;
		return r;
	    };

	    return newR;
	};

	r.update = function(data, t) {
	    r.counts(data);
	    paths.data(pie(data));
	    t(paths);
	    return;
	};

    };

    r.counts = function(value) {
	if (!arguments.length) return counts;
	counts = value;
	return r;
    };

    r.colors = function(value) {
	if (!arguments.length) return colors;
	colors = value;
	return r;
    };

    r.arcTween = function(a) {
	var i = d3.interpolate(this._current, a);
	this._current = i(0);
	return function (t) {
	    return arc(i(t))
	};
    };

    return r;
}
