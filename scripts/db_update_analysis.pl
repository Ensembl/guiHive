#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;

use JSON::XS;

use lib "./scripts/lib";
use analysis_parameters;
use msg;

my $json_data = shift @ARGV || '{"analysis_id":["2"],"adaptor":["ResourceDescription"],"method":["parameters"],"args":["-C0 -M8000000  -R\"select[mem>8000]  rusage[mem=8000]\""],"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69a2"]}'; #'{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"], "column_name":["parameters"], "analysis_id":["27"], "newval":["cmalign_exe"]}';

my $var = decode_json($json_data);
my $url          = $var->{url}->[0];
my $args         = $var->{args}->[0];
my $analysis_id  = $var->{analysis_id}->[0];
my $adaptor_name = $var->{adaptor}->[0];
my $method       = $var->{method}->[0];

my @args = split(/,/,$args);

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

my $response = msg->new();

if (defined $dbConn) {
    ### TODO: A better way to get the object?
    ## The problem is that each adaptor has its own method for
    ## fetching by dbID
    ## Would it be better to normalize this in analysis_parameters module?
    ## Then we would be able to read the adaptor name and call the same fetch
    ## method independently of the adaptor
    ## This code also presents a bug if there are two adaptors that can $method

    $adaptor_name = "get_".$adaptor_name."Adaptor";
    print STDERR "ADAPTOR_NAME: $adaptor_name\n";
    my $adaptor = $dbConn->$adaptor_name;
    my $obj = $adaptor->fetch_by_dbID($analysis_id);
    print STDERR "OBJECT: $obj\n";

#     my $analysis = $dbConn->get_AnalysisAdaptor->fetch_by_analysis_id($analysis_id);
#     my $analysis_stats = $analysis->stats();
#     my $resource_class = $dbConn->get_ResourceClassAdaptor->fetch_by_dbID($analysis_id);
#     print STDERR "ANALYSIS_ID: $analysis_id\n";
#     print STDERR "RESOURCE_CLASS: $resource_class\n";
#     my $resource_description = $resource_class->description;
#     print STDERR "ANALYSIS: $analysis\n";
#     print STDERR "ANLYSIS_STATS: $analysis_stats\n";
#     print STDERR "RESOURCE_DESCRIPTION: $resource_description\n";

#     my $obj;
#     if ($analysis->can($method)) {
#       $obj = $analysis;
#     } elsif ($analysis_stats->can($method)) {
#       $obj = $analysis_stats;
#     } elsif ($resource_class->can($method)) {
# 	$obj = $resource_class;
#     } elsif ($resource_description->can($method)) {
# 	$obj = $resource_description;
#     } else {
#       $response->err_msg("$method is not a valid method");
#       $response->status("FAILED");
#     }

    if ($obj) {
      eval {
	  print STDERR "$obj->$method(@args)\n";
	$obj->$method(@args);
	$obj->adaptor->update($obj);
      };
      $response->err_msg($@);
      $response->status($response->err_msg) if ($@);
    }
} else {
    $response->err_msg("Error connecting to the database. Please try to connect again");
    $response->status("FAILED");
}

print $response->toJSON();

