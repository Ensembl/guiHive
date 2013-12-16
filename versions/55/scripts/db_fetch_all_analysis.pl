#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Data::Dumper;

#use lib ("./scripts/lib");
# use analysisInfo;
# use hive_extended;
# use msg;

my $json_data = shift @ARGV || '{"version":["53"],"url":["mysql://ensadmin:ensembl@127.0.0.1:2914/mp12_compara_nctrees_74sheep"]}';

my $var = decode_json($json_data);
my $url = $var->{url}->[0];
my $version = $var->{version}->[0];

my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";

unshift @INC, $project_dir. "scripts/lib";
require msg;
require analysisInfo;
require hive_extended;

unshift @INC, $project_dir. "ensembl-hive/modules/";
require Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );

my $response = msg->new();

if (defined $dbConn) {
    my $all_analysis;
    eval {
	$all_analysis = $dbConn->get_AnalysisAdaptor()->fetch_all();
    };
    if ($@) {
	$response->err_msg("I can't retrieve the analysis from the database: $@");
	$response->status("FAILED");
    }
    $response->out_msg(formAnalysisInfo($all_analysis));

} else {
    $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again");
}

print $response->toJSON;

sub formAnalysisInfo {
    my ($all_analysis) = @_;
    my %all_analysis_info = ();
    my $resourceClassAdaptor = $dbConn->get_ResourceClassAdaptor();
    for my $analysis (@$all_analysis) {
      my $new_analysis = analysisInfo->fetch($analysis);

      if (lsf_report_exists()) {
	my ($min_mem, $max_mem, $avg_mem, $resource_mem) = fetch_mem ($analysis->dbID);
	$new_analysis->mem($min_mem, $max_mem, $avg_mem, $resource_mem);
      }

      $new_analysis->meadow_type($resourceClassAdaptor->fetch_by_dbID($analysis->resource_class_id)->description->meadow_type());
      $all_analysis_info{$new_analysis->{analysis_id}} = $new_analysis;
#      push @all_analysis_info, $new_analysis;
    }

    my @all_analysis_info = ();
    for my $pos (keys %all_analysis_info) {
      $all_analysis_info[$pos] = $all_analysis_info{$pos};
    }

    return [@all_analysis_info];
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

sub fetch_mem {
  my ($analysis_id) = @_;
  my $sql = "select min(mem_megs), max(mem_megs), avg(mem_megs), submission_cmd_args from lsf_report join worker using(process_id) join resource_description using(resource_class_id) where analysis_id = ?";
  my $sth = $dbConn->dbc->prepare($sql);

  eval {
      $sth->execute($analysis_id);
  };
  my ($min_mem, $max_mem, $avg_mem, $resource_params) = $sth->fetchrow_array();
  my $resource_mem;
  if (! defined $resource_params) {
    $resource_mem = 125;  # Default
  } else {
    ($resource_mem) = $resource_params =~ /mem=(\d+)/;
  }
  return ($min_mem, $max_mem, $avg_mem, $resource_mem || 125);
}
