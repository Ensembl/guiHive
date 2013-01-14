function setup_timer() {
    var cback = function(){console.log("EXECUTED_CALLBACK")};
    var timer = 10; // 10 seconds by default
    var stop  = false;
    var tCurr = 0;
    var div; // undef by default

    // Closure / Object
    var tf = function() {
    };

    // LOOP
    tf.loop = function() {
	if (tCurr > timer) {
	    tf.now();
	    tf.loop();
	    return;
	}
	var time_to_refresh = tf.time_to_refresh()
	div.html(time_to_refresh);
	console.log(time_to_refresh);
	tf.increase_time();
	var tid = setTimeout(function() {tf.loop()}, 1000);
	if (stop) {
	    clearTimeout(tid);
	}
    };

    // Controls
    tf.start = function() {
	stop = false;
	tf.loop();
    };

    tf.stop = function() {
	stop = true;
    };

    tf.now = function() {
	cback();
	tCurr = 0;
    };

    tf.reset = function() {
	tCurr = 0;
	div.html(tf.time_to_refresh());
    };

    // Getters/Setters
    tf.callback = function(f) {
	if (!arguments.length) return cback;
	cback = f;
	return tf;
    };

    tf.timer = function(t) {
	if (!arguments.length) return timer;
	t = timer;
	return tf;
    };

    tf.increase_time = function() {
	tCurr++;
	return tf;
    };

    tf.div = function(elem) {
	if (!arguments.length) return div;
	div = elem;
	return tf;
    };

    // misc
    tf.time_to_refresh = function() {
	return timer - tCurr;
    };


    return tf;
}

