/* Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
/* Copyright [2016] EMBL-European Bioinformatics Institute

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


// hStackedBarChart for a given analysis
function jobs_chart(analysis_id) {
    var div = d3.select("#analysis_details");

    // We assume that the analysis_board can be indexed by analysis_id
    var g = div
	.append("div")
	.attr("class","jobs_chart")
	.append("svg")
	.attr("height", 60)
	.attr("width", 500)
	.append("svg:g");
    var gChart = hStackedBarChart(guiHive.analysis_board[analysis_id]).height(50).width(300).barsmargin(120).fontsize(12).id(1);
    gChart.analysis_id = analysis_id;
    gChart(g);
    guiHive.views.addChart("jobs_chart",gChart, live_analysis_chart);
//    setTimeout(function() {live_analysis_chart(gChart, analysis_id)}, 2000); // We update fast from the zero values
}

function live_analysis_chart(gChart) {
    var analysis_id = gChart.analysis_id;
    var t = gChart.transition();

    gChart.update(guiHive.analysis_board[analysis_id], t);
//    setTimeout(function() {live_analysis_chart(gChart, analysis_id)}, guiHive.monitorTimeout);
}
