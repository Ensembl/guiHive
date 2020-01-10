/* Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
/* Copyright [2016-2020] EMBL-European Bioinformatics Institute

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


// We need to have all the views centralized to make it possible to
// orchestrate the refreshes
// TODO: Should this be included in the guiHive global object?
var basicViews = function() {
    // TODO: we can convert this into an object
    // so the update method, calls all the update submethods
    var overviewChart = {};
    overviewChart.chart = pipeline_overview();
    overviewChart.update = pipeline_overview_update; // a closure;

    // var allAnalysisCharts = {};
    // allAnalysisCharts.chart = initialize_analysis_summary();
    // allAnalysisCharts.update = analysis_summary_update; // a closure;

    var allAnalysisPies = {};
    allAnalysisPies.chart = initialize_pipeline_diagram();
    allAnalysisPies.update = pipeline_diagram_update; // a closure

    var legendChart = {};
    legendChart.chart = legend();
    legendChart.chart();
    legendChart.update = legendChart.chart.transition() // a closure

    var allBubbles = {};
    allBubbles.chart = initialize_bubbles_cloud();
    allBubbles.update = bubbles_cloud_update; // a closure
    // more...

    var charts = { overview     : overviewChart,
		   // allAnalysis  : allAnalysisCharts,
		   allAnalysisP : allAnalysisPies,
		   bubblesCloud : allBubbles,
		   legend       : legendChart,
		 };

    var views = function() {
    };

    views.addChart = function (name, chart_closure, update_closure) {
	var new_chart = {chart : chart_closure,
			 update : update_closure};
	charts.name = new_chart;
    };

    views.removeChart = function (name) {
	delete charts.name;
    };

    views.replaceChart = function (name, chart_closure, update_closure) {
	views.removeChart(name);
	views.addChart(name, chart_closure, update_closure);
    };

    views.update = function() {
	for (chartname in charts) {
	    views.updateOneChart(chartname);
	}
    };

    views.getAllCharts = function () {
	return charts;
    };

    views.getChart = function (name) {
	return charts[name];
    };

    views.updateOneChart = function (name) {
	var chart = charts[name].chart;
	var update = charts[name].update;
	update(chart);
    }

    return views;
}

function initialize_views_and_refresh() {
    // We remove all the previous charts (if any):
    if (guiHive.views !== undefined) {
	var allCharts = guiHive.views.getAllCharts();
	for (var i in allCharts) {
	    if (allCharts.hasOwnProperty(i)) {
		guiHive.views.removeChart(i);
	    }
	}
    }

    // Create the new refresh timer
    $("#refresh_time").html("<p>Time to refresh: </p>");

    // We need some initial data, so we first call this method with an empty callback
    // At this point, the board is empty, so
    // refresh_data_and_views will run in "sync" mode
    // and the views will not be updated (they are not created yet)
    // TODO: We are retrieving data twice (see below in this function). But this is
    // not easy to avoid because for some of the views we need to have initial values to work with
    // so we are in a loop here.
    refresh_data_and_views(function(){});

    // We initialize the views
    guiHive.views = basicViews();

    // We set up the callbacks for the timer
//    guiHive.refresh_data_timer.callback(function(){refresh_data_and_views(guiHive.views.update)});
    guiHive.refresh_data_timer.callback(refresh_data_and_views);
    guiHive.refresh_data_timer.inner_callback(guiHive.views.update);

    // We now refresh data and views
    // We need the analysis_board to be populated by now
    guiHive.refresh_data_timer.now();
    // refresh_data_and_views(guiHive.views.update);

    // We listen to the timer controls    
    $(".refresh_now").click(guiHive.refresh_data_timer.now);
    $(".start_refreshing").click(guiHive.refresh_data_timer.start);
    $(".stop_refreshing").click(guiHive.refresh_data_timer.stop);
    $(".reset_timer").click(guiHive.refresh_data_timer.reset);
    
}

