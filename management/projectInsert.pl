#!/usr/bin/perl 

########################################################################
# Tim M Strom   February 2007
########################################################################

use strict;
use CGI;
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path(-e));
use CGI::Carp qw(fatalsToBrowser);
use Snvedit;
use DBI;

########################################################################
# global variables
########################################################################

my $cgiquery        = new CGI;
my $ref             = $cgiquery->Vars;
my $solexa          = new Snvedit;
my $personref       = "";
my @fields          =();
my @values          =();

my $sql             = "";
my $sth             = "";

########################################################################
# main
########################################################################

$solexa->printHeader;
my $dbh = $solexa->loadSessionId();


# delete beginning and trailing space
$solexa->deleteSpace($ref);

if ($ref->{mode} eq "edit") {
	delete($ref->{"mode"});
	$solexa->editProject($ref,$dbh,'project');
}
else {
	delete($ref->{"mode"});
	$solexa->insertIntoProject($ref,$dbh,'project');
}

# select and display new entry
$solexa->showMenu();


$solexa->showAllProject($dbh,$ref->{idproject});


$solexa->printFooter();


