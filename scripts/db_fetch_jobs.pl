#!/usr/bin/env perl

=pod

 Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 Copyright [2016-2020] EMBL-European Bioinformatics Institute

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


use strict;
use warnings;

use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

use JSON;
use HTML::Template;
use Data::Dumper;

use lib ("./lib");
use msg;
use hive_extended;
use version_check;

my $json_data = shift @ARGV || '{"version":["53"],"url":["mysql://ensro@127.0.0.1:2899/tm6_qc_pipeline_chicken_72_full_pipeline"],"analysis_id":["1"],"sSortDir_0":["asc"],"iDisplayLength":["10"],"iDisplayStart":["0"],"iSortCol_0":["0"],"iSortingCols":["1"]}';

# Input
my $var = decode_json($json_data);
my $analysis_id    = $var->{analysis_id}->[0];

my $sSearch        = $var->{sSearch}->[0];
my $bRegex         = $var->{bRegex}->[0];
my $iSortingCols   = $var->{iSortingCols}->[0];
my $sEcho          = $var->{sEcho}->[0];
my $version        = $var->{version}->[0];

my $project_dir = $ENV{GUIHIVE_BASEDIR};
my $input_ids_template = $project_dir . "static/jobs_input_ids.html";

# Initialization
my $dbConn = check_db_versions_match($var);
my $response = msg->new();


    my $jobs;
    my $njobs;
    my ($constraints, $final_clause) = constraints($var);
    eval {
      ## TODO: If the jobs are very short, we get some inconsistency between the jobs fetched and the number of jobs
      ## We can't assument that $njobs = scalar @$jobs because the $final_clause include a LIMIT
      ## So, for now $njobs is "aproximate"
      $jobs = $dbConn->get_AnalysisJobAdaptor()->fetch_all("WHERE " . $constraints . " " . $final_clause);
      $njobs = $dbConn->get_AnalysisJobAdaptor()->count_all($constraints);
    };
    if ($@) {
	$response->err_msg("I can't retrieve jobs with analysis_id $analysis_id: $@");
	$response->status("FAILED");
    }
    if (! defined $jobs) {
	$response->err_msg("I can't retrieve jobs with analysis_id $analysis_id: $@");
	$response->status("FAILED");
    }
    $response->out_msg(formJobsInfo($jobs, $analysis_id, $njobs));

print encode_json($response->out_msg);
#print $response->toJSON;

sub formJobsInfo {
  my ($jobs, $analysis_id, $iTotalDisplayRecords) = @_;
  my $adaptor = "AnalysisJob";

  my $iTotalRecords = $dbConn->get_AnalysisJobAdaptor()->count_all("analysis_id = '$analysis_id'");
  my @aaData;

  my $template = HTML::Template->new(filename=> $input_ids_template);

  for my $job (@$jobs) {
    my $job_id = $job->dbID();
    my $msg = fetch_last_error_for_jobid($job_id);
    my $unique_job_label = unique_job_label($job);
    $template->param('JOB_INPUT_ID' => formInputIDs($job, $unique_job_label, $adaptor));
    push @aaData, { "0" => { 'value' => $job_id,
			     'id'    => $unique_job_label
			   },
		    "1" => $job->analysis_id(),
		    "2" => $template->output(),
		    "3" => $job->worker_id,
		    "4" => { 'value'     => $job->status(),
			     'job_label' => $unique_job_label,
			     'adaptor'   => $adaptor,
			     'method'    => "status"
			   },
		    "5" => { 'value'     => $job->retry_count(),
			     'job_label' => $unique_job_label,
			     'adaptor'   => $adaptor,
			     'method'    => 'retry_count'
			   },
		    "6" => $job->when_completed(),
		    "7" => $job->runtime_msec(),
		    "8" => { 'value'     => $job->semaphore_count(),
			     'job_label' => $unique_job_label,
			     'adaptor'   => $adaptor,
			     'method'    => 'semaphore_count'
			   },
		    "9" => $job->semaphored_job_id(),
		    "10" => $msg,
		  };
  }
  my $response = {
		  "iTotalRecords" => $iTotalRecords,
		  "iTotalDisplayRecords" => $iTotalDisplayRecords,
		  "sEcho"  => $sEcho,
		  "aaData" =>  [@aaData],
		 };

  return $response;
}

