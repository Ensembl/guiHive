// pChart is the function returning the reusable pie-chart with transitions.
function pieChart() {
    // Initial values:
    // TODO: height should be substituted by max_height
    var height=800;
    var data = {counts : [1,1,1,1,1],
		colors : ["green", "yellow", "red", "blue", "cyan"],
		total  : 5
               }

    var pie = d3.layout.pie()
        .sort(null);

    // The size of the pie chart (outerRadius) is dynamic.
    var total_counts_extent = [0, max_counts];
    var pie_size_scale = d3.scale.linear()
        .range([height/10, height/5])
        .domain(total_counts_extent);
      
    var outerRadius = pie_size_scale(data.total);
    var posx = 420;
    var posy = 258;
  
    var paths = [];
    var radiusFactor = 4;
    var innerRadius = outerRadius / radiusFactor;
  
    var arc = d3.svg.arc()
        .innerRadius(innerRadius)
        .outerRadius(outerRadius);

    // chart is the returned closure
    var chart = function(g) {

	// path defined the parts of the pie chart.
	// It is stored internally in the closure (i.e. not returned).
	// In each path node we store its current value. This is needed for the transitions later
	g.attr("transform", "translate(" + chart.x() + "," + chart.y() + ")");
	var path = g.selectAll("path").data(pie(data.counts))
            .enter().append("path")
            .attr("fill", "white")
            .attr("d", arc)
            .each(function(d) { this._current = d; }); // store the initial values
  
	// The pie-chart is feeded with the initial data and colouring
	path.data(pie(data.counts))
            .attr("fill", function(d,i) {return data.colors[i]});    
    
	// transition is a method on the pie chart that returns a transition closure
	// This closure knows how to make the transition given new data for the pie chart.
	chart.transition = function() {
	    var newT = function(path) {
		var duration = 1500;
		var delay    = 0;
		path.transition().delay(delay).duration(newT.duration()).attrTween("d", function(a) {
		    var i = d3.interpolate(this._current, a),
		    k = d3.interpolate(arc.outerRadius()(),pie_size_scale(data.total));
		    this._current = i(0);
		    return function(t) {
			return arc.innerRadius(k(t)/radiusFactor).outerRadius(k(t))(i(t));
		    };
		}); // redraw the arcs
	    };
 
	    // duration is a method that allows to change the duration of the transition
	    newT.duration = function(value) {
		if (!arguments.length) return duration;
		duration = value;
		return newT
	    };

	    return newT;
	}
 
	// update is a method to update the pie-chart (given new data and a transition closure)
	chart.update = function(data, trans) {
	    // We update the data variable and...
	    chart.data(data);
	    // ...the pie paths with the new data.
	    paths.data(pie(data.counts))

	    // call the transition closure
	    trans(paths);

	    paths = path;
	    return;
	}
       
	paths = path;
	return;
    }; // end of chart closure

    // Some methods are defined over the chart: outerRadius and data
    chart.data = function(value) {
	if (!arguments.length) return data;
	data = value;
	return chart;
    };
    
    chart.x = function(value) {
	console.log(posx)
	if (!arguments.length) return posx;
	posx = value;
	return chart;
    };
      
    chart.y = function(value) {
	if (!arguments.length) return posy;
	posy = value;
	return chart;
    };
        
    return chart;
}
