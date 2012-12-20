

// Compile the analysis_id regexp once
var analysis_id_regexp = /analysis_(\d+)/;

// TODO: Put this inside the monitor function
// TODO: Now that we have analysis_board this should be removed!
var total_jobs_counts = [];

function initialize_overview2() {
    var height = 350;
    var width  = 800;
    var x = d3.scale.linear().domain([0, 100]).range([0, width]);

    var vis = d3.select("#pipeline_summary")
	.append("svg:svg")
	.attr("width", width + 40)
	.attr("height", height + 20)
	.append("svg:g")
	.attr("transform", "translate(20,0)");

    return vis;
}

// uses analysis_board -- duplicated with initialize_overview. Fix!
function initialize_overview() {
    console.log(analysis_board);
    var vis = d3.select("#pipeline_summary");

    var gs = vis.selectAll("div")
	.data(analysis_board)
	.enter()
	.append("div")
	.append("svg:svg")
	.attr("height", 60)
	.append("svg:g")

    var gCharts = [];
    for (var i = 0; i < gs[0].length; i++) {
	console.log(gs[0][i]);
	var gChart = hStackedBarChart(analysis_board[i]).height(50).width(500).barsmargin(100);
	gChart(d3.select(gs[0][i]));
	// transitions can be obtained from gChart directly
	gCharts.push(gChart);
    }
    setTimeout(function() {live_overview(gCharts)}, monitorTimeout);
}

function live_overview(gCharts) {
    for (var i = 0; i < gCharts.length; i++) {
	var gChart = gCharts[i];
	var t = gChart.transition();
	gChart.update(analysis_board[i], t);
    }
    setTimeout(function() {live_overview(gCharts)}, monitorTimeout);
}

function live_overview2() {
    var height = 350;
    var width  = 800;
    var x = d3.scale.linear().domain([0, 100]).range([0, width]);

    var vis = d3.select("#pipeline_summary")
	.append("svg:svg")
	.attr("width", width + 40)
	.attr("height", height + 20)
	.append("svg:g")
	.attr("transform", "translate(20,0)");

    console.log(analysis_board);

    vis.selectAll("rect")
	.data(analysis_board)
	.enter()
	.insert("svg:rect")
	.attr("x", 10)
	.attr("y", function(d,i) {return i*2})
	.attr("height", 20)
	.attr("width", function(d,i) {return x(d.total_job_count)})   
}


// draw_diagram incorporate the pipeline diagram into the DOM
// and set the "draggability" and "pannability" of the diagram
function draw_diagram(xmlStr) {
    var DOMParser = new window.DOMParser();
    var xml = DOMParser.parseFromString(xmlStr,'img/svg+xml');
    var importedNode = document.importNode(xml.documentElement,true);

    // TODO: This is creating a nested svg structure. It is working fine, but it may be better
    // to find a way to get a cleaner structure and still have the zoom, panning capabilities
    var g = d3.select("#pipeline_diagram")
	.append("svg:svg")
	.attr("pointer-events", "all")
	.append("svg:g")
	.call(d3.behavior.zoom().on("zoom", function() { redraw(g) }))
	.append("svg:g");

    g.node().appendChild(importedNode);
}


function monitor_analysis() {
    var pie = d3.layout.pie()
	.sort(null)

    jQuery.map($('.node title'), function(v,i) {
	var titleText = $(v).text();
	var matches = analysis_id_regexp.exec(titleText);
	if (matches != null &&  matches.length > 1) {
	    var analysis_id = matches[1];
	    var gRoot = $(v).parent()[0]; 
	    var bbox = gRoot.getBBox();
	    // Links to the analysis_details
	    d3.select(gRoot)
		.attr("data-analysis_id", analysis_id) // TODO: I think this can be removed
		.on("click", function(){
		    display(analysis_id, "/scripts/db_fetch_analysis.pl", onSuccess_fetchAnalysis);
		    display(analysis_id, "/scripts/db_fetch_jobs.pl", onSuccess_fetchJobs);
		});

	    var outerRadius = bbox.height/3;
	    var innerRadius = outerRadius/4; //bbox.height/7;

	    var arc = d3.svg.arc()
		.innerRadius(innerRadius)
		.outerRadius(outerRadius)
	    // piecharts with jobs information
	    var gpie = d3.select(gRoot)
		.append("g")
		.attr("transform", "translate(" + (bbox.x+bbox.width) + "," + bbox.y + ")");

	    var path = gpie.selectAll("path").data(pie([1,1,1,1,1,1]))
		.enter().append("path")
		.attr("fill", "white")
		.attr("stroke", "black")
		.attr("d", arc)
		.each(function(d) { this._current = d; }); // store initial values

	    $(v).bind("monitor", {analysis_id:analysis_id, path:path, arc:arc, pie:pie}, worker);
	    $(v).trigger("monitor");
	}
    });
}

// One monitor per analysis
function worker(event) {
    var gRoot = $(this).parent()[0]; 
    var bbox = gRoot.getBBox();
    
    var analysis_id = event.data.analysis_id;
    var path        = event.data.path;
    var arc         = event.data.arc;
    var pie         = event.data.pie;

    var called_elem = $(this);
    var node_shape  = $(this).siblings("ellipse,polygon")[0];

    $.ajax({ url      : "/scripts/db_monitor_analysis.pl",
	     type     : "post",
	     data     : "url=" + url + "&analysis_id=" + analysis_id,
	     dataType : "json",
	     success  : function(monitorRes) {
		 if(monitorRes.status != "ok") {
		     $("#log").append(monitorRes.err_msg); scroll_down();
		 } else {
		     // The worker posts its value for total_job_count
		     // This is not very fast, since workers can update their
		     // size before all the other workers post their number of jobs
		     // in the wall.
		     total_jobs_counts[analysis_id] = parseInt(monitorRes.out_msg.total_job_count);

		     // Here we change the color status of the node
		     var color = monitorRes.out_msg.status;
		     d3.select(node_shape).transition().duration(1500).delay(0).style('fill',color);

		     // We update the labels in the nodes
		     var breakdown_label = monitorRes.out_msg.breakdown_label;
		     var label = $(gRoot).children("text")[1];
		     $(label).text(breakdown_label);

		     // and include the pie charts showing the progression of the analysis
		     var jobs_info   = monitorRes.out_msg.jobs;
		     var jobs_counts = jobs_info.counts;
		     var jobs_colors = jobs_info.colors;

		     // TODO: Shouldn't the scale be .domain([0, total_counts_extent[1]]) ???
		     var total_counts_extent = d3.extent(total_jobs_counts, function(d){return d});
		     var pie_size_scale = d3.scale.linear()
			 .range([bbox.height/5, bbox.height/3])
			 .domain(total_counts_extent);

		     path = path.data(pie(jobs_counts))
			 .attr("fill", function(d,i) { return jobs_colors[i] });

		     path.transition().duration(1500).attrTween("d", function(a) {
			 var i = d3.interpolate(this._current, a),
			     k = d3.interpolate(arc.outerRadius()(), pie_size_scale(total_jobs_counts[analysis_id]));
			 this._current = i(0);
			 return function(t) {
			     return arc.innerRadius(k(t)/4).outerRadius(k(t))(i(t));
			 };
		     }); // redraw the arcs
		 }
	     },
	     complete : setTimeout(function(){$(called_elem).trigger("monitor")}, monitorTimeout),
	   });
}

function redraw(viz) {
    viz.attr("transform",
	     "translate(" + d3.event.translate + ")"
	     + " scale("  + d3.event.scale + ")");
}
