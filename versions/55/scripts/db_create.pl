#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use JSON;

use lib "./scripts/lib";
# use hive_extended;
# use msg;

my $json_data = shift @ARGV || '{"version":["53"],"adaptor":["ResourceClass"],"args":["new_resource_class", "LSF", "-q ok"],"method":["create_full_description"],"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69a2"]}';

my $var = decode_json($json_data);
my $url          = $var->{url}->[0];
my $args         = $var->{args}->[0];
my $adaptor_name = $var->{adaptor}->[0];
my $method       = $var->{method}->[0];
my $version      = $var->{version}->[0];

my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";
unshift @INC, $project_dir . "scripts/lib";
require msg;
require hive_extended;

unshift @INC, $project_dir . "ensembl-hive/modules";
require Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

my @args = split(/,/,$args);

my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );

my $response = msg->new();

if (defined $dbConn) {

    $adaptor_name = "get_".$adaptor_name."Adaptor";
    my $adaptor = $dbConn->$adaptor_name;

    eval {
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

