#!/usr/bin/env perl

=pod

 Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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
use URI::Escape;

use lib "./lib"; ## Only needed for local testing
use hive_extended;
use msg;
use version_check;

my $json_data = shift @ARGV || '{"adaptor":["PipelineWideParameters"],"method":["store"],"url":["mysql://ensro@127.0.0.1:4306/mm14_protein_trees_78"],"fields":["param_name,param_value"],"args":["a,2"],"version":["62"]}';

my $var = decode_json($json_data);
my $pipeline = check_db_versions_match($var);
my $dbConn = $pipeline->hive_dba;
my $response = msg->new();

warn Dumper $var;

eval {
    my $method = $var->{method}->[0];

    my $adaptor = $dbConn->get_PipelineWideParametersAdaptor();

    if ($method eq 'update_key') {
        my $objs = $adaptor->fetch_all(sprintf('param_name = "%s"', $var->{inikey}->[0]));
        die "I was expecting to find a single object for $var->{inikey}->[0]\n" if not $objs or (scalar(@$objs) != 1);
        $adaptor->remove($objs->[0]);
        my $new_obj = bless { 'param_name' => $var->{key}->[0], 'param_value' => $objs->[0]->{param_value} }, 'Bio::EnsEMBL::Hive::PipelineWideParameters';
        $adaptor->store($new_obj);
    } else {
        my $obj = bless { 'param_name' => $var->{key}->[0], 'param_value' => $var->{value}->[0] }, 'Bio::EnsEMBL::Hive::PipelineWideParameters';
        $adaptor->$method($obj);
    }
};
$response->err_msg($@);
$response->status($response->err_msg) if ($@);

print $response->toJSON();

