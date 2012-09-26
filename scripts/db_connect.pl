#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;
use Data::Dumper;

my $json_url = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"]}';
my $analyses_template = '../static/pipeline_diagram.html'; # use BASEDIR or something similar

my $url = decode_json($json_url)->{url}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response;

if (defined $dbConn) {
  my $all_analyses;
  eval {
    $all_analyses = $dbConn->get_AnalysisAdaptor()->fetch_all();
  };
  if ($@) {
    $response->{status} = formError();
  } else {
    $response->{status} = formResponse($dbConn);
    $response->{analyses} = formAnalyses($all_analyses);
  }
} else {
  $response->{status} = formError();
}

print encode_json($response);

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

sub formError {
  return "I can't connect to the database: Please check the URL and try again";
}

sub formAnalyses_ {
  my ($all_analyses) = @_;
  my $encoded_analyses = "<p>";
  for my $analysis (@{$all_analyses}) {
#    push @$encoded_analyses, $analysis->logic_name();
      $encoded_analyses .= $analysis->logic_name(). "<br />";
  }
  $encoded_analyses .= "</p>";
  return $encoded_analyses;
}

sub formAnalyses {
    my ($all_analyses) = @_;
    my $template = HTML::Template->new(filename => $analyses_template);
    $template->param(analyses => [ map{ {logic_name_id => $_->logic_name, logic_name => $_->logic_name} } @$all_analyses] );
    return $template->output();
}
