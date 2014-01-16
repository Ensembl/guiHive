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

use JSON;
use Data::Dumper;

use lib ("./scripts/lib");
# use hive_extended;
# use msg;

my $json_data = shift @ARGV || '{ "url":["version":["53"],"mysql://ensro@127.0.0.1:2913/mp12_compara_homology_72"],"analysis_id":["116"], "method":["reset_jobs_for_analysis_id"] }';

# Input
my $var          = decode_json($json_data);
my $url          = $var->{url}->[0];
my $analysis_id  = $var->{analysis_id}->[0];
my $method       = $var->{method}->[0];
my $adaptor_name = "AnalysisJob";
my $version      = $var->{version}->[0];

my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";
unshift @INC, $project_dir . "scripts/lib";
require msg;
require hive_extended;

unshift @INC, $project_dir . "ensembl-hive/modules";
require Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

# Initialization
my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
my $response = msg->new();

if (defined $dbConn) {
  $adaptor_name = "get_".$adaptor_name."Adaptor";
  my $adaptor = $dbConn->$adaptor_name;
  eval {
    $adaptor->$method($analysis_id);
  };
  $response->err_msg($@);
  $response->status($response->err_msg) if ($@);
} else {
  $response->err_msg("Error connecting to the database. Please try to connect again");
  $response->status("FAILED");
}

print $response->toJSON();

