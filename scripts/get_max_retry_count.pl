#!/usr/bin/env perl

use strict;
use warnings;
use JSON::XS;
use Data::Dumper;

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69d"]&"job_id"';
