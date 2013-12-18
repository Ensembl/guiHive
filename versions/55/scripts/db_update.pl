#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use JSON;
use URI::Escape;
use lib "./scripts/lib"; ## Only needed for local testing
#use hive_extended;
#use msg;

my $json_data = shift @ARGV || '{"version":["53"],"adaptor":["Analysis"],"analysis_id":["2"],"args":["plus9,5+6"],"method":["add_param"],"url":["mysql://ensro@127.0.0.1:2911/mp12_long_mult"]}';#'{"analysis_id":["2"],"adaptor":["ResourceDescription"],"method":["parameters"],"args":["-C0 -M8000000  -R\"select[mem>8000]  rusage[mem=8000]\""],"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69a2"]}'; #'{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"], "column_name":["parameters"], "analysis_id":["27"], "newval":["cmalign_exe"]}';

my $var = decode_json($json_data);
my $url          = $var->{url}->[0];
my $args         = uri_unescape($var->{args}->[0]);
my $analysis_id  = $var->{analysis_id}->[0];
my $adaptor_name = $var->{adaptor}->[0];
my $method       = $var->{method}->[0];
my $version      = $var->{version}->[0];

my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";

unshift @INC, $project_dir . "scripts/lib";
require msg;
require hive_extended;

unshift @INC, $project_dir . "ensembl-hive/modules";
require Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

my @args = split(/,/,$args,2);

# If we pass the 'NULL' string, then we undef the value to update a NULL mysql value:
if ((scalar @args == 1) && ($args[0] eq "NULL")) {
  @args = undef;
}

my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );

my $response = msg->new();

if (defined $dbConn) {

    $adaptor_name = "get_".$adaptor_name."Adaptor";
    my $adaptor = $dbConn->$adaptor_name;
    my $obj = $adaptor->fetch_by_dbID($analysis_id);

    if ($obj) {
      eval {
	$obj->$method(@args);
	$obj->adaptor->update($obj);
      };
      $response->err_msg($@);
      $response->status($response->err_msg) if ($@);
    } else {
      $response->err_msg("Error getting the object from the database.");
      $response->status("FAILED");
    }
} else {
    $response->err_msg("Error connecting to the database. Please try to connect again");
    $response->status("FAILED");
}

print $response->toJSON();

