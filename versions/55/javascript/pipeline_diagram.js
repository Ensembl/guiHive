/* Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/


d3.selection.prototype.moveToFront = function() { 
  return this.each(function() { 
    this.parentNode.appendChild(this); 
  }); 
};

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
    // var width = $("#pipeline_diagram").css("width");
    // var height = $("#pipeline_diagram").css("height");
    var width = $(window).width();
    var height = $(window).height()-guiHive.offset;

    d3.select(importedNode)
    	.attr("width", width)
    	.attr("height", height);

    var g = d3.select("#pipeline_diagram")
	.style("width", width-30 + "px")
	.style("height", height + "px")
    	.append("svg")
    	.attr("width",width)
    	.attr("height",height)
    	.attr("pointer-events", "all")
    	.append("g")
    	.call(d3.behavior.zoom().on("zoom", function() { redraw(g) }))
    	.append("g");
    
    g.node().appendChild(importedNode);

    // We move to front all the nodes to avoid being hidden behind other elements
    d3.selectAll("#pipeline_diagram .node").moveToFront();
}

// This is creating the pie charts in the pipeline diagram
function initialize_pipeline_diagram() {
    var allPies = [];
    jQuery.map($('.node title'), function(v,i) {
	var titleText = $(v).text();
	// We delete the title text to allow for better tooltips
	$(v).text("");
	var matches = analysis_id_regexp.exec(titleText);
	if (matches != null && matches.length > 1) {
	    var analysis_id = matches[1];
	    var gRoot = $(v).parent()[0];

	    var polygon_coords = points_from_string(d3.select(gRoot).select("polygon").attr("points"));
	    var posx = polygon_coords[1].x + 15;
	    var posy = polygon_coords[4].y;
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


	    // Let's add a label with the analysis_id (should accommodate 3 digits)
	    d3.select(gRoot)
		.append("rect")
      	    .attr("x", polygon_coords[0].x)
		.attr("y", polygon_coords[4].y - 15)
		.attr("width", 25)
		.attr("height", 15)
		.attr("stroke", "black")
		.attr("fill", "white");
	    d3.select(gRoot)
		.append("text")
		.text(analysis_id)
	        .attr("x", polygon_coords[0].x + 3)
		.attr("y", polygon_coords[4].y - 2);

	    // Links to the analysis_details
	    // and makes the gRoots tooltip-able
	    d3.select(gRoot)
		.attr("data-analysis_id", analysis_id)
		.attr("rel", "tooltip-it")
		.on("click", function() {
		    display(analysis_id, "./scripts/db_fetch_analysis.pl", onSuccess_fetchAnalysis);
    //		    display(analysis_id, "/scripts/db_fetch_jobs.pl", onSuccess_fetchJobs);
		});
	}
    });

    // Apart from pies we need to setup and listen node_colors
    guiHive.node_colors = nodeColor();
    $("#select_analysis_colors").change(function(){
	guiHive.node_colors.attr($(this).val())
	var pChart = guiHive.views.updateOneChart("allAnalysisP");
    });

    // And change the cursor style for text
    d3.selectAll('.node text')
	.attr("style", "cursor:default");

    return allPies;
}

function pipeline_diagram_update(allCharts) {
    var max_counts = d3.max(guiHive.analysis_board, function(v){if (v === null) {return 0} return d3.sum(v.jobs_counts.counts)});
//    var node_colors = nodeColor(); // closure
//    node_colors.attr("avg_msec_per_job");
    for (var i = 0; i < allCharts.length; i++) {
	var analysis_id = allCharts[i].analysis_id;

	// Update the color status of the node
	var node_color = guiHive.node_colors(analysis_id);
	var nodes = $(allCharts[i].root_node).siblings("path,polygon,polyline,rect");
	d3.selectAll(nodes).transition().duration(1500).delay(0).attr("fill",node_color).attr("stroke",function() {if($(this).attr("stroke") === "black") {return "black"} else {return node_color}});


	// Update the pie charts
	var chart = allCharts[i].chart;
	chart.max_counts(max_counts);
	var t = allCharts[i].transition;
	var data = guiHive.analysis_board[analysis_id].jobs_counts;
	chart.update(data, t);

	// Update the breakout_label
	// TODO: The breakout label should be re-located in the node as it grows
	var breakout_label = guiHive.analysis_board[analysis_id].breakout_label;
	var breakout_elem = allCharts[i].breakout_label;
	var curr_x = $(breakout_elem).attr("x");
	var curr_l = $(breakout_elem).text().length;
	// var font_size = $(breakout_elem).attr("font-size");
	var old_size = curr_l * 8; // magic number?
	var new_size = breakout_label.length * 8; // magic number?
	var new_x = parseFloat(curr_x) - ~~(new_size/2) + ~~(old_size/2);
	$(breakout_elem).attr("x", new_x);
	$(breakout_elem).text(breakout_label);

	// Update the tooltips
	var d = guiHive.analysis_board[analysis_id];
	var tooltip_msg = "Analysis ID: " + analysis_id + "<br/>Logic name: " + d.logic_name + "<br/>Number of jobs:" + d.total_job_count + "<br/>Avg time per job: " + d.avg_msec_per_job_parsed;
	if (d.mem !== undefined) {
            tooltip_msg = tooltip_msg + "<br/>Min memory used: " + d.mem[0] + "<br/>Mean memory used: " + d.mem[1] + "<br/>Max memory used:" + d.mem[2];
	}
	tooltip_msg = tooltip_msg + "<br/>Breakout label: " + d.breakout_label + "<br/>Status: " + d.status + "<br/>guiHiveStatus: " + d.guiHiveStatus;
	$(allCharts[i].root_node).parent().attr("title",tooltip_msg);
    }
}

function redraw(viz) {
    viz.attr("transform",
	     "translate(" + d3.event.translate + ")"
	     + " scale("  + d3.event.scale + ")");
}


function points_from_string(str) {
    var points_str = str.split(" ");
    var points = [];
    for (var i = 0; i < points_str.length; i++) {
	var new_point = {};
	var coords = points_str[i].split(",");
	new_point.x = parseInt(coords[0]);
	new_point.y = parseInt(coords[1]);
	points.push(new_point);
    }
    return points;
}
