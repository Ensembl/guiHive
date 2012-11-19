package analysisInfo;

use strict;
use warnings;
use Data::Dumper;

use Bio::EnsEMBL::Hive::Utils::Graph;

## TODO:  normalize these colors with Hive colors
my $job_colors = {
		  'semaphored' => 'yellow',
		  'ready'      => 'cyan',
		  'inprogress' => 'blue',
		  'failed'     => 'red',
		  'done'       => 'green',
		  'background' => 'white',
		 };

sub fetch {
    my ($class, $analysis) = @_;
    print STDERR "$analysis\n";
    my $self = bless({}, $class);
    my $analysis_stats = $analysis->stats();
    my $config = Bio::EnsEMBL::Hive::Utils::Config->new();
    my $status = $analysis_stats->status();
    my $status_colour = $config->get('Graph', 'Node', $analysis_stats->status, 'Colour');
    my ($breakout_label, $total_job_count, $job_counts) = $analysis_stats->job_count_breakout();

    $self = {status => $status_colour,
		       breakout_label => $breakout_label,
		       total_job_count => $total_job_count,
		       jobs_counts => {
			   counts => [],
			   colors => [],
		       },
    };

    for my $job_status (qw/semaphored ready inprogress failed done/) {
	my $job_status_full = $job_status . "_job_status";
	my $count = $job_counts->{$job_status_full};
	$self->add_count($job_status, $count);
    }

    # We can't have all job counts = 0, so we add a new category
    # that can be 0 (if any other category is =/= 0.
    # or 1 if all other categories are == 0
    if ($self->sum_jobs()) {
	push @{$self->{jobs}->{counts}}, 0;
    } else {
	push @{$self->{jobs}->{counts}}, 1;
    }
    push @{$self->{jobs}->{colors}}, $job_colors->{"background"};

    return $self;
}

sub add_count {
    my ($self, $status, $count) = @_;
    push @{$self->{jobs}->{counts}}, $count+0; # ensure int context
    push @{$self->{jobs}->{colors}}, $job_colors->{$status};
    return; 
}

sub sum_jobs {
    my ($self) = @_;
    my $arr = $self->{jobs}->{counts};
    my $res = 0;
    for my $i (@$arr) {
	$res += $i;
    }
    return $res;
}

1;
