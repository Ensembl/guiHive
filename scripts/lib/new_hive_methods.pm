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

package new_hive_methods;

use strict;
use warnings;
use Data::Dumper;
no warnings "once";

use Bio::EnsEMBL::Hive::Utils qw/stringify destringify/;

# Analysis' module should check that the module exists and is compilable
*Bio::EnsEMBL::Hive::Analysis::update_module = sub {
    my $self = shift;
    $self->{'_module'} = shift if(@_ && do{
	my $module = $_[0];
	eval "require $module";
	die "The module '$module' can't be loaded: $@\n" if ($@);
	die "Problem accessing methods in '$module'. Please check that it inherits from Bio::EnsEMBL::Hive::Process and is named correctly\n" unless ($module->isa('Bio::EnsEMBL::Hive::Process'));
	1;
				  });
    return $self->{'_module'};
};

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
    my ($self, $key, $value) = @_;
    my $curr_raw_input_id = $self->input_id;
    $curr_raw_input_id = '{}' unless ($curr_raw_input_id);
    my $curr_input_id = Bio::EnsEMBL::Hive::Utils::destringify($curr_raw_input_id);
    return $curr_input_id->{$key} unless (defined $value);
    $curr_input_id->{$key} = $value;
    my $new_raw_input_id = Bio::EnsEMBL::Hive::Utils::stringify($curr_input_id);
    $self->input_id($new_raw_input_id);
    return $value;
};

# delete_input_id deletes a single input_id key/value pair in the AnalysisJob table
*Bio::EnsEMBL::Hive::AnalysisJob::delete_input_id = sub {
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
    my ($self, $key, $value) = @_;
    my $var = eval $value;
    $var = $value unless(defined $var);
    my $curr_raw_parameters = $self->parameters;
    my $curr_parameters = Bio::EnsEMBL::Hive::Utils->destringify($curr_raw_parameters);
    $curr_parameters->{$key} = $var;
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

# This should be fetched correctly by AnalysisStatsAdaptor now
# TODO: Test that this natively in the Adaptor and if so,
# remove this injected method from here
*Bio::EnsEMBL::Hive::DBSQL::AnalysisStatsAdaptor::fetch_by_dbID = sub {
  my ($self, $id) = @_;
  my $obj = $self->fetch_by_analysis_id($id);
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
  my $rc = $self->create_new(-NAME => $rc_name);
  my $rc_id = $rc->dbID();

  $self->db->get_ResourceDescriptionAdaptor->create_new(
      -RESOURCE_CLASS_ID => $rc_id,
      -MEADOW_TYPE       => $meadow_type,
      -PARAMETERS        => $parameters,
      );
};

## AnalysisJobAdaptor doesn't have a generic update method
## and it doesn't inherits from Hive::DBSQL::BaseAdaptor either
## I guess that this will change in the future,
## but for now I am injecting a generic update for that adaptor.
*Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::update = sub {
  my ($self, $job) = @_;
  my $sql = "UPDATE job SET input_id='" . $job->input_id . "'";
  $sql .= ",status='" . $job->status . "'";
  $sql .= ",retry_count=" . $job->retry_count;
  $sql .= ",semaphore_count=" . $job->semaphore_count;
  $sql .= ",semaphored_job_id=" . $job->semaphored_job_id if (defined $job->semaphored_job_id);
  $sql .= " WHERE job_id=" . $job->dbID;
  my $sth = $self->prepare($sql);
  $sth->execute();
  $sth->finish();

  unless ($job->completed) {
    $self->update_status($job);
  }
};

## Method to get all the jobs in the database
## Too tricky. It would be better to have a _generic_count directly in the AnalysisJob adaptor
## or better still in Hive's BaseAdaptor
*Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::_generic_count = sub {
  my ($self, $constraints) = @_;

  # We save previous _columns and _objs_from_sth methods
  my $old_columns = *Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::_columns;
  my $old_objs_from_sth = *Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::_objs_from_sth;

  # _columns and _objs_from_sth methods are redefined
  no warnings 'redefine';
  *Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::_columns = sub {
    return "COUNT(*)";
  };
  *Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::_objs_from_sth = sub {
    my ($self, $sth) = @_;
    my ($n) = $sth->fetchrow_array();
    $sth->finish();
    return $n;
  };

  ## We call _generic_fetch as usual and get back only the count
  my $n = $self->_generic_fetch($constraints);

  ## We reassign the _columns and _objs_from_sth to their original form
  *Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::_columns = $old_columns;
  *Bio::EnsEMBL::Hive::DBSQL::AnalysisJobAdaptor::_objs_from_sth = $old_objs_from_sth;

  return $n;
};

1;

