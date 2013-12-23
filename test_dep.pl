#!/usr/bin/env perl

=pod

 Copyright [1999-2013] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute

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


use strict;
use warnings;

#######################
##      Server       ##
#######################
print "CHECKING SERVER:\n";

## GO
print " Checking if the Go is installed in the system: ";
my $go_path = `which go`;
chomp $go_path;
if ($go_path) {
  print "[$go_path] ... OK\n";
}
else {
  not_met_dep("Go",
	      "which go",
	      "The Go compiler is not found in your system. It is expected to be in your PATH",
	      "http://golang.org/doc/install");
}

# EHIVE_ROOT_DIR
print " Checking EHIVE_ROOT_DIR environmental variable: ";
my $ehive_root_dir_envar = $ENV{EHIVE_ROOT_DIR};
chomp $ehive_root_dir_envar;
if ($ehive_root_dir_envar) {
  print "[$ehive_root_dir_envar] ... OK\n";
} else {
  not_met_dep( "EHIVE_ROOT_DIR",
	       "echo \$EHIVE_ROOT_DIR",
	       "The EHIVE_ROOT_DIR has to be defined in the session where the guiHive server is running",
	       "Set this env variable to the root dir of your hive code"
	     );
}

###########################
##       eHive           ##
###########################
print "\nCHECKING EHIVE CODE:\n";

## Perl
print " Checking that perl is installed in the system: ";
my $perl_path = `which perl`;
chomp $perl_path;
if ($perl_path) {
  print "[$perl_path] ... OK\n";
} else {
  not_met_dep( "Perl",
	       "Perl is not found in the PATH (which Perl)",
	       ""
	     );
}

print " Checking Perl version: ";
my ($vers, $subvers, $subsubvers) = `perl -v` =~ /\(v(\d+)\.(\d+)\.(\d+)\)/;
if ($subvers >= 8) {
  print "[v$vers.$subvers.$subsubvers] ... OK\n";
} else {
  not_met_dep( "Perl",
	       "perl -v",
	       "Perl version v$vers.$subvers.$subsubvers",
	       ""
	     );
}

print  " Checking Ensembl API installation";
eval {
  require Bio::EnsEMBL::Registry;
};
if ($@) {
  not_met_dep( "Ensembl",
	       "perl -MBio::EnsEMBL::Registry -e ''",
	       "The ensembl API checkout is not found in the system. eHive depends on the core API. BioPerl or any other Ensembl checkout are not needed",
	       "See http://www.ensembl.org/info/docs/api/api_installation.html"
	     );
} else {
  print " ... OK\n";
}

## Hive code
print " Checking eHive API installation";
eval {
  require Bio::EnsEMBL::Hive;
};
if ($@) {
  not_met_dep( "Hive",
	       "perl -MBio::EnsEMBL::Hive -e ''",
	       "The hive API checkout is not found in the system",
	       "See http://www.ensembl.org/info/docs/eHive/installation.html"
	     );
} else {
  print " ... OK\n";
}

print "\nCHECKING EHIVE DEPENDENCIES:\n";

# graphViz
print " Checking GraphViz (dot) installation: ";
my $dot_path = `which dot`;
chomp $dot_path;
if ($dot_path) {
print "[$dot_path] ... Ok\n";
} else {
  not_met_dep( "GraphViz (dot)",
	       "which dot",
	       "The 'dot' binary is not found in your system. It is expected to be in your PATH",
	       "Install graphviz (See http://www.graphviz.org/Download..php)"
	     );
}

print " Checking GraphViz Perl module";
eval {
  require GraphViz;
};
if ($@) {
  not_met_dep( "GraphViz (Perl API)",
	       "perl -MGraphViz -e ''",
	       "The GraphViz perl API is not found in your system.",
	       "See http://search.cpan.org/~rsavage/GraphViz-2.14/lib/GraphViz.pm"
	     );
}
else {
  print " ... OK\n";
}

print " Checking Perl DBI";
eval {
  require DBI;
};
if ($@) {
  not_met_dep( "DBI (Perl API)",
	       "perl -MDBI -e ''",
	       "The Perl DBI module is not installed in your system. It is possible that you need to install a database client too",
	       "See http://search.cpan.org/~timb/DBI-1.630/DBI.pm"

	     );
} else {
  print " ... OK\n";
}

print "\nCHECKING OTHER PERL MODULES DEPENDENCIES\n";

print " Checking JSON Perl module";
eval {
  require JSON;
};
if($@) {
  not_met_dep( "JSON (Perl API)",
	       "perl -MJSON -e''",
	       "The Perl JSON interfaz is missing in your system",
	       "See http://search.cpan.org/~makamaka/JSON-2.90/lib/JSON.pm"
	     );
} else {
  print " ... OK\n";
}

print " Checking JSON::PP Perl module";
eval {
  require JSON::PP;
};
if($@) {
  not_met_dep( "JSON::PP (Perl module)",
	       "perl -MJSON::PP -e''",
	       "The JSON::PP Perl module is missing in your system",
	       "See http://search.cpan.org/~makamaka/JSON-PP-2.27203/lib/JSON/PP.pm"
	     );
} else {
  print " ... OK\n";
}

print " Checking HTML::Template Perl module";
eval {
  require HTML::Template;
};
if($@) {
  not_met_dep( "HTML::Template (Perl module)",
	       "perl -MHTML::Template -e''",
	       "The HTML::Template Perl module is missing in your system",
	       "See http://search.cpan.org/~wonko/HTML-Template-2.95/lib/HTML/Template.pm"
	     );
} else {
  print " ... OK\n";
}

print " Checking URI::Escape Perl module";
eval {
  require URI::Escape;
};
if($@) {
  not_met_dep( "URI::Escape (Perl module)",
	       "perl -MURI::Escape -e''",
	       "The URI::Escape Perl module is missing in your system",
	       "See http://search.cpan.org/~gaas/URI-1.60/URI/Escape.pm"
	     );
} else {
  print " ... OK\n";
}


print " \n... ALL LOOKS GOOD\n";
print "\nIf you are experiencing problems:\n\n";
print "1.- Make sure your server is running by opening http://127.0.0.1:8080\n";
print "2.- Make sure you have access to your database:\n";
print "\$EHIVE_ROOT_DIR/scripts/db_cmd.pl -url <mysql_path_to_your_db>\n";
print "\$GUIHIVE_BASEDIR/scripts/db_test.pl <mysql_path_to_your_db>\n";
print "3.- If you have problems refreshing the data during a guiHive run try the following script:\n";
print "\$GUIHIVE_BASEDIR/scripts/db_refresh_test.pl <mysql_path_to_your_db>\n";
print "\nIf you have any problem email mp[AT]ebi.ac.uk\n\n";

sub not_met_dep {
  my ($who, $command, $desc, $help) = @_;
  my $msg = "\n\n" . "#"x80 . "\n";
  $msg .= "UNMET DEPENDECY: $who\n";
  $msg .= "   COMM: $command\n";
  $msg .= "   DESC: $desc\n";
  $msg .= "   HELP: $help\n";
  $msg .= "#"x80 . "\n\n";
  die $msg;
}

