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


#!/usr/bin/env perl

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
my $url = decode_json($json_url)->{url}->[0];
my $version = decode_json($json_url)->{version}->[0];

# Initialization
my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";
my $resources_template = $project_dir . 'static/resources.html';

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
} else {
    $response->err_msg("The provided URL seems to be invalid. Please check it and try again\n");
    $response->status("FAILED");
}

print $response->toJSON();

sub formResources {
  my ($all_resources) = @_;
  my $template = HTML::Template->new(filename => $resources_template);
  my $info;
  my $i = 0;
  for my $rc (sort {$a->dbID <=> $b->dbID} @$all_resources) {
    my $rd = $rc->description();
    $info->{"resources"}->[$i]->{ 'rcID' } = $rc->dbID;
    $info->{"resources"}->[$i]->{ 'meadow' } = $rd->meadow_type();

    $info->{"resources"}->[$i]->{"resourceName"} = [{ "name"      => $rc->name(),
  						      "id"        => $rc->dbID,
  						      "adaptor"   => "ResourceClass",
  						      "method"    => "name",
  						      "rcName"    => "rc_".$rc->name(),
  						    }];

    $info->{"resources"}->[$i]->{"resourceParams"} = [{ "params"   => encode_entities($rd->submission_cmd_args()),
  							"id"       => $rc->dbID(),
  							"adaptor"  => "ResourceDescription",
  							"method"   => "submission_cmd_args",
  							"rcParams" => "rc_".$rc->dbID()."_".$rd->meadow_type(),
  						      }];
    $i++;
  }

  $info->{create_resource} = [{ "adaptor"    => "ResourceClass",
				"method"     => "create_full_description",
  			   }],

  $template->param(%$info);
  return $template->output();
}
