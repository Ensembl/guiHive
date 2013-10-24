// Globally defined
"use strict";
var guiHive = {
    pipeline_url              : "",        // The url to connect to the pipeline
                                           // This is the value of $("#db_url") i.e. it is entered by the user
    refresh_data_timer        : undefined, // The timer for the next data update
    monitorTimeout            : 30000,     // Time for next data update
                                           // TODO: This has to disappear in favor of refresh_data_timer
                                           // once the pie charts get listens to the analysis_board
    analysis_board            : undefined, // The analysis data pulled from the database
                                           // All the views should read this data.
    views                     : undefined, // All the views generated that consumes from analysis_board
                                           // They are included in the global object to allow dynamically
                                           // generated views (like the jobs_chart that is generated and destroyed on demand)
                                           // Instead of storing here an array of views, we store a closure that knows how to generate them
                                           // and how to update them once the analysis_board is updated
    databaseConnectionTimeout : 60000,     // 30s
    config                    : undefined  // The values in hive_config.json 
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


    // We read the hive json configuration file
    $.ajax({ url      : "/scripts/db_load_config.pl",
	     data     : "url=dummy",  // To keep the server happy (TODO: better way to handle this)
	     type     : "post",
	     dataType : "json",
	     timeout  : guiHive.databaseConnectionTimeout,
	     success  : function(resp) {
		 if (resp.status === "ok") {
		     guiHive.config = jQuery.parseJSON( resp.out_msg );
		 } else {
		     log(resp.err_msg);
		 }
	     }
    });

    // We initialize the refresh_data_timer
    guiHive.refresh_data_timer = setup_timer().timer(guiHive.monitorTimeout/1000);

    // If the url contains database information...
    guess_database_url();

    $("#Connect").click(function() {
	// connect();
	go_to_full_url();
    }); 

    $("#db_url").keyup(function(e) {
	if (e.keyCode === 13) {
	    // connect();
	    go_to_full_url();
	}
    });
});

function go_to_full_url () {
    var full_url = $("#db_url").val();

    $.ajax({
	url      : "/scripts/url_parser.pl",
	type     : "post",
	data     : "url=" + full_url,
	dataType : "json",
	async    : false,
	success  : function(dbConn) {
	    if (dbConn.status !== "FAILED") {
		console.log(dbConn.out_msg);
		var http_url = $.url();
		var new_http_url = "http://" + http_url.attr("host") + ":" + http_url.attr("port") + "/?username=" + dbConn.out_msg.user + "&host=" + dbConn.out_msg.host + "&dbname=" + dbConn.out_msg.dbname + "&port=" + dbConn.out_msg.port;
		if (dbConn.out_msg.passwd !== undefined && dbConn.out_msg.passwd !== '') {
		    new_http_url = new_http_url + "&passwd=xxxxx";
		}
		window.location.href = new_http_url;
	    } else {
		log(dbConn);
	    }
	},
	error      : function (x, t, m) {
	    if(t==="timeout") {
		log({err_msg : "No response from mysql sever for 10s. Try it later"});
		$("#connexion_msg").empty();
	    } else {
		log({err_msg : m});
	    }
	}
    });
}

function guess_database_url () {

    // Get the URL in case we have something there
    var url = $.url();
    var loc = {};
    loc.user   = url.param("username");
    loc.passwd = url.param("passwd");
    loc.port   = url.param("port");
    loc.dbname = url.param("dbname");
    loc.server = url.param("host");

    if (loc.user !== undefined && loc.server !== undefined && loc.dbname !== undefined) {
	var autoconnect = false;
	var loc_url = "mysql://" + loc.user;
	if (loc.passwd !== undefined) {
	    loc_url = loc_url + ":" + loc.passwd;

	    $("#password-id").modal("show");
	    $("#password-id").on("shown", function(){
		$("#mysql_password").focus();
	    });

	    $("#mysql_password").keyup(function(e) {
		if (e.keyCode === 13) {
		    get_mysql_password(loc_url);
		}
	    });

	    $("#set_mysql_passwd").on("click", function(){
		get_mysql_password(loc_url);
	    });
	} else {
	    autoconnect = true;
	}
	loc_url = loc_url + "@" + loc.server;
	if (loc.port !== "null") {
	    loc_url = loc_url + ":" + loc.port;
	}
	loc_url = loc_url + "/" + loc.dbname;
	$("#db_url").val(loc_url);
	if (autoconnect) {
	    guiHive.pipeline_url = loc_url;
	    connect();
	}
    } else {
	// Default value. Only for testing
	$("#db_url").val("mysql://ensro@127.0.0.1:2912/mp12_long_mult");
    }
    
}

