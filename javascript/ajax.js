// Globally defined
var guiHive = {
    pipeline_url       : "",        // The url to connect to the pipeline
                                    // This is the value of $("#db_url") i.e. it is entered by the user
    refresh_data_timer : undefined, // The timer for the next data update
    monitorTimeout     : 30000,     // Time for next data updaet
                                    // TODO: This has to disappear in favor of refresh_data_timer
                                    // once the pie charts get listens to the analysis_board
    analysis_board     : undefined, // The analysis data pulled from the database
                                    // All the views should read this data.
    views              : undefined, // All the views generated that consumes from analysis_board
                                    // They are included in the global object to allow dynamically
                                    // generated views (like the jobs_chart that is generated and destroyed on demand)
                                    // Instead of storing here an array of views, we store a closure that knows how to generate them
                                    // and how to update them once the analysis_board is updated
};

// wait for the DOM to be loaded 
$(document).ready(function() {
    // There are elements that have to be hidden by default
    // and only show after connection
    // TODO: Maybe there is a better way to handle this
    $(".hide_by_default").hide();

    // Listening changes to configuration options
    // TODO: This can be done via a config file (json?)
    // that is read and process to make these options
    listen_config();

    //  We are creating a hidden button for showing resources and 
    //  firing it once the analysis are displayed
    //  we are doing this to allow re-load of the resources when
    //  they are changed (without having to reload the analysis too or re-connect to the db)
    //  TODO: We may try to find a better solution for this
    $("#show_resources").hide().click(function() {
	fetch_resources();
    });

    // We initialize the refresh_data_timer
    guiHive.refresh_data_timer = setup_timer().timer(guiHive.monitorTimeout/1000);

    // Default value. Only for testing. TODO: Remove the following line
    $("#db_url").val("mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_long_mult");
    $("#Connect").click(function() {
	// We first remove the analysis_board
	analysis_board = undefined;
	$.ajax({url        : "/scripts/db_connect.pl",
		type       : "post",
		data       : "url=" + $("#db_url").val(),
		dataType   : "json",
		beforeSend : function() {showProcessing($("#connexion_msg"))},
		success    : onSuccess_dbConnect
	       });
    });
}); 

function fetch_resources() {
    var fetch_url = "/scripts/db_fetch_resource.pl";
    $.ajax({url        : fetch_url,
	    type       : "post",
	    data       : "url=" + guiHive.pipeline_url,
	    dataType   : "json",
	    beforeSend : function() {showProcessing($("#resource_details"))},
	    success    : function() {display("", fetch_url, onSuccess_fetchResources)}
	   });
}

// refresh_data_and_views retrieves the information for all the analysis
// and post them in the analysis_board
// callback is executed after a successful update of the analysis_info
function refresh_data_and_views(callback) {
    // We can't run this asynchronously if analysis_board is undefined (first run of the method)
    // So, we check first and run in async/sync mode (see the async parameter)
    console.log("UPDATING DATA AND VIEWS");
    $.ajax({url      : "/scripts/db_fetch_all_analysis.pl",
	    type     : "post",
	    data     : "url=" + $("#db_url").val(),
	    async    : analysis_board != undefined,
	    dataType : "json",
	    success  : function(allAnalysisRes) {
		if(allAnalysisRes.status != "ok") {
		    $("#log").append(allAnalysisRes.err_msg); scroll_down();
		} else {
		    guiHive.analysis_board = allAnalysisRes.out_msg;
		    // We only update the views once the data has been updated
		    callback();
		    console.log("OK");
		}
	    },
//	    complete : reset_time_to_refresh,
	   });
}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_dbConnect(res) {
    // Hidden elements are now displayed
    $(".hidden_by_default").show();
    
    // Connexion message is displayed
    var connexion_header = "<h4>Connexion Details</h4>";
    $("#connexion_msg").html(connexion_header + res.status);

    // The number of seconds to refresh is exposed
    guiHive.refresh_data_timer.div($("#secs_to_refresh"));

    // We draw the pipeline diagram
    draw_diagram(res.out_msg);

    // We activate tooltips and popups
    $("[rel=tooltip-it]").tooltip({animation:true});
    $("[rel=popup-it]").popover({animation:true, content:"kk", title:"kk doble"});

    // If there has been an error, it is reported in the "log" div
    $("#log").append(res.err_msg); scroll_down();

    // the url for the rest of the queries is set (url var is global)
    guiHive.pipeline_url = $("#db_url").val();

    // Showing the resources
    $("#show_resources").trigger('click');  // TODO: Best way to handle?

    // Now we start monitoring the analyses.
    initialize_views_and_refresh();

    // TODO: This has to be cleaned up?
//    monitor_overview();
//    monitor_pipeline_diagram();
}

function display(analysis_id, fetch_url, callback) {
    $.ajax({url        : fetch_url,
	    type       : "post",
	    data       : "url=" + guiHive.pipeline_url + "&analysis_id=" + analysis_id,
	    dataType   : "json",
	    success    : function(resp) {callback(resp, analysis_id, fetch_url)},
	   });
}

