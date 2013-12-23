package version_check;

use strict;
use warnings;
use Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(get_hive_code_version get_hive_db_version);

sub get_hive_code_version {
  return Bio::EnsEMBL::Hive::DBSQL::SqlSchemaAdaptor->get_code_sql_schema_version();
}

sub get_hive_db_version {
  my ($dbConn) = @_;
  my $metaAdaptor = $dbConn->get_MetaAdaptor;
  my $db_sql_schema_version = eval { $metaAdaptor->fetch_value_by_key( 'hive_sql_schema_version' ); };
  return $db_sql_schema_version;
}

1;
