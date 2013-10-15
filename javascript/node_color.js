function nodeColor() {
    var attr = 'status';
    var color_scale;
    var extent;

    var color_status = guiHive.config.Graph.Node.AnalysisStatus;

    var node_range = function(index) {
	if (attr === "status") {
	    console.log("INDEX: " + index);
	    return color_status[guiHive.analysis_board[index].status[0]].Colour;
	}
	node_range.range();
	return color_scale(guiHive.analysis_board[index][attr]);
    };

    node_range.attr = function(new_attr) {
	if (!arguments.length) {
	    return attr;
	}
	attr = new_attr;
	extent = node_range.range();
    }

    node_range.range = function() {
	if (attr === 'total_job_count' || attr === 'avg_msec_per_job') {
	    var extent = d3.extent(guiHive.analysis_board, function(d,i){ return parseInt(d[attr]) });

	    color_scale = d3.scale.linear()
		.domain(extent)
		.range(["#FFEDAO","#F03B20"])
	}

	return;
    };

    return node_range;

}

function isNumber(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}
