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
my $json_url = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2912/mp12_long_mult"]}';
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
  $resp .= "Time to next refresh: <span id=\"secs_to_refresh\"></span>";
  $resp .= "</p>";
  return $resp;
}

sub formAnalyses {
    my ($dbConn) = @_;
    my $graph = Bio::EnsEMBL::Hive::Utils::Graph->new($dbConn);
    my $graphviz = $graph->build();

    return $graphviz->as_svg;
}


