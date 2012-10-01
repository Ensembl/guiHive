#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;
use Data::Dumper;

use msg;

my $json_data = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"], "logic_name":["infernal"]}';
my $details_template = $ENV{GUIHIVE_BASEDIR} . "static/analysis_details.html"; ## TODO: use BASEDIR or something similar

my $var = decode_json($json_data);
my $url = $var->{url}->[0];
my $logic_name = $var->{logic_name}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

my $response = msg->new();

if (defined $dbConn) {
  my $analysis;
  eval {
    $analysis = $dbConn->get_AnalysisAdaptor()->fetch_by_logic_name_or_url($logic_name);
  };
  if ($@) {
      $response->status("I can't retrieve analysis with logic name $logic_name: $@");
  }
  if (! defined $analysis) {
      $response->status("I can't retrieve analysis with logic name $logic_name from the database");
  }
  $response->out_msg(formAnalysisInfo($analysis));
} else {
    $response->status("I have lost connection with the database\n")
}

print $response->toJSON;


sub formAnalysisInfo {
  my ($analysis) = @_;
  my $analysis_stats = $analysis->stats();

  my $info;
  $info->{logic_name}        = $analysis->logic_name();
  $info->{module}            = $analysis->module();
  $info->{parameters}        = template_mappings_PARAMS($analysis,
							"parameters", $analysis->dbID);
  $info->{id}                = $analysis->dbID();
  $info->{priority}          = template_mappings_SELECT($analysis_stats,
							"priority",
							build_values({1=>[0,20]}));

  $info->{batch_size}        = template_mappings_SELECT($analysis_stats,
							"batch_size",
							build_values({1=>[0,9],10=>[10,90],100=>[100,1000]}));

  $info->{can_be_empty}      = template_mappings_SELECT($analysis_stats,
							"can_be_empty",
							build_values({1=>[0,1]}));

  $info->{resource_class_id} = $analysis->resource_class_id();
  $info->{hive_capacity}     = template_mappings_SELECT($analysis_stats,
							"hive_capacity",
							build_values({1=>[-1,9],10=>[10,90],100=>[100,1000]}));

  my $template = HTML::Template->new(filename => $details_template);
  $template->param(%$info);

  return $template->output();
}

sub template_mappings_SELECT {
  my ($obj, $method, $vals) = @_;
  my $curr_val = $obj->$method;
  return [map {{is_current => $curr_val == $_, $method."_value" => $_}} @$vals];
}

sub template_mappings_PARAMS {
  my ($obj, $method, $id) = @_;
  my $curr_raw_val = $obj->$method;
  my $curr_val = eval $curr_raw_val;
  my $vals;
  for my $param (keys %$curr_val) {
    push @$vals, {"id" => $id, "key" => $param, "value" => $curr_val->{$param}};
  }
  return $vals;
}

sub build_values {
  my ($ranges) = @_;
  my @vals;
  for my $step (keys %$ranges) {
    for (my $i = $ranges->{$step}->[0]; $i <= $ranges->{$step}->[1]; $i+=$step) {
      push @vals, $i;
    }
  }
  return [@vals];
}
