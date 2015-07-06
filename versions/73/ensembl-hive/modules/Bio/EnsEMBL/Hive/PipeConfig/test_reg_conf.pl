#!/usr/bin/env perl

use strict;
use warnings;
use Bio::EnsEMBL::Registry;
use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Compara::DBSQL::DBAdaptor;

$ENV{'EHIVE_ROOT_DIR'} = $ENV{'HOME'}.'/work/ensembl-hive';

my $mlm_hive_dba = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new(
    -url => "mysql://ensadmin:$ENV{'ENSADMIN_PSW'}\@localhost/lg4_long_mult;wait_timeout=5",
    -no_sql_schema_version_check => 1,
    -species => 'mlm',
);

Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new(
    -url => "pgsql://ensadmin:$ENV{'ENSADMIN_PSW'}\@localhost/lg4_long_mult",
    -species => 'plm',
    -no_sql_schema_version_check => 1,
);

Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new(
    -url => "sqlite:///lg4_long_mult",
    -species => 'slm',
    -no_sql_schema_version_check => 1,
);

Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new(
    -url => "sqlite:///lg4_long_mult2",
    -species => 'slm2',
    -no_sql_schema_version_check => 1,
);

Bio::EnsEMBL::Compara::DBSQL::DBAdaptor->new(
    -host => 'localhost',
    -user => 'ensadmin',
    -pass => $ENV{'ENSADMIN_PSW'},
    -dbname => 'lg4_long_mult',
    -species => 'clm',
);

1;
