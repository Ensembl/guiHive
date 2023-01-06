/* Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
/* Copyright [2016-2023] EMBL-European Bioinformatics Institute

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


function initialize_analysis_summary() {
    // We first remove previous diagrams;
    $("#analysis_summary").empty();
    var vis = d3.select("#analysis_summary");

    var gs = vis.selectAll("div")
	.data(guiHive.analysis_board)
	.enter()
	.append("div")
	.append("svg:svg")
	.attr("height", 60)
	.attr("width", 800)
	.append("svg:g")

    var gCharts = [];
    for (var i = 0; i < gs[0].length; i++) {

	var gChart = hStackedBarChart(guiHive.analysis_board[i]).height(50).width(500).barsmargin(220).id(2);
	gChart(d3.select(gs[0][i]));
	// transitions can be obtained from gChart directly
	gCharts.push(gChart);
    }
    return gCharts;
}

function analysis_summary_update(gCharts) {
    for (var i = 0; i < gCharts.length; i++) {
	var gChart = gCharts[i];
	var t = gChart.transition();//.duration(1000); TODO: Include "duration" method
	gChart.update(guiHive.analysis_board[i], t);
    }
    setTimeout(function() {analysis_summary_update(gCharts)}, guiHive.monitorTimeout);
}
