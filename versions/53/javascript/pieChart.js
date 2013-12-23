/* Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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


// pChart is the function returning the reusable pie-chart with transitions.
function pieChart() {
  // Initial values:
  var max_height=100;
  var data = {counts : [0,0,0,0,0,1],
              colors : ["green", "yellow", "red", "blue", "cyan", "white"],
	      names  : ["semaphored", "ready", "inprogress", "failed", "done"],
             }

  var pie = d3.layout.pie()
              .sort(null);

    var attr = 'status';

  var max_counts = d3.sum(data.counts);
  // The size of the pie chart (outerRadius) is dynamic.
  var total_counts_extent = [0, max_counts];
  var pie_size_scale = d3.scale.linear()
                               .range([max_height/5, max_height/3])
                               .domain(total_counts_extent);
    var outerRadius = pie_size_scale(d3.sum(data.counts));
//  var radiusFactor = 4;

  var paths = [];
  var innerRadius = 12;

  var arc = d3.svg.arc()
                  .innerRadius(innerRadius)
                  .outerRadius(outerRadius);


  // chart is the returned closure
  var chart = function(g) {

    // path defined the parts of the pie chart.
    // It is stored internally in the closure (i.e. not returned).
    // In each path node we store its current value. This is needed for the transitions later
    g.attr("transform", "translate(" + chart.x() + "," + chart.y() + ")");
    var path = g.selectAll("path").data(pie(data.counts))
                                  .enter().append("path")
                                  .attr("fill", "white")
                         	  .attr("stroke", "black")
                                  .attr("d", arc)
                                  .each(function(d) { this._current = d; }); // store the initial values

    var panic_circle = g.append("circle")
	  .attr("cx", 0)
	  .attr("cy", 0)
	  .attr("r", innerRadius)
	  .attr("fill", "white");
  
    // The pie-chart is feeded with the initial data and colouring
    path.data(pie(data.counts))
        .attr("fill", function(d,i) {return data.colors[i]});    
    
    // transition is a method on the pie chart that returns a transition closure
    // This closure knows how to make the transition given new data for the pie chart.
    chart.transition = function() {
      var newT = function(path) {
        
        // The size of the pie chart (outerRadius) is dynamic.
        var total_counts_extent = [0, chart.max_counts()];
        var pie_size_scale = d3.scale.linear()
                               .range([max_height/5, max_height/3])
                               .domain(total_counts_extent);

	// We use the current colors given in the transitions
        path.attr("fill", function(d,i) {return data.colors[i]});

        var duration = 1500;
        var delay    = 0;

	  // We update the panic_circle
	  panic_circle.transition().duration(duration).delay(delay).attr("fill",function(){if (chart.data().counts[3] === 0){return "white"} else {return "red"}});

        path.transition().delay(delay).duration(newT.duration()).attrTween("d", function(a) {
         var i = d3.interpolate(this._current, a),
             k = d3.interpolate(arc.outerRadius()(),pie_size_scale(d3.sum(data.counts)));
          this._current = i(0);
          return function(t) {
	      return arc.outerRadius(k(t))(i(t));
//            return arc.innerRadius(k(t)/radiusFactor).outerRadius(k(t))(i(t));
          };
        }); // redraw the arcs
      };
 
      // duration is a method that allows to change the duration of the transition
      newT.duration = function(value) {
        if (!arguments.length) return duration;
        duration = value;
        return newT
      };

      return newT;
    }
 
      // update is a method to update the pie-chart (given new data and a transition closure)
    chart.update = function(data, trans) {
      // We update the data variable and...
      chart.data(data);
      // ...the pie paths with the new data.
      paths.data(pie(data.counts))
        
      // call the transition closure
      trans(paths);

	// TODO: What is "path" here?
      paths = path;
      return;
    }
       
    paths = path;
    return;
  } // end of chart closure
      
 
  // Some methods are defined over the chart: outerRadius and data
  chart.data = function(value) {
    if (!arguments.length) return data;
    data = value;
    return chart;
  };
  
  chart.max_counts = function(value) {
    if (!arguments.length) return max_counts;
    max_counts = value;
    return chart;
  };
    
  chart.x = function(value) {
    if (!arguments.length) return posx;
    posx = value;
    return chart;
  }
      
  chart.y = function(value) {
    if (!arguments.length) return posy;
    posy = value;
    return chart;
  }
        
  return chart;
}
