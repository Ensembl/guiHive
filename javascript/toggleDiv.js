/* Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
/* Copyright [2016-2020] EMBL-European Bioinformatics Institute

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
