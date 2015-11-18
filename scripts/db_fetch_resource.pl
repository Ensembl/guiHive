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

use JSON;
use HTML::Template;
use HTML::Entities;

use Data::Dumper;

use lib ("./scripts/lib");
use msg;
use hive_extended;
use version_check;

# Input data
my $json_url = shift @ARGV || '{"version":["53"],"url":["mysql://ensro@127.0.0.1:2911/mp12_long_mult"]}';

my $decoded_json = decode_json($json_url);

# Initialization
my $project_dir = $ENV{GUIHIVE_BASEDIR};
my $resources_template = $project_dir . 'static/resources.html';

my $dbConn = check_db_versions_match($decoded_json);
my $response = msg->new();

    my $all_resources;
    eval {
	$all_resources = $dbConn->get_ResourceClassAdaptor()->fetch_all();
    };
    if ($@) {
	$response->err_msg("I can't retrieve the resources from the database:$@");
	$response->status("FAILED");
    } else {
	$response->out_msg(formResources($all_resources));
    }

print $response->toJSON();

sub formResources {
  my ($all_resources) = @_;
  my $template = HTML::Template->new(filename => $resources_template);
  my $info;
  my $i = 0;
  for my $rc (sort {$a->dbID <=> $b->dbID} @$all_resources) {
    my $rd = $rc->description();
    my $meadow_type = defined $rd ? $rd->meadow_type : '';
    my $submission_cmd_args = defined $rd ? $rd->submission_cmd_args : '';

    $info->{"resources"}->[$i]->{ 'rcID' } = $rc->dbID;
    $info->{"resources"}->[$i]->{ 'meadow' } = $meadow_type;
    $info->{"resources"}->[$i]->{"resourceName"} = [{ "name"      => $rc->name(),
  						      "id"        => $rc->dbID,
  						      "adaptor"   => "ResourceClass",
  						      "method"    => "name",
  						      "rcName"    => "rc_".$rc->name(),
  						    }];

    $info->{"resources"}->[$i]->{"resourceParams"} = [{ "params"   => encode_entities($submission_cmd_args),
  							"id"       => $rc->dbID(),
  							"adaptor"  => "ResourceDescription",
  							"method"   => "submission_cmd_args",
  							"rcParams" => "rc_".$rc->dbID()."_".$meadow_type,
  						      }];
    $i++;
  }

  $info->{create_resource} = [{ "adaptor"    => "ResourceClass",
				"method"     => "create_full_description",
  			   }],

  $template->param(%$info);
  return $template->output();
}
