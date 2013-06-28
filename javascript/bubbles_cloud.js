function initialize_bubbles_cloud() {
    // We first remove previous diagrams;
    $("#bubbles_vis").remove();

    var width = parseInt($("#views").css("width"));
    var height = parseInt($("#views").css("height"));

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

    $("#job-counts").on("click", function() {myCloud.attribute("total_job_count"); myCloud.update()});
    $("#job-time").on("click", function() {myCloud.attribute("avg_msec_per_job"); myCloud.update()});
    $("#mem").on("click", function() {myCloud.attribute("mem"); myCloud.update()});
    $("#mem-resource").on("click", function() {myCloud.attribute("resource_mem"); myCloud.update()});
    $("#one-sun").on("click", function() {myCloud.group_all()});
    $("#two-suns").on("click", function() {myCloud.display_by_meadow()});
    $("#max-size").on("change", function() {var v = $("#max-size").val(); myCloud.max_bubble_size($("#max-size").val()); myCloud.update()});

    return myCloud;
}

function bubbles_cloud_update(myCloud) {
    myCloud.data(guiHive.analysis_board)
	.update();
}