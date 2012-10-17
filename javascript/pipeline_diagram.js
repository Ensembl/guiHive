//JSON object with the data

var treeData = {"name" : "A", "info" : "tst", "children" : [
    {"name" : "A1", "children" : [ 
        {"name" : "A12" }, 
        {"name" : "A13" }, 
        {"name" : "A14" }, 
        {"name" : "A15" }, 
        {"name" : "A16" }
    ] }, 
    {"name" : "A2", "children" : [ 
        {"name" : "A21" }, 
        {"name" : "A22", "children" : [ 
	    {"name" : "A221" }, 
	    {"name" : "A222" }, 
	    {"name" : "A223" }, 
	    {"name" : "A224" }
        ]}, 
        {"name" : "A23" }, 
        {"name" : "A24" }, 
        {"name" : "A25" }] }, 
    {"name" : "A3", "children": [
        {"name" : "A31", "children" :[
	    {"name" : "A311" }, 
	    {"name" : "A312" }, 
	    {"name" : "A313" }, 
	    {"name" : "A314" }, 
	    {"name" : "A315" }
        ]}] }
]};

var height = 500,
    width = 900;

$(document).ready(function() {
    var vis = d3.select("#viz")
	.append("svg:svg")
	.attr("width", width)
	.attr("height", height)
	.attr("pointer-events", "all")
	.append("svg:g")
	.attr("transform", "translate(250, 100)")
	.append("svg:g")
	.call(d3.behavior.zoom().on("zoom", function() {redraw(vis)}))
	.append("svg:g");

// To avoid scrolling on mouse events
    vis.append('svg:rect')
	.attr('width', width)
	.attr('height', height)
	.attr('fill', 'white');

    update(vis);
});

function redraw(vis) {
    vis.attr("transform",
	     "translate(" + d3.event.translate + ")"
	     + " scale(" + d3.event.scale + ")");
}


function update(vis) {

    var layout = d3.layout.tree().size([300,300]);

    var diagonal = d3.svg.diagonal()
    // change x and y (for the left to right tree)
        .projection(function(d) { return [d.y, d.x]; });
    
    // Preparing the data for the tree layout, convert data into an array of nodes
    var nodes = layout.nodes(treeData);
    // Create an array with all the links
    var links = layout.links(nodes);
    
    var link = vis.selectAll("pathlink")
        .data(links)
        .enter().append("path")
        .attr("class", "link")
        .attr("d", diagonal)
    
    var node = vis.selectAll("g.node")
        .data(nodes)
        .enter().append("svg:g")
        .attr("transform", function(d) { return "translate(" + d.y + "," + d.x + ")"; })
    
    // Add the dot at every node
    node.append("svg:circle")
        .attr("r", 3.5);

    // place the name atribute left or right depending if children
    node.append("svg:text")
        .attr("dx", function(d) { return d.children ? -8 : 8; })
        .attr("dy", 3)
        .attr("text-anchor", function(d) { return d.children ? "end" : "start"; })
        .text(function(d) { return d.name; });
}

