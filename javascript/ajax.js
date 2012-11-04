// Globally defined
var url = "";
// Compile the analysis_id regexp once
var analysis_id_regexp = /analysis_(\d+)/;

// TODO: Put this inside the monitor function
var total_jobs_counts = [];

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
    $("#db_url").val("mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_long_mult");
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

function monitor_analysis() {
    var pie = d3.layout.pie()
	.sort(null)

    jQuery.map($('.node title'), function(v,i) {
	var titleText = $(v).text();
	var matches = analysis_id_regexp.exec(titleText);
	if (matches != null &&  matches.length > 1) {
	    var analysis_id = matches[1];
	    var gRoot = $(v).parent()[0]; 
	    var bbox = gRoot.getBBox();
	    // Links to the analysis_details
	    d3.select(gRoot)
		.attr("data-analysis_id", analysis_id)
	        .on("click", function(){
		    var button = $(this);
		    $.ajax({url        : "/scripts/db_fetch_analysis.pl",
			    type       : "post",
			    data       : "url=" + url + "&analysis_id=" + $(this).attr("data-analysis_id"),
			    dataType   : "json",
			    success    : function(resp) {onSuccess_fetchAnalysis(resp, button)},
			   });

		    // TODO: For now, there is a duplicated ajax call (one for analysis details
		    // and one for jobs) because I still don't know where the jobs should be
		    // accessible (here? in the pie-charts?)
		    $.ajax({url        : "/scripts/db_fetch_jobs.pl",
			    type       : "post",
			    data       : "url=" + url + "&analysis_id=" + $(this).attr("data-analysis_id"),
			    dataType   : "json",
			    success    : function(resp) {onSuccess_fetchJobs(resp)},
			   })
		});

		    var outerRadius = bbox.height/3;
	    var innerRadius = outerRadius/4; //bbox.height/7;

	    var arc = d3.svg.arc()
		.innerRadius(innerRadius)
		.outerRadius(outerRadius)
	    // piecharts with jobs information
	    var gpie = d3.select(gRoot)
		.append("g")
		.attr("transform", "translate(" + (bbox.x+bbox.width) + "," + bbox.y + ")");

	    var path = gpie.selectAll("path").data(pie([1,1,1,1,1,1]))
		.enter().append("path")
		.attr("fill", "white")
		.attr("stroke", "black")
		.attr("d", arc)
		.each(function(d) { this._current = d; }); // store initial values

	    $(v).bind("monitor", {analysis_id:analysis_id, path:path, arc:arc, pie:pie}, worker);
	    $(v).trigger("monitor");
	}
    });
}

// One monitor per analysis
function worker(event) {
    var gRoot = $(this).parent()[0]; 
    var bbox = gRoot.getBBox();
    
    var analysis_id = event.data.analysis_id;
    var path        = event.data.path;
    var arc         = event.data.arc;
    var pie         = event.data.pie;

    var called_elem = $(this);
    var node_shape  = $(this).siblings("ellipse,polygon")[0];

    $.ajax({ url      : "/scripts/db_monitor_analysis.pl",
	     type     : "post",
	     data     : "url=" + url + "&analysis_id=" + analysis_id,
	     dataType : "json",
	     success  : function(monitorRes) {
		 if(monitorRes.status != "ok") {
		     $("#log").append(monitorRes.err_msg); scroll_down();
		 } else {
		     // The worker posts its value for total_job_count
		     // This is not very fast, since workers can update their
		     // size before all the other workers post their number of jobs
		     // in the wall.
		     total_jobs_counts[analysis_id] = monitorRes.out_msg.total;

		     // Here we change the color status of the node
		     var color = monitorRes.out_msg.status;
		     d3.select(node_shape).transition().duration(1500).delay(0).style('fill',color);

		     // and include the pie charts showing the progression of the analysis
		     var jobs_info   = monitorRes.out_msg.jobs;
		     var jobs_counts = jobs_info.counts;
		     var jobs_colors = jobs_info.colors;

		     var total_counts_extent = d3.extent(total_jobs_counts, function(d){return d});
		     var pie_size_scale = d3.scale.linear()
			 .range([bbox.height/5, bbox.height/3])
			 .domain(total_counts_extent);

		     console.log(jobs_counts);
		     console.log(jobs_colors);
		     path = path.data(pie(jobs_counts))
			 .attr("fill", function(d,i) { return jobs_colors[i] });

		     path.transition().duration(1500).attrTween("d", function(a) {
			 var i = d3.interpolate(this._current, a),
			     k = d3.interpolate(arc.outerRadius()(), pie_size_scale(total_jobs_counts[analysis_id]));
			 this._current = i(0);
			 return function(t) {
			     return arc.innerRadius(k(t)/4).outerRadius(k(t))(i(t));
			 };
		     }); // redraw the arcs
		 }
	     },
	     complete : setTimeout(function(){$(called_elem).trigger("monitor")}, 5000), // 5seg TODO: Increase in production
	   });
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
}

function redraw(viz) {
    viz.attr("transform",
	     "translate(" + d3.event.translate + ")"
	     + " scale("  + d3.event.scale + ")");
}


function draw_diagram(xmlStr) {
    var DOMParser = new window.DOMParser();
    var xml = DOMParser.parseFromString(xmlStr,'img/svg+xml');
    var importedNode = document.importNode(xml.documentElement,true);

    // TODO: This is creating a nested svg structure. It is working fine, but it may be better
    // to find a way to get a cleaner structure and still have the zoom, panning capabilities
    var g = d3.select("#pipeline_diagram")
	.append("svg:svg")
	.attr("pointer-events", "all")
	.append("svg:g")
	.call(d3.behavior.zoom().on("zoom", function() { redraw(g) }))
	.append("svg:g");

    g.node().appendChild(importedNode);
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

function onSuccess_fetchJobs(jobsRes) {
    if(jobsRes.status == "ok") {
	$("#jobs").html(jobsRes.out_msg);
    } else {
	$("#log").append(jobsRes.err_msg); scroll_down();
	$("#connexion_msg").html(jobsRes.status);
    }
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
