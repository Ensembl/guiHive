#!/usr/bin/env perl

=pod

 Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 Copyright [2016-2020] EMBL-European Bioinformatics Institute

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

use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Hive::Utils::Graph;
use Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor;

use JSON;
use HTML::Template;

use lib ("./scripts/lib");
use msg;
use version_check;

my $url = shift @ARGV;
my $connection_template = "static/connection_details.html";
my $hive_config_file = "config/hive_config.json";

my $dbConn = check_db_versions_match($var);

my $response = msg->new();
    my ($graph, $status);
    eval {
	$graph = formAnalyses($dbConn);
	$status = formResponse($dbConn);
    };
    if ($@) {
	$response->err_msg("I have problems retrieving data from the database:$@");
	$response->status("FAILED");
    } else {
	$response->status($status);
	$response->out_msg($graph);
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
    $info->{hive_db_version} = get_hive_db_meta_key('hive_sql_schema_version');
    $info->{hive_code_version} = get_hive_code_version();
    # $info->{mysql_url} = "?username=" . $dbConn->dbc->username . "&host=" . $dbConn->dbc->host . "&dbname=" . $dbConn->dbc->dbname . "&port=" . $dbConn->dbc->port;

    my $template = HTML::Template->new(filename => $connection_template);
    $template->param(%$info);
    return $template->output();
}

sub formAnalyses {
    my ($dbConn) = @_;
    my $graph = Bio::EnsEMBL::Hive::Utils::Graph->new($dbConn, $hive_config_file);
    my $graphviz = $graph->build();

    return $graphviz->as_svg;
}

