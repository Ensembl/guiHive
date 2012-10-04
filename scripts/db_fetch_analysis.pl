#!/usr/bin/env perl

use strict;
use warnings;

use Bio::EnsEMBL::Hive::URLFactory;
use JSON::XS;
use HTML::Template;
use Data::Dumper;

use msg;

my $json_data = shift @ARGV || '{"url":["mysql://ensadmin:ensembl@127.0.0.1:2912/mp12_compara_nctrees_69a2"], "logic_name":["CAFE_species_tree"]}';
my $details_template = $ENV{GUIHIVE_BASEDIR} . "static/analysis_details.html"; ## TODO: use BASEDIR or something similar

my $var = decode_json($json_data);
my $url = $var->{url}->[0];
my $logic_name = $var->{logic_name}->[0];

my $dbConn = Bio::EnsEMBL::Hive::URLFactory->fetch($url);

my $response = msg->new();

if (defined $dbConn) {
  my $analysis;
  eval {
    $analysis = $dbConn->get_AnalysisAdaptor()->fetch_by_logic_name_or_url($logic_name);
  };
  if ($@) {
    $response->err_msg("I can't retrieve analysis with logic name $logic_name: $@");
    $response->status("");
  }
  if (! defined $analysis) {
      $response->err_msg("I can't retrieve analysis with logic name $logic_name from the database");
      $response->status("FAILED");
  }
  $response->out_msg(formAnalysisInfo($analysis));
} else {
  $response->err_msg("I have lost connection with the database\n");
  $response->status("FAILED");
}

print $response->toJSON;


sub formAnalysisInfo {
  my ($analysis) = @_;
  my $analysis_stats = $analysis->stats();

  my $info;
  $info->{id}                = $analysis->dbID();
  $info->{logic_name}        = $analysis->logic_name();
  $info->{module}            = [
				{module  => $analysis->module(),
				 id      => $analysis->dbID(),
				 adaptor => "analysisAdaptor",
				 method  => "module",
				}
			       ];

  $info->{parameters}        = template_mappings_PARAMS($analysis,
							"parameters",
							$analysis->dbID);

  $info->{hive_capacity}     = template_mappings_SELECT($analysis_stats,
							"hive_capacity",
							build_values({1=>[-1,9],10=>[10,90],100=>[100,1000]}));

  $info->{priority}          = template_mappings_SELECT($analysis_stats,
							"priority",
							build_values({1=>[0,20]}));

  $info->{batch_size}        = template_mappings_SELECT($analysis_stats,
							"batch_size",
							build_values({1=>[0,9],10=>[10,90],100=>[100,1000]}));

  $info->{can_be_empty}      = template_mappings_SELECT($analysis_stats,
							"can_be_empty",
							build_values({1=>[0,1]}));

  $info->{resource_class_id} = $analysis->resource_class_id();

  my $template = HTML::Template->new(filename => $details_template);
  $template->param(%$info);

  return $template->output();
}

sub module_mappings {
  my ($obj, $method) = @_;
  my $module = $obj->$method;
  return [
	  {"module"  => $module,
	   "id"      => $obj->dbID,
	   "adaptor" => "analysis",
	   "method"  => "module",
	  }
	 ];
}

sub template_mappings_SELECT {
  my ($obj, $method, $vals) = @_;
  my $curr_val = $obj->$method;
  return [{id                   => $obj->analysis_id,
	   adaptor              => "analysisStatsAdaptor",
	   method               => $method,
	   values => [map {{is_current => $curr_val == $_, $method."_value" => $_}} @$vals]
	  }];
}

sub template_mappings_PARAMS {
  my ($obj, $method) = @_;
  my $curr_raw_val = $obj->$method;
  my $curr_val = eval $curr_raw_val;
  my $vals;
  my $adaptor = "analysisAdaptor";
  my $i = 0;
  for my $param (keys %$curr_val) {
#    print STDERR "PARAM: $param\n";
    push @{$vals->{existing_parameters}}, {
					   "key"              => $param,
					   "parameterKeyID"   => "p_$param",
					   "parameterValueID" => "v_$param",
					   "value"            => stringify_if_needed($curr_val->{$param}),
					  };

    push @{$vals->{existing_parameters}->[$i]->{delete_parameter}}, {"id"             => $obj->dbID,
								     "adaptor"        => $adaptor,
								     "method"         => "delete_param",
								     "parameterKeyID" => "p_$param",
								    };
    push @{$vals->{existing_parameters}->[$i]->{change_parameter}}, {"id"               => $obj->dbID,
								     "adaptor"          => $adaptor,
								     "method"           => "add_param",
								     "parameterKeyID"   => "p_$param",
								     "parameterValueID" => "v_$param",
								    };
    $i++;
  }
  $vals->{new_parameter} = [{"id"      => $obj->dbID,
			    "adaptor" => $adaptor,
			    "method"  => "add_param",
			   }],
  return [$vals];
}

sub stringify_if_needed {
  my ($scalar) = @_;
  if (ref $scalar) {
    local $Data::Dumper::Indent    = 0;  # we want everything on one line
    local $Data::Dumper::Terse     = 1;  # and we want it without dummy variable names
    local $Data::Dumper::Sortkeys  = 1;  # make stringification more deterministic

    return Dumper($scalar);
  }
  return $scalar;
}

sub build_values {
  my ($ranges) = @_;
  my @vals;
  for my $step (keys %$ranges) {
    for (my $i = $ranges->{$step}->[0]; $i <= $ranges->{$step}->[1]; $i+=$step) {
      push @vals, $i;
    }
  }
  return [@vals];
}
