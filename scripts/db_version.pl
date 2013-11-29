#!/usr/bin/env perl

use strict;
use warnings;

## These are probably the ones already in PERL5LIB
use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor;
use Bio::EnsEMBL::Hive::Utils::URL;

use JSON;

use lib ("../lib");
use msg;

my $json_url = shift @ARGV || '{"url":["mysql://ensro@127.0.0.1:2914/mp12_compara_nctrees_74sheep"]}';

# Input data
my $url = decode_json($json_url)->{url}->[0];

my $response = msg->new();

# Initialization
my $dbConn;
eval {
  $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
};

if ($@) {
  $response->err_msg($@);
  $response->status("FAILED");
}

if (defined $dbConn) {

  my $hive_db_version = get_hive_db_version($dbConn);
  if (defined $hive_db_version) {
    my $parsed_url = Bio::EnsEMBL::Hive::Utils::URL::parse($url);
    my $json_obj = { 'user'       => $parsed_url->{user},
		     'dbname'     => $parsed_url->{dbname},
		     'host'       => $parsed_url->{host},
		     'port'       => $parsed_url->{port},
		     'passwd'     => $parsed_url->{pass},
		     'db_version' => $hive_db_version,
		   };

    $response->out_msg($json_obj);
  } else {
    $response->err_msg("No version found for db");
    $response->status("FAILED");
  }
} else {
  $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again\n") unless($response->err_msg);
  $response->status("FAILED");
}

print $response->toJSON();

#######################
#  This method is also defined in scripts/db_connect.pl
sub get_hive_db_version {
  my ($dbConn) = @_;
  my $metaAdaptor      = $dbConn->get_MetaAdaptor;
  my $db_sql_schema_version   = eval { $metaAdaptor->fetch_value_by_key( 'hive_sql_schema_version' ); };
  return $db_sql_schema_version;
}
