#!/usr/bin/env perl

use strict;
use warnings;


use Bio::EnsEMBL::Hive::Utils::Graph;
use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use Graph::Reader::Dot;
use Data::Dumper;

use lib ("./scripts/lib");
use msg;

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69a2"]}';
my $url = decode_json($json_data)->{url}->[0];
my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response = msg->new();

my $hive_config_file = $ENV{GUIHIVE_BASEDIR} . "config/hive_config.json";
my $graph = Bio::EnsEMBL::Hive::Utils::Graph->new($dbConn, $hive_config_file);
my $graphviz = $graph->build();

# We get the graph in svg. This is displayed directly in the web paged and parsed by d3

$response->out_msg($graphviz->as_svg);

# my $dotReader = Graph::Reader::Dot->new();
# open my $fh, "+<", \$graph_txt;
# my $gGraph = $dotReader->read_graph($fh);
# print STDERR Dumper [$gGraph->vertices];

