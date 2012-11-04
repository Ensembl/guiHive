#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;
use Data::Dumper;

use lib ("./scripts/lib");
use new_hive_methods;
use msg;

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69d"], "analysis_id":["22"], "status":["DONE"]}';
my $jobs_template = $ENV{GUIHIVE_BASEDIR} . "static/jobs.html";

# Input
my $var = decode_json($json_data);
my $url = $var->{url}->[0];
my $analysis_id = $var->{analysis_id}->[0];
my $status = $var->{status}->[0];

# Initialization
my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);
my $response = msg->new();

if (defined $dbConn) {
    my $jobs;
    my $params = {'analysis_id' => $analysis_id};
    $params->{status} = $status if (defined $status);
    eval {
	$jobs = $dbConn->get_AnalysisJobAdaptor()->fetch_jobs(%$params);
    };
    if ($@) {
	$response->err_msg("I can't retrieve jobs with analysis_id $analysis_id and status $status: $@");
	$response->status("FAILED");
    }
    if (! defined $jobs) {
	$response->err_msg("I can't retrieve jobs with analysis_id $analysis_id and status $status: $@");
	$response->status("FAILED");
    }
    $response->out_msg(formJobsInfo($jobs));
} else {
    $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again");
    $response->status("FAILED");
}

print $response->toJSON;

sub formJobsInfo {
# There is no method for prev_job_id. Should we include it?
    my ($jobs) = @_;
    my @all_jobs;
    my @methods = qw/analysis_id input_id worker_id status retry_count completed runtime_msec query_count semaphore_count semaphored_job_id/;
    for my $job (@$jobs) {
	my $job_info;
	$job_info->{job_id} = $job->dbID();
	for my $method (@methods) {
	    $job_info->{$method} = $job->$method;
	}
	push @all_jobs, $job_info;
    }
    my $template = HTML::Template->new(filename => $jobs_template);
    $template->param('job' => [@all_jobs]);
    return $template->output();
}