function get_mysql_password(loc_url) {
    
    var passwd = $("#mysql_password").val();
    loc_url = loc_url.replace("xxxxx", passwd);

    $("#password-id").modal("hide");
    guiHive.pipeline_url = loc_url;
    connect();
}

function clearPreviousPipeline() {
    guiHive.analysis_board = undefined;
 
    $("#jobs_table").remove();
}

function connect() {
    // We first remove the analysis_board
    clearPreviousPipeline();

    $.ajax({url        : "/scripts/db_connect.pl",
	    type       : "post",
	    data       : "url=" + guiHive.pipeline_url, //$("#db_url").val(),
	    dataType   : "json",
	    timeout    : guiHive.databaseConnectionTimeout,
	    beforeSend : function() {showProcessing($("#connexion_msg"))},
	    success    : onSuccess_dbConnect,
	    error      : function (x, t, m) {
		if(t==="timeout") {
		    log({err_msg : "No response from mysql sever for 10s. Try it later"});
		    $("#connexion_msg").empty();
		} else {
		    log({err_msg : m});
		}
	    }
	   });
}


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
    console.log("UPDATING DATA AND VIEWS ... ");
    $.ajax({url      : "/scripts/db_fetch_all_analysis.pl",
	    type     : "post",
	    data     : "url=" + guiHive.pipeline_url, //$("#db_url").val(),
	    async    : guiHive.analysis_board != undefined,
	    timeout  : guiHive.databaseConnectionTimeout,
	    dataType : "json",
	    success  : function(allAnalysisRes) {
		if(allAnalysisRes.status !== "ok") {
		    log(allAnalysisRes);
//		    $("#log").append(allAnalysisRes.err_msg); scroll_down();
		} else {
		    guiHive.analysis_board = allAnalysisRes.out_msg;
		    // We only update the views once the data has been updated
		    callback();
		    console.log("OK");
		}
	    },
	    error    : function (x, t, m) {
		if(t==="timeout") {
		    log({err_msg : "No response from mysql sever for 10s. No refresh this time"});
		}
	    }
	   });
}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_dbConnect(res) {

    // Hidden elements are now displayed
    $(".hidden_by_default").show();
    
    // Connexion message is displayed
    var connexion_header = "<h4>Connexion Details</h4>";
    $("#connexion_msg").html(connexion_header + res.status);

    // We update the timer:
    guiHive.refresh_data_timer.stop();
    guiHive.refresh_data_timer.reset();
    // The number of seconds to refresh is exposed
    guiHive.refresh_data_timer.div($("#secs_to_refresh"));

    // We draw the pipeline diagram
    draw_diagram(res.out_msg);

    // If there has been an error, it is reported in the "log" div
    log(res);

    // the url for the rest of the queries is set (url var is global)
    // guiHive.pipeline_url = $("#db_url").val();

    // Showing the resources
    $("#show_resources").trigger('click');  // TODO: Best way to handle?

    // We load the jobs form
    $.get('/scripts/db_jobs_form.pl', {url : guiHive.pipeline_url} ,function(data) {
	$('#jobs_form').html(data);
	listen_jobs();
    });
    // and table
    $.get('/static/jobs_table.html', function(data) {
	$("#jobs_table_div").append(data);
    });
    
    // Now we start monitoring the analyses.
    initialize_views_and_refresh();

// Tooltips:
// For some reason I haven't been able to make the bootstrap's tooltips work with the force layout (bubbles view).
// The tootips div appear too deep in the svg hierarchy and thery are not displayed (visible) at all.
// Tipsy seems to work better, so I am using it at the moment.

// Tooltips -- This should have worked with Bootstrap's tooltips, but the divs seem to be inserted in a wrong place
//    $('body').tooltip({
//	selector: '[rel=tooltip-it]'
//    });

    // We activate tipsy tooltips
    $("[rel=tooltip-it]").tipsy({
//	gravity  : $.fn.tipsy.autoNS,
	gravity  : 'e',
	fade     : true,
	html     : true
    });
    $("[data-analysis_id=1]").tipsy('show');
//    $("[rel=popup-it]").popover({animation:true, content:"kk", title:"kk doble"});


    return;
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
	log(resourcesRes);
//	$("#log").append(resourcesRes.err_msg); scroll_down();
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

    // TODO: This shouldn't be here. This button is not in the config pane anymore
    $("#ClearLog").click(function(){$("#log").html("Log"); $("#log-tab").css("color","#B8B8B8")});
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

function listen_jobs() {
    $("#jobs_select").change(fetch_jobs);
}

// This is the new jobs table with server-side processing
function fetch_jobs() {
    var analysis_id = $(this).find(":selected").val();
    
    var oTable = $('#jobs_table').dataTable( {
	"aoColumnDefs"  : [
	    { "fnCreatedCell"  : function(elem, cellData, rowData, rowIndex, colIndex) {
		$(elem).attr("data-method", rowData[colIndex].method);
		$(elem).attr("data-adaptor", rowData[colIndex].adaptor);
		$(elem).attr("data-linkTo", rowData[colIndex].job_label);
	    }, "aTargets" : [4,5,9]
	    },
	    { "fnCreatedCell" : function(elem, cellData, rowData, rowIndex, colIndex) {
		$(elem).attr("id", rowData[0].id);
	    }, "aTargets" : [0]
	    },
	    { "mRender"   : "value", "aTargets" : [0,4,5,9] },

	    { "bSortable" : false, "aTargets" : [1,2,4,10,11] },
	    { "sClass"    : "editableStatus" , "aTargets" : [4] },
	    { "sClass"    : "editableRetries", "aTargets" : [5] },
	    //	    { "bVisible": false, "aTargets": [ 3,7,8,9,10 ] },
	],
	"bServerSide"   : true,
	"bProcessing"   : true,
	"sAjaxSource"   : "/scripts/db_fetch_jobs.pl?url=" + guiHive.pipeline_url + "&analysis_id=" + analysis_id,
	"sDom": 'C<"clear">lfrtip',
	"bRetrieve"     : false,
	"bDestroy"      : true,
//	"oColVis": {
//	    "aiExclude": [ 0,1 ],
//	},
	"fnDrawCallback" : function() {
	    // Delete input_id key/value pairs
	    $(".delete_input_id").click(function(){var sel = this;
						   $.ajax({url       : "/scripts/db_update2.pl",
							   type      : "post",
							   data      : jQuery.param(buildSendParams(sel)),
							   dataType  : "json",
							   async     : false,
							   cache     : false,
							   success   : function() {
							       oTable.fnDraw();
							   }
							  });
						  }
				       );

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
			job_ids.push(v[0].value); // pushed the job_ids (first column). TODO: More portable way
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
			    oTable.fnDraw();
			}
		       });
		    
		// We return to default in the select
		$(this).children('option:selected').removeAttr("selected");
		$(this).children('option:first-child').attr("selected","selected");
	    });

	    oTable.$("td.editableInputID").editable("/scripts/db_update2.pl", {
		indicator  : "Saving...",
		tooltip    : "Click to edit...",
		event      : "dblclick",
		callback   : function(response) {
		    oTable.fnDraw();
		},
		submitdata : function() {
		    return (buildSendParams(this));
		}
	    });

	    oTable.$("td.editableStatus").editable("/scripts/db_update2.pl", {
		indicator  : "Saving...",
		tooltip    : "Click to edit...",
		data       : "{'SEMAPHORED':'SEMAPHORED','READY':'READY','RUN':'RUN','DONE':'DONE'}",
		type       : "select",
		submit     : "Ok",
		event      : "dblclick",
		callback   : function(response) {
		    oTable.fnDraw();
		},
		submitdata : function() {
		    return (buildSendParams(this));
		}
	    });
    
	    oTable.$("td.editableRetries").each(function() {
		var job_id = $(this).attr("data-linkTo");
		$(this).editable("/scripts/db_update2.pl", {
		    indicator  : "Saving...",
		    tooltip    : "Click to edit...",
		    loadurl    : "/scripts/db_fetch_max_retry_count.pl?url=" + guiHive.pipeline_url + "&job_id=" + job_id,
		    type       : "select",
		    submit     : "Ok",
		    event      : "dblclick",
		    callback   : function(response) {
			oTable.fnDraw();
		    },
		    submitdata : function() {
			return (buildSendParams(this))
		    }
		});
	    });
	    
	},
    }).columnFilter( {
	aoColumns : [ { type : "number" },
		      { type : "number" },
		      { type : "text", bRegex : true },
		      { type : "number" },
		      { type : "select", values: [ 'SEMAPHORED', 'READY', 'DONE', 'FAILED', 'RUN' ] },
		      { type : "number-range" },
		      { type : "date-range" },
		      { type : "number-range" },
		      { type : "number" },
		      { type : "number" },
		      { type : "number" },
		      { type : "text", bRegex : true }
		    ],
    });

}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_fetchAnalysis(analysisRes, analysis_id, fetch_url) {
    if(analysisRes.status === "ok") {
	// We first empty any previous analysis displayed -- TODO: Not harmful, but... needed?
	$("#analysis_details").empty();
	// We also remove any jobs_chart we may have
	guiHive.views.removeChart("jobs_chart");

	// We populate the analysis_details div with the new analysis data
	$("#analysis_details").html(analysisRes.out_msg);

	// The details can be closed
	$("#close_analysis_details").click(function(){$("#analysis_details").empty(); guiHive.views.removeChart("jobs_chart")});
	listen_Analysis(analysis_id, fetch_url);
    } else {
	log(analysisRes);
//	$("#log").append(analysisRes.err_msg); scroll_down();
	$("#connexion_msg").html(analysisRes.status);
    }
}

