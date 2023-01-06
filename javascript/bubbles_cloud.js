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


function initialize_bubbles_cloud() {
    // We first remove previous diagrams;
    $("#bubbles_vis").remove();

    // var width = parseInt($("#views").css("width"));
    // var height = parseInt($("#views").css("height"));
    var width = $(window).width();
    var height = $(window).height()-guiHive.offset;

    var vis = d3.select("#bubbles")
	.append("svg")
	.attr("width",width)
	.attr("height",height)
	.attr("id", "bubbles_vis");

    var myCloud = bubbleCloud()
	.width(width)
	.height(height)
	.data(guiHive.analysis_board)
	.attribute("total_job_count");

    myCloud(vis);
    myCloud.start().group_all();

    $("#bubble-size").change(function() {
	myCloud.attribute($(this).val()); myCloud.update();
    });

    $("#display_by_meadow_type").change(function() {
	var val = $(this).val();
	if (val === "one-sun") {
	    myCloud.group_all();
	} else {
	    myCloud.display_by_meadow();
	}
    });

    $("#max-size").on("change", function() {var v = $("#max-size").val(); myCloud.max_bubble_size($("#max-size").val()); myCloud.update()});

    return myCloud;
}

function bubbles_cloud_update(myCloud) {
    myCloud.data(guiHive.analysis_board)
	.update();
}
