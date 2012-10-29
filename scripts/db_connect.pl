#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::Utils::Graph;
use GraphViz; # Remove -- Only for testing custom svg created with GraphViz (more lightweight than the full diagram)
use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;

use lib ("./scripts/lib");
use msg;

# Input data
my $json_url = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"]}';
my $url = decode_json($json_url)->{url}->[0];

# Initialization
my $analyses_template = $ENV{GUIHIVE_BASEDIR} . 'static/pipeline_diagram.html';
my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response = msg->new();

if (defined $dbConn) {
    my ($graph, $status);
    eval {
	$graph = formAnalyses($dbConn);
	$status = formResponse($dbConn);
    };
    if ($@) {
	$response->err_msg("I have problems retrieving data from the database:$@");
	$response->status("FAILED");
    } else {
	$response->status($status);
	$response->out_msg($graph);
    }
} else {
    $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again\n");
    $response->status("FAILED");
}

print $response->toJSON();

sub formResponse {
  my ($dbConn) = @_;
  my $resp;
  $resp .= "<p>";
  $resp .= "DB name: ". $dbConn->dbc->dbname. "<br />";
  $resp .= "Host: ". $dbConn->dbc->host. "<br />";
  $resp .= "Port: ". $dbConn->dbc->port. "<br />";
  $resp .= "Driver: ". $dbConn->dbc->driver. "<br />";
  $resp .= "Username: ". $dbConn->dbc->username. "<br />";
  $resp .= "</p>";
  return $resp;
}

sub formAnalyses {
#     my ($dbConn) = @_;
#     my $hive_config_file = $ENV{GUIHIVE_BASEDIR} . "config/hive_config.json";
#     my $graph = Bio::EnsEMBL::Hive::Utils::Graph->new($dbConn, $hive_config_file);
#     my $graphviz = $graph->build();

    my $graphviz = GraphViz->new();

    $graphviz->add_node('London');
    $graphviz->add_node('Paris', label => 'City of Louvre');
    $graphviz->add_node('New York');

    $graphviz->add_edge('London' => 'Paris');
    $graphviz->add_edge('London' => 'New York', label => 'Far');
    $graphviz->add_edge('Paris'  => 'London');

    return $graphviz->as_svg;
}

# sub formAnalyses {
#     my ($all_analyses) = @_;
#     my $template = HTML::Template->new(filename => $analyses_template);
#     $template->param(analyses => [ map{ {logic_name => $_->logic_name, id => $_->dbID} } @$all_analyses] );
#     return $template->output();
# }


