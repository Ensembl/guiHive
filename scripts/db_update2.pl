#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;

use JSON::XS;

use lib "./scripts/lib";
use new_hive_methods;
use msg;

my $json_data = shift @ARGV || '{"adaptor":["AnalysisJob"],"id":[""],"method":["status"],"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_long_mult"],"value":["DONE"],"dbID":["8"]}'; #'{"analysis_id":["2"],"adaptor":["ResourceDescription"],"method":["parameters"],"args":["-C0 -M8000000  -R\"select[mem>8000]  rusage[mem=8000]\""],"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69a2"]}'; #'{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"], "column_name":["parameters"], "analysis_id":["27"], "newval":["cmalign_exe"]}';

my $var          = decode_json($json_data);
my $url          = $var->{url}->[0];
my $args         = $var->{value}->[0];
my $dbIDs        = $var->{dbID}->[0];
my $adaptor_name = $var->{adaptor}->[0];
my $method       = $var->{method}->[0];

my @dbIDs = split(/,/,$dbIDs);
my @args  = split(/,/,$args);

my $response = msg->new();
my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

if (defined $dbConn) {

  $adaptor_name = "get_".$adaptor_name."Adaptor";
  my $adaptor = $dbConn->$adaptor_name;

  my ($objs, $failed) = fetch_objs($adaptor, @dbIDs);

  if ($failed) {
    $response->err_msg("Error getting these objects from the database: $failed");
    $response->status("FAILED");
  }

  for my $obj (@$objs) {
    eval {
      $obj->$method(@args);
      $obj->adaptor->update($obj);
    };
    if ($@) {
      $response->err_msg($@);
      $response->status("FAILED");
    } else {
      $response->out_msg($obj->$method());
    }
  }

} else {
  $response->err_msg("Error connecting to the database. Please try to connect again");
  $response->status("FAILED");
}

print $response->toJSON();

## TODO: Maybe this one can be abstracted
sub fetch_objs {
  my ($adaptor, @dbIDs) = @_;
  my @objs;
  my @failed_ids;
  for my $dbID (@dbIDs) {
    my $obj = $adaptor->fetch_by_dbID($dbID);
    unless ($obj) {
      push @failed_ids, $dbID;
    }
    push @objs, $obj;
  }
  return ([@objs], join (",", @failed_ids));
}
