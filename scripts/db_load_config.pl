#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use Data::Dumper;

use lib ("./scripts/lib"); ## Only needed for local testing
use msg;

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



