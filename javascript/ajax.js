/* Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
/* Copyright [2016] EMBL-European Bioinformatics Institute

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/


// Globally defined
"use strict";
var guiHive = {
    version                   : undefined, // The guiHive/Hive version
    pipeline_url              : "",        // The url to connect to the pipeline
                                           // This is the value of $("#db_url") i.e. it is entered by the user
    refresh_data_timer        : undefined, // The timer for the next data update
    monitorTimeout            : 30000,     // Time for next data update
                                           // TODO: This has to disappear in favor of refresh_data_timer
                                           // once the pie charts get listens to the analysis_board
    analysis_board            : undefined, // The analysis data pulled from the database
                                           // All the views should read this data.
    views                     : undefined, // All the views generated that consumes from analysis_board
                                           // They are included in the global object to allow dynamically
                                           // generated views (like the jobs_chart that is generated and destroyed on demand)
                                           // Instead of storing here an array of views, we store a closure that knows how to generate them
                                           // and how to update them once the analysis_board is updated
    databaseConnectionTimeout : 60000,     // 30s
    config                    : undefined, // The values in hive_config.json 
    offset                    : 140,
};

// wait for the DOM to be loaded 
$(document).ready(function() {

    // There are elements that have to be hidden by default
    // and only shown after connection
    // TODO: Maybe there is a better way to handle this
    $(".hide_by_default").hide();

    // Listening changes to configuration options
    // TODO: This can be done via a config file (json?)
    // that is read and process to make these options
    listen_config();

    //
    var cur_http_url = $.url();
    var dir = cur_http_url.attr("directory");
    var parts = dir.split("/");
    guiHive.version = parts[2];

    // We read the hive json configuration file
    $.ajax({ url      : "./scripts/db_load_config.pl",
	     data     : "version=" + parts[2],
	     type     : "post",
	     dataType : "json",
	     timeout  : guiHive.databaseConnectionTimeout,
	     success  : function(resp) {
		 if (resp.status === "ok") {
		     guiHive.config = jQuery.parseJSON( resp.out_msg );
		 } else {
		     log(resp);
		 }
	     }
    });

    // Listening to changes in the height of the window
    $(window).on("resize", function(){
	var new_height = $(window).height() - guiHive.offset;
	$("#pipeline_diagram").css("height", new_height + "px");
	$("#pipeline_diagram > svg").attr("height", new_height);
	if (guiHive.views !== undefined) {
	    guiHive.views.getAllCharts().bubblesCloud.chart.height(new_height).centers().update();
	}
    });

    // $("#full_screen_icon")
    // 	.on("click", function()  {
    // 	    var curr_class = $("#expandable").attr("class");
    // 	    if (curr_class === "show") {
    // 		// Hiding the header:
    // 		$("#expandable").slideUp("slow", function() {$("#expandable").removeClass("show").addClass("hide")});

    // 		// Resizing different views...
    // 		var new_height = $(window).height() - guiHive.offsets.fullscreen;
    // 		console.log("SETTING NEW HEIGHT TO: " + new_height);

    // 		// ... pipeline diagram
    // 		$("#pipeline_diagram").css("height", new_height + "px");
    // 		$("#pipeline_diagram > svg").attr("height", new_height);

    // 		// ... bubbles cloud
    // 		$("#bubbles").css("height", new_height + "px");
    // 		$("#bubbles_vis").attr("height", new_height);

    // 		if (guiHive.views !== undefined) {
    // 		    guiHive.views.getAllCharts().bubblesCloud.chart.height(new_height).centers().update();
    // 		}
		
    // 		d3.select(this).attr("src", "./images/down.png");

    // 	    } else {
    // 		// Showing the header
    // 		$("#expandable").slideDown("slow", function(){$("#expandable").removeClass("hide").addClass("show")});

    // 		// Resizing different views...
    // 		var new_height = $(window).height() - guiHive.offsets.normal;

    // 		// ... pipeline diagram
    // 		$("#pipeline_diagram").css("height", new_height + "px");
    // 		$("#pipeline_diagram > svg").attr("height", new_height);

    // 		// ... bubbles cloud
    // 		$("#bubbles").css("height", new_height + "px");
    // 		$("#bubbles_vis").attr("height", new_height);

    // 		// ... and the bubbles gracefully feels attracted to the center of the view
    // 		if (guiHive.views !== undefined) {
    // 		    guiHive.views.getAllCharts().bubblesCloud.chart.height(new_height).centers().update();
    // 		}

    // 		d3.select(this).attr("src", "./images/up.png");
    // 	    }
    // 	});

    // We initialize the refresh_data_timer
    guiHive.refresh_data_timer = setup_timer().timer(guiHive.monitorTimeout/1000);

    // If the url contains database information...
    guess_database_url();

    // We populate the URL bit on the header
    $("#guiHive_url").text(guiHive.pipeline_url);
    $("#guihiveVersion").text("(v" + guiHive.version + ")");

    // $("#Connect").click(function() {
    // 	// connect();
    // 	go_to_full_url();
    // }); 

    // $("#db_url").keyup(function(e) {
    // 	if (e.keyCode === 13) {
    // 	    // connect();
    // 	    go_to_full_url();
    // 	}
    // });
});

function ask_for_number(title, ini_value, callback) {

    function validate_input () {
        var new_value = $('#number-popup-input').val();
        // ==  to allow matching a number with its stringified version
        //if (new_value == ini_value) {
            //console.log("same");
        //} else {
            callback(new_value);
        //}
        $('#number-popup-div').modal('hide');
    };
    if (ini_value == "NULL") {ini_value = 0};

    $('#number-popup-title').text(title);
    $('#number-popup-input').val(ini_value);

    $('#number-popup-div').keyup(function(e) {
        if (e.keyCode === 13) {
            validate_input();
        }
    });
    $('#number-popup-setter').on("click", function() {
        validate_input();
    });

    $('#number-popup-div').modal("show");
    $('#number-popup-div').on("shown", function(){
        $('#number-popup-input').focus();
    });
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
	guiHive.pipeline_url = loc_url;
	if (autoconnect) {
	    connect();
	}
    } else {
	alert("Not enough information to connect to db");
	// Default value. Only for testing
	// $("#db_url").val("mysql://ensro@127.0.0.1:2912/mp12_long_mult");
    }
    
}

function get_mysql_password(loc_url) {
    
    var passwd = $("#mysql_password").val();
    loc_url = loc_url.replace("xxxxx", passwd);

    $("#password-id").modal("hide");
    guiHive.pipeline_url = loc_url;
    connect();
}

// TODO: This is probably not needed anymore since the pipelines
// are reloaded
function clearPreviousPipeline() {
    guiHive.analysis_board = undefined;
 
    $("#jobs_table").remove();
}

function connect() {
    // We first remove the analysis_board. TODO: Probably not needed anymore
    clearPreviousPipeline();
    console.log("IN CONNECT");
    $.ajax({url        : "./scripts/db_connect.pl",
	    type       : "post",
	    data       : "url=" + guiHive.pipeline_url + "&version=" + guiHive.version,
	    dataType   : "json",
	    timeout    : guiHive.databaseConnectionTimeout,
	    beforeSend : show_db_access,
	    success    : onSuccess_dbConnect,
	    error      : function (x, t, m) {
		if(t==="timeout") {
		    log({err_msg : "No response from mysql sever for 10s. Try it later"});
		    $("#connection_msg").empty();
		} else {
		    log({err_msg : m});
		}
	    }
	   });
}

// refresh_data_and_views retrieves the information for all the analysis
// and post them in the analysis_board
// callback is executed after a successful update of the analysis_info
function refresh_data_and_views(callback) {
    // We can't run this asynchronously if analysis_board is undefined (first run of the method)
    // So, we check first and run in async/sync mode (see the async parameter)
    console.log("UPDATING DATA AND VIEWS ... ");
    $.ajax({url        : "./scripts/db_fetch_all_analysis.pl",
	    type       : "post",
	    data       : "url=" + guiHive.pipeline_url + "&version=" + guiHive.version,
	    async      : guiHive.analysis_board != undefined,
	    timeout    : guiHive.databaseConnectionTimeout,
	    dataType   : "json",
	    beforeSend : show_db_access,
	    success    : function(allAnalysisRes) {
		no_db_access();
		if(allAnalysisRes.status !== "ok") {
		    log(allAnalysisRes);
		} else {
		    guiHive.analysis_board = allAnalysisRes.out_msg;

		    // If we have mem and cpu information, we allow selecting color schemas for them
		    var mems = 0;
		    var cpus = 0;
		    for (var analysis in allAnalysisRes.out_msg) {
			if (allAnalysisRes.out_msg[analysis]["mem"] !== undefined) {
			    mems++;
			}
			if (allAnalysisRes.out_msg[analysis]["cpu"] !== undefined) {
			    cpus++;
			}
		    }
		    // var mems = allAnalysisRes.out_msg.filter(function(d){return (d !== null && d.mem !== undefined)});
		    // var cpus = allAnalysisRes.out_msg.filter(function(d){return (d !== null && d.cpu !== undefined)});
		    if (mems>0) {
			$("#select_analysis_colors option[value='mem']").attr("disabled", null);
		    } else {
			$("#select_analysis_colors option[value='mem']").attr("disabled", 1);
		    }
		    if (cpus>0) {
			$("#select_analysis_colors option[value='cpu']").attr("disabled", null);
		    } else {
			$("#select_analysis_colors option[value='mem']").attr("disabled", 1);
		    }
		    // We only update the views once the data has been updated
		    callback();
		    console.log("OK");
		}
	    },
	    error    : function (x, t, m) {
		no_db_access();
		if(t==="timeout") {
		    log({err_msg : "No response from mysql sever for 10s. No refresh this time"});
		}
	    }
	   });
}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_dbConnect(res) {
    if (res.status !== "ok") {
	log(res);
    } else {
	// Hidden elements are now displayed
	$(".hidden_by_default").show();
    
	// Connection message is displayed
	$("#connection_msg").html(res.out_msg.html);

	// We update the timer:
	guiHive.refresh_data_timer.stop();
	guiHive.refresh_data_timer.reset();
	// The number of seconds to refresh is exposed
	guiHive.refresh_data_timer.div($("#secs_to_refresh"));

	// We draw the pipeline diagram
	draw_diagram(res.out_msg.graph);

	// Showing the resources
        fetch_and_setup_change_listener( "scripts/db_fetch_resource.pl", "scripts/db_update_resource.pl", "#resource_details" );

	// And the pipeline-wide parameters
        fetch_and_setup_change_listener( "scripts/db_fetch_pipeline_params.pl", "scripts/db_update_nonobject.pl", "#pipeline_wide_parameters"  );

	// We load the jobs form
	$.get('./scripts/db_jobs_form.pl', {url : guiHive.pipeline_url, version : guiHive.version} ,function(data) {
	    $('#jobs_form').html(data);
	    listen_jobs();
	});
	// and table
	$.get('./static/jobs_table.html', function(data) {
	    $("#jobs_table_div").append(data);
	});

	// Now we start monitoring the analyses.
	initialize_views_and_refresh();

// Tooltips:
// For some reason I haven't been able to make the bootstrap's tooltips work with the force layout (bubbles view).
// The tootips div appear too deep in the svg hierarchy and they are not displayed (visible) at all.
// Tipsy seems to work better, so I am using it at the moment.

// Tooltips -- This should have worked with Bootstrap's tooltips, but the divs seem to be inserted in a wrong place
//    $('body').tooltip({
//	selector: '[rel=tooltip-it]'
//    });

    // We activate tipsy tooltips
	$("[rel=tooltip-it]").tipsy({
	    //	gravity  : $.fn.tipsy.autoNS,
	    gravity  : 'e',
	    fade     : true,
	    html     : true
	});
	$("[data-analysis_id=1]").tipsy('show');
    }

    return;
}

function display(analysis_id, fetch_url, callback) {
    $.ajax({url        : fetch_url,
	    type       : "post",
	    data       : "url=" + guiHive.pipeline_url + "&analysis_id=" + analysis_id + "&version=" + guiHive.version,
	    dataType   : "json",
	    success    : function(resp) {
		callback(resp, analysis_id, fetch_url)
	    },
	    error      : function(resp,error) {log({err_msg : error})},
	   });
}


function fetch_and_setup_change_listener(fetch_url, write_url, target_div) {

    var tooltip_onlyalpha = 'Only alpha-numeric characters and the underscore are allowed';
    var tooltip_uniquename = 'Parameter names have to be unique';
    var tooltip_nonempty = 'The parameter name must be defined'

    // Replace the div with the output of fetch_url
    function doFetch() {
        $.ajax({
            url        : fetch_url,
            type       : "post",
            data       : "url=" + guiHive.pipeline_url + "&version=" + guiHive.version,
            dataType   : "json",
            success    : onFetchSuccess_handler,
            error      : function(resp,error) {log({err_msg : error})},
        });
    }

    // Read the data objects and build the post data to send to write_url
    function get_url_data(ref_object) {
        var url_data = "url="+ guiHive.pipeline_url +
            "&method="+$(ref_object).attr("data-method") +
            "&" + $(ref_object).attr("data-args") +
            "&version="+guiHive.version;

        function add_links(name, f) {
            if ($(ref_object).attr(name)) {
                var blocks = $(ref_object).attr(name).split(",");
                var vals = jQuery.map(blocks, function(e,i) {
                    var parts = e.split("=");
                    return parts[0] + "=" + f($('#'+parts[1])[0]);
                });
                return "&" + vals.join("&");
            } else {
                return "";
            }
        };
        url_data = url_data + add_links('data-linkTo', function(o) {return o.value});
        url_data = url_data + add_links('data-linkToDef', function(o) {return o.defaultValue});
        return url_data
    };

    // Check that input_object has a valid key name (not empty, not duplicated, and alphanumeric only)
    function key_check(d, input_object, check_empty) {
        var new_tooltip = null;
        var control_group = $(input_object).closest('.control-group');

        if (check_empty && (input_object.value === "")) {
            new_tooltip = tooltip_nonempty;
        } else if ($(input_object).hasClass('onlyalpha') && !(input_object.value.match(/^[0-9a-zA-Z\_]*$/))) {
            new_tooltip = tooltip_onlyalpha;
        } else if ((input_object.value !== input_object.defaultValue) || control_group.hasClass("error")) {
            jQuery.map(d.find("input[id^='pw_key_']").add(d.find("#p_new_key")), function(obj, i) {
                var same_name = (obj.id !== input_object.id) && ((obj.value === input_object.value) || (obj.defaultValue === input_object.value));
                $(obj).closest('.control-group').toggleClass('warning', same_name);
                if (same_name) {
                    new_tooltip = tooltip_uniquename
                }
            });
        }
        var is_error = !!new_tooltip;
        var tooltip_placeholder = $(input_object);
        if (is_error) {
            if (!tooltip_placeholder.data("tooltip") || (tooltip_placeholder.data("tooltip").options.title !== new_tooltip)) {
                tooltip_placeholder.tooltip('destroy');
                tooltip_placeholder.tooltip({title: new_tooltip});
                tooltip_placeholder.tooltip('show');
            }
        } else {
            tooltip_placeholder.tooltip('destroy');
        }
        control_group.toggleClass("error", is_error);
        control_group.toggleClass("info", !is_error);
        return is_error;
    };

    // Setup all the listeners
    function onFetchSuccess_handler(resp) {
        if (resp.status != "ok") {
            log(resp);
            return;
        }

        var d = $(target_div);
        d.html(resp.out_msg);

        d.find("input.monitored").map( function(i, monitored_input) {
            var ref_object = $(monitored_input);

            var control_group = ref_object.parent();
            control_group.addClass('control-group');

            var input_append_group = $('<div class="input-append"></div>');
            input_append_group.appendTo(control_group);
            ref_object.appendTo(input_append_group);

            var controls_container = $('<div class="control_container"></div>');
            input_append_group.append(controls_container);
            var input_sender = $('<a class="btn btn-mini add-on"><i class="icon-ok"></i></a>');
            controls_container.append(input_sender);
            var input_restorer = $('<a class="btn btn-mini add-on"><i class="icon-refresh"></i></a>');
            controls_container.append(input_restorer);
            var targets = controls_container.children();
            targets.hide();

            $(monitored_input).keyup( function(evt) {
                var is_change = (monitored_input.value !== monitored_input.defaultValue);
                var is_valid_input = !key_check(d, this, true);
                input_restorer.toggle(is_change);
                input_sender.toggle(is_change && is_valid_input);
            });

            input_restorer.click( function(evt) {
                monitored_input.value = monitored_input.defaultValue;
                key_check(d, this, false);
                targets.hide();
                control_group.removeClass("success");
                control_group.removeClass("info");
                control_group.removeClass("error");
            });

            input_sender.click( function(evt) {
                var url_data = get_url_data(monitored_input);
                control_group.removeClass("info");
                function success(updateRes) {
                    if (updateRes.status === "ok") {
                        monitored_input.defaultValue = monitored_input.value;
                        targets.hide();
                        control_group.addClass("success");
                    } else {
                        control_group.addClass("error");
                        log(updateRes);
                    };
                };
                onClick_handler(url_data, success, null);
            });
        });

        d.find(".ajaxable_btn").click( function(evt) {
            var url_data = get_url_data(this);
            var o = $(this);
            var refresh = true;
            function success(updateRes) {
                if (updateRes.status !== "ok") {
                    log(updateRes);
                } else if (o.hasClass("remove_row")) {
                    o.closest("tr").remove();
                    refresh = false;
                };
            };
            function complete() {
                if (refresh) {
                    doFetch();
                }
            };
            onClick_handler(url_data, success, complete);
        });

        jQuery.map(d.find("ul.dropdown-menu[data-target]"), function(e,i) {
            var target = $("#" + $(e).attr("data-target"));
            var vals = [];
            jQuery.map($(e).find("a"), function(x,j) {
                vals.push(x.innerHTML);
            });
            $(target).autocomplete( {
                source: vals,
            });
            $(e).find("a").click( function(evt) {
                target.val(this.innerHTML);
            });
        });

        jQuery.map(d.find("select.combobox"), function(e,i) {
            $(e).combobox();
        });

        d.find(".control-add").keyup( function(evt) {
            var is_error = key_check(d, this, false);
            $(this).closest("tr").find(".btn").toggleClass("disabled", (is_error || (this.value === "")))
        });
    };

    function onClick_handler(url_data, fs, fc) {
        $.ajax({
            url        : write_url,
            type       : "post",
            data       : url_data,
            dataType   : "json",
            async      : false,
            cache      : false,
            success    : fs,
            complete   : fc
        });
    }

    doFetch();
}



function change_refresh_time() {
    guiHive.monitorTimeout = $(this).val()
    guiHive.refresh_data_timer.timer(guiHive.monitorTimeout/1000);
}

function listen_config() {
    $("#select_refresh_time").change(change_refresh_time);

    // TODO: This shouldn't be here. This button is not in the config pane anymore
    $("#ClearLog").click(function(){$("#log").html("Log"); $("#log-tab").css("color","#B8B8B8")});
}


function listen_jobs() {
    $("#jobs_select").change(fetch_jobs);
}

// This is the new jobs table with server-side processing
function fetch_jobs() {
    var analysis_id = $(this).find(":selected").val();
    
    var oTable = $('#jobs_table').dataTable( {
	"aoColumnDefs"  : [
	    { "fnCreatedCell"  : function(elem, cellData, rowData, rowIndex, colIndex) {
		$(elem).attr("data-method", rowData[colIndex].method);
		$(elem).attr("data-adaptor", rowData[colIndex].adaptor);
		$(elem).attr("data-linkTo", rowData[colIndex].job_label);
	    }, "aTargets" : [4,5]
	    },
	    { "fnCreatedCell" : function(elem, cellData, rowData, rowIndex, colIndex) {
		$(elem).attr("id", rowData[0].id);
	    }, "aTargets" : [0]
	    },
	    { "mRender"   : "value", "aTargets" : [0,4,5,8] },

	    { "bSortable" : false, "aTargets" : [1,2,4,9,10] },
	    { "sClass"    : "editableStatus" , "aTargets" : [4] },
	    { "sClass"    : "editableRetries", "aTargets" : [5] },
	    //	    { "bVisible": false, "aTargets": [ 3,7,8,9,10 ] },
	],
	"bServerSide"   : true,
	"bProcessing"   : true,
	"sAjaxSource"   : "./scripts/db_fetch_jobs.pl?url=" + guiHive.pipeline_url + "&analysis_id=" + analysis_id + "&version=" + guiHive.version,
	"sDom": 'C<"clear">lfrtip',
	"bRetrieve"     : false,
	"bDestroy"      : true,
//	"oColVis": {
//	    "aiExclude": [ 0,1 ],
//	},
	"fnDrawCallback" : function() {
	    // Delete input_id key/value pairs
	    $(".delete_input_id").click(function(){var sel = this;
						   $.ajax({url       : "./scripts/db_update2.pl",
							   type      : "post",
							   data      : jQuery.param(buildSendParams(sel)),
							   dataType  : "json",
							   async     : false,
							   cache     : false,
							   success   : function() {
							       oTable.fnDraw();
							   }
							  });
						  }
				       );

	    // Global updaters work on all the visible fields of the dataTable.
	    $('.update_param_all').change(function() {
		column = $(this).attr("data-column");
		column_index = $(this).attr("data-column-index");

		var job_ids = [];
		$.each(oTable._('tr', {"filter":"applied"}), function(i,v) { // applied to all visible rows via the _ method
 		    // TODO: There seems to be a bug here
		    // Now we have 1 extra row that is null
		    // I think this happens since we have introduced the tables in the input_id field.
 		    // Take a look to debug!
		    if (v != null) {
			job_ids.push(v[0].value); // pushed the job_ids (first column). TODO: More portable way
		    }
		});

		var sel = this;
		$.ajax({url      : "./scripts/db_update2.pl",
			type     : "post",
			data     : jQuery.param(buildSendParams(sel)) + "&dbID=" + job_ids.join() + "&value=" + $(sel).val(),
			dataType : "json",
			async    : false,
			cache    : false,
			success  : function () {
			    oTable.fnDraw();
			}
		       });
		    
		// We return to default in the select
		$(this).children('option:selected').removeAttr("selected");
		$(this).children('option:first-child').attr("selected","selected");
	    });

	    // WARNING: We need to send the version here but it looks as if I can't
	    // The same may happen with the other editable entries that uses db_update2.pl
	    oTable.$("td.editableInputID").editable("./scripts/db_update2.pl", {
		indicator  : "Saving...",
		tooltip    : "Click to edit...",
		event      : "dblclick",
		callback   : function(response) {
		    oTable.fnDraw();
		},
		submitdata : function() {
		    return (buildSendParams(this));
		}
	    });

	    oTable.$("td.editableStatus").editable("./scripts/db_update2.pl", {
		indicator  : "Saving...",
		tooltip    : "Click to edit...",
		data       : "{'SEMAPHORED':'SEMAPHORED','READY':'READY','RUN':'RUN','DONE':'DONE'}",
		type       : "select",
		submit     : "Ok",
		event      : "dblclick",
		callback   : function(response) {
		    oTable.fnDraw();
		},
		submitdata : function() {
		    return (buildSendParams(this));
		}
	    });
    
	    oTable.$("td.editableRetries").each(function() {
		var job_id = $(this).attr("data-linkTo");
		$(this).editable("./scripts/db_update2.pl", {
		    indicator  : "Saving...",
		    tooltip    : "Click to edit...",
		    loadurl    : "./scripts/db_fetch_max_retry_count.pl?url=" + guiHive.pipeline_url + "&job_id=" + job_id + "&version=" + guiHive.version,
		    type       : "select",
		    submit     : "Ok",
		    event      : "dblclick",
		    callback   : function(response) {
			oTable.fnDraw();
		    },
		    submitdata : function() {
			return (buildSendParams(this))
		    }
		});
	    });
	    
	},
    }).columnFilter( {
	aoColumns : [ { type : "number" },
		      { type : "number" },
		      { type : "text", bRegex : true },
		      { type : "number" },
		      { type : "select", values: [ 'SEMAPHORED', 'READY', 'DONE', 'FAILED', 'RUN' ] },
		      { type : "number-range" },
		      { type : "date-range" },
		      { type : "number-range" },
		      { type : "number" },
		      { type : "number" },
		      { type : "text", bRegex : true }
		    ],
    });

}

// res is the JSON-encoded response from the server in the Ajax call
function onSuccess_fetchAnalysis(analysisRes, analysis_id, fetch_url) {
    if(analysisRes.status === "ok") {
	// We first empty any previous analysis displayed -- TODO: Not harmful, but... needed?
	$("#analysis_details").empty();
	// We also remove any jobs_chart we may have
	guiHive.views.removeChart("jobs_chart");

	// We populate the analysis_details div with the new analysis data
	$("#analysis_details").html(analysisRes.out_msg);

	// The details can be closed
	$("#close_analysis_details").click(function(){$("#analysis_details").empty(); guiHive.views.removeChart("jobs_chart")});
	listen_Analysis(analysis_id, fetch_url);

	// We also activate the jobs table with the current analysis_id
	$("#jobs_select option[value='" + analysis_id + "']").prop('selected', true);
	$("#jobs_select option[value='" + analysis_id + "']").trigger("change");

    } else {
	log(analysisRes);
	$("#connection_msg").html(analysisRes.status);
    }
}

function listen_Analysis(analysis_id, fetch_url) {
    //  We activate the show/hide div toggle
    $(".toggle-div").click(function(){$(this).toggleDiv()});

    jobs_chart(analysis_id);

    // We have db_update.pl and db_update2.pl
    // TODO: use a generic version (db_update.pl or db_update2.pl)
    // that can deal with both cases
    // It this is not possible, give better names
    // TODO: analysis_id should be named only dbID or something similar
    // to make it more clear that also resources calls update_db --
    // even if it doesn't use the dbID field
    $("select.update_param").on('focus', function() {
        $(this).data.ini_value = this.value;
    } );
    $("select.update_param").change(
	    { analysis_id:analysis_id,
	      fetch_url:fetch_url,
	      script:"./scripts/db_update.pl",
	      callback:onSuccess_fetchAnalysis},
	    update_db);

    $("a.update_param").click(
	{analysis_id:analysis_id,
	 fetch_url:fetch_url,
	 script:"./scripts/db_update.pl",
	 callback:onSuccess_fetchAnalysis},
	update_db);  // This is recursive!

    $(".job_command").click(function(){
	var sel = this;
	$.ajax({url        : "./scripts/db_commands.pl",
		data       : jQuery.param(buildSendParams(sel)) + "&analysis_id=" + $(sel).attr('data-analysisid') + "&version=" + guiHive.version,
		async      : true,
		dataType   : "json",
		beforeSend : show_db_access,
		success  : function (resp) {
		    console.log(resp);
		    no_db_access();
		    if (resp.status !== "ok") {
			log(resp);
		    } else {
			guiHive.refresh_data_timer.now();
		    }
		}
	       });
    });

}

function buildSendParams(obj) {
    var value = "";
    if ($(obj).attr("data-linkTo")) {
	var elem = $('#'+$(obj).attr("data-linkTo"));
	value = $(elem).text();
    }

    var urlHash = {url      : guiHive.pipeline_url,
		   adaptor  : $(obj).attr("data-adaptor"),
		   method   : $(obj).attr("data-method"),
		  };

    if (value != "") {
	urlHash.dbID = value;
    }

    // If the update is associated with a key/value pair
    if ($(obj).attr("data-key")) {
	urlHash.key = $(obj).attr("data-key");
    }

    urlHash.version = guiHive.version;

    return (urlHash);
}

function update_db(obj) {
    var callback = obj.data.callback;
    var url = obj.data.script;
    var fetch_url = obj.data.fetch_url;
    var analysis_id = obj.data.analysis_id;
    var payload = buildURL(this);
    if (!payload) {return};
    $.ajax({url        : url,
	    type       : "post",
	    data       : payload,
	    dataType   : "json",
	    async      : false,
	    cache      : false,
	    success    : function(updateRes) {
		if(updateRes.status !== "ok") {
		    log(updateRes);
		};
	    },
	    // TODO: I think the log is populated twice... One in the success callback and one in the
	    // onSuccess_fetchAnalysis callback. Check!
	    complete   : function() { display(analysis_id, fetch_url, callback)}
	   });
}

// TODO: Duplicated with buildSendParams. It would be nice to merge both
function buildURL(obj) {
    var value = "";
    if ($(obj).attr("data-linkTo")) {
	var ids = $(obj).attr("data-linkTo").split(",");
	var vals = jQuery.map(ids, function(e,i) {
	    var elem = $('#'+e);
	    if ($(elem).is("span")) {
		return $(elem).attr("data-value")
	    } else {
		return $(elem).val();
	    }
	});
	value = vals.join(",");
    } else {
	value = obj.value;
    }

    if (value == "...") {
        ask_for_number($(obj).attr("data-method"), $(obj).data.ini_value, function(x) {obj.add(new Option(x, x, true)); $(obj).change()} );
        return;
    }

    var URL = "url="+ guiHive.pipeline_url + 
        "&args="+encodeURIComponent(value) + 
        "&adaptor="+$(obj).attr("data-adaptor") + 
        "&method="+$(obj).attr("data-method") +
	"&version="+guiHive.version;
    if ($(obj).attr("data-analysisID")) {
	URL = URL.concat("&analysis_id="+$(obj).attr("data-analysisID"));
    }
    if ($(obj).attr("data-fields")) {
	URL = URL.concat("&fields="+$(obj).attr("data-fields"));
    }

    return(URL);
}

function show_db_access() {
    $("#refreshing").html('<img src="./images/485.GIF" width="22px" height="22px"></img>');
}

function no_db_access() {
    $("#refreshing").html('');
}

function onSend(req, settings) {
    alert(JSON.stringify(this));
}

// There seems not to be good ways to automatically fire methods
// when a div has change. This is a bit ugly, but other alternatives doesn't look
// promising either. Anyway, we can implement something like:
// http://stackoverflow.com/questions/3233991/jquery-watch-div/3234646#3234646
// or (non-IE, AFAIK):
// http://stackoverflow.com/questions/4979738/fire-jquery-event-on-div-change
function scroll_down() {
    $("#logContainer").scrollTop($("#log").height()+10000000); // TODO: Try to avoid this arbitrary addition
}

function log(res) {
    // We first see if we had a version error. These are treated differently
    if (res.status === "VERSION MISMATCH") {
	var versions = res.err_msg.split(" ");
	alert("Code version (" + versions[0] + ") and DB version (" + versions[1] + ") mismatch. You will be redirected to the correct code version of your hive database");
	redirect(versions[1]);
	return;
    }

    // If not a version error, we log the error message
    var msg = res.err_msg;
    if (msg !== "") {
	// Now, new messages substitute old ones
	$("#log").text(msg); scroll_down();
	$("#log-tab").css("color", "red");
    }
    return
}

function redirect(new_version) {
    var loc_url = guiHive.pipeline_url;
    var cur_http_url = $.url();
    console.log(cur_http_url);
    var new_http_url = cur_http_url.attr("base") +
	"/versions/" + new_version + "/?" +
	cur_http_url.attr("query");
    window.location.href=new_http_url;
}
