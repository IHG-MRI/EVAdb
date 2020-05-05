#!/usr/bin/perl

########################################################################
# Tim M Strom   Oct 2013
########################################################################

use strict;
#use lib "/srv/www/cgi-bin/mysql/test";
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path(-e));
use Snv;

my $snv         = new Snv;
my $cgi         = new CGI;
my $sname       = $cgi->param('sname');

$snv->printHeader();
my ($dbh)       = $snv->loadSessionId();

$sname          = $snv->htmlencode($sname);
$snv->showMenu("searchSv");

print "<span class=\"big\">Search</span><br><br>" ;
my $search      = $snv->initSearchSv($sname,$dbh);
print "<br><br>";
print "<form action=\"searchSvDo.pl\" method=\"post\" name=\"myform\">" ;

$snv->drawMask($search);

print "</form>" ;

$snv->printFooter();