function listen_Analysis(analysis_id, fetch_url) {
    //  We activate the show/hide div toggle
    $(".toggle-div").click(function(){$(this).toggleDiv()});

    jobs_chart(analysis_id);

    // We have db_update.pl and db_update2.pl
    // TODO: use a generic version (db_update.pl or db_update2.pl)
    // that can deal with both cases
    // It this is not possible, give better names
    // TODO: analysis_id should be named only dbID or something similar
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

    $(".job_command").click(function(){
	var sel = this;
	$.ajax({url      : "/scripts/db_commands.pl",
		data     : jQuery.param(buildSendParams(sel)) + "&analysis_id=" + $(sel).attr('data-analysisid'),
		async    : true,
		success  : function () {
		    guiHive.refresh_data_timer.now();
		}
	       });
    });

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
    $.ajax({url        : url, //guiHive.pipeline_url,
	    type       : "post",
	    data       : buildURL(this),
	    dataType   : "json",
	    async      : false,
	    cache      : false,
	    success    : function(updateRes) {
		if(updateRes.status != "ok") {
		    log(updateRes);
//		    $("#log").append(updateRes.err_msg); scroll_down();
		};
	    },
//	    complete   :  function() {$(button).trigger('click')},
	    // TODO: I think the log is populated twice... One in the success callback and one in the
	    // onSuccess_fetchAnalysis callback. Check!
	    complete   : function() { display(analysis_id, fetch_url, callback)}
	   });
}

// TODO: Duplicated with buildSendParams. It would be nice to merge both
function buildURL(obj) {
    var value = "";
    if ($(obj).attr("data-linkTo")) {
	var ids = $(obj).attr("data-linkTo").split(",");
	var vals = jQuery.map(ids, function(e,i) {
	    var elem = $('#'+e);
	    console.log(elem);
	    if ($(elem).is("span")) {
		return $(elem).attr("data-value")
	    } else {
		return $(elem).val();
		//return $(elem).attr("value")
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
    $("#logContainer").scrollTop($("#log").height()+10000000); // TODO: Try to avoid this arbitrary addition
}

function log(res) {
    if (res.err_msg !== "") {
	$("#log").append(res.err_msg); scroll_down();
	$("#log-tab").css("color","red");
    }
    return
}
