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

use JSON;
use Data::Dumper;

use lib("./lib");
use msg;
use analysisInfo;
use hive_extended;
use version_check;

my $json_data = shift @ARGV || '{"version":["56"],"url":["mysql://ensro@127.0.0.1:2911/mm14_protein_trees_75"]}';

my $var = decode_json($json_data);

my $dbConn = check_db_versions_match($var);

my $response = msg->new();


  my $all_analysis;
  eval {
    $all_analysis = $dbConn->get_AnalysisAdaptor()->fetch_all();
  };
  if ($@) {
    $response->err_msg("I can't retrieve the analysis from the database: $@");
    $response->status("FAILED");
  }
  $response->out_msg(formAnalysisInfo($all_analysis));


print $response->toJSON;

sub formAnalysisInfo {
    my ($all_analysis) = @_;
    my %all_analysis_info = ();
    my $resourceClassAdaptor = $dbConn->get_ResourceClassAdaptor();
    for my $analysis (@$all_analysis) {
      my $new_analysis = analysisInfo->fetch($analysis);

      if (lsf_report_exists()) {
	my ($min_mem, $max_mem, $avg_mem, $min_cpu, $max_cpu, $avg_cpu, $resource_mem) = fetch_stats ($analysis->dbID);
	$new_analysis->stats($min_mem, $max_mem, $avg_mem, $min_cpu, $max_cpu, $avg_cpu, $resource_mem);
      }

      unless (defined $new_analysis->meadow_type()) {
	my $resource_description = $resourceClassAdaptor->fetch_by_dbID($analysis->resource_class_id)->description;
	if (defined $resource_description) {
	  $new_analysis->meadow_type($resource_description->meadow_type());
	}
      }
      $all_analysis_info{$new_analysis->{analysis_id}} = $new_analysis;
    }

    return {%all_analysis_info};
}


sub lsf_report_exists {
  my $sql = "SHOW TABLES LIKE 'lsf_report'";
  my $sth = $dbConn->dbc->prepare($sql);
  $sth->execute;
  if ($sth->fetchrow_array) {
    return 1;
  }
  return 0;
}

sub fetch_stats {
  my ($analysis_id) = @_;
  my $sql = "select min(mem_megs), max(mem_megs), avg(mem_megs), min(cpu_sec), max(cpu_sec), avg(cpu_sec), submission_cmd_args from lsf_report join worker using(process_id) join resource_description using(resource_class_id) where analysis_id = ?";
  my $sth = $dbConn->dbc->prepare($sql);

  $sth->execute($analysis_id);

  my ($min_mem, $max_mem, $avg_mem, $min_cpu, $max_cpu, $avg_cpu, $resource_params) = $sth->fetchrow_array();
  my $resource_mem;
  if (! defined $resource_params) {
    $resource_mem = 125;  # Default
  } else {
    ($resource_mem) = $resource_params =~ /mem=(\d+)/;
  }
  return ($min_mem, $max_mem, $avg_mem, sprintf("%.2f",$min_cpu || 0), sprintf("%.2f", $max_cpu || 0), sprintf("%.2f", $avg_cpu || 0), $resource_mem || 125);
}
