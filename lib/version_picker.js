"use strict"

$(document).ready(function() {
    // $("#db_url").val("mysql://ensro@127.0.0.1:2911/mp12_long_mult");

    console.log("Taking old urls");
    var old_urls_cookie = $.cookie('guihive_urls');
    var old_urls_obj = {};
    if (old_urls_cookie !== undefined) {
	old_urls_obj = JSON.parse(old_urls_cookie);
    }
    var old_urls = Object.getOwnPropertyNames(old_urls_obj);
    console.log("OLD_URLS");
    console.log(old_urls);
    if (old_urls.length) {
	$("#cached_connections").append("<p>Previous connections:</p>");
	for (var i=0; i<old_urls.length; i++) {
	    $("<p class='cached_conn_link'/>").appendTo("#cached_connections").html("<a style='cursor:pointer;'>" + old_urls[i] + "</a>");
	}
	$(".cached_conn_link").on("click", function(){go_to_version_url($(this).text())});
    }

    $("#Connect").click(function() {
        go_to_version_url($("#db_url").val());
    });

// TODO: This is not working atm
    $("#db_url").keyup(function(e) {
	if (e.keyCode === 13) {
	    go_to_version_url($("#db_url").val());
	}
    });

});

// TODO: alert calls should be changed for proper (i.e. less intrussive) messages
function go_to_version_url (full_url) {
    $.ajax( { url      : "./scripts/db_version.pl",
	      data     : "url=" + full_url,
	      dataType : "json",
	      success  : function(dbConn) {
		  if (dbConn.status !== "FAILED") {

		      // The url is added to the cookie
		      $.cookie.json = true;
		      var guihive_cookie = $.cookie('guihive_urls');
		      var cookie_obj = {};
		      if (guihive_cookie !== undefined) {
			  cookie_obj = guihive_cookie;
		      }
		      cookie_obj[full_url] = 1;
		      $.cookie('guihive_urls', cookie_obj, {expires : 7});

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
		      if (dbConn.out_msg.passwd !== null) {
			  new_http_url = new_http_url + "&passwd=xxxxx";
		      }
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
