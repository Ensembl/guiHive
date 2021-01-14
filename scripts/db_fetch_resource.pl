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
use HTML::Template;
use HTML::Entities;

use Data::Dumper;

use lib ("./scripts/lib");
use msg;
use hive_extended;
use version_check;

# Input data
my $json_data = shift @ARGV || '{"version":["53"],"url":["mysql://ensro@127.0.0.1:2911/mp12_long_mult"]}';

main($json_data);

sub main {
    my ($json_url) = @_;
    ## Input
    my $decoded_json = decode_json($json_url);

    ## Initialization
    my $dbConn = check_db_versions_match($decoded_json);
    my $response = msg->new();

    eval {
        $response->out_msg(formResources($dbConn));
    };
    if ($@) {
	$response->err_msg("I can't retrieve the resources from the database:$@");
	$response->status("FAILED");
    }

    print $response->toJSON();
}

sub formResources {
    my ($dbConn) = @_;

    my $project_dir = $ENV{GUIHIVE_BASEDIR};
    my $resources_template = $project_dir . 'static/resources.html';
    my $template = HTML::Template->new(filename => $resources_template);

    my $all_resources = $dbConn->get_ResourceClassAdaptor()->fetch_all();
    my $rd_adaptor = $dbConn->get_ResourceDescriptionAdaptor;
    my %meadow_types = ('LOCAL' => 1);

    my @param_rc = ();
    for my $rc (sort {$a->dbID <=> $b->dbID} @$all_resources) {
        my $all_rds = $rd_adaptor->fetch_all_by_resource_class_id($rc->dbID);
        my @param_rd = ();
        foreach my $rd (sort {$a->meadow_type <=> $b->meadow_type} @$all_rds) {
            $meadow_types{$rd->meadow_type} = 1;
            push @param_rd, {
                'rcID' => $rc->dbID,
                'meadow_type' => $rd->meadow_type,
                'submission_cmd_args' => encode_entities($rd->submission_cmd_args || ''),
                'worker_cmd_args' => encode_entities($rd->worker_cmd_args || ''),
                'rd_desc' => "rc_".$rc->dbID()."_".$rd->meadow_type,
            };
        }
        push @param_rc, {
            'rcID' => $rc->dbID,
            'name' => $rc->name(),
            'rd'   => \@param_rd,
            'n_rd' => scalar(@param_rd),
        } if @param_rd;
    }

    my %toplevel_params = (
        'resources' => \@param_rc,
        'available_meadow_types' => [map {{'meadow_type' => $_}} sort (keys %meadow_types)],
        'used_resource_classes' => [map {{'resource_class' => $_->name}} sort {$a->name cmp $b->name} @$all_resources],
    );

    $template->param(%toplevel_params);
        #'resources' => \@param_rc, 'available_meadow_types' => [map {{'meadow_type' => $_}} (keys %meadow_types)]);
    return $template->output();
}
