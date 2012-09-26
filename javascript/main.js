
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
    $(".analysis_link").click(function() {
	$.ajax({url        : "/scripts/test.pl",
//		beforeSend : onSend,
		type       : "post",
		data       : "logic_name=" + $(this).val(),
		success    : function(resp) {
		    alert(resp);
		    $("#analysis_details").html(resp);
		}
	       });
    });
}

function onSend_dbconnect() {
//    $('#connexion_msg').html('<img src="http://static.tumblr.com/d0qlne1/qVol4tb08/loading.gif" />');
    $('#connexion_msg').html('<img src="../images/preloader.gif" width="40px" height="40px"/>');
}

function onSend(req, settings) {
    alert(req);
}