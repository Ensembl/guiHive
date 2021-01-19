#!/usr/bin/env perl

=pod

 Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 Copyright [2016-2021] EMBL-European Bioinformatics Institute

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.


=cut


use strict;
use warnings;

use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Hive::Utils::Graph;
use JSON;
use Data::Dumper;

use lib ("./scripts/lib");  # Only needed for testing the script
use hive_extended;   # needed?
use msg;

## colors encoding the different job status we may have
my $job_colors = {
		  'semaphored' => 'yellow',
		  'ready'      => 'cyan',
		  'inprogress' => 'blue',
		  'failed'     => 'red',
		  'done'       => 'green',
		 };

my $json_data = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69d"], "analysis_id":["22"]}';

my $var         = decode_json($json_data);
my $analysis_id = $var->{analysis_id}->[0];

my $pipeline = check_db_versions_match($var);
my $dbConn = $pipeline->hive_dba;
my $response = msg->new();

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

print $response->toJSON;

sub formMonitorInfo {
  my ($analysis_stats) = @_;
  my $config = Bio::EnsEMBL::Hive::Utils::Config->new();
  my $status = $analysis_stats->status();
  my $status_colour = $config->get('Graph', 'Node', $analysis_stats->status, 'Colour');
  my ($breakout_label, $total_job_count, $job_counts) = $analysis_stats->job_count_breakout();

  my $full_status = {status => $status_colour,
		     breakout_label => $breakout_label,
		     total_job_count => $total_job_count,
		     jobs_counts => {
				     counts => [],
				     colors => [],
				    },
		    };


  for my $job_status (qw/semaphored ready inprogress failed done/) {
    my $job_status_full = $job_status . "_job_count";
    my $count = $job_counts->{$job_status_full};
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
