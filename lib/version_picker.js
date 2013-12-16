"use strict"

$(document).ready(function() {
    // $("#db_url").val("mysql://ensro@127.0.0.1:2911/mp12_long_mult");
    guess_database_url();
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

function guess_database_url () {

    // Get the URL in case we have something there                                                                  
    var url = $.url();
    var loc = {};
    loc.user   = url.param("username");
    loc.passwd = url.param("passwd");
    loc.port   = url.param("port");
    loc.dbname = url.param("dbname");
    loc.server = url.param("host");
    loc.driver = url.param("driver") || "mysql";

    var autoconnect = false;
    if (loc.user !== undefined && loc.server !== undefined && loc.dbname !== undefined) {
        var loc_url = loc.driver + "://" + loc.user;
        if (loc.passwd !== undefined) {
	    console.log("We need a password");
            loc_url = loc_url + ":" + loc.passwd;

            $("#password-id").modal("show");
            $("#password-id").on("shown", function(){
                $("#mysql_password").focus();
            });

            $("#mysql_password").keyup(function(e) {
                if (e.keyCode === 13) {
                    get_mysql_password(loc_url);
                }
            });

            $("#set_mysql_passwd").on("click", function(){
                get_mysql_password(loc_url);
            });
        } else {
            autoconnect = true;
        }
        loc_url = loc_url + "@" + loc.server;
        if (loc.port !== "null") {
            loc_url = loc_url + ":" + loc.port;
        }
        loc_url = loc_url + "/" + loc.dbname;
        if (autoconnect) {
	    console.log("DB_URL: " + loc_url);
	    go_to_version_url(loc_url);
        }
    } else {
	var old_urls_cookie = $.cookie('guihive_urls');
	var old_urls_obj = {};
	if (old_urls_cookie !== undefined) {
	    old_urls_obj = JSON.parse(old_urls_cookie);
	}
	var old_urls = Object.getOwnPropertyNames(old_urls_obj);
	if (old_urls.length) {
	    $("#cached_connections").append("<p>Previous connections:</p>");
	    for (var i=0; i<old_urls.length; i++) {
		$("<p class='cached_conn_link'/>").appendTo("#cached_connections").html("<a style='cursor:pointer;'>" + old_urls[i] + "</a>");
	    }
	    $(".cached_conn_link").on("click", function(){$("#db_url").val($(this).find("a").text())})
	}
	
	$("#Connect").click(function() {
            go_to_version_url($("#db_url").val());
	});
	
	$("#db_url").keyup(function(e) {
	    if (e.keyCode === 13) {
		go_to_version_url($("#db_url").val());
	    }
	});

    }

}

function get_mysql_password(loc_url) {

    var passwd = $("#mysql_password").val();
    loc_url = loc_url.replace("xxxxx", passwd);

    $("#password-id").modal("hide");
    go_to_version_url(loc_url);
}
