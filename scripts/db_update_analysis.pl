#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use analysis_parameters;

use JSON::XS;
use msg;

my $json_data = shift @ARGV || '{"action":["whatever"],"analysis_id":["40"],"method":["delete_param"],"newval":["mlss_id"],"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"]}'; #'{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"], "column_name":["parameters"], "analysis_id":["27"], "newval":["cmalign_exe"], "action":["del_param"]}';

my $var = decode_json($json_data);
my $url = $var->{url}->[0];
my $newval      = $var->{newval}->[0];
my $analysis_id = $var->{analysis_id}->[0];
#my $adaptor     = $var->{adaptor}->[0];
my $method      = $var->{method}->[0];
#my $action      = $var->{action}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

my $response = msg->new();

if (defined $dbConn) {
    my $analysis = $dbConn->get_AnalysisAdaptor->fetch_by_analysis_id($analysis_id);
    my $analysis_stats = $analysis->stats();

    my $obj;
    if ($analysis->can($method)) {
      $obj = $analysis;
    } elsif ($analysis_stats->can($method)) {
      $obj = $analysis_stats;
    } else {
      $response->err_msg("$method is not a valid method in Analysis or AnalysisStats");
      $response->status("FAILED");
    }

    if ($obj) {
      eval {
	$obj->$method($newval);
	$obj->adaptor->update($obj);
      };
      $response->err_msg($@);
      $response->status($response->err_msg);
    }
} else {
    $response->err_msg("Error connecting to the database. Please try to connect again");
    $response->status("FAILED");
}

print $response->toJSON();

