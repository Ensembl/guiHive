#!/usr/bin/env perl

=pod

 Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 Copyright [2016] EMBL-European Bioinformatics Institute

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
use hive_extended;
use msg;
use version_check;

my $json_data = shift @ARGV || '{"version":["53"],"url":["mysql://ensro@127.0.0.1:2911/mp12_long_mult"], "analysis_id":["1"]}';

## Input
my $var = decode_json($json_data);
my $analysis_id = $var->{analysis_id}->[0];

my $project_dir = $ENV{GUIHIVE_BASEDIR};
my $details_template = $project_dir . "static/analysis_details.html";

## Initialization
my $dbConn = check_db_versions_match($var);
my $response = msg->new();

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
				 method  => "module",
				}
			       ];

  $info->{parameters}        = template_mappings_PARAMS($analysis,
							"parameters",
							$analysis->dbID);

  $info->{analysis_capacity} = template_mappings_SELECT("Analysis",
							$analysis,
							"analysis_capacity",
							build_values({0=>["NULL", "0"],  ## values
								      1=>[1,9],
								      10=>[10,90],
								      100=>[100,1000]}),
							build_values({0=>["NULL (unlimited)", "0 (blocked)"],   ## displays
								      1=>[1,9],
								      10=>[10,90],
								      100=>[100,1000]
								     })
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
							build_values({0=>["NULL"],
								      1=>[0,9],
								      10=>[10,90],
								      100=>[100,1000]}),
							build_values({0=>["NULL (unlimited)", "0 (blocked)"],   ## displays
								      1=>[1,9],
								      10=>[10,90],
								      100=>[100,1000]
								     })

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
				   method  => "reset_jobs_for_analysis_id_and_sync",
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


sub template_mappings_PARAMS {
  my ($obj, $method) = @_;
  my $curr_raw_val = $obj->$method;
  my $curr_val = eval $curr_raw_val;
  my $vals;
  my $adaptor = "Analysis";
  my $i = 0;
  for my $param (sort keys %$curr_val) {
    push @{$vals->{existing_parameters}}, {
					   "key"              => $param,
					   "parameterKeyID"   => "p_$param",
					   "parameterValueID" => "v_$param",
					   "value"            => stringify_if_needed($curr_val->{$param}),
					  };

    push @{$vals->{existing_parameters}->[$i]->{delete_parameter}}, {"id"             => $obj->dbID,
								     "adaptor"        => $adaptor,
								     "method"         => "delete_param_THEN_update_parameters",
								     "parameterKeyID" => "p_$param",
								    };
    push @{$vals->{existing_parameters}->[$i]->{change_parameter}}, {"id"               => $obj->dbID,
								     "adaptor"          => $adaptor,
								     "method"           => "add_param_THEN_update_parameters",
								     "parameterKeyID"   => "p_$param",
								     "parameterValueID" => "v_$param",
								    };
    $i++;
  }
  $vals->{new_parameter} = [{"id"     => $obj->dbID,
			    "adaptor" => $adaptor,
			    "method"  => "add_param_THEN_update_parameters",
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
  for my $step (sort { $a <=> $b } keys %$ranges) {
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

  my $newVals = insert_val_if_needed($vals,$curr_val);
  if ((defined $displays) && (scalar(@$newVals) != scalar(@$vals))) {
    $displays = insert_val_if_needed($displays,$curr_val);
  }

  ## In case the value and its display should be different
  $displays = $newVals unless (defined $displays);

  my @final_vals = ();
  for (my $i=0; $i<scalar(@$newVals); $i++) {
      push @final_vals, [$newVals->[$i], $displays->[$i]];
  }

  return [{"id"       => $obj->isa('Bio::EnsEMBL::Hive::AnalysisStats') ? $obj->analysis_id : $obj->dbID,
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
	push @names, sprintf('%s (%d)', $rcs->{$rc_id}, $rc_id);
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
#    next if ($i == scalar(@$arref - 1));
    if ( ($arref->[$i] < $newVal) &&
	 ($arref->[$i+1] > $newVal) ) {
      return [(@{$arref}[0..$i], $newVal, @{$arref}[$i+1..$#{$arref}])];
    }
  }
  return [($newVal, @$arref)];
}
