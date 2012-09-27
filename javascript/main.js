// Globally defined
var url = "";

// wait for the DOM to be loaded 
$(document).ready(function() { 
    $("#Connect").click(function() {
	$.ajax({url        : "/scripts/db_connect.pl",
		type       : "post",
		data       : "url=" + $("#db_url").val(),
		dataType   : "json",
		beforeSend : onSend_dbconnect,
		success    : onSuccess
	       });
    });

}); 

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess(res) {
    $("#connexion_msg").html(res.status);
    $("#pipeline_diagram").html(res.analyses);
    url = $("#db_url").val();
    $(".analysis_link").click(function() {
	$.ajax({url        : "/scripts/db_fetch_analyis.pl",
//		beforeSend : onSend,
		type       : "post",
		dataType   : "json",
		data       : "url=" + url + "&logic_name=" + this.id,
		success    : function(resp) {
		    if (resp.status == "ok") {
			$("#analysis_details").html(resp.analysis_info);	
		    } else {
			$("#connexion_msg").html(resp.status);
		    }
		}
	       });
    });
}

function onSend_dbconnect() {
//    $('#connexion_msg').html('<img src="http://static.tumblr.com/d0qlne1/qVol4tb08/loading.gif" />');
    $('#connexion_msg').html('<img src="../images/preloader.gif" width="40px" height="40px"/>');
}

function onSend(req, settings) {
    alert(JSON.stringify(this));
}