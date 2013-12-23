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
