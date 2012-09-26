#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;
use Data::Dumper;

my ($json_data) = @ARGV || '{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"], "logic_name":["infernal"]}';
my $details_template = "../static/analysis_details.html"; ## TODO: use BASEDIR or something similar

## TODO: A better way to decode the json data into the appropriate variables
my $url = decode_json($json_data)->{url}->[0];
my $logic_name = decode_json($json_data)->{logic_name}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response;

## TO-DO: This flow is flaw. FIX!
if (defined $dbConn) {
  my $analysis;
  eval {
    $analysis = $dbConn->get_AnalysisAdaptor()->fetch_by_logic_name_or_url($logic_name);
  };
  if ($@) {
    # TODO: We can loose connection from the database. This should be handled better
    die "Can't connect to database\n";
  }
  if (! defined $analysis) {
    # TODO: This is unlikely to happen since the logic_name comes from the database. This should be handled better.
    die "Can't find analysis\n";
  }

  $response->{analysis_info} = formAnalysisInfo($analysis);
} else {
  $response->{analysis_info} = formError();
}

print encode_json($response);

sub formError {
  return "I can't connect to the database: Please check the URL and try again";
}

sub formAnalysisInfo {
  my ($analysis) = @_;
  my $analysis_stats = $analysis->stats();

  my $info;
  $info->{logic_name}        = $analysis->logic_name();
  $info->{module}            = $analysis->module();
  $info->{parameters}        = $analysis->parameters();
  $info->{id}                = $analysis->dbID();
  $info->{priority}          = $analysis_stats->priority();
  $info->{batch_size}        = $analysis_stats->batch_size();
  $info->{can_be_empty}      = $analysis_stats->can_be_empty();
  $info->{resource_class_id} = $analysis_stats->resource_class_id();

  my $template = HTML::Template->new(filename => $details_template);
  $template->param(%$info);

  return $template->output();
}

