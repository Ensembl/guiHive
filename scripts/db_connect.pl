#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use CGI::Pretty;
use JSON::XS;
use Data::Dumper;

my $query = new CGI::Pretty;

my $url = $query->param('db_url') || 'mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69b';

my $remotehost = $query->remote_host();

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
  $resp .= "DB name: ". $dbConn->dbc->dbname. "<br />\n";
  $resp .= "Host: ". $dbConn->dbc->host. "<br />\n";
  $resp .= "Port: ". $dbConn->dbc->port. "<br />\n";
  $resp .= "Driver: ". $dbConn->dbc->driver. "<br />\n";
  $resp .= "Username: ". $dbConn->dbc->username. "<br />\n";
  $resp .= '<\p>';
  return $resp;
}

sub formError {
  return "I can't connect to the database: Please check the URL and try again";
}

sub formAnalyses {
  my ($all_analyses) = @_;
  my $encoded_analyses;
  for my $analysis (@{$all_analyses}) {
    push @$encoded_analyses, $analysis->logic_name();
  }
  return $encoded_analyses;
}
