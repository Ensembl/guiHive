#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use GraphViz;

my $graph = GraphViz->new();

$graph->add_node('London');
$graph->add_node('Paris', label => 'City of Louvre');
$graph->add_node('New York');

$graph->add_edge('London' => 'Paris');
$graph->add_edge('London' => 'New York', label => 'Far');
$graph->add_edge('Paris'  => 'London');

print $graph->as_svg;
