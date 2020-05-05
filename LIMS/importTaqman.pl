#!/usr/bin/perl 

########################################################################
# Tim M Strom   April 2011
########################################################################

use strict;
use CGI;
use Cwd qw( abs_path );
use File::Basename qw( dirname );
use lib dirname(abs_path(-e));
use CGI::Carp qw(fatalsToBrowser);
use Solexa;

my $solexa      = new Solexa;

########################################################################
# main
########################################################################

$solexa->printHeader;
my $dbh=$solexa->loadSessionId();

$solexa->showMenu("importtaqman");
print "<span class=\"big\">Import Taqman results</span><br><br>" ;

print qq#
<form action="importTaqmanDo.pl" method="post" enctype="multipart/form-data">
txt-file<br />
<input name="file" type="file" size="50" maxlength="500000" accept="text/*"><br /><br />

<input type="submit" name="sheet" 
value='Import' >
&nbsp;&nbsp;&nbsp;&nbsp;

</form>
#;

$solexa->printFooter();
