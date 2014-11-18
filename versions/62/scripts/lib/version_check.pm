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
use Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(get_hive_code_version get_hive_db_version get_hive_db_meta_key);

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


sub get_hive_db_version {
  my ($dbConn) = @_;
  my $metaAdaptor = $dbConn->get_MetaAdaptor;
  my $db_sql_schema_version;
  eval { $db_sql_schema_version = $metaAdaptor->get_value_by_key( 'hive_sql_schema_version' ); };
  return $db_sql_schema_version;
}


1;
