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


package version_check;

use strict;
use warnings;
use JSON;
use Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor;

use msg;

use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(get_hive_code_version get_hive_db_meta_key check_db_versions_match);

sub get_hive_code_version {
  return Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor->get_code_sql_schema_version();
}

sub get_hive_db_meta_key {
  my ($dbConn, $key_name) = @_;
  my $metaAdaptor = $dbConn->get_MetaAdaptor;
  my $val;
  eval { $val = $metaAdaptor->get_value_by_key( $key_name ); };
  return $val;
}

sub _fail_with_status_message {
    my ($status, $message) = @_;
    my $response = msg->new();
    $response->err_msg($message);
    $response->status($status);
    print $response->toJSON;
    exit(0);
}

sub check_db_versions_match {
    my ($decoded_json, $silent) = @_;

    # Input data
    my $url = $decoded_json->{url}->[0];
    my $version = $decoded_json->{version}->[0];

    my $response = msg->new();

    # Initialization
    my $dbConn;
    eval {
        $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
    };
    if ($@) {
        exit(0) if $silent;
        _fail_with_status_message('FAILED', $@);
    }

    if (defined $dbConn) {
        ## Check if the code version is OK
        my $code_version = $version || get_hive_code_version();
        my $hive_db_version;
        eval {
            $hive_db_version = get_hive_db_meta_key($dbConn, 'hive_sql_schema_version');
        };
        if ($@) {
            exit(0) if $silent;
            _fail_with_status_message('FAILED', $@);
        }

        if ($code_version != $hive_db_version) {
            exit(0) if $silent;
            _fail_with_status_message('VERSION MISMATCH', "$code_version $hive_db_version");
        }

    } else {
        exit(0) if $silent;
        _fail_with_status_message('FAILED', "The provided URL seems to be invalid. Please check the URL and try again\n");
    }

    return $dbConn;
}


1;
