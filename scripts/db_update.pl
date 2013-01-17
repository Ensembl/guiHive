#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;

use JSON::XS;

use lib "./scripts/lib";
use new_hive_methods;
use msg;

my $json_data = shift @ARGV || '{"adaptor":["Analysis"],"analysis_id":["2"],"args":["NULL"],"method":["analysis_capacity"],"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_long_mult"]}';#'{"analysis_id":["2"],"adaptor":["ResourceDescription"],"method":["parameters"],"args":["-C0 -M8000000  -R\"select[mem>8000]  rusage[mem=8000]\""],"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69a2"]}'; #'{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"], "column_name":["parameters"], "analysis_id":["27"], "newval":["cmalign_exe"]}';

my $var = decode_json($json_data);
my $url          = $var->{url}->[0];
my $args         = $var->{args}->[0];
my $analysis_id  = $var->{analysis_id}->[0];
my $adaptor_name = $var->{adaptor}->[0];
my $method       = $var->{method}->[0];

my @args = split(/,/,$args);

# If we pass the 'NULL' string, then we undef the value to update a NULL mysql value:
if ((scalar @args == 1) && ($args[0] eq "NULL")) {
  @args = undef;
}

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

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

