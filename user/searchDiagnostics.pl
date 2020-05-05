#!/usr/bin/perl 

########################################################################
# Tim M Strom   February 2007
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
$snv->loadSessionId();

$sname          = $snv->htmlencode($sname);
my $search      = $snv->initSearchDiagnostics($sname);
	
$snv->showMenu("searchDiagnostics");
print "<span class=\"big\">Search</span><br><br>" ;

print "<form action=\"searchDiagnosticsDo.pl\" method=\"post\">" ;

$snv->drawMask($search);

print "</form>" ;

$snv->printFooter();
