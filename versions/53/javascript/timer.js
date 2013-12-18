function setup_timer() {
    var cback       = function(){console.log("EXECUTED_CALLBACK")};
    var inner_cback = undefined;
    var inner_cback_loop = undefined;
    var tMax        = 10; // 10 seconds by default
    var stop        = true;
    var tCurr       = 0;
    var startElem   = undefined;
    var div; // undef by default

    // Closure / Object
    var tf = function() {
    };

    // LOOP
    tf.loop = function() {
	if (tCurr > tMax) {
	    tf.nowloop();
	    return;
	}
	tf.show();
	tf.increase_time();
	var tid = setTimeout(function() {tf.loop()}, 1000);
	if (stop) {
	    clearTimeout(tid);
	    $(startElem).removeAttr("disabled");
	}
    };

    // Controls
    tf.unfreeze = function() {
	if (!stop) {
	    tf.start();
	}
    };

    tf.start = function() {
	startElem = this;
	$(startElem).attr("disabled",1);
	var old_inner_cback = inner_cback;
	inner_cback_loop = function(){old_inner_cback(); tf.loop()};
	stop = false;
	tf.loop();
    };

    tf.stop = function() {
	stop = true;
    };

    tf.nowloop = function() {
	tf.reset();
	cback(inner_cback_loop);
    };

    tf.now = function() {
	tf.reset();
	cback(inner_cback);
    };

    tf.reset = function() {
	tCurr = 0;
	tf.show();
    };

    // Getters/Setters
    tf.callback = function(f) {
	if (!arguments.length) return cback;
	cback = f;
	return tf;
    };

    tf.inner_callback = function(f) {
	if (!arguments.length) return inner_cback;
	inner_cback = f;
	return tf;
    }

    tf.timer = function(t) {
	if (!arguments.length) return tMax;
	tMax = t;
	tCurr = 0;
	tf.show();
	return tf;
    };

    tf.increase_time = function() {
	tCurr++;
	return tf;
    };

    tf.div = function(elem) {
	if (!arguments.length) return div;
	div = elem;
	tf.show()
	return tf;
    };

    // misc
    tf.time_to_refresh = function() {
	return tMax - tCurr;
    };

    // Show
    tf.show = function() {
	if (div !== undefined) {
	    div.html(tf.time_to_refresh());
	}
    };

    return tf;
}
