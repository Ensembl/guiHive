// The reusable horizontal stacked bar

// TODO: raw_data is needed as a parameter to have the proper analysis labels in place.
// But the bar charts are created using 0 width, so we still need to call the transition to make
// them appear. We may remove this requirement and create the first width based on the passed data.
function hStackedBarChart(raw_data) {
    var barsmargin = 80;
    var stack = d3.layout.stack();
    var width = 300;
    var height = 50;
    var rightmargin = 50;
    var fontsize = 14;

    // id is there to prevent clashes in switch_type because there, the rects are select by "to_id"
    // and 2 charts having the same underlying data (i.e. the same analysis_id) would clash
    var id = 0;

    var bChart = function(g){
	var data = bChart.transformData(raw_data);

	//	var layers = stack(data);
	bChart.layers = stack(data);

	// bChart.y is global to the reusable object
	// while y is local to this closure
	// so whenever y is needed outside of the closure, bChart.y is needed
	bChart.y = bChart.new_scale(g, bChart.layers);
	var y = bChart.y;

	// Only 1 layer
	var gLayer = g.selectAll(".layer")
	    .data(bChart.layers)
	    .enter().append("g")
	    .attr("class", "layer")
	    .style("fill", function(d, i) { return raw_data.jobs_counts.colors[i] })
 
	var gRects = gLayer.selectAll("g")
	    .data(function(d) {return d})
	    .enter().append("g")
	    .attr("class", raw_data.logic_name + "__" + id)
	    .classed("bar", true);

	gRects.append("rect")
	      .attr("x", function(d) {return barsmargin + y(d.y0)})
              .attr("y", 0) // at the top
	      .attr("height", height)
	    .attr("width", function(d) {return y(d.y)})
	      .each(function(d,i){this._type = "stacked"});

	// analysis label
	g
	    .append("g")
	    .attr("class", "analysis_label")
	    .attr("to_id", raw_data.logic_name + "__" + id)
	    .on("click", bChart.switch_type)
	    .append("a")
	    .attr("style", "cursor:pointer")
	    .append("text")
	    .style("fill", "#0088cc")
	    .attr("x", 0)
	    .attr("y", bChart.height()/2 + bChart.fontsize()/2.5)
	    .attr("fill", "black")
	    .attr("font-size", fontsize)
	    .text(raw_data.logic_name + " (" + raw_data.analysis_id + ")");
    

    // general counts label
	g
	    .append("text")
	    .attr("class", "count_label")
	    .attr("x", barsmargin + y.range()[1]+10)
	    .attr("y", bChart.height()/2 + bChart.fontsize()/2.5)
	    .attr("fill", "black")
	    .attr("font-size", fontsize)
	    .text(y.domain()[1]);
    
	gRects.append("text")
	    .attr("x", barsmargin)
	    .attr("y", 0)
	    .attr("font-size", 10)
	    .attr("fill", "blue")
	    .text(0)
	    .each(function(d,i){this._type = "stacked"});
    
	bChart.transition = function () {
	    var duration = 1000;
	    var delay    = 0;

	    var newT = function (newlayers) {
		bChart.y = bChart.new_scale(g, newlayers);
		var y = bChart.y;

		var layer = g.selectAll(".layer")
		    .data(newlayers);

		var rect = layer.selectAll("rect")
		    .data(function(d) {return d});

		var text = layer.selectAll("text")
		    .data(function(d) {return d});
        
		layer.selectAll(".bar").call(bChart.redrawBars, duration, delay);
        
		g.selectAll(".count_label")
		    .data(newlayers)
		    .transition()
		    .delay(function(d,i){return i*100})
		    .duration(1000)
		    .text(function(){return bChart.data().total_job_count});
	    };
      
	    return newT;
	};
    

	bChart.update = function(new_raw_data, trans) {
	    bChart.data(new_raw_data);
	    var new_data = bChart.transformData(new_raw_data);
	    var new_layers = stack(new_data);
	    trans(new_layers);
	    bChart.layers = new_layers;
	    return;
	};
 
	return gRects;
    };
  
    bChart.fontsize = function (value) {
	if (!arguments.length) return fontsize;
	fontsize = value;
	return bChart;
    };
   
    bChart.data = function (value) {
	if (!arguments.length) return raw_data;
	raw_data = value;
	return bChart;
    };

    bChart.width = function (value) {
	if (!arguments.length) return width;
	width = value;
	return bChart;
    };
  
    bChart.height = function (value) {
	if (!arguments.length) return height;
	height = value;
	return bChart;
    };
  
    bChart.barsmargin = function (value) {
	if (!arguments.length) return barsmargin;
	barsmargin = value;
	return bChart;
    };

    bChart.rightmargin = function (value) {
	if (!arguments.length) return rightmargin;
	rightmargin = value;
	return bChart;
    };

    bChart.id = function (value) {
	if (!arguments.length) return id;
	id = value;
	return bChart;
    }

 
    bChart.switch_type = function () {
	var y = bChart.y;
	d3.selectAll("." + d3.select(this).attr("to_id")) // these are g with rects
	    .each(function(d,i) {
		if($(this).children("rect")[0]._type=="grouped"){
		    $(this).children("rect")[0]._type="stacked";
		    $(this).children("text")[0]._type="stacked";
		} else {
		    $(this).children("rect")[0]._type="grouped";
		    $(this).children("text")[0]._type="grouped";
		}
		$(this).children("rect")[0]._column=i;
		$(this).children("text")[0]._column=i;
	    })
		.call(bChart.redrawBars, 300, 10);
    };
  
    bChart.redrawBars = function (bar, time, delay) {
	var y = bChart.y;
	var height = bChart.height();
	var n = bChart.data().jobs_counts.counts.length;
	var indHeight = height/n;
	var barsmargin = bChart.barsmargin();
    
	var rect = bar.selectAll("rect");
	rect
	    .transition()
	    .delay(function(d,i) {return i*delay})
	    .duration(time)
	    .attr("x",function(d) {if (this._type == "stacked") {return barsmargin+y(d.y0)} else {return barsmargin}})
	    .attr("y", function(d,i) {if (this._type == "stacked") {return 0} else {return this._column * indHeight}})
	    .attr("width", function(d) {return y(d.y)})
	    .attr("height", function() {if (this._type == "stacked") { return height } else {return indHeight}});

	var counts_labels = bar.selectAll("text");
    
	counts_labels
	    .transition()
	    .delay(function(d,i) {return i*delay})
	    .duration(time)
	    .attr("x", function(d) {if (this._type == "stacked") {return barsmargin+y(d.y0+d.y)} else {return barsmargin+y(d.y)}})
	    .attr("y", function(d,i) { if (this._type == "stacked") { return 0 } else { return this._column * indHeight + indHeight/2 + (16/2.5)}})
	    .text(function(d){return (d.y)});
    };
  
    bChart.transformData = function (data) {
	// Data comes with an extra value for counts and colors.
	// This is populated by the script getting all the analysis
	// and they are needed to draw the pie-charts
	// (If all the arcs are 0, the pie-chart code complaints)
	// TODO: We may want to rewrite this.
	// Maybe it is better to add these new values in the pie-chart code
	// For now, we get rid of the last artificial elements
//	data.jobs_counts.counts.pop(); // Don't pop!!!!!! it is poping the objects that are shared throughout the app!
//	data.jobs_counts.colors.pop();
	// Let's just assume that we want values with name associated... so loop through all the names

	var transfData = [];
	
	for (var i=0; i<data.jobs_counts.names.length; i++) {
	    transfData[i] = [];
	}
    
	for (var j=0; j<data.jobs_counts.names.length; j++) {
	    transfData[j].push({x:0, y:data.jobs_counts.counts[j]})
	}
    
	return transfData;
    };
      
    bChart.new_scale = function(svg, layers) {
	var yStackMax = d3.max(layers, function(layer) { return d3.max(layer, function(d) { return d.y0 + d.y; }); });
	var width = bChart.width() - bChart.rightmargin();
	var newy = d3.scale.linear()
	    .domain([0, yStackMax])
	    .range([0,width]);
	return newy;
    };

    return bChart;
}

