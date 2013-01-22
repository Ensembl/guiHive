// hStackedBarChart for a given analysis
function jobs_chart(div, analysis_id) {
    // We assume that the analysis_board can be indexed by analysis_id
    var g = d3.select(div)
	.append("div")
	.attr("class","jobs_chart")
	.append("svg")
	.attr("height", 60)
	.attr("width", 500)
	.append("svg:g");
    var gChart = hStackedBarChart(guiHive.analysis_board[analysis_id-1]).height(50).width(300).barsmargin(120).fontsize(12).id(1);
    gChart(g);
    setTimeout(function() {live_analysis_chart(gChart, analysis_id)}, 2000); // We update fast from the zero values
}

function live_analysis_chart(gChart, analysis_id) {
    var t = gChart.transition();

    gChart.update(guiHive.analysis_board[analysis_id - 1], t);
    setTimeout(function() {live_analysis_chart(gChart, analysis_id)}, guiHive.monitorTimeout);
}
