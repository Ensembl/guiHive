#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use HTML::Template;
use HTML::Entities;

use Data::Dumper;

use lib ("./scripts/lib");

# Input data
my $json_url = shift @ARGV || '{"version":["53"],"url":["mysql://ensro@127.0.0.1:2911/mp12_long_mult"]}';
my $url = decode_json($json_url)->{url}->[0];
my $version = decode_json($json_url)->{version}->[0];

# Initialization
my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";
my $resources_template = $project_dir . 'static/resources.html';

unshift @INC, $project_dir . "scripts/lib";
require msg;
require hive_extended;

unshift @INC, $project_dir . "ensembl-hive/modules";
require Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
my $response = msg->new();

if (defined $dbConn) {
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

    $info->{"resources"}->[$i]->{"resourceParams"} = [{ "params"   => encode_entities($rd->parameters()),
							"id"       => $rc->dbID(),
							"adaptor"  => "ResourceDescription",
							"method"   => "parameters",
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
