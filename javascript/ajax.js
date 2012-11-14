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
    monitor_analysis();
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
	$.datepicker.regional[""].dateFormat = 'dd/mm/yy';
	$.datepicker.setDefaults($.datepicker.regional['']);
	$("#jobs").html(jobsRes.out_msg);
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
			    ]
	    });

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
		   dbID     : value,
		   adaptor  : $(obj).attr("data-adaptor"),
		   method   : $(obj).attr("data-method"),
		  };

    console.log(urlHash);
    return (urlHash);
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
	    console.log("ELEM: " + $(elem).text());
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
