
package Bio::EnsEMBL::Hive::PipeConfig::TopUp_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');  # All Hive databases configuration files should inherit from HiveGeneric, directly or indirectly

sub pipeline_create_commands {
    return [];
}


sub hive_meta_table {
    my ($self) = @_;
    
    return {
        'hello' => 'world!',
        'foo'   => 'baz',
    };
}


sub resource_classes {
    my ($self) = @_;
    return {
        'default' => { 'LOCAL' => 'new_definition' },
        'urgent'  => { 'LSF' => '-q day_before_yesterday' },
        'slow'    => { 'LSF' => '-q basement' },
    };
}


sub pipeline_wide_parameters {
    my ($self) = @_;
    return {
        %{$self->SUPER::pipeline_wide_parameters},          # here we inherit anything from the base class

        'take_time'     => 2,
        'fake_time'     => 42,
    };
}


sub pipeline_analyses {
    my ($self) = @_;
    return [
        {   -logic_name => 'add_together',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::LongMult::AddTogether',
            -wait_for => [ 'part_multiply' ],
            -flow_into => {
                1 => [ ':////final_result',
                       'foo'
                     ],
            },
        },

        {   -logic_name => 'foo',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
        },
    ];
}

1;

