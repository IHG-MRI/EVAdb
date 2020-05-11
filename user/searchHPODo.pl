#!/usr/bin/perl 

########################################################################
# Tim M Strom   Sept 2010
########################################################################

use strict;
BEGIN {require './Snv.pm';}

my $cgiquery   = new CGI;
my $ref        = $cgiquery->Vars;
my $snv        = new Snv;

########################################################################
# main
########################################################################

$snv->printHeader();
my ($dbh) = $snv->loadSessionId();

#$ref = $snv->htmlencodehash($ref);

$snv->showMenu('searchHPO');
print "<span class=\"big\">Search results</span><br><br>" ;

$snv->searchResultsHPO($dbh,$ref);

$dbh->disconnect;

$snv->printFooter();
