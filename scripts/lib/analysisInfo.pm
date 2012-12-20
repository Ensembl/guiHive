package analysisInfo;

use strict;
use warnings;
use Data::Dumper;

use Bio::EnsEMBL::Hive::Utils::Graph;

## TODO:  normalize these colors with Hive colors
## It would be good to have this in a centralize language-agnostic format (JSON?)
## So these color-encodings are used in the javascript side and script side (the svg pipeline_diagram).
## The problem right now is that eHive's hive_config.json doesn't have a comprehensive description
## of states and colors (for example, there is no color for in_progress or semaphored).
## I need to sit down with Leo and try to define a better/comprehensive coloring schema.
## This is issue#17
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
    my $analysis_stats = $analysis->stats();
    my $config = Bio::EnsEMBL::Hive::Utils::Config->new();
    my $status = $analysis_stats->status();
    my $status_colour = $config->get('Graph', 'Node', $analysis_stats->status, 'Colour');
    my ($breakout_label, $total_job_count, $job_counts) = $analysis_stats->job_count_breakout();

## TODO: status should be only the $status string (not the color), but we need to define this here
## until issue#17 is solved (job's colors in json and accessible by client code -- javascript)
    my $self = bless( {analysis_id => $analysis->dbID(),
		       logic_name => $analysis->logic_name(),
		       status => [$status,$status_colour],
		       breakout_label => $breakout_label,
		       total_job_count => $total_job_count,
		       jobs_counts => {
			   counts => [],
			   colors => [],
		       }
		      }, $class);

    for my $job_status (qw/semaphored ready inprogress failed done/) {
	my $job_status_full = $job_status . "_job_count";
	my $count = $job_counts->{$job_status_full} || 0;
	$self->add_count($job_status, $count);
    }

    # We can't have all job counts = 0, so we add a new category
    # that can be 0 (if any other category is =/= 0.
    # or 1 if all other categories are == 0
    if ($self->sum_jobs()) {
	push @{$self->{jobs_counts}->{counts}}, 0;
    } else {
	push @{$self->{jobs_counts}->{counts}}, 1;
    }
    push @{$self->{jobs_counts}->{colors}}, $job_colors->{"background"};

    return $self;
}

sub add_count {
    my ($self, $status, $count) = @_;
    push @{$self->{jobs_counts}->{counts}}, $count+0; # ensure int context
    push @{$self->{jobs_counts}->{colors}}, $job_colors->{$status};
    return;
}

sub sum_jobs {
    my ($self) = @_;
    my $arr = $self->{jobs_counts}->{counts};
    my $res = 0;
    for my $i (@$arr) {
	$res += $i;
    }
    return $res;
}

sub TO_JSON {
    my ($self) = @_;
    return { %$self };
}

sub toJSON {
    my ($self) = @_;
    return JSON::XS->
	new->
	indent(0)->
	allow_blessed->
	convert_blessed->encode($self);
}

1;
