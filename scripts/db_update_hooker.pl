#!/usr/bin/perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;

use Data::Dumper;

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69b"], "adaptor_name":["AnalysisStats"], "column_name":["hive_capacity"], "analysis_id":["20"], "newval":["100"]}';

my $url = decode_json($json_data)->{url}->[0];
my $analysis_id = decode_json($json_data)->{analysis_id}->[0];
my $adaptor_name = decode_json($json_data)->{adaptor_name}->[0];
my $column_name = decode_json($json_data)->{column_name}->[0];
my $newval = decode_json($json_data)->{newval}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

my $response = {
		status => "ok",
	       };

if (defined $dbConn) {
  my $adaptor_method = "get_${adaptor_name}Adaptor";
  my $adaptor = $dbConn->$adaptor_method;
  print STDERR "ADAPTOR: ", $adaptor, "\n";
  print STDERR "ANALYSIS_ID: ", $analysis_id, "\n";
  my $object = $adaptor->fetch_by_analysis_id($analysis_id);
  $object->hive_capacity($newval);
  eval {
    $adaptor->update($object);
  };
  if ($@) {
    $response->{status} = @_;
  }
} else {
  $response->{status} = "I have lost connection to the database. Please connect again";
}

my $json = JSON::XS->new->indent(0);
print $json->encode($response);

