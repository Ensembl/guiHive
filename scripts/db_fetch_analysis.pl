#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use JSON;
use HTML::Template;
use Data::Dumper;

use lib ("./scripts/lib");
use hive_extended;
use msg;

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_long_mult"], "analysis_id":["2"]}';
my $details_template = $ENV{GUIHIVE_BASEDIR} . "static/analysis_details.html";

## Input
my $var = decode_json($json_data);
my $url = $var->{url}->[0];
my $analysis_id = $var->{analysis_id}->[0];

## Initialization
my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );
my $response = msg->new();

if (defined $dbConn) {
  my $analysis;
  eval {
    $analysis = $dbConn->get_AnalysisAdaptor()->fetch_by_analysis_id($analysis_id);
  };
  if ($@) {
    $response->err_msg("I can't retrieve analysis with id $analysis_id: $@");
    $response->status("FAILED");
  }
  if (! defined $analysis) {
      $response->err_msg("I can't retrieve analysis with analysis_id $analysis_id from the database");
      $response->status("FAILED");
  }
  $response->out_msg(formAnalysisInfo($analysis));
} else {
  $response->err_msg("The provided URL seems to be invalid. Please check the URL and try again");
  $response->status("FAILED");
}

print $response->toJSON;


sub formAnalysisInfo {
  my ($analysis) = @_;
  my $analysis_stats = $analysis->stats();

  my $info;
  $info->{id}                = $analysis->dbID();
  $info->{logic_name}        = $analysis->logic_name();
  $info->{module}            = [
				{module  => $analysis->module(),
				 id      => $analysis->dbID(),
				 adaptor => "Analysis",
				 method  => "update_module",
				}
			       ];

  $info->{parameters}        = template_mappings_PARAMS($analysis,
							"parameters",
							$analysis->dbID);

  $info->{analysis_capacity} = template_mappings_SELECT("Analysis",
							$analysis,
							"analysis_capacity",
							build_values({0=>["NULL"],
								      1=>[-1,9],
								      10=>[10,90],
								      100=>[100,1000]}),
						       );

  $info->{failed_job_tolerance} = template_mappings_SELECT("Analysis",
							   $analysis,
							   "failed_job_tolerance",
							   build_values({10 => [0,100]}),
 #							   build_values({int($analysis_stats->total_job_count()/10)||1=>[0,$analysis_stats->total_job_count()]}),
							  );

  $info->{max_retry_count}   = template_mappings_SELECT("Analysis",
							$analysis,
							"max_retry_count",
							build_values({1=>[0,3]}),
						       );

  $info->{hive_capacity}     = template_mappings_SELECT("AnalysisStats",
							$analysis_stats,
							"hive_capacity",
							build_values({1=>[-1,9],
								      10=>[10,90],
								      100=>[100,1000]})
						       );

  $info->{priority}          = template_mappings_SELECT("Analysis",
							$analysis,
							"priority",
							build_values({1=>[0,20]}),
						       );

  $info->{batch_size}        = template_mappings_SELECT("AnalysisStats",
							$analysis_stats,
							"batch_size",
							build_values({1=>[0,9],
								      10=>[10,90],
								      100=>[100,1000]}),
						       );

  $info->{can_be_empty}      = template_mappings_SELECT("Analysis",
							$analysis,
							"can_be_empty",
							build_values({1=>[0,1]}),
						       );

  $info->{meadow_type}       = template_mappings_SELECT("Analysis",
							$analysis,
							"meadow_type",
							build_values({0=>["NULL","LOCAL","LSF"]}));

  $info->{resource_class_id} = template_mappings_SELECT("Analysis",
							$analysis,
						       "resource_class_id",
						       get_resource_class_ids());

  $info->{discard_ready_jobs}    = [{
				    method => "discard_ready_jobs",
				    adaptor => "AnalysisJob",
				    id      => $analysis_id
				   }];

  $info->{failed_jobs_to_ready} = [{
				   method  => "reset_jobs_for_analysis_id",
				   adaptor => "AnalysisJob",
				   id      => $analysis_id
				   }];

  $info->{done_jobs_to_ready} = [{
				   method  => "reset_jobs_and_semaphores_for_analysis_id",
				   adaptor => "AnalysisJob",
				   id      => $analysis_id
				   }];

  $info->{forgive_failed_jobs} = [{
				   method  => "forgive_failed_jobs",
				   adaptor => "AnalysisJob",
				   id      => $analysis_id
				   }];

  $info->{unblock_jobs} = [{
			    method  => "unblock_jobs",
			    adaptor => "AnalysisJob",
			    id      => $analysis_id
			   }];

  my $template = HTML::Template->new(filename => $details_template);
  $template->param(%$info);

  return $template->output();
}

