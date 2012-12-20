#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use Data::Dumper;

use lib ("./scripts/lib");
use analysisInfo;
use msg;

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_long_mult"]}';

my $var = decode_json($json_data);
my $url = $var->{url}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response = msg->new();

if (defined $dbConn) {
    my $all_analysis;
    eval {
	$all_analysis = $dbConn->get_AnalysisAdaptor()->fetch_all();
    };
    if ($@) {
	$response->err_msg("I can't retrieve the analysis from the database: $@");
	$response->status("FAILED");
    }
    $response->out_msg(formAnalysisInfo($all_analysis));

} else {
    $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again");
}

print $response->toJSON;

sub formAnalysisInfo {
    my ($all_analysis) = @_;
    my @all_analysis_info = ();
    for my $analysis (@$all_analysis) {
	push @all_analysis_info, analysisInfo->fetch($analysis);
    }
    return [@all_analysis_info];
}
