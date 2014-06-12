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


function barChart() {
    var fontsize = 14;
    var x = 0;
    var y = 0;
    var rx = 0;
    var label_margin = 80;
    var bar_height = 20;
    var width = 240;
    var labelspace = 10;
    var xspace = 10;
    var yspace = 5;

    var bChart = function(g) {
	console.log("DATA:");
	console.log(data);
	bChart.yscale = bChart.new_scale(g, data);

	var gs = g.selectAll("rect")
	.data(data.counts)
	.enter().append("g")
	.attr("class", "baz");

	// The bars
	gs.append("rect")
	    .attr("x", x + xspace + label_margin)
	    .attr("y", function(d,i) { return (y + (bar_height * i) + (yspace * i)) })
	    .attr("height", bar_height)
	    .attr("width", function(d, i) { return bChart.yscale(data.counts[i]) })
	    .style("fill", function(d, i) { return data.colors[i] });

	// The labels
	gs.append("text")
	    .attr("x", 0)
	    .attr("y", function(d,i) { return (y + (bar_height * i) + (yspace * i) + bar_height/2 + fontsize/2) })
	    .text( function(d,i) { return data.names[i] } )
	    .style("font-size", fontsize);

	// The counts
	gs.append("text")
	    .attr("x", function(d, i) { return (x + 2*xspace + label_margin + bChart.yscale(data.counts[i])) })
	    .attr("y", function(d, i) { return (y + (bar_height * i) + (yspace * i) + bar_height/2 + fontsize/2) })
	    .attr("class", "overview_counts")
	    .text(function(d, i) {return data.counts[i]})
	    .style("font-size", fontsize);

	// Transition for bars and counts
	bChart.transition = function() {
	    var duration = 1000;
	    var delay    = 0;
	    var newT = function(data) {
		var data  = bChart.data();
		bChart.yscale = bChart.new_scale(g, data);

		var rects = g.selectAll("rect");
		rects
		    .transition()
		    .delay(delay)
		    .duration(duration)
		    .style("fill", function(d, i) { return data.colors[i] })
		    .attr("width", function(d,i) { return bChart.yscale(data.counts[i]) });

		var counts = g.selectAll(".overview_counts");
		counts
		    .transition()
		    .delay(delay)
		    .duration(duration)
		    .attr("x", function(d, i) { return (x + 2*xspace + label_margin + bChart.yscale(data.counts[i])) })
		    .text(function(d, i) { return data.counts[i] });
		
	    };
	    return newT;
	};

	return bChart;
    };

    bChart.update = function(new_data, trans) {
	bChart.data(new_data);
	trans(new_data);
	return;
    };

    bChart.data = function(value) {
	if (!arguments.length) return data;
	data = value;
	return bChart;
    };

    bChart.fontsize = function(value) {
	if (!arguments.length) return fontsize;
	fontsize = value;
	return bChart;
    };

    bChart.new_scale = function(svg, data) {
	var maxVal = d3.max(data.counts);
	
	var newy = d3.scale.linear()
	    .domain([0, maxVal])
	    .range([0, width]);

	return newy;
    };

    return bChart;
}
