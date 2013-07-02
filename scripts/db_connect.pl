#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::Utils::Graph;
use Bio::EnsEMBL::Hive::URLFactory;
#use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use JSON;
use HTML::Template;

use lib ("./scripts/lib");
use msg;

my $json_url = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2912/mp12_long_mult"]}';
my $connexion_template = $ENV{GUIHIVE_BASEDIR} . "static/connexion_details.html";
my $hive_config_file = $ENV{GUIHIVE_BASEDIR} . "config/hive_config.json";

# Input data
my $url = decode_json($json_url)->{url}->[0];

my $response = msg->new();

# Initialization
#my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
my $dbConn;
eval {
  $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
};
if ($@) {
  $response->err_msg($@);
  $response->status("FAILED");
}

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
    $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again\n") unless($response->err_msg);
    $response->status("FAILED");
}

print $response->toJSON();

sub formResponse {
    my ($dbConn) = @_;
    my $info;

    $info->{db_name}   = $dbConn->dbc->dbname;
    $info->{host}      = $dbConn->dbc->host;
    $info->{port}      = $dbConn->dbc->port;
    $info->{driver}    = $dbConn->dbc->driver;
    $info->{username}  = $dbConn->dbc->username;
    # $info->{mysql_url} = "?username=" . $dbConn->dbc->username . "&host=" . $dbConn->dbc->host . "&dbname=" . $dbConn->dbc->dbname . "&port=" . $dbConn->dbc->port;

    my $template = HTML::Template->new(filename => $connexion_template);
    $template->param(%$info);
    return $template->output();
}

sub formAnalyses {
    my ($dbConn) = @_;
    my $graph = Bio::EnsEMBL::Hive::Utils::Graph->new($dbConn, $hive_config_file);
    my $graphviz = $graph->build();

    return $graphviz->as_svg;
}


