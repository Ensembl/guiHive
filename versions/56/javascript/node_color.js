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


function nodeColor() {
    var attr = 'guiHiveStatus';
    var color_scale;
    var extent;

    var color_status = guiHive.config.Graph.Node.AnalysisStatus;

    var node_range = function(index) {
	// if the analysis doesn't have data, we don't change it color
	if (guiHive.analysis_board[index].status === "EMPTY" ) {
	    return "white";
	}


	if (attr === "status" || attr === "guiHiveStatus") {
	    return color_status[guiHive.analysis_board[index][attr]].Colour;
	}
	if (attr === 'mem' || attr === 'cpu') {
	    return color_scale(guiHive.analysis_board[index][attr][1]);
	}
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
	if (attr === 'total_job_count' ||
	    attr === 'avg_msec_per_job'){
	    var extent = d3.extent(guiHive.analysis_board.filter(function(d){return d!==null}), function(d,i){return parseInt(d[attr]) });
	    color_scale = d3.scale.linear()
		.domain(extent)
		.range(["#FFEDAO","#F03B20"]);
	} else if (attr === 'mem' ||
		   attr === 'cpu') {
	    var extent = d3.extent(guiHive.analysis_board.filter(function(d){return d!==null}), function(d,i){return parseInt(d[attr][1]) });
	    color_scale = d3.scale.linear()
		.domain(extent)
		.range(['#FFEDAO',"#F03B20"]);
	}

	return;
    };

    return node_range;

}

function isNumber(n) {
  return !isNaN(parseFloat(n)) && isFinite(n);
}
