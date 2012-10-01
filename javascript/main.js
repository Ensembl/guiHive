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

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_dbConnect(res) {
    $("#connexion_msg").html(res.status);
    $("#pipeline_diagram").html(res.out_msg);
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
	$("#connexion_msg").html(analysisRes.status);
    }
    $(".set_val").change(analysisRes, update_db);
    $(".delete_param").click(analysisRes, update_db);
}

function update_db(e) {
    $.ajax({url        : "/scripts/db_update_analysis.pl",
	    type       : "post",
	    data       : "url=" + url + "&newval=" + this.value + "&column_name=" + this.id + "&analysis_id=" + this.name + "&action=" + $(this).attr("class"),
	    dataType   : "json",
	    success    : function(updateRes) {
		if(updateRes.status != "ok") {
		    alert(updateRes.status);
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

