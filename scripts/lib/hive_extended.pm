=pod

 Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 Copyright [2016-2021] EMBL-European Bioinformatics Institute

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


# This module contains several methods that I would like to see
# in the Hive API but it is unlikely that they get into it.
# 
# They are convenient to simplify constructs like:
# $obj->$method(@args);
#
# and work with (for example):
# $analysis_stats->hive_capacity(555);
# and
# $analysis->delete_param("mlss_id");
# or
# $analysis->add_param("mlss_id", 40086);
#
# The cost is not being coded in the class itself
#

package hive_extended;

use strict;
use warnings;
use Data::Dumper;
no warnings "once";

use Bio::EnsEMBL::Hive::Utils;
use Bio::EnsEMBL::Hive::ResourceClass;
use Bio::EnsEMBL::Hive::ResourceDescription;
use Bio::EnsEMBL::Hive::DBSQL::BaseAdaptor;

# add_input_id_key adds a new key with empty value
*Bio::EnsEMBL::Hive::AnalysisJob::add_input_id_key = sub {
    my ($self, $key) = @_;
    my $value = "";
    $self->add_input_id($key, $value);
    return $key;
};

# add_input_id adds/change a single input_id key/value pair in the AnalysisJob table
# if no new value is provided, the current value is returned
*Bio::EnsEMBL::Hive::AnalysisJob::add_input_id = sub {
  Bio::EnsEMBL::Hive::Utils->import(qw/stringify destringify/);
    my ($self, $key, $value) = @_;
    my $curr_raw_input_id = $self->input_id;
    $curr_raw_input_id = '{}' unless ($curr_raw_input_id);
    my $curr_input_id = Bio::EnsEMBL::Hive::Utils::destringify($curr_raw_input_id);
    return $curr_input_id->{$key} unless (defined $value);
    $curr_input_id->{$key} = Bio::EnsEMBL::Hive::Utils::destringify($value);
    my $new_raw_input_id = Bio::EnsEMBL::Hive::Utils::stringify($curr_input_id);
    $self->input_id($new_raw_input_id);
    return $value;
};

# delete_input_id deletes a single input_id key/value pair in the AnalysisJob table
*Bio::EnsEMBL::Hive::AnalysisJob::delete_input_id = sub {
  Bio::EnsEMBL::Hive::Utils->import(qw/stringify destringify/);
    my ($self, $key) = @_;
    my $curr_raw_input_id = $self->input_id;
    my $curr_input_id = Bio::EnsEMBL::Hive::Utils::destringify($curr_raw_input_id);
    delete $curr_input_id->{$key};
    my $new_raw_parameters = Bio::EnsEMBL::Hive::Utils::stringify($curr_input_id);
    $self->input_id($new_raw_parameters);
    return;
};

# delete_param deletes a single param in the param table by key
# It is injected in the Analysis object directly so it works as a 
# native method of the object
*Bio::EnsEMBL::Hive::Analysis::delete_param = sub {
  Bio::EnsEMBL::Hive::Utils->import(qw/stringify destringify/);
    my ($self, $key) = @_;
    my $curr_raw_parameters = $self->parameters;
    my $curr_parameters = Bio::EnsEMBL::Hive::Utils->destringify($curr_raw_parameters);
    delete $curr_parameters->{$key};
    my $new_raw_parameters = Bio::EnsEMBL::Hive::Utils->stringify($curr_parameters);
    $self->parameters($new_raw_parameters);
    return;
};

# add_param adds/change a single param in the param table by key
# It is injected in the Analysis object directly so it works as a 
# native method of the object
*Bio::EnsEMBL::Hive::Analysis::add_param = sub {
  Bio::EnsEMBL::Hive::Utils->import(qw/stringify destringify/);
    my ($self, $key, $value) = @_;
    my $curr_raw_parameters = $self->parameters;
    $curr_raw_parameters = '{}' unless ($curr_raw_parameters);
    my $curr_parameters = Bio::EnsEMBL::Hive::Utils->destringify($curr_raw_parameters);
    $curr_parameters->{$key} = Bio::EnsEMBL::Hive::Utils->destringify( $value );
    my $new_raw_parameters = Bio::EnsEMBL::Hive::Utils->stringify($curr_parameters);
    $self->parameters($new_raw_parameters);
    return;
};