sub module_mappings {
  my ($obj, $method) = @_;
  my $module = $obj->$method;
  return [
	  {"module"  => $module,
	   "id"      => $obj->dbID,
	   "adaptor" => "Analysis",
	   "method"  => "module",
	  }
	 ];
}

sub template_mappings_PARAMS {
  my ($obj, $method) = @_;
  my $curr_raw_val = $obj->$method;
  my $curr_val = eval $curr_raw_val;
  my $vals;
  my $adaptor = "Analysis";
  my $i = 0;
  for my $param (keys %$curr_val) {
    push @{$vals->{existing_parameters}}, {
					   "key"              => $param,
					   "parameterKeyID"   => "p_$param",
					   "parameterValueID" => "v_$param",
					   "value"            => stringify_if_needed($curr_val->{$param}),
					  };

    push @{$vals->{existing_parameters}->[$i]->{delete_parameter}}, {"id"             => $obj->dbID,
								     "adaptor"        => $adaptor,
								     "method"         => "delete_param",
								     "parameterKeyID" => "p_$param",
								    };
    push @{$vals->{existing_parameters}->[$i]->{change_parameter}}, {"id"               => $obj->dbID,
								     "adaptor"          => $adaptor,
								     "method"           => "add_param",
								     "parameterKeyID"   => "p_$param",
								     "parameterValueID" => "v_$param",
								    };
    $i++;
  }
  $vals->{new_parameter} = [{"id"     => $obj->dbID,
			    "adaptor" => $adaptor,
			    "method"  => "add_param",
			   }],
  return [$vals];
}

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

## build_values creates a range of values given its input
## The input is a hashref where the keys are the steps
## and the values are arrayrefs with the first and final values of that range
## Return value is an arrayref with all the generated values
## This method doesn't make sure that the current value is in the range. That
## is a job for the generator of the "selects" elements
sub build_values {
  my ($ranges) = @_;
  my @vals;
  @vals = @{$ranges->{0}} if (defined $ranges->{0});
  delete $ranges->{0};
  for my $step (keys %$ranges) {
    for (my $i = $ranges->{$step}->[0]; $i <= $ranges->{$step}->[1]; $i+=$step) {
      push @vals, $i;
    }
  }
  return [@vals];
}

sub template_mappings_SELECT {
  my ($adaptor, $obj, $method, $vals, $displays) = @_;

  # We have to make sure that the current value as one of the possible values to choose from
  # If the value is undefined (hive_capacity and analysis_capacity can be NULL, for example)
  # We insert the string "NULL"
  my $curr_val = $obj->$method;
  $curr_val = "NULL" unless(defined $curr_val);

  $vals = insert_val_if_needed($vals,$curr_val);

  ## In case the value and its display should be different
  $displays = $vals unless (defined $displays);

  my @final_vals = ();
  for (my $i=0; $i<scalar(@$vals); $i++) {
      push @final_vals, [$vals->[$i], $displays->[$i]];
  }

  return [{"id"       => $obj->can("analysis_id") ? $obj->analysis_id : $obj->dbID,
	   "adaptor"  => $adaptor,
	   "method"   => $method,
	   "values"   => [map {{is_current => $curr_val eq $_->[0], $method."_value" => $_->[0], $method."_display" => $_->[1]}} @final_vals],
	  }];
}

sub get_resource_class_ids {
    my $rcs;
    for my $rc (@{$dbConn->get_ResourceClassAdaptor()->fetch_all}) {
	$rcs->{$rc->dbID} = $rc->name;
    }
    my (@ids, @names);
    for my $rc_id (sort {$a <=> $b} keys %$rcs) {
	push @ids, $rc_id;
	push @names, "$rc_id (" . $rcs->{$rc_id} . ")";
    }
    return [@ids], [@names];
}

## insert_val_if_needed takes an ordered array ref of numbers and a value
## and inserts it in the correct position (if the value is not in the array ref)
## The value can be of a different type (for example, "undef" in
## an array ref with numbers.
sub insert_val_if_needed {
  # We may be doing string and numeric comparisons, so we turn off
  # this kind of warnings for this function
  no warnings 'numeric';

  my ($arref, $newVal) = @_;

  if ($newVal > $arref->[$#{$arref}]) {
    return [(@{$arref}, $newVal)];
  }

  if ($newVal < $arref->[0]) {
    return [($newVal, @{$arref})];
  }

  for (my $i=0; $i<scalar(@$arref); $i++) {
    if ($arref->[$i] eq $newVal) {
      return $arref;
    }
    next if ($i == scalar(@$arref - 1));
    if ( ($arref->[$i] < $newVal) &&
	 ($arref->[$i+1] > $newVal) ) {
      return [(@{$arref}[0..$i], $newVal, @{$arref}[$i+1..$#{$arref}])];
    }
  }
  return [($newVal, @$arref)];
}
