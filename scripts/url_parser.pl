#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use Bio::EnsEMBL::Hive::Utils::URL;

use JSON;
use lib ("../lib");
use msg;

my $json_url = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2914/mp12_compara_nctrees_72"]}';
# Input data
my $url = decode_json($json_url)->{url}->[0];
my $response = msg->new();

my $dbConn = Bio::EnsEMBL::Hive::Utils::URL::parse($url);

if (defined $dbConn) {
  $response->{'out_msg'} = {
			    'user'   => $dbConn->{user},
			    'dbname' => $dbConn->{dbname},
			    'host'   => $dbConn->{host},
			    'port'   => $dbConn->{port},
			    'passwd' => $dbConn->{pass},
	     };
} else {
  $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again\n") unless($response->err_msg);
  $response->status("FAILED");
}

print $response->toJSON();


