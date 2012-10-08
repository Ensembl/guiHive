#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;

use Data::Dumper;

use lib ("./scripts/lib");
use analysis_parameters;
use msg;

# Input data
my $json_url = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"]}';
my $resources_template = $ENV{GUIHIVE_BASEDIR} . 'static/resources.html';
my $url = decode_json($json_url)->{url}->[0];

# Initialization
my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response = msg->new();

if (defined $dbConn) {
    my $all_resources;
    eval {
	$all_resources = $dbConn->get_ResourceClassAdaptor()->fetch_all();
    };
    if ($@) {
	$response->err_msg("I can't retrieve the resources: $@");
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
    for my $rc (@$all_resources) {
	my $rd = $rc->description();
	$info->{"resources"}->[0]->{"resourceName"} = [{ "name"      => $rc->name(),
				     "id"        => $rc->dbID,
				     "adaptor"   => "ResourceClass",
				     "method"    => "name",
				     "rcName"    => "rc_".$rc->name(),
				   }];
	$info->{"resources"}->[0]->{"resourceMeadow"} = [{ "meadow"    => $rd->meadow_type(),
				       "id"        => $rc->dbID(),
				       "adaptor"   => "ResourceDescription",
				       "method"    => "meadow_type",
				       "rcMeadow"  => "rc_".$rc->dbID()."_".$rd->meadow_type(),
				     }];
	$info->{"resources"}->[0]->{"resourceParams"} = [{ "params"   => $rd->parameters(),
				       "id"       => $rc->dbID(),
				       "adaptor"  => "ResourceDescription",
				       "method"   => "parameters",
				       "rcParams" => "rc_".$rc->dbID()."_".$rd->meadow_type."_".join("",$rd->parameters),
				     }];
	$info->{"resources"}->[0]->{ 'rcID' } = $rc->dbID;
    }
    $template->param(%$info);
    return $template->output();
}
