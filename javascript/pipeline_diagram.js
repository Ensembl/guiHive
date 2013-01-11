

// Compile the analysis_id regexp once
var analysis_id_regexp = /analysis_(\d+)/;

// TODO: Put this inside the monitor function
// TODO: Now that we have analysis_board this should be removed! -- but pieCharts still use this
var total_jobs_counts = [];

function refresh_data() {
//function show_refresh_time() {
    $("#refresh_time").html("<p>Time to refresh: </p>");
    var vis = d3.select("#refresh_time")
	.append("svg:svg")
	.attr("width", 50)
	.attr("height", 50)
	.append("svg:g");

    var timeChart = timeRefresh();
    timeChart(vis);
    var t = timeChart.transition()
    update_refresh_time(timeChart,t,monitorTimeout/1000,0); 
}

function update_refresh_time(tChart, trans, tOrig, tCurr) {
    if (tCurr > tOrig) {
	// We show a red signal while updating (takes 1 second)
	tChart.colors(["grey","red"]);
	tChart.update([1,0], trans);
	trans.duration(0);
	update_analysis_board();
	trans.delay(1000);
	tChart.update([0,1], trans);
	return
    }
    var countsDone = tCurr/tOrig;
    var countsAhead = 1 - countsDone;
    var newcounts = [countsAhead,countsDone];
    tChart.update(newcounts, trans);
    setTimeout(function() {update_refresh_time(tChart, trans, tOrig, tCurr + 1)}, 1000);
}

function get_totals() {
    var totals = new Array();
    for (var k = 0; k<analysis_board[0].jobs_counts.counts.length; k++) {
	totals[k] = 0;
    }
    for (var i = 0; i<analysis_board.length; i++) {
	for (var j = 0; j<analysis_board[i].jobs_counts.counts.length; j++) {
	    totals[j] += analysis_board[i].jobs_counts.counts[j]
	}
    }

    return totals;
}

function form_data() {
    var totals = get_totals();
    // We always have at least 1 value (job),
    // so we don't need the last "white" value
    // TODO: Investigate why the "white" color is not here
    totals.pop();
    var data = {};
    data.counts = totals;
    data.colors = analysis_board[0].jobs_counts.colors;
    data.names  = analysis_board[0].jobs_counts.names;
    data.total  = d3.sum(totals);

    return data;
}

function monitor_overview() {
    var summary_header = "<h4>Pipeline progress</h4>";
    $("#summary").html(summary_header);
    var data = form_data();
    var foo = d3.select("#summary")
	.append("svg:svg")
	.attr("width", 550)
	.attr("height", 150)
	.append("svg:g");
    var bChart = barChart().data(data);
    bChart(foo);
//    var tt = bChart.transition();
    setTimeout (function() { live_overview_lite(bChart)}, 2000);


//// Pie chart instead of bars:
//     var vis = d3.select("#summary")
//     .append("svg:svg")
//     .attr("width", 250)
//     .attr("height", 300)
//     .append("svg:g");

//     var data = form_data();
//     var pChart = pieChart().x(110).y(110).data(data);
//     pChart(vis);
//     var l = legend().x(-60).y(100);
//     l(vis, data.colors, data.names);
//     setTimeout(function() {live_overview_lite(pChart)}, monitorTimeout);
}

// TODO: The name of the methods are poorly chosen.
// We have a general overview (pieChart / hBarChart)
// and a per-analysis overview
function live_overview_lite(pChart) {
    var data = form_data();
    var t = pChart.transition();
//    pChart.max_counts(data.total).update(data, t);
    pChart.update(data,t);
    
    setTimeout(function() {live_overview_lite(pChart)}, monitorTimeout);
}

function jobs_chart(div, analysis_id) {
    // We assume that the analysis_board can be indexed by analysis_id
    var g = d3.select(div)
	.append("div")
	.append("svg:svg")
	.attr("height", 60)
	.attr("width", 700)
	.append("svg:g");
    var gChart = hStackedBarChart(analysis_board[analysis_id-1]).height(50).width(400).barsmargin(120).id(1);
    gChart(g);
    setTimeout(function() {live_analysis_chart(gChart, analysis_id)}, 2000); // We update fast from the zero values
}

function live_analysis_chart(gChart, analysis_id) {
    var t = gChart.transition();

    gChart.update(analysis_board[analysis_id - 1], t);
    setTimeout(function() {live_analysis_chart(gChart, analysis_id)}, monitorTimeout);
}

// uses analysis_board -- duplicated with initialize_overview. Fix!
function initialize_overview() {
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

	var gChart = hStackedBarChart(analysis_board[i]).height(50).width(500).barsmargin(220).id(2);
	gChart(d3.select(gs[0][i]));
	// transitions can be obtained from gChart directly
	gCharts.push(gChart);
    }
    setTimeout(function() {live_overview(gCharts)}, 2000); // We update fast from the zero values
}

function live_overview(gCharts) {
    for (var i = 0; i < gCharts.length; i++) {
	var gChart = gCharts[i];
	var t = gChart.transition();//.duration(1000); TODO: Include "duration" method
	gChart.update(analysis_board[i], t);
    }
    setTimeout(function() {live_overview(gCharts)}, monitorTimeout);
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
		     var breakdown_label = monitorRes.out_msg.breakout_label;
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
