/* Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

legend = function() {
    $("#legend").children().remove();
    var fontsize = 12;
    var x = 0;
    var y = 0;
    var rx = 0;
    var width = 10;
    var height = 10;
    var yspace = 10;
    var xspace = 10;
    var labelspace = 10;
    var min_color = "#FFEDA0";
    var max_color = "#F03B20";

    var mode = "guiHiveStatus";

    var lChart = function() {
	var g = d3.select("#legend")
	    .append("svg")
	    .append("g");

	// Only range-based legends will initialize these vars
	var slices;
	var color_scale;
	var gradient_box;
	var gradient_box_height;

	if ((mode === "total_job_count") || (mode === "mem") || (mode === "cpu") || (mode === "avg_msec_per_job")) {
	    // range-based
	    slices = 100;
	    gradient_box_height = 150;
	    color_scale = d3.scale.linear()
		.domain([0, slices])
		.range([min_color, max_color]);

	    for (var i = 0; i < slices; i++) {
		g.append("rect")
		    .attr("x", x)
		    .attr("y", y+(i * gradient_box_height / slices))
		    .attr("height", gradient_box_height / slices) // slices 1px each
		    .attr("width", width)
		    .attr("fill", color_scale(i));
	    }
	    $("#legend").css("height", (gradient_box_height + 20) + "px")
	    
	}


	lChart.transition = function(chart) {

	    var newT = function() {
		if ((mode === "guiHiveStatus") || (mode === "status")) {
		    // Categorical legend
		    var objs = [];
		    for (var analysis in guiHive.analysis_board) {
			if (guiHive.analysis_board.hasOwnProperty(analysis)) {
			    objs[guiHive.analysis_board[analysis][mode]] = {
				"name" : guiHive.analysis_board[analysis][mode],
				"color" : guiHive.config.Graph.Node.AnalysisStatus[guiHive.analysis_board[analysis][mode]].Colour
			    }
			}
		    }

		    var colors = [];
		    for (var key in objs) {
			if (objs.hasOwnProperty(key)) {
			    colors.push(objs[key]);
			}
		    }

		    var r = g.selectAll("rect")
			.data(colors, function(d){return d.name});

		    r
			.attr("y", function(d,i) { return (y + (height * i) + (yspace * i)) })

		    r
			.enter().append("rect")
      			.attr("x", x + xspace)
			.attr("y", function(d,i) { return (y + (height * i) + (yspace * i))})
      			.attr("rx", rx)
      			.attr("width", width)
      			.attr("height", height)
      			.style("fill", function(d,i) {return colors[i].color})
			.style("stroke-width", 1)
			.style("stroke", "rgb(0,0,0)");
		    r.exit().remove()

		    var t = g.selectAll("text")
			.data(colors, function(d){return d.name});

		    t
			.attr("y", function(d,i) { return (y + (height *i) + (yspace * i) + height)})

		    t
			.enter().append("text")
			.attr("x", x + xspace + labelspace + width)
			.attr("y", function(d,i) {return (y + (height * i) + (yspace * i) + height)})
			.text(function(d,i) {return colors[i].name});

		    $("#legend").css("height", colors.length * (height + yspace));
		    t.exit().remove();

		} else if ((mode === "total_job_count") || (mode === "mem") || (mode === "cpu") || (mode === "avg_msec_per_job")) {
		    // For some reason, the height of the legend div is reset to 40px. This code is inserted here to make sure that the original height is preserved
		    // TODO: trace back why the $(#legend).css("height") is lost before updating
		    $("#legend").css("height", (gradient_box_height + 20) + "px"); 

		    var data = [];
		    for (var analysis in guiHive.analysis_board) {
			if (guiHive.analysis_board.hasOwnProperty(analysis)) {
			    data.push(parseInt(guiHive.analysis_board[analysis][mode]));
			}
		    }

		    var extent = d3.extent(data);
		    var labels = g.selectAll("text")
			.data(extent)

		    labels
			.text(function(d){return d})

		    labels
			.enter()
			.append("text")
			.attr("x", x + width)
			.attr("y", function(d,i) {return y + (gradient_box_height * i) + (i === 0 ? 10 : 0)})
			.attr("font-size", fontsize)
			.text(function(d){return d});

		}
	    };
	    return newT;
	};

	lChart.transition()();
	return lChart;
    }
    
    lChart.x = function(value) {
	if (!arguments.length) return x;
	x = value;
	return lChart;
    };

    lChart.y = function(value) {
        if (!arguments.length) return y;
	y = value;
	return lChart;
    };

    lChart.width = function(value) {
	if (!arguments.length) return width;
	width = value;
	return lChart;
    };

    lChart.height = function(value) {
	if (!arguments.length) return height;
	height = value;
	return lChart;
    };

    lChart.fontsize = function(value) {
	if (!arguments.length) return fontsize;
	fontsize = value;
	return lChart;
    };

    lChart.mode = function (str) {
	if (!arguments.length) return mode;
	mode = str;
	return lChart;
    }

    return lChart;
};
