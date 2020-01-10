#!/usr/bin/env perl

=pod

 Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 Copyright [2016-2020] EMBL-European Bioinformatics Institute

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

use JSON;
use Data::Dumper;

use lib("./lib");
use msg;
use analysisInfo;
use hive_extended;
use version_check;

my $json_data = shift @ARGV || '{"version":["62"],"url":["mysql://ensro@mysql-e-farm-test56.ebi.ac.uk:4449/ayates_fastq_align_run2"]}';

my $var = decode_json($json_data);

my $pipeline = check_db_versions_match($var);
my $dbConn = $pipeline->hive_dba;

my $response = msg->new();

my $stats_table_has_data = 0;

  my $all_analysis;
  eval {
    $all_analysis = $pipeline->collection_of( 'Analysis' )->listref;
  };
  if ($@) {
    $response->err_msg("I can't retrieve the analysis from the database: $@");
    $response->status("FAILED");
  }

  $stats_table_has_data = stats_table_is_not_empty($dbConn->dbc->dbname);
  $response->out_msg(formAnalysisInfo($all_analysis));


print $response->toJSON;

sub formAnalysisInfo {
    my ($all_analysis) = @_;
    my %all_analysis_info = ();
    for my $analysis (@$all_analysis) {
      my $analysis_info = analysisInfo->fetch($analysis);

      if ($stats_table_has_data) {
        my ($min_mem, $max_mem, $avg_mem, $min_cpu, $max_cpu, $avg_cpu, $resource_mem) = fetch_stats_worker_resource_usage($analysis);
        $analysis_info->stats($min_mem, $max_mem, $avg_mem, $min_cpu, $max_cpu, $avg_cpu, $resource_mem);
      }

      unless (defined $analysis_info->meadow_type()) {
	my $resource_description = $pipeline->collection_of( 'ResourceDescription' )->find_one_by('resource_class_id', $analysis->resource_class_id);
	if (defined $resource_description) {
	  $analysis_info->meadow_type($resource_description->meadow_type());
	}
      }
      $all_analysis_info{$analysis_info->{logic_name}} = $analysis_info;
    }

    return {%all_analysis_info};
}


sub stats_table_is_not_empty {
  my $sql = "SELECT * FROM worker_resource_usage WHERE exit_status='done' LIMIT 1";
  my $sth = $dbConn->dbc->prepare($sql);
  $sth->execute;
  if ($sth->fetchrow_arrayref) {
    return 1;
  }
  return 0;
}

sub fetch_stats_worker_resource_usage {
  my ($analysis) = @_;
  my $rds = $analysis->hive_pipeline->collection_of('ResourceDescription')->find_all_by('resource_class', $analysis->resource_class);
  my $sql = "SELECT min(mem_megs), max(mem_megs), avg(mem_megs), min(cpu_sec), max(cpu_sec), avg(cpu_sec) from worker_resource_usage join role using(worker_id) join analysis_base using (analysis_id) where analysis_id = ?";
  my $sth = $dbConn->dbc->prepare($sql);

  $sth->execute($analysis->dbID);
  my ($min_mem, $max_mem, $avg_mem, $min_cpu, $max_cpu, $avg_cpu) = $sth->fetchrow_array();
  my $resource_mem = 125;
  foreach my $resource_params (@$rds) {
    ($resource_mem) = $resource_params =~ /mem=(\d+)/;
  }
  return ($min_mem, $max_mem, $avg_mem, sprintf("%.2f",$min_cpu || 0), sprintf("%.2f", $max_cpu || 0), sprintf("%.2f", $avg_cpu || 0), $resource_mem || 125);
}

