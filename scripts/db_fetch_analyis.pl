#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use CGI::Pretty;
use JSON::XS;
use Data::Dumper;

my $query = new CGI::Pretty;

my $url = $query->param('db_url') || 'mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69b';
my $logic_name = $query->param('db_url') || 'infernal';

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response;

if (defined $dbConn) {
  my $analysis;
  eval {
    $analysis = $dbConn->get_AnalysisAdaptor()->fetch_by_logic_name_or_url($logic_name);
  };
  if ($@) {
    # We can loose connection from the database. This should be handled better
    die "Can't connect to database\n";
  }
  if (! defined $analysis) {
    # This is unlikely to happen since the logic_name comes from the database. This should be handled better.
    die "Can't find analysis\n";
  }
  my $analysis_info = formAnalysisInfo($analysis);
  print encode_json($analysis_info);
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

  return $info;
}
