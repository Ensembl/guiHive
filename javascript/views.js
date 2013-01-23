// We need to have all the views centralized to make it possible to
// orchestrate the refreshes
// TODO: Should this be included in the guiHive global object?
var basicViews = function() {
    // TODO: we can convert this into an object
    // so the update method, calls all the update submethods
    var overviewChart = {};
    overviewChart.chart = pipeline_overview();
    overviewChart.update = pipeline_overview_update; // a closure;

    var allAnalysisCharts = {};
    allAnalysisCharts.chart = initialize_analysis_summary();
    allAnalysisCharts.update = analysis_summary_update; // a closure;

    var allAnalysisPies = {}
    allAnalysisPies.chart = initialize_pipeline_diagram();
    allAnalysisPies.update = pipeline_diagram_update; // a closure
    // more...

    var charts = { overview     : overviewChart,
		   allAnalysis  : allAnalysisCharts,
		   allAnalysisP : allAnalysisPies,
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

    views.update = function() {
	for (chartname in charts) {
	    var chart = charts[chartname].chart;
	    var update = charts[chartname].update;
	    update(chart);
	}
    };

    return views;
}

function initialize_views_and_refresh() {
    // Create the new refresh timer
    $("#refresh_time").html("<p>Time to refresh: </p>");

    // We need some initial data, so we first call update_analysis_board with an empty callback
    // At this point, the board is empty, so
    // update_analysis_board will run in "sync" mode
    // and the views will not be updated (they are not created yet)
    // TODO: We are retrieving data twice (see below in this function). But this is
    // not easy to avoid because for some of the views we need to have initial values to work with
    // so we are in a loop here.
    refresh_data_and_views(function(){});

    // We initialize the views
    guiHive.views = basicViews();

    // We set up the callback for the timer
    guiHive.refresh_data_timer.callback(function(){refresh_data_and_views(guiHive.views.update)});

    // We now refresh data and views
    // We need the analysis_board to be populated by now
    guiHive.refresh_data_timer.now();

    // We listen to the timer controls    
    $(".refresh_now").click(guiHive.refresh_data_timer.now);
    $(".start_refreshing").click(guiHive.refresh_data_timer.start);
    $(".stop_refreshing").click(guiHive.refresh_data_timer.stop);
    $(".reset_timer").click(guiHive.refresh_data_timer.reset);
    
}

