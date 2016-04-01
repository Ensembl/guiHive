/* Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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


function bubbleCloud() {
    var width = 500;
    var height = 400;
    var center;
    var meadow_centers;
    var layout_gravity = 0.05;
    var damper = 0.1;
    var friction = 0.9;
    var data = {};
    var attr = "";
    var node;
    var force;
    var min_range = 5;
    var max_range = 50;
    var radius_scale;
    var node_colors = nodeColor();
    
    var bCloud = function(vis) {
	bCloud.centers();

        var domain = bCloud.domain();
        radius_scale = d3.scale.linear()
            .domain(domain)
            .range([min_range,max_range]);

        node = vis.selectAll("node")
            .data(data, function (d) {return d.analysis_id})
            .enter()
	    .append("g")
            .attr("class", "node")
	    .attr("rel", "tooltip-it");

        var max_circles = node.append("circle")
            .attr("class", "max")
            .attr("cx", 0)
            .attr("cy", 0)
            .attr("r", function (d) {
		if (typeof(d[attr]) !== "object") {
		    if (d[attr] === 0) {
			return 0
		    } else {
			return radius_scale(d[attr])
		    }
		} else {
		    return radius_scale((d[attr][2]))
		}
	    })
            .style("fill", function (d) { return (node_colors(d.logic_name)) })
            .style("stroke", "black")
            .style("stroke-width", 1.5);
        
        var mean_circles = node.append("circle")
            .attr("class", "mean")
            .attr("cx", 0)
            .attr("cy", 0)
            .attr("r", function(d) { if (typeof(d[attr]) !== "object") {return 0} else {return (radius_scale(d[attr][1]))} })
            .style("stroke", function(d) { return d3.rgb(node_colors(d.logic_name)).darker() })
            .style("fill", "none")
            .style("stroke-width", 2);
        
        var min_circles = node.append("circle")
            .attr("class", "min")
            .attr("cx", 0)
            .attr("cy", 0)
            .attr("r", function(d) { if (typeof(d[attr]) !== "object") {return 0} else {return (radius_scale(d[attr][0]))} })
            .style("stroke", function (d) { return d3.rgb(node_colors(d.logic_name)).darker() })
            .style("fill", function (d) { return d3.rgb(node_colors(d.logic_name)).darker() });
        
        node.append("text")
            .attr("dx",-5)
            .attr("dy",5)
            .text(function(d){return d.analysis_id});

        bCloud.update = function() {
            var domain = bCloud.domain();
            radius_scale.domain(domain);
	    node
		.attr("title", function(x, i){
		    var d = data[i];
		    var tooltip_msg = "Analysis ID: " + (d.analysis_id) + "<br/>Logic name: " + d.logic_name + "<br/>Number of jobs:" + d.total_job_count + "<br/>Avg msec per job: " + d.avg_msec_per_job_parsed;
		    if (d.mem !== undefined) {
			tooltip_msg = tooltip_msg + "<br/>Min memory used: " + d.mem[0] + "<br/>Mean memory used: " + d.mem[1] + "<br/>Max memory used:" + d.mem[2];
		    }

		    if (d.cpu !== undefined) {
			tooltip_msg = tooltip_msg + "<br/>Min cpu time: " + d.cpu[0] + "<br/>Mean cpu time: " + d.cpu[1] + "<br/>Max cpu time:" + d.cpu[2];
		    }

		    tooltip_msg = tooltip_msg + "<br/>Breakout label: " + d.breakout_label + "<br/>Status: " + d.status + "<br />guiHive Status: " + d.guiHiveStatus;
		    return tooltip_msg;
		});

	    max_circles
		.transition()
		.duration(1000)
		.attr("r", function(d, i){
		    d[attr] = data[i][attr];
		    d.status = data[i].status;
		    if (typeof(d[attr]) !== "object") {
			if (d[attr] === 0) {
			    return 0
			} else {
			    return radius_scale(d[attr])
			}
		    } else {
			return radius_scale(d[attr][2])
		    }
		})
		.attr("title", function(d){
                    if (typeof(d[attr]) !== "object") {
			return "<pre>Val:" + d[attr] + "</pre>"
                    } else {
			return "<pre>Max:" + d[attr][2] + "\nMean:" + d[attr][1] + "\nMin:" + d[attr][0] + "\n</pre>";
                    }
		})
		.style("fill", function(d) { return d3.rgb(node_colors(d.logic_name)) });
            
            mean_circles
		.transition()
		.duration(1000)
		.attr("r", function(d){
		    if (typeof(d[attr]) !== "object") {
			return 0
		    } else {
			return radius_scale(d[attr][1])
		    }
		})
		.style("stroke", function(d) { return d3.rgb(node_colors(d.logic_name)).darker() });
	    
            min_circles
		.transition()
		.duration(1000)
		.attr("r", function(d){
		    if (typeof(d[attr]) !== "object") {
			return 0
		    } else {
			return radius_scale(d[attr][0])
		    }
		})
		.style("stroke", function (d) { return d3.rgb(node_colors(d.logic_name)).darker() })
		.style("fill", function (d) { return d3.rgb(node_colors(d.logic_name)).darker() });
            
            force.start();
        };
        
        bCloud.displayMeadow = function() {
            var d = width/3;
            var meadows_x = {"LOCAL" : d, "LSF" : d*2};
            var meadows_data = d3.keys(meadows_x);
            var by_meadow = vis.selectAll(".meadow")
		.data(meadows_data);
        
            by_meadow
		.enter()
		.append("text")
		.attr("class", "meadow")
		.attr("x", function(d) {return meadows_x[d]})
		.attr("y", 20)
		.attr("text-anchor", "middle")
		.text(function(d){return d});
        };
        
        bCloud.hideMeadow = function() {
            vis.selectAll(".meadow").remove();
        };
    };
    
    bCloud.max_bubble_size = function(v) {
        if (!arguments.length) {
            return max_range_size;
        }
        max_range = v;
        radius_scale.range([min_range, max_range]);
        bCloud.charge();
        return bCloud;
    };
    
    bCloud.domain = function() {
        var max = d3.max(data, function(d){
	    if (typeof(d[attr]) !== "object") {
		return parseInt(d[attr])
	    } else { 
		return parseInt(d[attr][2])}
	});
	//        var min = d3.min(nodes, function(d){if (typeof(d[attr]) !== "object") { return d[attr] } else {return d[attr][0]}});
        var min=0;
        return ([min,max]);
    };
    
    bCloud.attribute = function(a) {
        if(!arguments.length) {
            return attr;   
        }
        attr = a;
        return bCloud;
    };
    
    bCloud.centers = function() {
	center = {x: width/2,
		  y: height/2};

	meadow_centers = {"LOCAL" : {x : width/3,
				     y : height/2},
			  "LSF"   : {x : 2*width/3,
				     y : height/2}
			 };
	return bCloud;
    }

    bCloud.width = function(w) {
        if(!arguments.length) {
            return width;   
        }
        width = w;
        return bCloud;
    };
    
    bCloud.height = function(h) {
        if(!arguments.length) {
            return height;   
        }
        height = h;
        return bCloud;
    };
        
    bCloud.data = function(d) {
        if (!arguments.length) {
            return data
        }
	var data_list = [];
	for (var o in d) {
	    if (d.hasOwnProperty(o)) {
		data_list.push (d[o]);
	    }
	}
	data = data_list;
        return bCloud;
    };
    
    bCloud.start = function() {
        force = d3.layout.force()
            .nodes(data)
            .size([width, height]);
        
        node.call(force.drag);
        return bCloud;
    };
    
    bCloud.charge = function() {
        force.charge(function(d,i) {
            var val;
            if (typeof(d[attr]) !== "object"){
                val = d[attr]
            } else {
                val=d[attr][2]
            }
            return (-Math.pow(radius_scale(val), 2.0)/4)
        });
    };
    
    bCloud.group_all = function() {
        force
            .gravity(layout_gravity)
            .friction(friction);
        bCloud.charge();
        force.on("tick", function(e) {
            node.each(function(d) {d.x = d.x + (center.x - d.x) * (damper + 0.02) * e.alpha;
                                   d.y = d.y + (center.y - d.y) * (damper + 0.02) * e.alpha});
            node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")" });
        })
            .start();
        
        bCloud.hideMeadow();
        
        return bCloud;
    };
        
    bCloud.display_by_meadow = function() {
        force
            .gravity(layout_gravity)
            .friction(friction);
        bCloud.charge();
	
        force.on("tick", function(e) {
            node.each(function(d) {
                var target = meadow_centers[d.meadow_type];
                d.x = d.x + (target.x - d.x) * (damper + 0.02) * e.alpha * 1.1;
                d.y = d.y + (target.y - d.y) * (damper + 0.02) * e.alpha * 1.1;
            });
            node.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")" });
        })
            .start();
        
        bCloud.displayMeadow();
        
        return bCloud;
    };
    
    return bCloud;
}

