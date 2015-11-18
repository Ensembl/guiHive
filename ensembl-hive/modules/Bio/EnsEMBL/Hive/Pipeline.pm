package Bio::EnsEMBL::Hive::Pipeline;

use strict;
use warnings;

use Bio::EnsEMBL::Hive::Utils::Collection;
use Bio::EnsEMBL::Hive::Utils ('stringify');
use Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Hive::DBSQL::AnalysisAdaptor;
use Bio::EnsEMBL::Hive::DBSQL::AnalysisStatsAdaptor;
use Bio::EnsEMBL::Hive::Analysis;
use Bio::EnsEMBL::Hive::AnalysisStats;


sub new {       # construct an attached or a detached Pipeline object
}


sub url {       # Scalar representation of hive_dba
}

sub hive_dba {  # Object representation or url. Set if attached, unset if detached.
}


sub hive_meta {
}


sub resources { # ??? hash? multi-hash?
}


sub parameters {
}


sub all_analyses_collection {
    my $self = shift @_;

    if(@_) {
        $self->{'_all_analyses_collection'} = Bio::EnsEMBL::Hive::Utils::Collection->new( shift @_ );
    }
    return $self->{'_all_analyses_collection'};
}


sub all_control_rules_collection {
    my $self = shift @_;

    if(@_) {
        $self->{'_all_control_rules_collection'} = Bio::EnsEMBL::Hive::Utils::Collection->new( shift @_ );
    }
    return $self->{'_all_control_rules_collection'};
}


sub all_dataflow_rules_collection {
    my $self = shift @_;

    if(@_) {
        $self->{'_all_dataflow_rules_collection'} = Bio::EnsEMBL::Hive::Utils::Collection->new( shift @_ );
    }
    return $self->{'_all_dataflow_rules_collection'};
}


# Analysis[Stats?]Collection (of a Pipeline):
#       can be created & accessed as an ordered array Analysis[]    - before we have stored it in a db, preserve the natural order
#       can also be accessed as a hash with dbID as the key         - after having been stored in a db (dbID range may have gaps)
#       can also be accessed as a hash with logic_name as the key   - whether stored or unstored
#   (before switching make sure we can always access AnalysisStats from Analysis and there is no need to go the other way around; 
#    fetch_all_by_suitability_rc_id_meadow_type should return Analyses, not AnalysisStats objects)
#
# JobCollection (of an Analysis, so they all share the analysis[_id]):
#       can be created and accessed as an ordered array Job[]   - before they were stored in a db
#
# ControlRuleCollection (of an Analysis, so they all share the ctrled_analysis[_id] )
#       is an array of AnalysisCtrlRule objects
#
# DataflowRuleCollecton (of an Analysis, so they all share the from_analysis[_id] ):
#       can be created and accessed as an array
#       can also be accessed filtered/hashed by (from_analysis[_id], branch_code) combination
#


# ----------------------------------------------------




sub load_from_pipeconfig {
}


sub store { # or should it be [the only method in] in the PipelineAdaptor?
}

1;

