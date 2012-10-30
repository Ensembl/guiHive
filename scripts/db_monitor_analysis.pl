#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;
use Data::Dumper; ## needed?

use lib ("./scripts/lib"); ## Only needed for testing the script.
use new_hive_methods; # needed?
use msg;

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69d"], "analysis_id":["22"]}';
my $monitor_template = $ENV{GUIHIVE_BASEDIR} . "static/analysis_monitor.html";

my $var         = decode_json($json_data);
my $url         = $var->{url}->[0];
my $analysis_id = $var->{analysis_id}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response = msg->new();

if (defined $dbConn) {
  my $analysis_stats;
  eval {
    $analysis_stats = $dbConn->get_AnalysisStatsAdaptor->fetch_by_analysis_id($analysis_id);
  };
  if ($@) {
    $response->err_msg("I can't retrieve the analysis_stats with id $analysis_id: $@");
    $response->status("FAILED");
  }
  if (!defined $analysis_stats) {
    $response->err_msg("I can't retrieve analysis_stats with id $analysis_id from the database");
    $response->status("FAILED");
  }
  $response->out_msg(formMonitorInfo($analysis_stats));
} else {
  $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again");
  $response->status("FAILED");
}

print $response->toJSON;

sub formMonitorInfo {
  my ($analysis_stats) = @_;
  my $template = HTML::Template->new(filename => $monitor_template);
  $template->param( 'jobs_total'      => $analysis_stats->total_job_count(),
		    'jobs_done'       => $analysis_stats->done_job_count(),
		    'jobs_failed'     => $analysis_stats->failed_job_count(),
		    'jobs_ready'      => $analysis_stats->ready_job_count(),
		    'jobs_semaphored' => $analysis_stats->semaphored_job_count(),
		    'jobs_running'    => $analysis_stats->inprogress_job_count(),
		    'jobs_remaining'  => $analysis_stats->remaining_job_count(),
			   );
  return $template->output();
}
