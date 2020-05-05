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
my $idsnv       = $cgi->param('idsnv');
my $idsample    = $cgi->param('idsample');
my $reason      = $cgi->param('reason');
my $table       = $cgi->param('table');

$snv->printHeader();
my ($dbh) = $snv->loadSessionId();
my $search      = $snv->initComment($idsnv,$idsample,$reason,$dbh,$table);

$idsnv          = $snv->htmlencode($idsnv);
$idsample       = $snv->htmlencode($idsample);
$reason         = $snv->htmlencode($reason);
$table          = $snv->htmlencode($table);

$snv->showMenu("");
print "<span class=\"big\">Comment</span><br><br>" ;

print "<form action=\"commentDo.pl\" method=\"post\">" ;
$snv->getShowComment($dbh,$idsnv,$idsample,$search,'noprint',$table);
$snv->drawMask($search);

print "</form>" ;

$snv->printFooter();
