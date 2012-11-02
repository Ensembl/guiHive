#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use Bio::EnsEMBL::Hive::Utils::Graph;
use JSON::XS;
use Data::Dumper;

use lib ("./scripts/lib");  # Only needed for testing the script
use new_hive_methods;   # needed?
use msg;

## colors encoding the different job status we may have
my $job_colors = {
		  'semaphored' => 'yellow',
		  'ready'      => 'cyan',
		  'inprogress' => 'blue',
		  'failed'     => 'red',
		  'done'       => 'green',
		 };

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69d"], "analysis_id":["22"]}';

my $var         = decode_json($json_data);
my $url         = $var->{url}->[0];
my $analysis_id = $var->{analysis_id}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response = msg->new();

if (defined $dbConn) {
    my $analysis_stats;
    eval {
	$analysis_stats = $dbConn->get_AnalysisStatsAdaptor->fetch_by_analysis_id($analysis_id);
    };
    if ($@) {
	$response->err_msg("In can't retrieve the analysis_stats with id $analysis_id: $@");
	$response->status("FAILED");
    }
    if (!defined $analysis_stats) {
	$response->err_msg("I can't retrieve analysis_stats with id $analysis_id from the database");
	$response->status("FAILED");
    }
    $response->out_msg(formMonitorInfo($analysis_stats));
} else {
    $response->err_msg("The provided URL seems to be invalid. Please check it and try again");
    $response->status("FAILED");
}

print $response->toJSON;

sub formMonitorInfo {
  my ($analysis_stats) = @_;
  my $config = Bio::EnsEMBL::Hive::Utils::Config->new();
  my $status = $analysis_stats->status();
  my $status_colour = $config->get('Graph', 'Node', $analysis_stats->status, 'Colour');
  my $full_status = {status => $status_colour,
		     jobs   => {
				counts => [],
				colors => [],
			       },
		    };

  for my $job_status (qw/semaphored ready inprogress failed done/) {
    my $method_name = ${job_status} . "_job_count";
    my $count = $analysis_stats->$method_name;
      push @{$full_status->{jobs}->{counts}}, $count+0;
      push @{$full_status->{jobs}->{colors}}, $job_colors->{$job_status};
  }

  # We can't have all zeros
  if (sum($full_status->{jobs}->{counts})) {
    push @{$full_status->{jobs}->{counts}}, 0;
  } else {
    push @{$full_status->{jobs}->{counts}}, 1;
  }
  push @{$full_status->{jobs}->{colors}}, "white";

  return $full_status;
}

sub sum {
  my ($arr) = @_;
  my $res = 0;
  for my $i (@$arr) {
    $res+=$i;
  }
  return $res;
}
