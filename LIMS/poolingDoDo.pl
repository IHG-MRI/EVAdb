#!/usr/bin/perl 

########################################################################
# Tim M Strom   May 2008
########################################################################

use strict;
use CGI;
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path(-e));
use CGI::Carp qw(fatalsToBrowser);
use Solexa;

my $solexa      = new Solexa;
my $cgiquery    = new CGI;
my $ref         = $cgiquery->Vars;
my @check_id    = $cgiquery->param('checkbox');
my $checkboxref = \@check_id;

$solexa->printHeader();
my $dbh=$solexa->loadSessionId();

$solexa->showMenu("pooling");
print "<span class=\"big\">Pooling sheet</span><br><br>" ;

$solexa->poolingsheet($ref,$dbh,$checkboxref);


$solexa->printFooter();
