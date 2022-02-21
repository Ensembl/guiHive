#!/usr/bin/env perl

=pod

 Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 Copyright [2016-2022] EMBL-European Bioinformatics Institute

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
use Bio::EnsEMBL::Hive::HivePipeline;

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

my $pipeline = check_db_versions_match($decoded_json);
my $dbConn = $pipeline->hive_dba;

eval {
    my $graph = formAnalyses($pipeline);
    if ($graph) {
        my $html = formResponse($pipeline);
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
    my ($hive_pipeline) = @_;

    my $dbc = $pipeline->hive_dba->dbc;

    my $info;

    $info->{db_name}   = $dbc->dbname;
    $info->{host}      = $dbc->host;
    $info->{port}      = $dbc->port;
    $info->{driver}    = $dbc->driver;
    $info->{username}  = $dbc->username;
    $info->{hive_db_version} = $hive_pipeline->hive_sql_schema_version();
    $info->{hive_code_version} = get_hive_code_version();
    $info->{pipeline_name} = $hive_pipeline->hive_pipeline_name();
    $info->{hive_auto_rebalance_semaphores} = $hive_pipeline->hive_auto_rebalance_semaphores() ? 'Enabled' : 'Disabled';
    $info->{hive_use_param_stack} = $hive_pipeline->hive_use_param_stack() ? 'Enabled' : 'Disabled';
    $info->{hive_default_max_retry_count} = $hive_pipeline->hive_default_max_retry_count();

    my $template = HTML::Template->new(filename => $connection_template);
    $template->param(%$info);
    return $template->output();
}

sub formAnalyses {
    my ($pipeline) = @_;

    my $graph = Bio::EnsEMBL::Hive::Utils::Graph->new($pipeline, @hive_config_files);
    my $graphviz = $graph->build();

    return $graphviz->as_svg;
}
