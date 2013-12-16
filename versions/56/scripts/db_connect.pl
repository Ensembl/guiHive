#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::Utils::Graph;
use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor;

use JSON;
use HTML::Template;

use lib ("./lib");
use msg;
use version_check;

my $json_url = shift @ARGV || '{"version":["53"],"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_74clean2"]}';
my $hive_config_file = $ENV{GUIHIVE_BASEDIR} . "config/hive_config.json";

# Input data
my $url = decode_json($json_url)->{url}->[0];
my $version = decode_json($json_url)->{version}->[0];

# Set up @INC and paths for static content
my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";
my $connection_template = "${project_dir}static/connection_details.html";

my $response = msg->new();


# Initialization
my $dbConn;
eval {
  $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
};
if ($@) {
  $response->err_msg($@);
  $response->status("FAILED");
}

if (defined $dbConn) {
  ## First check if the code version is OK
  my $code_version = get_hive_code_version();
  my $hive_db_version = get_hive_db_version($dbConn);

  if ($code_version != $hive_db_version) {
    $response->status("VERSION MISMATCH");
    $response->err_msg("$code_version $hive_db_version");
    print $response->toJSON;
    exit 0;
  }

  my ($graph, $html);
  eval {
	$graph = formAnalyses($dbConn);
	$html = formResponse($dbConn);
    };
    if ($@) {
	$response->err_msg("I have problems retrieving data from the database:$@");
	$response->status("FAILED");
    } else {
	$response->out_msg({"graph" => $graph,
			    "html" => $html});
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
    $info->{hive_db_version} = get_hive_db_version($dbConn);
    $info->{hive_code_version} = get_hive_code_version();

    my $template = HTML::Template->new(filename => $connection_template);
    $template->param(%$info);
    return $template->output();
}

sub formAnalyses {
    my ($dbConn) = @_;
    my $graph = Bio::EnsEMBL::Hive::Utils::Graph->new($dbConn, $hive_config_file);
    my $graphviz = $graph->build();

    return $graphviz->as_svg;
}


