package Bio::EnsEMBL::Hive::PipeConfig::OverloadTest_conf;

use strict;
use warnings;

use base ('Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf');


sub default_options {
    my ($self) = @_;
    return {
        %{ $self->SUPER::default_options() },

        'time'            => '1+0.1*rand(1)',
        'quant'           => 160,
        'a_cap'           => 2,
        'b_size'          => 40,
    };
}

sub pipeline_analyses {
    my ($self) = @_;
    return [
        {   -logic_name => 'factory_A',
            -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
            -meadow_type => 'LOCAL',
            -parameters => {
                'inputlist'    => '#expr([1..#howmany#])expr#',
                'column_names' => [ 'foo' ],
            },
            -input_ids => [
                { 'fan_branch_code' => 2, 'howmany' => $self->o('quant') },
            ],
            -analysis_capacity => 1,
            -flow_into => {
                '2' => [ 'fan_B' ],
            },
        },

        {   -logic_name    => 'fan_B',
            -module        => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
            -parameters    => {
                'take_time'         => $self->o('time'),
            },
            -analysis_capacity => $self->o('a_cap'),
            -batch_size => $self->o('b_size'),
        },
    ];
}

1;

