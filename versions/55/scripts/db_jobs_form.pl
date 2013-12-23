#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use HTML::Template;
use Data::Dumper;

my $json_data = shift @ARGV || '{"version":["53"],"url":["mysql://ensro@127.0.0.1:2912/mp12_compara_nctrees_70hmm"]}';

# Input
my $var = decode_json($json_data);
my $url = $var->{url}->[0];
my $version = $var->{version}->[0];

# Set up @INC and paths for static content
my $project_dir = $ENV{GUIHIVE_BASEDIR} . "versions/$version/";
my $jobs_form_template = $project_dir . "static/jobs_form.html";

unshift @INC, $project_dir . "ensembl-hive/modules";
require Bio::EnsEMBL::Hive::DBSQL::DBAdaptor;

# Initialization
my $dbConn = Bio::EnsEMBL::Hive::DBSQL::DBAdaptor->new( -no_sql_schema_version_check => 1, -url => $url );

if (defined $dbConn) {
  my $form = formJobsForm($dbConn);
  print $form;
}


sub formJobsForm {
  my ($dbConn) = @_;

  my $all_analysis = $dbConn->get_AnalysisAdaptor()->fetch_all();
  my @values = (map {{analysis_id => $_->dbID, analysis_display => "analysis_".$_->dbID." (".$_->logic_name.")"}} @$all_analysis);

  unshift @values, {
		    'analysis_display' => '',
		    'analysis_id' => ''
		   };
  print STDERR Dumper \@values;

  my $template = HTML::Template->new(filename => $jobs_form_template);
  $template->param('values' => [@values]);
  return $template->output();
}
