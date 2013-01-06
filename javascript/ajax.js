// Globally defined
var url = "";

// analysis_board stores the data of all the analysis.
// pipeline_diagram and pipeline_summary should read 
// from this board
// TODO: Should this be global?
var analysis_board;

// monitorTimeout is the time that passes before monitoring again
// It is being used by the analysis_board and its consumers
var monitorTimeout = 50000; // 50seg. TODO: Allow users to change this

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

    // Function for polling the analysis into the analysis_board
    $("#update_analysis_board").hide().bind("monitor", function() {
	var elem = this;
	$.ajax({url      : "/scripts/db_fetch_all_analysis.pl",
		type     : "post",
		data     : "url=" + $("#db_url").val(),
		async    : false,  // TODO: For now we are doing this sync to avoid a race between the polling of the board and its consumers
		                   // but we should support async in production, if possible.
		dataType : "json",
		success  : function(allAnalysisRes) {
		    if(allAnalysisRes.status != "ok") {
			$("#log").append(allAnalysisRes.err_msg); scroll_down();
		    } else {
			analysis_board = allAnalysisRes.out_msg;
		    }
		},
		complete : setTimeout(function(){$(elem).trigger("monitor")}, monitorTimeout),
	       })
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

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_dbConnect(res) {
    $("#connexion_msg").html(res.status);
    draw_diagram(res.out_msg);
    $("#show_resources").trigger('click');  // TODO: Best way to handle?
    $("#log").append(res.err_msg); scroll_down();
    url = $("#db_url").val();
    // Now we start monitoring the analyses:
    $("#update_analysis_board").trigger("monitor");
    // This has to disappear?
    monitor_overview();
    monitor_analysis();
    initialize_overview();
}

function display(analysis_id, fetch_url, callback) {
    $.ajax({url        : fetch_url,
	    type       : "post",
	    data       : "url=" + url + "&analysis_id=" + analysis_id,
	    dataType   : "json",
	    success    : function(resp) {callback(resp, analysis_id, fetch_url)},
	   });
}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_fetchAnalysis(analysisRes, analysis_id, fetch_url) {
    if(analysisRes.status == "ok") {
	$("#analysis_details").html(analysisRes.out_msg);
    } else {
	$("#log").append(analysisRes.err_msg); scroll_down();
	$("#connexion_msg").html(analysisRes.status);
    }

    // We have db_update.pl and db_update2.pl
    // TODO: use a generic version (db_update.pl or db_update2.pl)
    // that can deal with both cases
    // It this is not possible, give better names
    // TODO2: Shouldn't this code be moved to the "ok" condition above?
    $(".update_param").change(
	{ analysis_id:analysis_id,
	 fetch_url:fetch_url,
	 script:"/scripts/db_update.pl"},
	update_db);
    $(".update_param").click(
	{analysis_id:analysis_id,
	 fetch_url:fetch_url,
	 script:"/scripts/db_update.pl"},
	update_db);
}

// TODO: Currently, analysis_id and fetch_url are not being used
function onSuccess_fetchJobs(jobsRes, analysis_id, fetch_url) {
    if(jobsRes.status == "ok") {
	// Datepicker format
	$.datepicker.regional[""].dateFormat = 'dd/mmo/yy';
	$.datepicker.setDefaults($.datepicker.regional['']);
	$("#jobs").html(jobsRes.out_msg);

	// Listener to delete_input_id button:
	$(".delete_input_id").click(function(){console.log("THIS(click)::"); console.log(this);
					       var sel = this;
					       $.ajax({url       : "/scripts/db_update2.pl",
						       type      : "post",
						       data      : jQuery.param(buildSendParams(sel)),
						       dataType  : "json",
						       async     : false,
						       cache     : false,
						       success   : function() {display(analysis_id, "/scripts/db_fetch_jobs.pl", onSuccess_fetchJobs)}
						      });
					      }
				   );


	// We convert the whole job table in a dataTable
	var oTable = $('#jobs_table').dataTable()
	    .columnFilter( {
		aoColumns : [ { type : "number" },
			      { type : "number" },
			      { type : "text"   },
			      { type : "number" },
			      { type : "select", values: [ 'SEMAPHORED', 'READY', 'DONE', 'FAILED' ] },
			      { type : "number-range" },
			      { type : "date-range" },
			      { type : "number" },
			      { type : "number" },
			      { type : "number" },
			      { type : "number" }
			    ],
	    });

	// We attach global updaters. Maybe this can be inserted as datatable's fnInitComplete event
	// Global updaters work on all the visible fields of the dataTable.
	$('.update_param_all').change(function() {
	    column = $(this).attr("data-column");
	    column_index = $(this).attr("data-column-index");

	    var job_ids = [];
	    $.each(oTable._('tr', {"filter":"applied"}), function(i,v) { // applied to all visible rows via the _ method
		job_ids.push(v[0]); // pushed the job_ids (first column). TODO: More portable way?
	    });
	    console.log(job_ids);

	    var sel = this;
	    $.ajax({url      : "/scripts/db_update2.pl",
		    type     : "post",
		    data     : jQuery.param(buildSendParams(sel)) + "&dbID=" + job_ids.join() + "&value=" + $(sel).val(),
		    dataType : "json",
		    async    : false,
		    cache    : false,
		    success  : function () {
			$.each(oTable.$('tr', {"filter":"applied"}), function(i,v) {
			    var tr = $(v)[0];
			    var aPos = oTable.fnGetPosition(tr);
			    oTable.fnUpdate($(sel).val(), aPos, column_index);
			});
		    }
//		    complete : function() {$(button).trigger('click')},
//		    complete : display(analysis_id, fetch_url, onSuccess_fetchJobs)
		   });
		    
	    // TODO: In principle this is not needed because we re-create the table on column updates (or we should!)
	    $(this).children('option:selected').removeAttr("selected");
	    $(this).children('option:first-child').attr("selected","selected");
	});

	// We have individual jeditable fields specialized by columns
	oTable.$("td.editableRetries").each(function() {
	    var job_id = $(this).attr("data-linkTo");
	    $(this).editable("/scripts/db_update2.pl", {
		indicator  : "Saving...",
		tooltip    : "Click to edit...",
		loadurl    : "/scripts/db_fetch_max_retry_count.pl?url=" + url + "&job_id=" + job_id,
		type       : "select",
		submit     : "Ok",
		event      : "dblclick",
		callback   : function(response) {editableCallback.call(this, response, oTable)},
		submitdata : function() { return (buildSendParams(this)) }
	    });
	});

	oTable.$("td.editableInputID").editable("/scripts/db_update2.pl", {
	    indicator  : "Saving...",
	    tooltip    : "Click to edit...",
	    event      : "dblclick",
	    //		callback   : function(response) {innerEditableCallback.call(this, response, job_id)},
	    callback   : function(response) {
		console.log("RESPONSE:");
		console.log(response);
		var needsReload = $(this).attr("data-needsReload");
		if (needsReload == 1) {
		    display(analysis_id, "/scripts/db_fetch_jobs.pl", onSuccess_fetchJobs);
		} else {innerEditableCallback.call(this, response)}
	    },
	    submitdata : function() { return (buildSendParams(this)) }
	});

	oTable.$("td.editableStatus").editable("/scripts/db_update2.pl", {
	    indicator  : "Saving...",
	    tooltip    : "Click to edit...",
	    data       : "{'SEMAPHORED':'SEMAPHORED','READY':'READY','RUN':'RUN','DONE':'DONE'}",
	    type       : "select",
	    submit     : "Ok",
	    event      : "dblclick",
	    callback   : function(response) {editableCallback.call(this, response, oTable)},
	    submitdata : function() { return (buildSendParams(this)) }
	});

	// TODO: I think this action over td.editable is not needed because we have
	// to have specialised sections above (not sure though -- double-check)
	oTable.$("td.editable").editable("/scripts/db_update2.pl", {
	    indicator  : 'Saving...',
	    tooltip    : 'Click to edit...',
	    event      : "dblclick",
	    callback   : function(response) {editableCallback.call(this, response, oTable)},
	    submitdata : function() { return (buildSendParams(this)) }
	});

    } else {
	$("#log").append(jobsRes.err_msg); scroll_down();
	$("#connexion_msg").html(jobsRes.status);
    }
}

function innerEditableCallback(response) {
    console.log("INNER CALLED");
    var value = jQuery.parseJSON(response);
    console.log(value)
    $(this).html(value.out_msg);

    // If there exist a sibling with data-newvalueID then we activate it
    var val_sibling_id = $(this).attr("data-newValueID");
    if (val_sibling_id != undefined) {
	var val_sibling = $("#" + val_sibling_id);
	var key = $(this).html();
	console.log("VAL_SIBLING: " + val_sibling_id);	
	console.log(val_sibling);
	console.log("KEY:");
	console.log(key);
	val_sibling.addClass("editableInputID");
	val_sibling.attr("data-key", key);
	doEditableInputID();
    }
}

function editableCallback(response, oTable) {
    var aPos = oTable.fnGetPosition(this);
    var value = jQuery.parseJSON(response);
    oTable.fnUpdate( value.out_msg, aPos[0], aPos[1] );
}

function buildSendParams(obj) {
    var value = "";
    if ($(obj).attr("data-linkTo")) {
	var elem = $('#'+$(obj).attr("data-linkTo"));
	value = $(elem).text();
    }

    var urlHash = {url      : url,
		   adaptor  : $(obj).attr("data-adaptor"),
		   method   : $(obj).attr("data-method"),
		  };

    if (value != "") {
	urlHash.dbID = value;
    }

    // If the update is associated with a key/value pair
    if ($(obj).attr("data-key")) {
	urlHash.key = $(obj).attr("data-key");
    }

    console.log(urlHash);
    return (urlHash);
}

function update_db(obj) {
    var url = obj.data.script;
    var fetch_url = obj.data.fetch_url;
    var analysis_id = obj.data.analysis_id;
    $.ajax({url        : url,
	    type       : "post",
	    data       : buildURL(this),
	    dataType   : "json",
	    async      : false,
	    cache      : false,
	    success    : function(updateRes) {
		if(updateRes.status != "ok") {
		    $("#log").append(updateRes.err_msg); scroll_down();
		};
	    },
//	    complete   :  function() {$(button).trigger('click')},
	    complete   : display(analysis_id, fetch_url, onSuccess_fetchAnalysis)
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

