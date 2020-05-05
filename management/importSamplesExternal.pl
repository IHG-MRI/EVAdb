#!/usr/bin/perl 

########################################################################
# Tim M Strom   February 2011
########################################################################

use strict;
use CGI;
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path(-e));
use CGI::Carp qw(fatalsToBrowser);
use Snvedit;
use DBI;

my $solexa      = new Snvedit;
my $importsamplemaskexternal = $solexa->initImportSamplesExternal();

########################################################################
# main
########################################################################

$solexa->printHeader;
$solexa->loadSessionId();

$solexa->showMenu('importsamplesexternal');
print "<span class=\"big\">Import sample information.<br>Only external samples!</span><br><br>" ;

print "<form action=\"importSamplesExternalDo.pl\" method=\"post\" enctype=\"multipart/form-data\">";
print '<input name="file" type="file" size="50" maxlength="500000" accept="text/*"><br /><br />';

$solexa->drawMask($importsamplemaskexternal);

print "</form>";


$solexa->printFooter();
