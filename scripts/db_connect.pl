#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;
use HTML::Entities;

use lib ("./scripts/lib");
use analysis_parameters;
use msg;

# Input data
my $json_url = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"]}';
my $url = decode_json($json_url)->{url}->[0];

# Initialization
my $analyses_template = $ENV{GUIHIVE_BASEDIR} . 'static/pipeline_diagram.html';
my $resources_template = $ENV{GUIHIVE_BASEDIR} . 'static/resources.html';
my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response = msg->new();

if (defined $dbConn) {
  my $all_analyses;
  my $all_resources;
  eval {
    $all_analyses = $dbConn->get_AnalysisAdaptor()->fetch_all();
    $all_resources = $dbConn->get_ResourceClassAdaptor()->fetch_all();
  };
  if ($@) {
      $response->err_msg("I have problems retrieving data from the database:\n$@");
      $response->status("FAILED");
  } else {
      $response->status(formResponse($dbConn));
      $response->out_msg({"analyses" => formAnalyses($all_analyses),
			  "resources" => formResources($all_resources),
			 });
  }
} else {
    $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again\n");
    $response->status("FAILED");
}

print $response->toJSON();

sub formResponse {
  my ($dbConn) = @_;
  my $resp;
  $resp .= "<p>";
  $resp .= "DB name: ". $dbConn->dbc->dbname. "<br />";
  $resp .= "Host: ". $dbConn->dbc->host. "<br />";
  $resp .= "Port: ". $dbConn->dbc->port. "<br />";
  $resp .= "Driver: ". $dbConn->dbc->driver. "<br />";
  $resp .= "Username: ". $dbConn->dbc->username. "<br />";
  $resp .= "</p>";
  return $resp;
}

sub formAnalyses {
    my ($all_analyses) = @_;
    my $template = HTML::Template->new(filename => $analyses_template);
    $template->param(analyses => [ map{ {logic_name_id => $_->logic_name, logic_name => $_->logic_name} } @$all_analyses] );
    return $template->output();
}

sub formResources {
    my ($all_resources) = @_;
    my $template = HTML::Template->new(filename => $resources_template);
    my $info;
    my $i = 0;
    for my $rc (sort {$a->dbID <=> $b->dbID} @$all_resources) {
	my $rd = $rc->description();
	$info->{"resources"}->[$i]->{"resourceName"} = [{ "name"      => $rc->name(),
							  "id"        => $rc->dbID,
							  "adaptor"   => "ResourceClass",
							  "method"    => "name",
							  "rcName"    => "rc_".$rc->name(),
							}];
	$info->{"resources"}->[$i]->{"resourceMeadow"} = [{ "meadow"    => $rd->meadow_type(),
							    "id"        => $rc->dbID(),
							    "adaptor"   => "ResourceDescription",
							    "method"    => "meadow_type",
							    "rcMeadow"  => "rc_".$rc->dbID()."_".$rd->meadow_type(),
							  }];
	$info->{"resources"}->[$i]->{"resourceParams"} = [{ "params"   => encode_entities($rd->parameters()),
							    "id"       => $rc->dbID(),
							    "adaptor"  => "ResourceDescription",
							    "method"   => "parameters",
							    "rcParams" => encode_entities("rc_".$rc->dbID()."_".$rd->meadow_type."_".join("",$rd->parameters)),
							  }];
	$info->{"resources"}->[$i]->{ 'rcID' } = $rc->dbID;
	$i++;
    }
    $template->param(%$info);
    return $template->output();
}

