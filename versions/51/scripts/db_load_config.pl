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

use JSON;
use Data::Dumper;

use lib ("./scripts/lib"); ## Only needed for local testing
#use msg;

my $json_url = shift @ARGV || '{"version":["53"]}';
my $version = decode_json($json_url)->{version}->[0];

unshift @INC, $ENV{GUIHIVE_BASEDIR} . "versions/$version/scripts/lib";
require msg;

my $response = msg->new();
my $hive_config_file = $ENV{GUIHIVE_BASEDIR} . "config/hive_config.json";

if ((-e $hive_config_file) && (-r $hive_config_file)) {
  ## Slurp the file
  my $hive_config_string;
  eval {
    local $/=undef;
    open FILE, $hive_config_file or die "Couldn't open file: $!";
    $hive_config_string = <FILE>;
    close FILE;
  };
  if ($@) {
    $response->status('FAILED');
    $response->err_msg($@);
  } else {
    $response->out_msg($hive_config_string);
  }

} else {
  $response->status('FAILED');
  $response->err_msg("Hive config file: $hive_config_file doesn't exist or is not readable");
}

print $response->toJSON;


