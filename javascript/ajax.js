// Globally defined
var url = "";

// wait for the DOM to be loaded 
$(document).ready(function() { 
    //  We are creating a hidden button for showing resources and 
    //  firing it once the analysis are displayed
    //  we are doing this to allow re-load of the resources when
    //  they are changed (without having to reload the analysis too or re-connect to the db)
    //  TODO: We may try to find a better solution for this
    $("#show_resources").hide().click(function() {
	$.ajax({url        : "/scripts/db_fetch_resource.pl",
		type       : "post",
		data       : "url=" + $("#db_url").val(),
		dataType   : "json",
		beforeSend : function() {showProcessing($("#resource_details"))},
		success    : function(resourcesRes) {
		    if(resourcesRes.status != "ok") {
			$("#log").append(updateRes.err_msg); scroll_down();
		    } else {
			$("#resource_details").html(resourcesRes.out_msg);
			$(".update_resource").click(
			    { reload:$("#show_resources"),
			      script:"/scripts/db_update.pl"},
			    update_db);
			$(".create_resource").click(
			    { reload:$("#show_resources"),
			      script:"/scripts/db_create.pl"},
			    update_db);
		    }
		},
	       });
    });

    // Default value. Only for testing. TODO: Remove the following line
    $("#db_url").val("mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69d");
    $("#Connect").click(function() {
	$.ajax({url        : "/scripts/db_connect.pl",
		type       : "post",
		data       : "url=" + $("#db_url").val(),
		dataType   : "json",
		beforeSend : function() {showProcessing($("#connexion_msg"))},
		success    : onSuccess_dbConnect
	       });
    });

}); 

// One per analysis
// Monitorizes the analysis
function worker() {
    var analysis_id = $(this).attr("data-analysisID");
    var called_div = this;
    $.ajax({ url      : "/scripts/db_monitor_analysis.pl",
	     type     : "post",
	     data     : "url=" + url + "&analysis_id=" + analysis_id,
	     dataType : "json",
	     success  : function(monitorRes) {
		 if(monitorRes.status != "ok") {
		     $("#log").append(monitorRes.err_msg); scroll_down();
		 } else {
		     $(called_div).html(monitorRes.out_msg)
		 }
	     },
	     complete : setTimeout(function(){$(called_div).trigger("monitor")}, 10000), // 10seg TODO: Increase in production
	   });
}

function monitor_analysis() {
    $(".progress_monitor").bind("monitor", worker);
    $(".progress_monitor").trigger("monitor");
}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_dbConnect(res) {
    $("#connexion_msg").html(res.status);
    draw_diagram(res.out_msg);
    $("#show_resources").trigger('click');  // TODO: Best way to handle?
    $("#log").append(res.err_msg); scroll_down();
    url = $("#db_url").val();
    // Now we start monitoring the analyses:
    monitor_analysis();

    $(".analysis_link").click(function() {
	var button = $(this);
	$.ajax({url        : "/scripts/db_fetch_analysis.pl",
		type       : "post",
		data       : "url=" + url + "&logic_name=" + this.id,
		dataType   : "json",
		success    : function(resp) {onSuccess_fetchAnalysis(resp, button)},
	       });
    });
}

function draw_diagram(xml) {
    $("#pipeline_diagram").html(xml);

    var vis = d3.select("#pipeline_diagram")
	.append('svg:g')
	.call(d3.behavior.zoom().on("zoom", redraw))
	.append('svg:g')

    vis.append('svg:rect')
    .attr('width', 600)
    .attr('height', 600)
    .attr('fill', 'white');

    function redraw() {
	console.log("here", d3.event.translate, d3.event.scale);
    }

    d3.selectAll(".node text")
    .attr("text-decoration", "underline");
    d3.selectAll("ellipse")
    .attr("fill", "green");
    d3.select("svg")
	.append("svg:g")
	.call(d3.behavior.zoom().on("zoom", function() { redraw(svg) }))
	.append("svg:g");
    // Insert here code to avoid scrolling on mouse events
}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_fetchAnalysis(analysisRes, button) {
    if(analysisRes.status == "ok") {
	$("#analysis_details").html(analysisRes.out_msg);
    } else {
	$("#log").append(analysisRes.err_msg); scroll_down();
	$("#connexion_msg").html(analysisRes.status);
    }
    $(".update_param").change(
	{reload:button,
	 script:"/scripts/db_update.pl"},
	update_db);
    $(".update_param").click (
	{reload:button,
	 script:"/scripts/db_update.pl"},
	update_db);
}

function update_db(obj) {
    var url = obj.data.script;
    var button = obj.data.reload;
    $.ajax({url        : url,
	    type       : "post",
	    data       : buildURL(this),
	    dataType   : "json",
	    success    : function(updateRes) {
		if(updateRes.status != "ok") {
		    $("#log").append(updateRes.err_msg); scroll_down();
		};
	    },
	    complete   :  function() {button.trigger('click')},
	   });
}
			    
function buildURL(obj) {
    var value = "";
    if ($(obj).attr("data-linkTo")) {
	var ids = $(obj).attr("data-linkTo").split(",");
	var vals = jQuery.map(ids, function(e,i) {
	    var elem = $('#'+e);
	    if ($(elem).is("span")) {
		return $(elem).attr("data-value")
	    } else {
		return $(elem).attr("value")
	    }
	});
	value = vals.join(",");
    } else {
	value = obj.value;
    }

    var URL = "url="+url + 
        "&args="+value + 
        "&adaptor="+$(obj).attr("data-adaptor") + 
        "&method="+$(obj).attr("data-method");
    if ($(obj).attr("data-analysisID")) {
	URL = URL.concat("&analysis_id="+$(obj).attr("data-analysisID"));
    }
    return(URL);
}

function showProcessing(obj) {
    obj.html('<img src="../images/preloader.gif" width="40px" height="40px"/>');
}

function onSend(req, settings) {
    alert(JSON.stringify(this));
}

// There seems not to be good ways to automatically fire methods
// when a div has change. This is a bit ugly, but other alternatives doesn't look
// promising either. Anyway, we can implement something like:
// http://stackoverflow.com/questions/3233991/jquery-watch-div/3234646#3234646
// or (non-IE, AFAIK):
// http://stackoverflow.com/questions/4979738/fire-jquery-event-on-div-change
function scroll_down() {
    $("#log").scrollTop($("#log").height()+10000000); // TODO: Try to avoid this arbitrary addition
}