# description returns the ResourceDescription object
# of a given ResourceClass
*Bio::EnsEMBL::Hive::ResourceClass::description = sub {
    my ($self) = @_;
    my $description = $self->adaptor->db->get_ResourceDescriptionAdaptor->fetch_all_by_resource_class_id($self->dbID)->[0];
    return $description;
};

# Method for retrieving the ResourceDescription adaptor from a dbID
*Bio::EnsEMBL::Hive::DBSQL::ResourceDescriptionAdaptor::fetch_by_dbID = sub {
    my ($self, $id) = @_;
    my $obj = $self->fetch_all_by_resource_class_id($id)->[0];
    return $obj;
};

## To allow the creation of new resources (class + description) in one call
*Bio::EnsEMBL::Hive::DBSQL::ResourceClassAdaptor::create_full_description = sub {
  my ($self, $rc_name, $meadow_type, $parameters) = @_;
  # If we don't have parameters, the resource_class will be created but the description would
  # raise an exception
  # It is better to raise the exception here and let the client deal with it.
  # This way we don't create an orphan resource_class
  die "It is not allowed to create a class without parameters\n" unless (defined $parameters);

  for my $rc (@{$self->fetch_all}) {
    # if ($rc_name eq $rc->name) {
    #   throw("This resource name exists in the database\n");
    # }
  }
  my $rc = Bio::EnsEMBL::Hive::ResourceClass->new('name' => $rc_name);
  $self->store($rc);

  my $rd = Bio::EnsEMBL::Hive::ResourceDescription->new(
      'resource_class'      => $rc,
      'meadow_type'         => $meadow_type,
      'submission_cmd_args' => $parameters,
      );
  $self->db->get_ResourceDescriptionAdaptor->store($rd);
};

*Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::_update_input_id_in_job_table = sub {
  my ($self, $job, $input_id) = @_;

  my $sql = "UPDATE job SET input_id = ? WHERE job_id = ?";
  my $sth = $self->prepare($sql);
  $sth->execute($input_id, $job->dbID);
  $sth->finish();
  return;
};

## AnalysisJobAdaptor doesn't have a generic update method
## and it doesn't inherits from Hive::DBSQL::BaseAdaptor either
## I guess that this will change in the future,
## but for now I am injecting a generic update for that adaptor.
*Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::update = sub {
  my ($self, $job) = @_;

  return Bio::EnsEMBL::Hive::DBSQL::BaseAdaptor::update($self, $job, $_[2]) if $_[2];

  if (length($job->input_id) >= 255) {
    my $extended_input_id = $self->db->get_AnalysisDataAdaptor->store_if_needed($job->input_id);
    $job->input_id($extended_input_id);
  }
  $self->_update_input_id_in_job_table($job, $job->input_id);

  my $sql = "UPDATE job SET ";
  $sql .= "status='" . $job->status . "'";
  $sql .= ",retry_count=" . $job->retry_count;
  $sql .= ",semaphore_count=" . $job->semaphore_count;
  $sql .= ",semaphored_job_id=" . $job->semaphored_job_id if (defined $job->semaphored_job_id);
  $sql .= " WHERE job_id=" . $job->dbID;
  my $sth = $self->prepare($sql);
  $sth->execute();
  $sth->finish();
};


## forgive_failed_jobs sets FAILED jobs to DONE updating the semaphore count of dependent jobs
## This method is safer than the previous "forgive_dependent_jobs_semaphored_by_failed_jobs"
## because if the latter is run twice on the same analysis it would be decreasing the count twice on the same FAILED jobs
## because those jobs were not reset.
*Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::forgive_failed_jobs = sub {
  my ($self, $analysis_id) = @_;

  my $jobs = $self->fetch_all_by_analysis_id_status($analysis_id, 'FAILED');

  my %semaphored_analysis_ids = ();

  for my $job (@$jobs) {
    $self->decrease_semaphore_count_for_jobid($job->semaphored_job_id());
    $job->set_and_update_status('DONE');
    my $semaphored_job = $self->fetch_by_dbID($job->semaphored_job_id());
    $semaphored_analysis_ids{$semaphored_job->analysis_id}++ if (defined $semaphored_job)
  }

  # We sync the analysis_stats table (TODO: I think this is not really working)
  my @analysis_ids = ($analysis_id, keys %semaphored_analysis_ids);
  for my $analysis_id (@analysis_ids) {
    $self->db->get_Queen()->synchronize_AnalysisStats($self->db->get_AnalysisStatsAdaptor->fetch_by_analysis_id($analysis_id));
  }

  return scalar @$jobs;
};

