#!/usr/bin/perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;

use Data::Dumper;

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69b"], "column_name":["hive_capacity"], "analysis_id":["20"], "newval":["100"], "action=["set_val"]}';

## TODO: BETTER WAY TO DEAL WITH DECODING OF JSON
my $url = decode_json($json_data)->{url}->[0];
my $analysis_id = decode_json($json_data)->{analysis_id}->[0];
my $column_name = decode_json($json_data)->{column_name}->[0];
my $newval = decode_json($json_data)->{newval}->[0];
my $action = decode_json($json_data)->{action}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

my $response = {
		status => "ok",
	       };


my $actions = {
	       'set_val' => &set_val,
	       'del_param' => &del_param,
	      };



my $adaptor_name;

sub set_val {
  my ($obj, $column_name, $newval) = @_;
  my $response_status = {
			 status => "ok",
			};
  eval { $obj->column_name($newval) };
  if ($@) {
    $response->{status} = $@;
  } else {
    my $adaptor = $obj->adaptor();
    eval { $adaptor->update($analysis); };
    if ($@) {
      $response->{status} = $@;
    }
  }
  return $response_status;
}

sub del_param {
  my ($adaptor_name, $obj) = @_;
  
}

if (defined $dbConn) {
  my $analysis = $dbConn->get_AnalysisAdaptor->fetch_by_analysis_id($analysis_id);
  my $analysis_stats = $analysis->stats;

  if ($analysis->can($column_name)) {
    $response_status = $actions->{$analysis}
    eval { $analysis->$column_name($newval) };
    if ($@) {
      $response->{status} = $@;
    } else {
      my $adaptor = $analysis->adaptor();
      eval {
	$adaptor->update($analysis);
      };
      if ($@) {
	$response->{status} = $@;
      }
    }

  } elsif ($analysis_stats->can($column_name)) {
    $adaptor_name = "AnalysisStats";
    eval { $analysis_stats->$column_name($newval) };
    if ($@) {
      $response->{status} = $@;
    } else {
      my $adaptor_method = "get_${adaptor_name}Adaptor";
      my $adaptor = $dbConn->$adaptor_method;
      eval {
	$adaptor->update($analysis_stats);
      };
      if ($@) {
	$response->{status} = $@;
      }
    }
  } else {
    ## Something wrong happened. This shouldn't be reached
    $response->{status} = "$column_name is not a valid column!";
  }

} else {
  $response->{status} = "I have lost connection to the database. Please connect again";
}

my $json = JSON::XS->new->indent(0);
print $json->encode($response);

