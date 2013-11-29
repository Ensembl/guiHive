#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use JSON;
use Data::Dumper;

use lib ("./scripts/lib");
use hive_extended;
use msg;

my $json_data = shift @ARGV || '{ "url":["mysql://ensadmin:ensembl@127.0.0.1:2913/mp12_compara_homology_72"],"analysis_id":["116"], "method":["reset_jobs_for_analysis_id"] }';

# Input
my $var         = decode_json($json_data);
my $url         = $var->{url}->[0];
my $analysis_id = $var->{analysis_id}->[0];
my $method      = $var->{method}->[0];
my $adaptor_name = "AnalysisJob";

# Initialization
my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
my $response = msg->new();

if (defined $dbConn) {
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

