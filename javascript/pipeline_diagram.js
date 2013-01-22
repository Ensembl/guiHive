

// Compile the analysis_id regexp once
var analysis_id_regexp = /analysis_(\d+)/;

// draw_diagram incorporate the pipeline diagram into the DOM
// and set the "draggability" and "pannability" of the diagram
// TODO: Firefox can't run this.
//       It seems to have problems with DOMParser.parseFromString(xmlStr, 'img/svg+xml')
function draw_diagram(xmlStr) {
    // we first remove previous diagrams
    $("#pipeline_diagram").empty();

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

// This is creating the pie charts in the pipeline diagram
function initialize_pipeline_diagram() {
    var allPies = [];
    jQuery.map($('.node title'), function(v,i) {
	var titleText = $(v).text();
	var matches = analysis_id_regexp.exec(titleText);
	if (matches != null && matches.length > 1) {
	    var analysis_id = matches[1];
	    var gRoot = $(v).parent()[0];
	    var node  = $(v).siblings("ellipse,polygon")[0];
	    var bbox = gRoot.getBBox();
	    var posx = bbox.x + bbox.width;
	    var posy = bbox.y;
	    var pChart = pieChart().x(posx).y(posy);
	    var gpie = d3.select(gRoot)
		.append("g");
	    pChart(gpie);
	    allPies.push({chart          : pChart,
			  transition     : pChart.transition().duration(1500),
			  analysis_id    : analysis_id,
			  breakout_label : $(gRoot).children("text")[1],
			  root_node      : node,
			 });

	    // Links to the analysis_details
	    d3.select(gRoot)
		.attr("data-analysis_id", analysis_id)
		.on("click", function() {
		    display(analysis_id, "/scripts/db_fetch_analysis.pl", onSuccess_fetchAnalysis);
		    display(analysis_id, "/scripts/db_fetch_jobs.pl", onSuccess_fetchJobs);
		});
	}
    });
    return allPies;
}

function pipeline_diagram_update(allCharts) {
    var max_counts = d3.max(guiHive.analysis_board, function(v){return d3.sum(v.jobs_counts.counts)});
    for (var i = 0; i < allCharts.length; i++) {
	var analysis_id = allCharts[i].analysis_id;

	// Update the color status of the node
	var node_color = guiHive.analysis_board[analysis_id-1].status[1];
	var node_shape = allCharts[i].root_node;
	d3.select(node_shape).transition().duration(1500).delay(0).style("fill",node_color);
	
	// Update the pie charts
	var chart = allCharts[i].chart;
	chart.max_counts(max_counts);
	var t = allCharts[i].transition;
	var data = guiHive.analysis_board[analysis_id-1].jobs_counts;
	chart.update(data, t);

	// Update the breakout_label
	var breakout_label = guiHive.analysis_board[analysis_id-1].breakout_label;
	var breakout_elem = allCharts[i].breakout_lable;
	$(breakout_elem).text(breakout_label);
    }
}

function redraw(viz) {
    viz.attr("transform",
	     "translate(" + d3.event.translate + ")"
	     + " scale("  + d3.event.scale + ")");
}
