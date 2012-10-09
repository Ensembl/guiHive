#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;

use JSON::XS;

use lib "./scripts/lib";
use new_hive_methods;
use msg;

my $json_data = shift @ARGV || '{"adaptor":["ResourceClass"],"args":[""],"method":["create_full_description"],"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69a2"]}';

my $var = decode_json($json_data);
my $url          = $var->{url}->[0];
my $args         = $var->{args}->[0];
my $adaptor_name = $var->{adaptor}->[0];
my $method       = $var->{method}->[0];

my @args = split(/,/,$args);

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

my $response = msg->new();

if (defined $dbConn) {

    $adaptor_name = "get_".$adaptor_name."Adaptor";
    my $adaptor = $dbConn->$adaptor_name;

    eval {
      print STDERR "$adaptor->$method(@args)\n";
      $adaptor->$method(@args);
#      $adaptor->update($obj);
    };
    $response->err_msg($@);
    $response->status($response->err_msg) if ($@);
  } else {
    $response->err_msg("Error connecting to the database. Please try to connect again");
    $response->status("FAILED");
  }

print $response->toJSON();

