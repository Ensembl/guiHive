#!/usr/bin/env perl

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


