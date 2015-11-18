#!/usr/bin/env perl

use strict;
use warnings;

    # Finding out own path in order to reference own components (including own modules):
use Cwd            ();
use File::Basename ();
BEGIN {
    $ENV{'EHIVE_ROOT_DIR'} ||= File::Basename::dirname( File::Basename::dirname( Cwd::realpath($0) ) );
    unshift @INC, $ENV{'EHIVE_ROOT_DIR'}.'/modules';
}

use Getopt::Long;
use Bio::EnsEMBL::Hive::DBSQL::DBConnection;


sub main {
    my $url;

    GetOptions(
            'url=s'             => \$url,
    );

    if($url) {
        my $dbc = Bio::EnsEMBL::Hive::DBSQL::DBConnection->new( -url => $url )
            || die "Could not parse URL '$url'";

        my $sql = "UPDATE hive_meta SET meta_value=63 WHERE meta_key='hive_sql_schema_version' AND meta_value='62'";
        my $sth = $dbc->do( $sql );

    } else {
        die "Please provide -url parameter to this patch script";
    }
}

main();

