
// wait for the DOM to be loaded 
$(document).ready(function() { 
    $("#Connect").click(function() {
	$.ajax({url        : "/scripts/db_connect.pl",
		type       : "post",
		data       : "url=" + $("#db_url").val(),
		success    : function(res) {
		    var resObj = JSON.parse(res)
		    $("#connexion_msg").html(resObj.status);
		    $("#pipeline_diagram").html(resObj.analyses);
		}});
    });

}); 

function beforeFunc() {
    alert("url=" + $("#db_url").val())
}
