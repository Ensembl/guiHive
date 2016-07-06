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


function refreshTimer() {
    var radius = 20;
    var counts = [1,0];
    var default_colors = ["grey", "white"];
    var colors = default_colors; // by ref??

    var pie = d3.layout.pie()
	.sort(null);

    var arc = d3.svg.arc()
	.innerRadius(0)
	.outerRadius(radius);

    var r = function(g) {
	g.attr("transform", "translate(" + radius + "," + radius + ")");
	var paths = g.selectAll("path").data(pie(counts))
	    .enter().append("path")
	    .attr("d", arc)
	    .each(function(d) { this._current = d; });

	paths
	    .attr("fill", function(d,i) {return colors[i]});

	r.transition = function() {
	    var delay = 0;
	    var duration = 1000;
	    var ease = "linear";
	    var newR = function(path) {
		path.attr("fill", function(d,i) { return colors[i] });
		path.transition().ease(ease).delay(delay).duration(duration).attrTween("d", r.arcTween);
	    };

	    newR.delay = function(value) {
		if (!arguments.length) return delay;
		delay = value;
		return newR;
	    };

	    newR.duration = function(value) {
		if (!arguments.length) return duration;
		duration = value;
		return newR;
	    };

	    return newR;
	};

	r.update = function(data, t) {
	    r.counts(data);
	    paths.data(pie(data));
	    t(paths);
	    return;
	};

    };

    r.counts = function(value) {
	if (!arguments.length) return counts;
	counts = value;
	return r;
    };

    r.colors = function(value) {
	if (!arguments.length) return colors;
	colors = value;
	return r;
    };

    r.set_default_colors = function() {
	colors = default_colors;
	return r;
    }

    r.arcTween = function(a) {
	var i = d3.interpolate(this._current, a);
	this._current = i(0);
	return function (t) {
	    return arc(i(t))
	};
    };

    return r;
}
