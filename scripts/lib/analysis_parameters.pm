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

package analysis_parameters;

use strict;
use warnings;
no warnings "once";

use Bio::EnsEMBL::Hive::Utils qw/stringify destringify/;

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
    my $curr_raw_parameters = $self->parameters;
    my $curr_parameters = Bio::EnsEMBL::Hive::Utils->destringify($curr_raw_parameters);
    $curr_parameters->{$key} = $value;
    my $new_raw_parameters = Bio::EnsEMBL::Hive::Utils->stringify($curr_parameters);
    $self->parameters($new_raw_parameters);
    return;
};

# update_module evaluates its argument in order to 
# determine if the module exists and is in the path
# Then calls the "module" method of the Analysis adaptor
*Bio::EnsEMBL::Hive::Analysis::update_module = sub {
    my ($self, $module) = @_;
    eval "require $module";
    $self->module($module);
};

# description returns the ResourceDescription object
# of a given ResourceClass
*Bio::EnsEMBL::Hive::ResourceClass::description = sub {
    my ($self) = @_;
    my $description = $self->adaptor->db->get_ResourceDescriptionAdaptor->fetch_all_by_resource_class_id($self->dbID)->[0];
    return $description;
};

# Consistent way of retrieving the adaptor from a dbID
*Bio::EnsEMBL::Hive::DBSQL::ResourceDescriptionAdaptor::fetch_by_dbID = sub {
    my ($self, $id) = @_;
    my $obj = $self->fetch_all_by_resource_class_id($id)->[0];
    return $obj;
};

# update for ResourceDescriptionAdaptor
# *Bio::EnsEMBL::Hive::DBSQL::ResourceDescriptionAdaptor::update = sub {
#     my ($self, $obj) = @_;
#     $self->updatable_column_list("parameters","meadow_type");

#     SUPER::$self->update($obj, $obj);
    
# };

1;

