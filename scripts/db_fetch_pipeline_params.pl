#!/usr/bin/env perl

=pod

 Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 Copyright [2016] EMBL-European Bioinformatics Institute

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

use JSON;
use HTML::Template;
use Data::Dumper;

use lib ("./lib");
use hive_extended;
use msg;
use version_check;

my $json_data = shift @ARGV || '{"version":["62"],"url":["mysql://ensro@127.0.0.1:4306/mm14_protein_trees_78b"]}';

main($json_data);

sub main {
    ## Input
    my $decoded_json = decode_json($json_data);

    ## Initialization
    my $pipeline = check_db_versions_match($decoded_json);
    my $response = msg->new();

    eval {
        my $all_params_hash = { map { $_->{'param_name'} => $_->{'param_value'} } $pipeline->collection_of( 'PipelineWideParameters' )->list };
        die "all_params_hash is undefined\n" unless $all_params_hash;
        $response->out_msg(formPipelineWideParameters($all_params_hash));
    };
    if ($@) {
        $response->err_msg("I can't retrieve the pipeline-wide parameters: $@");
        $response->status("FAILED");
    }

    print $response->toJSON;
}

sub formPipelineWideParameters {
    my ($all_params_hash) = @_;

    my $project_dir = $ENV{GUIHIVE_BASEDIR};
    my $details_template = $project_dir . "static/pipeline_wide_parameters.html";
    my $template = HTML::Template->new(filename => $details_template);
    $template->param(%{ template_mappings_PARAMS($all_params_hash) });
    return $template->output();
}


sub template_mappings_PARAMS {
    my ($all_params_hash) = @_;
    my @existing_parameters;
    my $i = 0;
    for my $param (sort keys %$all_params_hash) {
        my $this_param_data = {
            "key"              => $param,
            "value"            => stringify_if_needed($all_params_hash->{$param}),
            "param_index"      => $i,
        };
        push @existing_parameters, $this_param_data;
        $i++;
    }
    return { 'existing_parameters' => \@existing_parameters };
}

sub stringify_if_needed {
  my ($scalar) = @_;
  if (ref $scalar) {
    local $Data::Dumper::Indent    = 0;  # we want everything on one line
    local $Data::Dumper::Terse     = 1;  # and we want it without dummy variable names
    local $Data::Dumper::Sortkeys  = 1;  # make stringification more deterministic

    return Dumper($scalar);
  }
  return $scalar;
}


