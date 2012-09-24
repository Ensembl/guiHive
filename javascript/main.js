
// wait for the DOM to be loaded 
$(document).ready(function() { 
    $("#Connect").click(function() {
	$.ajax({url        : "/scripts/db_connect.pl",
		type       : "post",
//		beforeSend : beforeFunc,
		data       : "url=" + $("#db_url").val(),
//		data       : "url=" + $("#db_url").serialize(),
		success    : function(res) {
		    $("#connexion_msg").html(res);
		}});
    });

}); 

function beforeFunc() {
    alert("url=" + $("#db_url").val())
}
