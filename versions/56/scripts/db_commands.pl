#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

use JSON;
use Data::Dumper;

use lib ("./lib");
use hive_extended;
use msg;
use version_check;

my $json_data = shift @ARGV || '{ "url":["version":["53"],"mysql://ensro@127.0.0.1:2913/mp12_compara_homology_72"],"analysis_id":["116"], "method":["reset_jobs_for_analysis_id"] }';

# Input
my $var          = decode_json($json_data);
my $url          = $var->{url}->[0];
my $analysis_id  = $var->{analysis_id}->[0];
my $method       = $var->{method}->[0];
my $adaptor_name = "AnalysisJob";
my $version      = $var->{version}->[0];

my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";

# Initialization
my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
my $response = msg->new();


if (defined $dbConn) {
  ## First check if the code version is OK
  my $code_version = get_hive_code_version();
  my $hive_db_version = get_hive_db_version($dbConn);

  if ($code_version != $version) {
    $response->status("VERSION MISMATCH");
    $response->err_msg("$code_version $hive_db_version");
    print $response->toJSON;
    exit 0;
  }

  $adaptor_name = "get_".$adaptor_name."Adaptor";
  my $adaptor = $dbConn->$adaptor_name;
  eval {
    $adaptor->$method($analysis_id);
  };
  $response->err_msg($@);
  $response->status($response->err_msg) if ($@);
} else {
  $response->err_msg("Error connecting to the database. Please try to connect again");
  $response->status("FAILED");
}

print $response->toJSON();

