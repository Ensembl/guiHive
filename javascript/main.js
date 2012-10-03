// Globally defined
var url = "";

// wait for the DOM to be loaded 
$(document).ready(function() { 
    // Default value. Only for testing. TODO: Remove the following line
    $("#db_url").val("mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b");
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
    $("#pipeline_diagram").html(res.out_msg);
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
}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_fetchAnalysis(analysisRes) {
    if(analysisRes.status == "ok") {
	$("#analysis_details").html(analysisRes.out_msg);
    } else {
	$("#log").append(analysisRes.err_msg); scroll_down();
	$("#connexion_msg").html(analysisRes.status);
    }
    $(".update_param").change(analysisRes, update_db);
    $(".update_param").click (analysisRes, update_db);
}

function update_db(e) {
    $.ajax({url        : "/scripts/db_update_analysis.pl",
	    type       : "post",
	    data       : "url="+url + 
                         "&newval="+this.value + 
                         "&analysis_id="+$(this).attr("data-analysisID") + 
                         "&adaptor="+$(this).attr("data-adaptor") + 
                         "&method="+$(this).attr("data-method") + 
                         "&action="+$(this).attr("data-action"),
	    dataType   : "json",
	    success    : function(updateRes) {
		if(updateRes.status != "ok") {
		    $("#log").append(updateRes.err_msg); scroll_down();
		}
		complete: onSuccess_fetchAnalysis(e.data);
	    }
	   });
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

