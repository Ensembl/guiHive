#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use Bio::EnsEMBL::Hive::Utils qw/stringify destringify/;

use JSON::XS;

use msg;

my $json_data = shift @ARGV || '{"action":["delete_param"],"analysis_id":["40"],"column_name":["parameters"],"newval":["mlss_id"],"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"]}'; #'{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"], "column_name":["parameters"], "analysis_id":["27"], "newval":["cmalign_exe"], "action":["del_param"]}';

my $var = decode_json($json_data);
my $url = $var->{url}->[0];
my $analysis_id = $var->{analysis_id}->[0];
my $column_name = $var->{column_name}->[0];
my $newval = $var->{newval}->[0];
my $action = $var->{action}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

my $actions = {
	       'set_val' => \&set_val,
	       'delete_param' => \&del_param,
	      };

my $adaptor_name;

my $response = msg->new();

if (defined $dbConn) {
    my $analysis = $dbConn->get_AnalysisAdaptor->fetch_by_analysis_id($analysis_id);
    my $analysis_stats = $analysis->stats();

    if ($analysis->can($column_name)) {
	$response->status($actions->{$action}->($analysis, $column_name, $newval)); ## Check that the action exists first
    } elsif ($analysis_stats->can($column_name)) {
	$response->status($actions->{$action}->($analysis_stats, $column_name, $newval)); ## Check that the action exists first
    } else {
	$response->status("$column_name is not a valid method in Analysis or AnalysisStats");
    }
} else {
    $response->status("Error connecting to the database. Please try to connect again");
}

print $response->toJSON();

sub set_val {
  my ($obj, $method, $newval) = @_;
  eval { $obj->$method($newval) };
  if ($@) {
      return "Error calling method $method: $@";
  }
  my $adaptor = $obj->adaptor();
  eval { $adaptor->update($obj); };
  if ($@) {
      return "Error writing in the database: $@";
  }
  return;
}

sub del_param {
  my ($obj, $method, $key) = @_;
  # TODO: This pattern is a good candidate for abstraction
  my $curr_raw_parameters = $obj->$method;
  my $curr_parameters = Bio::EnsEMBL::Hive::Utils->destringify($curr_raw_parameters);
  delete $curr_parameters->{$key};
  my $new_raw_parameters = Bio::EnsEMBL::Hive::Utils->stringify($curr_parameters);
  $obj->parameters($new_raw_parameters);
  eval { $obj->adaptor->update($obj) };
  if ($@) {
      return "Error writing to the database: $@";
  }
  return;
}