sub formInputIDs {
    my ($job, $unique_job_label, $adaptor) = @_;
    my $input_id_hash = eval $job->input_id();
    my $existing_ids = [];
    for my $inputKeyID (sort keys %$input_id_hash) {
	my $inputPair = {};
	$inputPair->{inputKeyID}       = $inputKeyID; # TODO: We may need stringify_if_needed here
	                                              #       that is currently defined in db_fetch_analysis.pl
	$inputPair->{job_label}        = $unique_job_label;
	$inputPair->{adaptor}          = $adaptor;
	$inputPair->{method}           = "add_input_id";
	$inputPair->{key}              = $inputKeyID;
	$inputPair->{inputValID}       = stringify_if_needed($input_id_hash->{$inputKeyID});
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

sub constraints {
  my ($var) = @_;
  my @columns = qw/job_id analysis_id input_id worker_id status retry_count completed runtime_msec semaphore_count semaphored_job_id msg/;

  ## For more information on these values, please see:
  # http://datatables.net/usage/server-side

  ## GROUP & LIMIT:
  my $iDisplayStart  = $var->{iDisplayStart}->[0];
  my $iDisplayLength = $var->{iDisplayLength}->[0];

  my $iSortCol_0     = $var->{iSortCol_0}->[0]; # The first column index we are sorting on
  my $order_by       = $columns[$iSortCol_0];
  my $order_dir      = $var->{sSortDir_0}->[0];
  my $final_clause   = get_final_clause($order_by, uc($order_dir), $iDisplayStart, $iDisplayLength);
  ## Constraints
  my $analysis_id = $var->{analysis_id}->[0];
  my %constraints = ('analysis_id' => $analysis_id);
  for (my $i = 0; $i < scalar @columns; $i++) {
    my $sSearch = $var->{"sSearch_$i"}->[0];
    next if (!$sSearch || $sSearch eq '~');
    if ($sSearch =~ /~/) {
      ## Range
      my ($from, $to) = split /~/, $sSearch;
      $constraints{$columns[$i]} = [$from, $to];
    } else {
      if ($var->{"bRegex_$i"}->[0] eq "true") {
	$constraints{$columns[$i]} = [$sSearch];
      } else {
	$constraints{$columns[$i]} = $sSearch;
      }
    }
  }
  return (_merge_constraints(\%constraints), $final_clause);
}

sub _merge_constraints {
  my ($constraints) = @_;
  my @constraints_strs = ();
  for my $constr (keys %$constraints) {
    if (ref ($constraints->{$constr}) eq "ARRAY") {
      if (scalar @{$constraints->{$constr}} > 1) {
	push @constraints_strs, "$constr >= " . $constraints->{$constr}->[0];
	push @constraints_strs, "$constr <= " . $constraints->{$constr}->[1];
      } else {
	push @constraints_strs, "$constr LIKE '%" . $constraints->{$constr}->[0] . "%'";
      }
    } else {
      push @constraints_strs, "$constr = '" . $constraints->{$constr}. "'";
    }
  }
  return join " AND ", @constraints_strs;
}

sub get_final_clause {
  my ($order_by, $dir, $iDisplayStart, $iDisplayLength) = @_;
  return   "ORDER BY $order_by $dir LIMIT $iDisplayLength OFFSET $iDisplayStart"
}

## TODO: There is more than 1 instance of this sub in the scripts. Factor out
sub stringify_if_needed {
  my ($scalar) = @_;
  if (ref $scalar) {
    local $Data::Dumper::Indent    = 0;  # we want everything on one line
    local $Data::Dumper::Terse     = 1;  # and we want it without dummy variable names
    local $Data::Dumper::Sortkeys  = 1;  # make stringification more deterministic

    return Dumper($scalar);
  }
  return $scalar;
}
