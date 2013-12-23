// toggleDiv is a jQuery plugin to deal with toggle divs visibility
// In the plugin "this" should have a data-target attribute, the value in that attr
// will be the target of the show/hide. In this case, the "text" of "this"
// is changed to "Show"/"Hide" accordingly
//

(function( $ ){

  $.fn.toggleDiv = function() {  
    return this.each(function() {
	var options = {
	    effect : "blind",
	    duration : 1000,
	    extra_options : {},
	};

	var target = $("#"+$(this).attr("data-target"));
	var curr_display = target.css('display');
	if (curr_display === "none") {
	    target.show(options.effect, options.extra_options, options.duration);
	    $(this).text("Hide");
	} else {
	    target.hide(options.effect, options.extra_options, options.duration);
	    $(this).text("Show");
	}
    });
  };

})( jQuery );
