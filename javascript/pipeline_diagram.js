
// Compile the analysis_id regexp once
var analysis_id_regexp = /^analysis_(\d+)/;

// draw_diagram incorporate the pipeline diagram into the DOM
// and set the "draggability" and "pannability" of the diagram
function draw_diagram(xmlStr) {
    // we first remove previous diagrams
    $("#pipeline_diagram").empty();

    var DOMParser = new window.DOMParser();
//    var xml = DOMParser.parseFromString(xmlStr,'img/svg+xml');
    var xml = DOMParser.parseFromString(xmlStr,'text/xml');
    var importedNode = document.importNode(xml.documentElement,true);

    // TODO: This is creating a nested svg structure. This is needed because Firefox will only use the
    // the width and height of the outer structure, so we need to give the width and height
    // of the inner svg (the real one).
    // I am not able to have zoom and panning capabilities without the outer svg
    var width = $("#pipeline_diagram").css("width");
    var height = $("#pipeline_diagram").css("height");

    var g = d3.select("#pipeline_diagram")
    	.append("svg")
    	.attr("width",width)
    	.attr("height",height)
    	.attr("pointer-events", "all")
    	.append("g")
    	.call(d3.behavior.zoom().on("zoom", function() { redraw(g) }))
    	.append("g");
    
    g.node().appendChild(importedNode);

}

// This is creating the pie charts in the pipeline diagram
function initialize_pipeline_diagram() {
    var allPies = [];
    jQuery.map($('.node title'), function(v,i) {
	var titleText = $(v).text();
	console.log(titleText);
	// We delete the title text to allow for better tooltips
	$(v).text("");
	var matches = analysis_id_regexp.exec(titleText);
	if (matches != null && matches.length > 1) {
	    var analysis_id = matches[1];
	    var gRoot = $(v).parent()[0];
	    var node  = $(v).siblings("path,polygon,polyline");
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
			  breakout_label : $(gRoot).children("text")[2],
			  root_node      : v,
			 });

	    // Links to the analysis_details
	    // and makes the gRoots tooltip-able
	    d3.select(gRoot)
		.attr("data-analysis_id", analysis_id)
		.attr("rel", "tooltip-it")
		.on("click", function() {
		    display(analysis_id, "/scripts/db_fetch_analysis.pl", onSuccess_fetchAnalysis);
		    //		    display(analysis_id, "/scripts/db_fetch_jobs.pl", onSuccess_fetchJobs);
		});
	}
    });
    return allPies;
}

function pipeline_diagram_update(allCharts) {
    var max_counts = d3.max(guiHive.analysis_board, function(v){return d3.sum(v.jobs_counts.counts)});

    // TODO: This relies on the possibility of mapping the analysis_id with the position in the array.
    // This breaks if the analysis_ids are not correlative (i.e. if we have updated manually the analysis_base table
    // removing an entry (ID) there).
    // This code would be more consistent if we don't rely on this and create another data structure to map analysis_IDs to indexes in the array of analysis
    for (var i = 0; i < allCharts.length; i++) {
	var analysis_id = allCharts[i].analysis_id;

	// Update the color status of the node
	// TODO: This is assuming that the analysis_id corresponds to indexes in the analysis_board (-1)
	// but this may not be the case if we have missing analysis_ids
	// A more robust version of this code would index the analysis_board by analysis_id, but this would
	// require an extra data structure (a ids=>index hash table or similar).
	var node_color = guiHive.analysis_board[analysis_id-1].status[1];
	var nodes = $(allCharts[i].root_node).siblings("path,polygon,polyline");
	d3.selectAll(nodes).transition().duration(1500).delay(0).attr("fill",node_color).attr("stroke",function() {if($(this).attr("stroke") === "black") {return "black"} else {return node_color}});

	// Update the pie charts
	var chart = allCharts[i].chart;
	chart.max_counts(max_counts);
	var t = allCharts[i].transition;
	var data = guiHive.analysis_board[analysis_id-1].jobs_counts;
	chart.update(data, t);

	// Update the breakout_label
	// TODO: The breakout label should be re-located in the node as it grows
	var breakout_label = guiHive.analysis_board[analysis_id-1].breakout_label;
	var breakout_elem = allCharts[i].breakout_label;
	$(breakout_elem).text(breakout_label);

	// Update the tooltips
	var d = guiHive.analysis_board[analysis_id-1];
	var tooltip_msg = "Analysis ID: " + (i+1) + "<br/>Logic name: " + d.logic_name + "<br/>Number of jobs:" + d.total_job_count + "<br/>Avg msec per job: " + d.avg_msec_per_job;
	if (d.mem !== undefined) {
            tooltip_msg = tooltip_msg + "<br/>Min memory used: " + d.mem[0] + "<br/>Mean memory used: " + d.mem[1] + "<br/>Max memory used:" + d.mem[2];
	}
	tooltip_msg = tooltip_msg + "<br/>Breakout label: " + d.breakout_label + "<br/>Status: " + d.status[0];
	$(allCharts[i].root_node).parent().attr("title",tooltip_msg);
//	$(allCharts[i].root_node).text(tooltip_msg);
    }
}

function redraw(viz) {
    viz.attr("transform",
	     "translate(" + d3.event.translate + ")"
	     + " scale("  + d3.event.scale + ")");
}
