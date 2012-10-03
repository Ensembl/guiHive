# This module injects the "delete_param" and "add_param" methods
# in the Bio::EnsEMBL::Hive::Analysis namespace.
# They are convenient to be able to use them in constructs like:
# $obj->$method(@args);
# and work with (for example):
# $analysis_stats->hive_capacity(555);
# and
# $analysis->delete_param("mlss_id");
# or
# $analysis->add_param("mlss_id", 40086);
#

package analysis_parameters;

use strict;
use warnings;
no warnings "once";

use Bio::EnsEMBL::Hive::Utils qw/stringify destringify/;

*Bio::EnsEMBL::Hive::Analysis::delete_param = sub {
  my ($self, $key) = @_;
  my $curr_raw_parameters = $self->parameters;
  my $curr_parameters = Bio::EnsEMBL::Hive::Utils->destringify($curr_raw_parameters);
  delete $curr_parameters->{$key};
  my $new_raw_parameters = Bio::EnsEMBL::Hive::Utils->stringify($curr_parameters);
  $self->parameters($new_raw_parameters);
  return;
};

*Bio::EnsEMBL::Hive::Analysis::add_param = sub {
  my ($self, $key, $value) = @_;
  my $curr_raw_parameters = $self->parameters;
  my $curr_parameters = Bio::EnsEMBL::Hive::Utils->destringify($curr_raw_parameters);
  $curr_parameters->{$key} = $value;
  my $new_raw_parameters = Bio::EnsEMBL::Hive::Utils->stringify($curr_parameters);
  $self->parameters($new_raw_parameters);
  return;
};

1;

