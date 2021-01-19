#!/usr/bin/env perl

=pod

 Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 Copyright [2016-2021] EMBL-European Bioinformatics Institute

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
my @hive_config_files = ($ENV{EHIVE_ROOT_DIR}.'/hive_config.json', $ENV{GUIHIVE_BASEDIR}.'/config/hive_config.json');

# Input data
my $decoded_json = decode_json($json_url);

# Set up @INC and paths for static content
my $connection_template = $ENV{GUIHIVE_BASEDIR} . "static/connection_details.html";

my $response = msg->new();

my $dbConn = check_db_versions_match($decoded_json);

$dbConn->load_collections();

eval {
    my $graph = formAnalyses($dbConn);
    if ($graph) {
        my $html = formResponse($dbConn);
        $response->out_msg({"graph" => $graph, "html" => $html});
    } else {
        $response->err_msg('GraphViz failed to generate a diagram');
        $response->status("FAILED");
    }
};
if ($@) {
    $response->err_msg("I have problems retrieving data from the database:$@");
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
    $info->{hive_db_version} = get_hive_db_meta_key($dbConn, 'hive_sql_schema_version');
    $info->{hive_code_version} = get_hive_code_version();
    $info->{pipeline_name} = get_hive_db_meta_key($dbConn, 'hive_pipeline_name');
    $info->{hive_auto_rebalance_semaphores} = get_hive_db_meta_key($dbConn, 'hive_auto_rebalance_semaphores') ? 'Enabled' : 'Disabled';
    $info->{hive_use_param_stack} = get_hive_db_meta_key($dbConn, 'hive_use_param_stack') ? 'Enabled' : 'Disabled';

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
