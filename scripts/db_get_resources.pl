#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use CGI::Pretty;
use JSON::XS;
use Data::Dumper;

my $query = new CGI::Pretty;

my $url = $query->param('db_url') || 'mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69b';

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response;

if (defined $dbConn) {
  my $resource_classes;
  eval {
    $all_resource_classes = $dbConn->get_ResourceClassAdaptor->fetch_all();
  };
  if ($@) {
    die "Can't connect to database\n";
  }
}

## This should be included in db_connect.pl
