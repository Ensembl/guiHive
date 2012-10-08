// Globally defined
var url = "";

// wait for the DOM to be loaded 
$(document).ready(function() { 
    // Default value. Only for testing. TODO: Remove the following line
    $("#db_url").val("mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69a2");
    $("#Connect").click(function() {
	$.ajax({url        : "/scripts/db_connect.pl",
		type       : "post",
		data       : "url=" + $("#db_url").val(),
		dataType   : "json",
		beforeSend : onSend_dbConnect,
		success    : onSuccess_dbConnect
	       });
    });

}); 

// There seems not to be good ways to automatically fire methods
// when a div has change. This is a bit ugly, but other alternatives doesn't look
// promising either. Anyway, we can implement something like:
// http://stackoverflow.com/questions/3233991/jquery-watch-div/3234646#3234646
// or (non-IE, AFAIK):
// http://stackoverflow.com/questions/4979738/fire-jquery-event-on-div-change
function scroll_down() {
    $("#log").scrollTop($("#log").height()+10000000); // TODO: Try to avoid this arbitrary addition
}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_dbConnect(res) {
    $("#connexion_msg").html(res.status);
    $("#pipeline_diagram").html(res.out_msg.analyses);
    $("#resource_details").html(res.out_msg.resources);
    $("#log").append(res.err_msg); scroll_down();
    url = $("#db_url").val();
    $(".analysis_link").click(function() {
	$.ajax({url        : "/scripts/db_fetch_analysis.pl",
		type       : "post",
		data       : "url=" + url + "&logic_name=" + this.id,
		dataType   : "json",
		success    : onSuccess_fetchAnalysis
	       });
    });
    $(".update_param").click (analysis, update_db);
}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_fetchAnalysis(analysisRes) {
    var analysis = this;
    if(analysisRes.status == "ok") {
	$("#analysis_details").html(analysisRes.out_msg);
    } else {
	$("#log").append(analysisRes.err_msg); scroll_down();
	$("#connexion_msg").html(analysisRes.status);
    }
    $(".update_param").change(analysis, update_db);
    $(".update_param").click (analysis, update_db);
}

function update_db(obj) {
    var analysis = obj;
    $.ajax({url        : "/scripts/db_update_analysis.pl",
	    type       : "post",
	    data       : buildURL(this),
	    dataType   : "json",
	    success    : function(updateRes) {
		if(updateRes.status != "ok") {
		    $("#log").append(updateRes.err_msg); scroll_down();
		};
	    },
	    complete   : $(analysis).trigger('click'),
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
        "&analysis_id="+$(obj).attr("data-analysisID") + 
        "&adaptor="+$(obj).attr("data-adaptor") + 
        "&method="+$(obj).attr("data-method");
    return(URL);
}

function onSend_dbConnect() {
    $('#connexion_msg').html('<img src="../images/preloader.gif" width="40px" height="40px"/>');
}

function onSend_dbUpdate() {
    $('#analysis_details').html('<img src="../images/preloader.gif" width="40px" height="40px"/>');
}

function onSend(req, settings) {
    alert(JSON.stringify(this));
}

