/* Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
/* Copyright [2016-2021] EMBL-European Bioinformatics Institute

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


function get_totals() {
    var totals = new Array();
    for (var f in guiHive.analysis_board) {
	if (guiHive.analysis_board[f].hasOwnProperty('jobs_counts')) {
	    for (var k=0; k<guiHive.analysis_board[f].jobs_counts.counts.length; k++) {
		totals[k] = 0;
	    }
	    break;
	}
    }

    for (var f in guiHive.analysis_board) {
	if (guiHive.analysis_board[f].hasOwnProperty('jobs_counts')) {
	    for (var j=0; j<guiHive.analysis_board[f].jobs_counts.counts.length; j++) {
		totals[j] += guiHive.analysis_board[f].jobs_counts.counts[j];
	    }
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
    for (var f in guiHive.analysis_board) {
	if (guiHive.analysis_board[f].hasOwnProperty('jobs_counts')) {
	    data.colors = guiHive.analysis_board[f].jobs_counts.colors;
	    data.names = guiHive.analysis_board[f].jobs_counts.names;
	    data.total = d3.sum(totals);
	}
    }
    data.total  = d3.sum(totals);

    return data;
}

function pipeline_overview() {
    var summary_header = "<h4>Pipeline progress</h4>";
    $("#summary").html(summary_header);
    var data = form_data();
    var foo = d3.select("#summary")
	.append("svg")
	.attr("width", 550)
	.attr("height", 150)
	.append("g");
    var bChart = barChart().data(data);
    bChart(foo);
    return bChart;
}

function pipeline_overview_update(bChart) {
    var data = form_data();
    var t = bChart.transition();
    bChart.update(data,t);
}
