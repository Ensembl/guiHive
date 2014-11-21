#!/usr/bin/env perl

=pod

 Copyright [1999-2014] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

use JSON;
use URI::Escape;

use lib "./lib"; ## Only needed for local testing
use hive_extended;
use msg;
use version_check;

my $json_data = shift @ARGV || '{"adaptor":["PipelineWideParameters"],"method":["store"],"url":["mysql://ensro@127.0.0.1:4306/mm14_protein_trees_78"],"fields":["param_name,param_value"],"args":["a,2"],"version":["62"]}';

my $var = decode_json($json_data);
my $url          = $var->{url}->[0];
my $args         = uri_unescape($var->{args}->[0]);
my $adaptor_name = $var->{adaptor}->[0];
my $method       = $var->{method}->[0];
my $version      = $var->{version}->[0];
my $fields       = $var->{fields}->[0];

my @fields = split(/,/,$fields);
my @args = split(/,/,$args,scalar(@fields));

##### This if is copied over from a script, but I don't know if it's really needed
# If we pass the 'NULL' string, then we undef the value to update a NULL mysql value:
if ((scalar @args == 1) && ($args[0] eq "NULL")) {
  @args = undef;
}

my $dbConn = check_db_versions_match($var);

my $response = msg->new();

$adaptor_name = "get_".$adaptor_name."Adaptor";
my $adaptor = $dbConn->$adaptor_name;

warn Dumper(\@fields, \@args);

my %obj = ();
@obj{@fields} = @args;
warn Dumper(\%obj);
eval {
    $adaptor->$method(\%obj);
};
$response->err_msg($@);
$response->status($response->err_msg) if ($@);



print $response->toJSON();

