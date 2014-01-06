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


function legend() {
    var fontsize = 16;
    var x = 0;
    var y = 0;
    var rx = 0;
    var width = 10;
    var height = 10;
    var yspace = 10;
    var xspace = 10;
    var labelspace = 10;
    var lChart = function(g, colors, names) {
	console.log("COLORS: ");
	console.log(colors);
	g.selectAll("rect")
	    .data(colors)
	    .enter().append("rect")
      	    .attr("x", x + xspace)
	    .attr("y", function(d,i) { return (y + (height * i) + (yspace * i))})
      	    .attr("rx", rx)
      	    .attr("width", width)
      	    .attr("height", height)
      	    .style("fill", function(d,i) {return colors[i]});

	g.selectAll("text")
	    .data(names)
	    .enter().append("text")
	    .attr("x", x + xspace + labelspace + width)
	    .attr("y", function(d,i) {return (y + (height * i) + (yspace * i) + height)})
	    .text(function(d,i) {return names[i]});
    };

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

    return lChart;
}
