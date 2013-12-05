#!/usr/bin/env perl

use strict;
use warnings;

use JSON;

use lib "./scripts/lib";
#use hive_extended;
# TODO: I am not returning the msg because the inner tables (input_id in jobs table and parameters
# in analysis table) can't be reached by dataTables. This makes difficult to parse the msg message
# and put the corresponding field in the inner cell
#use msg;

my $json_data = shift @ARGV || '{"version":["53"],"adaptor":["AnalysisJob"],"method":["status"],"url":["mysql://ensadmin:ensembl@127.0.0.1:2911/mp12_long_mult"],"value":["DONE"],"dbID":["3,9"]}'; #'{"analysis_id":["2"],"adaptor":["ResourceDescription"],"method":["parameters"],"args":["-C0 -M8000000  -R\"select[mem>8000]  rusage[mem=8000]\""],"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69a2"]}'; #'{"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_69b"], "column_name":["parameters"], "analysis_id":["27"], "newval":["cmalign_exe"]}';

my $var          = decode_json($json_data);
my $url          = $var->{url}->[0];
my $args         = $var->{value}->[0];
my $addArg       = $var->{key}->[0];
my $dbIDs        = $var->{dbID}->[0];
my $adaptor_name = $var->{adaptor}->[0];
my $method       = $var->{method}->[0];
my $version      = $var->{version}->[0];

my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";
unshift @INC, $project_dir . "scripts/lib";
require msg;
require hive_extended;

unshift @INC, $project_dir . "ensembl-hive/modules";
require Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
require Bio::EnsEMBL::Hive::Queen;

my @dbIDs = split(/,/,$dbIDs);
my @args  = ($args); #split(/,/,$args); ### TODO: JEditable only gives one value, so it is not possible to
                              ### pass extra contents here (separated with commas)
                              ### This is why I am using a new addArg parameter.
                              ### So I think we can treat @args as a single $arg
                              ### But we need to double-check that everything works
                              ### and no comma-separated values are passed to this script

## TODO: Maybe we should think about a better way to handle key/value pairs
## for example by having 2 classes with polymorphic methods dependent on the number of arguments
## or have 2 independent scripts, because we have to deal with the 2 cases differently in many 
## places here.

## If the update is associated with a key we need to insert it before the new value
unshift (@args, $addArg) if (defined $addArg);

my $response = msg->new();
my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );

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
      print STDERR "$obj->$method(@args)\n";
      $obj->$method(@args);
      $obj->adaptor->update($obj);
    };
    if ($@) {
      $response->err_msg($@);
      $response->status("FAILED");
    } else {
	if (defined $addArg) { # We need to provide the extra parameter here to get the value of the given key
	    $response->out_msg($obj->$method($addArg));
	} else {
	    # If the method doesn't return anything, the first passed arg is returned
	    # TODO: This is not ideal because break the intention of the code
	    # that is to return what is stored in the db
	    # but we need this here because when adding a new input_id_key
	    # we don't have an addArg and the method without arguments
	    # can't return the correct key
	    $response->out_msg($obj->$method()||$args[0]);
	}
    }
  }
  ## If we change something in the job table, we need to sync the hive to
  ## reflect the changes in the analysis_stats table
  ## We assume that only one analysis_id is changed
  ## If there may be more, we should change synchronize_AnalysisStats for synchronize_hive (without arguments)
  if ($adaptor_name  =~ /AnalysisJob/) {
    $dbConn->get_Queen()->synchronize_AnalysisStats($dbConn->get_AnalysisAdaptor->fetch_by_dbID($objs->[0]->analysis_id)->stats);
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
