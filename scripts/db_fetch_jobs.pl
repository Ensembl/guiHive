#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;
use Data::Dumper;

use lib ("./scripts/lib");
use msg;

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_long_mult"], "analysis_id":["2"], "status":["DONE"]}';
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
      $jobs = $dbConn->get_AnalysisJobAdaptor()->fetch_all_by_analysis_id_status($analysis_id, $status || undef, undef);
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
    my $adaptor = "AnalysisJob";
    for my $job (@$jobs) {
	my $job_id = $job->dbID();
#       LogMessageAdaptor inherits from 
	my $msg = fetch_last_error_for_jobid($job_id);
#	my $msg = $dbConn->get_LogMessageAdaptor()->fetch_job_messages($job_id)->[0];

	my $unique_job_label = unique_job_label($job);
      my $job_info = { job_id => $job_id,
		       unique_job_label => $unique_job_label,
		       analysis_id => $job->analysis_id(),
		       JOB_INPUT_ID => formInputIDs($job, $unique_job_label, $adaptor),
		       worker_id => $job->worker_id(),
		       JOB_STATUS => [{
				       status => $job->status(),
				       job_label => $unique_job_label,
				       adaptor => $adaptor,
				       method => "status",
				      }],
		       JOB_RETRY_COUNT => [{
					retry_count => $job->retry_count,
					job_label => $unique_job_label,
					adaptor => $adaptor,
					method => "retry_count",
				       }],
		       completed => $job->completed(),
		       runtime_msec => $job->runtime_msec(),
		       query_count  => $job->query_count(),
		       JOB_SEMAPHORE_COUNT => [{
						semaphore_count => $job->semaphore_count(),
						job_label => $unique_job_label,
						adaptor => $adaptor,
						method => "semaphore_count",
					       }],
		       JOB_SEMAPHORED_JOB_ID => [{
						  semaphored_job_id => $job->semaphored_job_id(),
						  job_label => $unique_job_label,
						  adaptor => $adaptor,
						  method => "semaphored_job_id",
						 }],
		       msg => $msg,
		     };

      push @all_jobs, $job_info;
    }

    my $status_col_edit = {
			   field => "status",
			   adaptor => $adaptor,
			   method => "status",
			  };
    my $retry_count_col_edit =  {
				 field => "retry_count",
				 adaptor => $adaptor,
				 method => "retry_count",
				};
    my $template = HTML::Template->new(filename => $jobs_template);
    $template->param('jobs' => [@all_jobs]);
    $template->param('STATUS_COL_EDIT' => [$status_col_edit]);
    $template->param('RETRY_COUNT_COL_EDIT' => [$retry_count_col_edit]);
    return $template->output();
}

sub formInputIDs {
    my ($job, $unique_job_label, $adaptor) = @_;
    my $input_id_hash = eval $job->input_id();
    my $existing_ids = [];
    for my $inputKeyID (keys %$input_id_hash) {
	my $inputPair = {};
	$inputPair->{inputKeyID} = $inputKeyID; # TODO: We may need stringify_if_needed here that is currently defined in db_fetch_analysis.pl
	$inputPair->{job_label}        = $unique_job_label;
	$inputPair->{adaptor}          = $adaptor;
	$inputPair->{method}           = "add_input_id";
	$inputPair->{key}              = $inputKeyID;
	$inputPair->{inputValID}       = $input_id_hash->{$inputKeyID};
	$inputPair->{del_input_id_method} = "delete_input_id";
#	$inputPair->{add_input_id_key_method} = "add_input_id_key";
	push @$existing_ids, $inputPair;
    }
    my $input_ids = [{
	job_label               => $unique_job_label,
	adaptor                 => $adaptor,
	add_input_id_key_method => "add_input_id_key",
	JOB_EXISTING_INPUT_ID   => $existing_ids,
    }];
 
   return $input_ids;
}

sub unique_job_label {
    my ($job) = @_;
    my $job_id = $job->dbID();
    my $unique_job_label = "job_" . $job_id;
    return $unique_job_label;
}

sub fetch_last_error_for_jobid {
    my ($job_id) = @_;

    # LogMessageAdaptor inherits from BaseAdaptor that has a special AUTOLOAD method that is able to return hashes with specific data
    my $all_msgs = $dbConn->get_LogMessageAdaptor()->fetch_by_job_id_HASHED_FROM_log_message_id_and_is_error_TO_msg($job_id);
    my @all_key_errors = grep {$all_msgs->{$_}->{1}} keys %$all_msgs;
    my ($msg_key) = sort {$b<=>$a} @all_key_errors;
    
    my $errmsg = defined ($msg_key)? $all_msgs->{$msg_key}->{1} : "";
    return $errmsg;
}

