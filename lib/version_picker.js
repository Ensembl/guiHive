"use strict"

$(document).ready(function() {
    $("#db_url").val("mysql://ensro@127.0.0.1:2911/mp12_long_mult");

    $("#Connect").click(function() {
        go_to_version_url();
    });

    $("#db_url").keyup(function(e) {
	if (e.keycode === 13) {
	    go_to_full_url();
	}
    });

});

// TODO: alert calls should be changed for proper (i.e. less intrussive) messages
function go_to_version_url () {
    var full_url = $("#db_url").val();
    console.log(full_url); 
    $.ajax( { url      : "./scripts/db_version.pl",
	      data     : "url=" + full_url,
	      dataType : "json",
	      success  : function(dbConn) {
		  console.log(dbConn);
		  if (dbConn.status !== "FAILED") {
		      var cur_http_url = $.url();
		      var new_http_url = "http://" +
			  cur_http_url.attr("host") +
			  ":" +
			  cur_http_url.attr("port") +
			  "/versions/" +
			  dbConn.out_msg.db_version +
			  "/?username=" +
			  dbConn.out_msg.user +
			  "&host=" +
			  dbConn.out_msg.host +
			  "&dbname=" +
			  dbConn.out_msg.dbname +
			  "&port=" +
			  dbConn.out_msg.port;
		      console.log(new_http_url);
		      window.location.href = new_http_url;
		  } else {
		      alert(dbConn);
		  }
	      },
	      error    : function (x, t, m) {
		  if (t==="timeout") {
		      alert("No response from mysql server for 10s. Try it later");
		  } else {
		      alert(m);
		  }
	      }
	    }
	  );
}
