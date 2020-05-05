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
use Solexa;

my $samples      = new Solexa;

########################################################################
# main
########################################################################

$samples->printHeader;
my $dbh=$samples->loadSessionId();

$samples->showMenu();
print "<span class=\"big\">Make Pool Extern</span><br><br>" ;

print qq#
<form action="makePoolExternDo.pl" method="post" enctype="multipart/form-data">
Barcode of new Pool in first line.<br /> 
File with a single sample ID in each following line.<br /> 
Nothing is stored in this step.<br /> 
<input name="file" type="file" size="50" maxlength="500000" accept="text/*"><br /><br />
<input type=submit name=submit value=submit>
</form>
#;

$samples->printFooter();