## This method is equivalent to AnalysisJobAdaptor's reset_job_for_analysis_id
## but updating the semaphore counts accordingly
*Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::reset_jobs_and_semaphores_for_analysis_id = sub {
    my ($self, $analysis_id) = @_;

    my %semaphored_analysis_ids = ();
    for my $job(@{$self->fetch_all_by_analysis_id_status($analysis_id, 'DONE')},
		@{$self->fetch_all_by_analysis_id_status($analysis_id, 'PASSED ON')}) {
      if ($job->semaphored_job_id()) {
	my $semaphored_job = $self->fetch_by_dbID($job->semaphored_job_id());
	$semaphored_analysis_ids{$semaphored_job->analysis_id}++ if (defined $semaphored_job);
	if ($semaphored_job && ($semaphored_job->status() ne 'SEMAPHORED')) {
	  $semaphored_job->set_and_update_status('SEMAPHORED');
	}
	$self->increase_semaphore_count_for_jobid($job->semaphored_job_id());
      }
    }
    $self->reset_jobs_for_analysis_id($analysis_id, ['DONE', 'PASSED_ON']);

    # We sync the analysis_stats table:
    my @analysis_ids = ($analysis_id, keys %semaphored_analysis_ids);
    for my $analysis_id (@analysis_ids) {
      $self->db->get_Queen()->synchronize_AnalysisStats($self->db->get_AnalysisStatsAdaptor->fetch_by_analysis_id($analysis_id));
    }

    return;
  };

## This method allows you to discard ready jobs for an analysis
## It also takes care of the controlled jobs via semaphores
*Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::discard_ready_jobs = sub {
  my ($self, $analysis_id) = @_;

  my %semaphored_analysis_ids = ();
  for my $job(@{$self->fetch_all_by_analysis_id_status($analysis_id, 'READY')}) {
    $self->decrease_semaphore_count_for_jobid($job->semaphored_job_id());
    $job->set_and_update_status('DONE');
    if ($job->semaphored_job_id) {
      my $semaphored_job = $self->fetch_by_dbID($job->semaphored_job_id());
      $semaphored_analysis_ids{$semaphored_job->analysis_id}++ if (defined $semaphored_job);
    }
  }

  # We sync the analysis_stats table:
  my @analysis_ids = ($analysis_id, keys %semaphored_analysis_ids);
  for my $analysis_id (@analysis_ids) {
    $self->db->get_Queen()->synchronize_AnalysisStats($self->db->get_AnalysisStatsAdaptor->fetch_by_analysis_id($analysis_id));
  }


  return;
};

## This method unblocks semaphored jobs of a given analysis
*Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::unblock_jobs = sub {
  my ($self, $analysis_id) = @_;

  for my $job (@{$self->fetch_all_by_analysis_id_status($analysis_id, 'SEMAPHORED')}) {
    my $semaphore_count = $job->semaphore_count;
    $self->decrease_semaphore_count_for_jobid($job->dbID, $semaphore_count);

    # Update the status
    $job->status('READY');
    $self->update_status($job);
  }

  return;
};

## This method is equivalent to reset_jobs_for_analysis_id but syncing
*Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::reset_jobs_for_analysis_id_and_sync = sub {
  my ($self, $analysis_id) = @_;

  $self->reset_jobs_for_analysis_id($analysis_id);
  $self->db->get_Queen()->synchronize_AnalysisStats($self->db->get_AnalysisStatsAdaptor->fetch_by_analysis_id($analysis_id));

  return;
};

1;

