=pod

 Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
 Copyright [2016] EMBL-European Bioinformatics Institute

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


package analysisInfo;

use strict;
use warnings;

use Bio::EnsEMBL::Hive::Utils::Graph;

my @hive_config_files = ($ENV{GUIHIVE_BASEDIR}.'/config/hive_config.json', $ENV{EHIVE_ROOT_DIR}.'/hive_config.json');

## TODO:  normalize these colors with Hive colors
## It would be good to have this in a centralize language-agnostic format (JSON?)
## So these color-encodings are used in the javascript side and script side (the svg pipeline_diagram).
## The problem right now is that eHive's hive_config.json doesn't have a comprehensive description
## of states and colors (for example, there is no color for in_progress or semaphored).
## I need to sit down with Leo and try to define a better/comprehensive coloring schema.
## This is issue#17
my $job_colors = {
		  'semaphored' => 'grey',
		  'ready'      => '#00FF00', # green
		  'inprogress' => 'yellow',
		  'failed'     => 'red',
		  'done'       => 'DeepSkyBlue',
		  'background' => 'white',
		 };

sub parse_msecs {
  my ($msec) = @_;

  my $days = int($msec/(24*60*60*1000));
  my $hours = ($msec/(60*60*1000))%24;
  my $mins = ($msec/(60*1000))%60;
  my $secs = ($msec/1000)%60;

  # Using the x!! operator explained in
  # http://www.perlmonks.org/?node_id=564792
  my @parts=(
	     ($days."d") x!! $days,
	     ($hours."h") x!! $hours,
	     ($mins."m") x!! $mins,
	     ($secs."s") x!! $secs,
	    );

  unless (scalar @parts) {
    return "<1s";
  }

  return join ":", @parts;
}

sub fetch {
  my ($class, $analysis) = @_;
  my $analysis_stats = $analysis->stats();
  my $config = Bio::EnsEMBL::Hive::Utils::Config->new(@hive_config_files);
  my $status = $analysis_stats->status();
#  my $status_colour = $config->get('Graph', 'Node', 'AnalysisStatus', $analysis_stats->status, 'Colour');
  my ($breakout_label, $total_job_count, $job_counts) = $analysis_stats->job_count_breakout();
  my $avg_msec_per_job = $analysis_stats->avg_msec_per_job();
  my $guiHiveStatus = getGuiHiveStatus($job_counts, $status);

  my $meadow_type = $analysis->meadow_type();

  ## TODO: status should be only the $status string (not the color), but we need to define this here
  ## until issue#17 is solved (job's colors in json and accessible by client code -- javascript).
  ## same for the names
  my $self = bless( {analysis_id => $analysis->dbID(),
		     logic_name => $analysis->logic_name(),
#		     status => [$status,$status_colour], ## TODO: This is not needed anymore. The Javascript colors are now taken directly from the hive_config.json
		     status => $status,
		     guiHiveStatus => $guiHiveStatus,
		     breakout_label => $breakout_label,
		     avg_msec_per_job => $avg_msec_per_job,
		     avg_msec_per_job_parsed => parse_msecs($avg_msec_per_job),
		     total_job_count => $total_job_count,
		     meadow_type => $meadow_type,
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

sub getGuiHiveStatus {
  my ($jobs, $hiveStatus) = @_;
  if ($hiveStatus eq 'BLOCKED') {
    return $hiveStatus;
  }
  if ($jobs->{inprogress_job_count}) {
    return "WORKING";
  } elsif ($jobs->{ready_job_count}) {
    return "READY";
  } elsif ($jobs->{semaphored_job_count}) {
    return "ALL_CLAIMED";
  } else {
    return $hiveStatus;
  }
}

sub meadow_type {
  my ($self, $meadow_type) = @_;
  if (defined $meadow_type) {
    $self->{meadow_type} = $meadow_type;
  }
  return $self->{meadow_type};
}

sub stats {
  my ($self, $min_mem, $max_mem, $avg_mem, $min_cpu, $max_cpu, $avg_cpu, $resource_mem) = @_;
  $self->{mem} = [$min_mem, $avg_mem, $max_mem];
  $self->{cpu} = [$min_cpu, $avg_cpu, $max_cpu];
  $self->{resource_mem} = [$max_mem, 0, $resource_mem];
}

sub TO_JSON {
    my ($self) = @_;
    return { %$self };
}

sub toJSON {
    my ($self) = @_;
    return JSON->
	new->
	indent(0)->
	allow_blessed->
	convert_blessed->encode($self);
}


1;
