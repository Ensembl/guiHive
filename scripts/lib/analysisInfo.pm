package analysisInfo;

use strict;
use warnings;
use Data::Dumper;

use Bio::EnsEMBL::Hive::Utils::Graph;

my $hive_config_file = $ENV{GUIHIVE_BASEDIR} . "config/hive_config.json";

## TODO:  normalize these colors with Hive colors
## It would be good to have this in a centralize language-agnostic format (JSON?)
## So these color-encodings are used in the javascript side and script side (the svg pipeline_diagram).
## The problem right now is that eHive's hive_config.json doesn't have a comprehensive description
## of states and colors (for example, there is no color for in_progress or semaphored).
## I need to sit down with Leo and try to define a better/comprehensive coloring schema.
## This is issue#17
my $job_colors = {
		  'semaphored' => 'red',
		  'ready'      => 'orange',
		  'inprogress' => 'yellow',
		  'failed'     => 'grey',
		  'done'       => 'green',
		  'background' => 'white',
		 };

sub fetch {
    my ($class, $analysis) = @_;
    my $analysis_stats = $analysis->stats();
    my $config = Bio::EnsEMBL::Hive::Utils::Config->new($hive_config_file);
    my $status = $analysis_stats->status();
    my $status_colour = $config->get('Graph', 'Node', 'AnalysisStatus', $analysis_stats->status, 'Colour');
    my ($breakout_label, $total_job_count, $job_counts) = $analysis_stats->job_count_breakout();
    my $avg_msec_per_job = $analysis_stats->avg_msec_per_job();

## TODO: status should be only the $status string (not the color), but we need to define this here
## until issue#17 is solved (job's colors in json and accessible by client code -- javascript).
## same for the names
    my $self = bless( {analysis_id => $analysis->dbID(),
		       logic_name => $analysis->logic_name(),
		       status => [$status,$status_colour],
		       breakout_label => $breakout_label,
		       avg_msec_per_job => $avg_msec_per_job,
		       total_job_count => $total_job_count,
		       jobs_counts => {
			   counts => [],
			   colors => [],
			   names => [],
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
    push @{$self->{jobs_counts}->{names}}, $status;
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

sub meadow_type {
  my ($self, $meadow_type) = @_;
  $self->{meadow_type} = $meadow_type;
}

sub mem {
  my ($self, $min_mem, $max_mem, $avg_mem, $resource_mem) = @_;
  $self->{mem} = [$min_mem, $avg_mem, $max_mem];
  $self->{resource_mem} = [$max_mem, 0, $resource_mem];
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
