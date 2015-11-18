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

use Bio::EnsEMBL::Hive::Utils::Graph;
use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor;

use JSON;
use HTML::Template;

use lib ("./lib");
use msg;
use version_check;

my $json_url = shift @ARGV || '{"version":["53"],"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_74clean2"]}';

# Input data
my $url = decode_json($json_url)->{url}->[0];

# Set up @INC and paths for static content
my @hive_config_files = ($ENV{GUIHIVE_BASEDIR}.'/config/hive_config.json', $ENV{EHIVE_ROOT_DIR}.'/hive_config.json');
my $connection_template = $ENV{GUIHIVE_BASEDIR}."/static/connection_details.html";

my $response = msg->new();


# Initialization
my $dbConn;
eval {
  $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
};
if ($@) {
  $response->err_msg($@);
  $response->status("FAILED");
  print $response->toJSON;
  exit(0);
}

if (defined $dbConn) {
  ## Check if the code version is OK
  my $code_version = get_hive_code_version();
  my $hive_db_version;
  eval {
    $hive_db_version = get_hive_db_version($dbConn);
  };
  if ($@) {
    $response->err_msg($@);
    $response->status("FAILED");
    print $response->toJSON;
    exit(0);
  }

  if ($code_version != $hive_db_version) {
    $response->status("VERSION MISMATCH");
    $response->err_msg("$code_version $hive_db_version");
    print $response->toJSON;
    exit 0;
  }

  my ($graph, $html);
  eval {
	$graph = formAnalyses($dbConn);
	$html = formResponse($dbConn);
    };
    if ($@) {
	$response->err_msg("I have problems retrieving data from the database:$@");
	$response->status("FAILED");
    } else {
	$response->out_msg({"graph" => $graph,
			    "html" => $html});
    }
} else {
    $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again\n") unless($response->err_msg);
    $response->status("FAILED");
}

print $response->toJSON();

sub formResponse {
    my ($dbConn) = @_;
    my $info;

    $info->{db_name}   = $dbConn->dbc->dbname;
    $info->{host}      = $dbConn->dbc->host;
    $info->{port}      = $dbConn->dbc->port;
    $info->{driver}    = $dbConn->dbc->driver;
    $info->{username}  = $dbConn->dbc->username;
    $info->{hive_db_version} = get_hive_db_version($dbConn);
    $info->{hive_code_version} = get_hive_code_version();

    my $template = HTML::Template->new(filename => $connection_template);
    $template->param(%$info);
    return $template->output();
}

sub formAnalyses {
    my ($dbConn) = @_;
    my $graph = Bio::EnsEMBL::Hive::Utils::Graph->new($dbConn, @hive_config_files);
    my $graphviz = $graph->build();

    return $graphviz->as_svg;
}


