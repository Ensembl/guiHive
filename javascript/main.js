// Globally defined
var url = "";

// wait for the DOM to be loaded 
$(document).ready(function() { 
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

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_dbConnect(res) {
    $("#connexion_msg").html(res.status);
    $("#pipeline_diagram").html(res.analyses);
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
	$("#analysis_details").html(analysisRes.analysis_info);
    } else {
	$("#connexion_msg").html(analysisRes.status);
    }
    $(".set_val").change(function() {
	$.ajax({url        : "/scripts/db_update_analysis.pl",
		type       : "post",
		data       : "url=" + url + "&newval=" + this.value + "&column_name=" + this.id + "&analysis_id=" + this.name + "&action=" + $(this).attr("class"),
		dataType   : "json",
		beforeSend : onSend_dbUpdate,
		success    : function(updateRes) {
		    if(updateRes.status != "ok") {
			alert(updateRes.status);
		    }
		    complete: onSuccess_fetchAnalysis(analysisRes);
		}
	       });
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

