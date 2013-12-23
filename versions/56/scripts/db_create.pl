#!/usr/bin/env perl

=pod

 Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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
use Data::Dumper;

use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

use JSON;

use lib "./lib";
use hive_extended;
use msg;
use version_check;

my $json_data = shift @ARGV || '{"version":["53"],"adaptor":["ResourceClass"],"args":["new_resource_class", "LSF", "-q ok"],"method":["create_full_description"],"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69a2"]}';

my $var = decode_json($json_data);
my $url          = $var->{url}->[0];
my $args         = $var->{args}->[0];
my $adaptor_name = $var->{adaptor}->[0];
my $method       = $var->{method}->[0];
my $version      = $var->{version}->[0];

my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";

my @args = split(/,/,$args);

my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );

my $response = msg->new();

if (defined $dbConn) {

  ## First check if the code version is OK
  my $code_version = get_hive_code_version();
  my $hive_db_version = get_hive_db_version($dbConn);

  if ($code_version != $version) {
    $response->status("VERSION MISMATCH");
    $response->err_msg("$code_version $hive_db_version");
    print $response->toJSON;
    exit 0;
  }

    $adaptor_name = "get_".$adaptor_name."Adaptor";
    my $adaptor = $dbConn->$adaptor_name;

    eval {
      $adaptor->$method(@args);
#      $adaptor->update($obj);
    };
    $response->err_msg($@);
    $response->status($response->err_msg) if ($@);
  } else {
    $response->err_msg("Error connecting to the database. Please try to connect again");
    $response->status("FAILED");
  }

print $response->toJSON();

