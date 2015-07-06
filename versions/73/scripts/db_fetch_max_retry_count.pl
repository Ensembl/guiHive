#!/usr/bin/env perl

=pod

 Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use JSON::PP;
use Data::Dumper;

my $json_data = shift @ARGV || '{"version":["53"],"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69d"], "job_id":["5"]}';

my $var = decode_json($json_data);
my $url = $var->{url}->[0];
my $job_id = $var->{job_id}->[0];
$job_id =~ s/job_//;

my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new(-no_sql_schema_version_check => 1, -url => $url);

my $resp;
if (defined $dbConn) {
  my $job;
  eval {
    $job = $dbConn->get_AnalysisJobAdaptor()->fetch_by_dbID($job_id);
  };
  if ($@) {
    $resp = "[ERROR]";
  }
  if (!defined $job) {
    $resp = "[ERROR]";
  } else {
    my $analysis_id = $job->analysis_id();
    my $analysis = $dbConn->get_AnalysisAdaptor()->fetch_by_analysis_id($analysis_id);
    my $max_retry_count = $analysis->max_retry_count();
    for my $i (0..$max_retry_count) {
      $resp->{$i} = $i;
    }
  }
}

## keys are sorted in numerical order
my $js = JSON::PP->new->allow_nonref->sort_by(sub {$JSON::PP::a <=> $JSON::PP::b});
print $js->encode($resp);

