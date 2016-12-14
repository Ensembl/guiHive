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
my $dbConn = check_db_versions_match($var);
my $response = msg->new();

warn Dumper $var;

eval {
    my $method = $var->{method}->[0];

    my $rc_adaptor = $dbConn->get_ResourceClassAdaptor();
    my $rd_adaptor = $dbConn->get_ResourceDescriptionAdaptor();

    if ($method eq 'update_class_name') {
        my $class = $rc_adaptor->fetch_by_dbID($var->{rcID}->[0]);
        $class->name($var->{new_name}->[0]);
        $rc_adaptor->update($class);
    } elsif ($method eq 'update_description_meadow') {
        my $rd = $rd_adaptor->fetch_by_resource_class_id_AND_meadow_type($var->{rcID}->[0], $var->{meadow_type}->[0]);
        $rd->submission_cmd_args($var->{new_args}->[0]);
        $rd_adaptor->update($rd);
    } elsif ($method eq 'update_description_worker') {
        my $rd = $rd_adaptor->fetch_by_resource_class_id_AND_meadow_type($var->{rcID}->[0], $var->{meadow_type}->[0]);
        $rd->worker_cmd_args($var->{new_args}->[0]);
        $rd_adaptor->update($rd);
    } elsif ($method eq 'create_full_description') {
        my $class = $rc_adaptor->fetch_by_name( $var->{class_name}->[0] );
        if (not $class) {
            use Bio::EnsEMBL::Hive::ResourceClass;
            $class = Bio::EnsEMBL::Hive::ResourceClass->new( 'name' => $var->{class_name}->[0] );
            $rc_adaptor->store($class);
        }
        use Bio::EnsEMBL::Hive::ResourceDescription;
        my $rd = Bio::EnsEMBL::Hive::ResourceDescription->new(
            'resource_class' => $class,
            'meadow_type' => $var->{meadow_type}->[0],
            'submission_cmd_args' => $var->{submission_cmd_args}->[0],
            'worker_cmd_args' => $var->{worker_cmd_args}->[0],
        );
        $rd_adaptor->store($rd);
    } elsif ($method eq 'remove') {
        my $rd = $rd_adaptor->fetch_by_resource_class_id_AND_meadow_type($var->{rcID}->[0], $var->{meadow_type}->[0]);
        $rd_adaptor->remove($rd);
        my $all_rds = $rd_adaptor->fetch_all_by_resource_class_id($rd->resource_class_id);
        if (scalar(@$all_rds) == 0) {
            $rc_adaptor->remove($rd->resource_class);
        }
    }
};
$response->err_msg($@);
$response->status($response->err_msg) if ($@);

print $response->toJSON();

