#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;
use Data::Dumper;

my $json_data = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"], "logic_name":["infernal"]}';
my $details_template = "../static/analysis_details.html"; ## TODO: use BASEDIR or something similar

my $url = decode_json($json_data)->{url}->[0];
my $logic_name = decode_json($json_data)->{logic_name}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

my $response = {
		status => "ok",
		analysis_info => "",
	       };

if (defined $dbConn) {
  my $analysis;
  eval {
    $analysis = $dbConn->get_AnalysisAdaptor()->fetch_by_logic_name_or_url($logic_name);
  };
  if ($@) {
    $response->{status} = formError();
  }
  if (! defined $analysis) {
    $response->{status} = formError();
  }
  $response->{analysis_info} = formAnalysisInfo($analysis);
} else {
  $response->{status} = formError();
}

my $json = JSON::XS->new->indent(0);
print $json->encode($response);

sub formError {
  return "I have lost connection to the database. Please connect again";
}

sub formAnalysisInfo {
  my ($analysis) = @_;
  my $analysis_stats = $analysis->stats();

  my $parameters = $analysis->parameters();
  $parameters =~ s/,/,<br \/>/g;
  my $info;
  $info->{logic_name}        = "analysis/" . $analysis->logic_name();
  $info->{module}            = "analysis/" . $analysis->module();
  $info->{parameters}        = "analysis/" . $parameters, #$analysis->parameters();
  $info->{id}                = "analysis/" . $analysis->dbID();
  $info->{priority}          = "analysis_stats/" . $analysis_stats->priority();
  $info->{batch_size}        = "analysis_stats/" . $analysis_stats->batch_size();
  $info->{can_be_empty}      = "analysis_stats/" . $analysis_stats->can_be_empty();
  $info->{resource_class_id} = "anslysis_stats/" . $analysis_stats->resource_class_id();
  $info->{hive_capacity}     = "analysis_stats/" . $analysis_stats->hive_capacity();

  my $template = HTML::Template->new(filename => $details_template);
  $template->param(%$info);

  return $template->output();
}