// TODO: analysis_id is not going to be used, so maybe we should move it
// to the last position (and avoid the 'undef' in the calling code)
function onSuccess_fetchResources(resourcesRes, analysis_id, fetch_url) {
    if (resourcesRes.status != "ok") {
	$("#log").append(resourcesRes.err_msg); scroll_down();
    } else {
	$("#resource_details").html(resourcesRes.out_msg);
    }
    listen_Resources(fetch_url);
}

function change_refresh_time() {
    guiHive.monitorTimeout = $(this).val()
    guiHive.refresh_data_timer.timer(guiHive.monitorTimeout/1000);
}

function listen_config() {
    $("#select_refresh_time").change(change_refresh_time);
}

function listen_Resources(fetch_url) {
    $(".update_resource").click(
	{ //reload:$("#show_resources"),
	  fetch_url:fetch_url, 
	  script:"/scripts/db_update.pl",
	  callback:onSuccess_fetchResources},
	update_db);
    $(".create_resource").click(
	{ //reload:$("#show_resources"),
	  fetch_url:fetch_url,
	  script:"/scripts/db_create.pl",
	  callback:onSuccess_fetchResources},
	update_db);
}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_fetchAnalysis(analysisRes, analysis_id, fetch_url) {
    if(analysisRes.status == "ok") {
	// We first empty any previous analysis displayed -- TODO: Not harmful, but... needed?
	$("#analysis_details").empty();

	// We populate the analysis_details div with the new analysis data
	$("#analysis_details").html(analysisRes.out_msg);

	// The details can be closed
	$("#close_analysis_details").click(function(){$("#analysis_details").empty();});
    } else {
	$("#log").append(analysisRes.err_msg); scroll_down();
	$("#connexion_msg").html(analysisRes.status);
    }
    listen_Analysis(analysis_id, fetch_url);
}

function listen_Analysis(analysis_id, fetch_url) {
    //  We activate the show/hide div toggle
    $(".toggle-div").click(function(){$(this).toggleDiv()});

    jobs_chart("#analysis_details", analysis_id);
    // We have db_update.pl and db_update2.pl
    // TODO: use a generic version (db_update.pl or db_update2.pl)
    // that can deal with both cases
    // It this is not possible, give better names
    // TODO2: Shouldn't this code be moved to the "ok" condition above?
    // TODO3: analysis_id should be named only dbID or something similar
    // to make it more clear that also resources calls update_db --
    // even if it doesn't use the dbID field
    $(".update_param").change(
	    { analysis_id:analysis_id,
	      fetch_url:fetch_url,
	      script:"/scripts/db_update.pl",
	      callback:onSuccess_fetchAnalysis},
	    update_db);

    $(".update_param").click(
	{analysis_id:analysis_id,
	 fetch_url:fetch_url,
	 script:"/scripts/db_update.pl",
	 callback:onSuccess_fetchAnalysis},
	update_db);  // This is recursive!
}

// TODO: Currently, analysis_id and fetch_url are not being used
function onSuccess_fetchJobs(jobsRes, analysis_id, fetch_url) {
    if(jobsRes.status == "ok") {
	// Datepicker format
	$.datepicker.regional[""].dateFormat = 'dd/mmo/yy';
	$.datepicker.setDefaults($.datepicker.regional['']);

	var jobs_header = "<h4>Jobs</h4>";
	$("#jobs").html(jobs_header + jobsRes.out_msg);

	// Listener to delete_input_id button:
	$(".delete_input_id").click(function(){var sel = this;
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
		// TODO: There seems to be a bug here
		// Now we have 1 extra row that is null
		// I think this happens since we have introduced the tables in the input_id field.
		// Take a look to debug!
		if (v != null) {
		    job_ids.push(v[0]); // pushed the job_ids (first column). TODO: More portable way?
		}
	    });

	    var sel = this;
	    $.ajax({url      : "/scripts/db_update2.pl",
		    type     : "post",
		    data     : jQuery.param(buildSendParams(sel)) + "&dbID=" + job_ids.join() + "&value=" + $(sel).val(),
		    dataType : "json",
		    async    : false,
		    cache    : false,
		    success  : function () {
			$.each(oTable.$('tr', {"filter":"applied"}), function(i,v) {
			    // TODO: There seems to be a bug here
			    // Now we have 1 extra row that is null (see above)
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
		loadurl    : "/scripts/db_fetch_max_retry_count.pl?url=" + guiHive.pipeline_url + "&job_id=" + job_id,
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
    var value = jQuery.parseJSON(response);
    $(this).html(value.out_msg);

    // If there exist a sibling with data-newvalueID then we activate it
    var val_sibling_id = $(this).attr("data-newValueID");
    if (val_sibling_id != undefined) {
	var val_sibling = $("#" + val_sibling_id);
	var key = $(this).html();
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

    var urlHash = {url      : guiHive.pipeline_url,
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
    var callback = obj.data.callback;
    var url = obj.data.script;
    var fetch_url = obj.data.fetch_url;
    var analysis_id = obj.data.analysis_id;
    $.ajax({url        : guiHive.pipeline_url,
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
	    // TODO: I think the log is populated twice... One in the success callback and one in the
	    // onSuccess_fetchAnalysis callback. Check!
	    complete   : function() { display(analysis_id, fetch_url, callback)}
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

    var URL = "url="+ guiHive.pipeline_url + 
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

