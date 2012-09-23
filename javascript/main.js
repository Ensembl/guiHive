


// wait for the DOM to be loaded 
$(document).ready(function() { 
    $("#Connect").click(function() {
	var url = $("#db_url").val()
	$.ajax({url        : "/scripts/db_connect.pl" + "#" + url,
		method     : "post",
		beforeSend : beforeFunc,
		success    : function(res) {
		    $("#connexion_msg").html(res);
		}});
    });

}); 

// function call_msg() {
//     beforeSend : beforeFunc,
//     success    : successFunc
// }

function beforeFunc() {
    alert("sending ajax request...\n");
}
