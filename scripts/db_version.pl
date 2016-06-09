#!/usr/bin/env perl

=pod

 Copyright [1999-2016] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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

## The servers should have already set the PERL5LIB to point to the latest hive API in versions
use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Hive::Utils::URL;

use JSON;
use lib ("../lib");
use msg;

my $response = msg->new();

main();

sub main {
    my $json_input_with_url = shift @ARGV
        or report_failure_and_exit( 'This script needs one argument formatted in JSON like so:  {"url":["mysql://username:password@hostname:portnumber/database_name"]}');

    my $url = decode_json($json_input_with_url)->{url}->[0];

    $url=~s/^\s+//;     # remove leading whitespace - the most common problem when people copy-and-paste URLs around

    my $hive_dba;
    eval {  # ------------------------- can we create the DBAdaptor?
        $hive_dba = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
    } or do {
        report_failure_and_exit( $@ || "Could not create a valid Hive DBAdaptor from URL: $url" );
    };

    eval {  # ------------------------- can we connect this DBAdaptor?
        $hive_dba->dbc->connect;
        1;
    } or do {
        report_failure_and_exit( "Could not connect using URL: $url" );
    };

    my $hive_db_version;
    eval {  # ------------------------- can we come up with a valid version?
        $hive_db_version = get_hive_db_version($hive_dba);
    } or do {
        report_failure_and_exit( $@ || "No version found in the database accessible via URL: $url" );
    };

    my $parsed_url = Bio::EnsEMBL::Hive::Utils::URL::parse($url);
    my $json_obj = {
        'user'       => $parsed_url->{user},
        'passwd'     => $parsed_url->{pass},
        'host'       => $parsed_url->{host},
        'port'       => $parsed_url->{port},
        'dbname'     => $parsed_url->{dbname},
        'db_version' => $hive_db_version,
    };

    $response->out_msg($json_obj);
    print $response->toJSON();
}


sub report_failure_and_exit {
    my ($error_message) = @_;

    $response->err_msg( $error_message );
    $response->status("FAILED");
    print $response->toJSON();
    exit 0;
}


sub get_hive_db_version {
    my ($hive_dba) = @_;

    my $metaAdaptor = $hive_dba->get_MetaAdaptor;
    my $db_sql_schema_version;
    eval {
        $db_sql_schema_version =
            $metaAdaptor->can('fetch_value_by_key') ? $metaAdaptor->fetch_value_by_key( 'hive_sql_schema_version' )
          : $metaAdaptor->can('get_value_by_key')   ? $metaAdaptor->get_value_by_key( 'hive_sql_schema_version' )
          :                                           $metaAdaptor->fetch_by_meta_key( 'hive_sql_schema_version' )->{'meta_value'};
    };
    return $db_sql_schema_version;
}
