########################################################################
# Tim M Strom June 2010-2021
# Institute of Human Genetics
# Klinikum rechts der Isar
########################################################################

use strict;
package Report;
#use warnings;

my $sampledb = $Snv::sampledb;
my $coredb = $Snv::coredb;
my $exomevcfe = $Snv::exomevcfe;

sub new {
	my $class = shift;
	my $self = {};
	bless $self,$class;
	return $self;
}

########################################################################
# report
########################################################################
sub report {
my $self         = shift;
my $dbh          = shift;
my $ref          = shift;

my $allowedprojects  = &Snv::allowedprojects();
#print "sampledb $sampledb<br>";
#print "allowedprojects $allowedprojects<br>";
#print "exomevcfe $exomevcfe<br>";

my $query            = "";
my $where            = "";
my $out              = "";
my @row              = ();
#my $values           = "128421";
my $values           = $ref->{samplename};
my $salutation       = $ref->{salutation};
my $userprobability  = $ref->{userprobability};
$salutation          = "Sehr geehrte Frau Kollegin" if ($salutation eq 'kollegin');
$salutation          = "Sehr geehrter Herr Kollege" if ($salutation eq 'kollege');
$salutation          = "Sehr geehrte KollegInnen"   if ($salutation eq 'kolleginnen');
my $cnvfilter        = $ref->{cnvfilter};
my $todaysdate       = &Snv::mylocaltime;
# select from conclusions, comments and gene
$query = qq#
SELECT
DISTINCT s.name,
s.foreignid,
s.saffected,
s.entered,
(select ss.name from $sampledb.sample ss where ss.idsample=s.mother),
(select ss.foreignid from $sampledb.sample ss where ss.idsample=s.mother),
(select ss.saffected from $sampledb.sample ss where ss.idsample=s.mother),
(select ss.name from $sampledb.sample ss where ss.idsample=s.father),
(select ss.foreignid from $sampledb.sample ss where ss.idsample=s.father),
(select ss.saffected from $sampledb.sample ss where ss.idsample=s.father),
co.omimphenotype,
cl.solved,
co.genesymbol,
"",
co.patho,
co.genotype,
co.inheritance,
co.chrom,
co.start,
co.end,
co.refallele,
co.altallele,
v.func,
cv.path,
GROUP_CONCAT(DISTINCT omim.disease),
s.sex,
GROUP_CONCAT(DISTINCT hpo.symptoms separator ", "),
GROUP_CONCAT(DISTINCT hpo.hpo separator " "),
evs.ea_het+evs.aa_het,
evs.ea_homalt+evs.aa_homalt,
x.coverage,
(select count(xx.idsample) from snvsample xx where (xx.idsnv=x.idsnv and xx.alleles=1)),
(select count(xx.idsample) from snvsample xx where (xx.idsnv=x.idsnv and xx.alleles=2)),
(select count(distinct idsample) from snvsample)
FROM $sampledb.sample s
INNER JOIN $exomevcfe.conclusion   cl ON s.idsample=cl.idsample
LEFT  JOIN $exomevcfe.comment      co ON s.idsample=co.idsample AND (co.patho like "%pathogenic" OR co.patho like "unknown significance")
LEFT  JOIN $coredb.clinvar         cv ON co.chrom=cv.chrom AND co.start=cv.start AND co.refallele=cv.ref AND co.altallele=cv.alt
LEFT  JOIN snv                      v ON v.chrom=co.chrom AND v.start=co.start AND v.end=co.end AND v.refallele=co.refallele AND v.allele=co.altallele
LEFT  JOIN snvsample                x ON v.idsnv=x.idsnv and s.idsample=x.idsample
LEFT  JOIN $sampledb.omim        omim ON co.omimphenotype=omim.omimdisease
LEFT  JOIN $exomevcfe.hpo         hpo ON s.name=hpo.samplename
LEFT  JOIN $coredb.evs            evs ON v.chrom=evs.chrom and v.start=evs.start and v.refallele=evs.refallele and v.allele=evs.allele
WHERE s.name=?
AND $allowedprojects
AND (co.causefor = "primary" OR cl.solved = 2)
GROUP BY v.idsnv
#;
#AND co.causefor = "primary"
#print "$query $values<br><br>";
$out = &executeQuerySth($dbh,$query,$values);
my @vep         = "";
my $i           = 0;
my $tmp         = "";
my $samplename  = "";
my $status      = "Index";
my $foreignid   = "";
my $affected    = "";
my $entered     = "";
my $mother      = "";
my $m_affected  = "";
my $m_foreignid = "";
my $father      = "";
my $f_affected  = "";
my $f_foreignid = "";
my $solved      = "";
my @cogene      = (); #genesymbol in comment table
my @ggene       = (); #genesymbol in gene table
my @omimnumber  = ();
my @solved      = ();
my @patho       = ();
my @pathoforsummary = ();
my @genotype    = ();
my @genotype_g  = ();
my @inheritance = ();
my @inheritance_orig = ();
my @chrom       = ();
my @start       = ();
my @end         = ();
my @refallele   = ();
my @altallele   = ();
my @func        = ();
my @clinvar     = ();
my @vepfeature  = ();
my @vepconseq   = ();
my @vepimpact   = ();
my @vepHGVSc    = ();
my @vepHGVSp    = ();
my @vepgene     = (); #genesymbol in vep table
my @omimdisease = (); # omim disease name
my $sex         = "";
my $sex_g       = "";
my $clinical    = "";
my $hpo         = "";
my @gnomad_het  = ();
my @gnomad_hom  = ();
my @coverage    = ();
my @inhouse_het = ();
my @inhouse_hom = ();
my $inhouse_exomes = "";
while (@row = $out->fetchrow_array) {
	#print "@row\n";
	$samplename=$row[0];
	$foreignid=$row[1];
	$affected=$row[2];
	$affected = "betroffen" if $affected == 1;
	$entered=$row[3];
	$mother=$row[4];
	$m_foreignid=$row[5];
	$m_affected=$row[6];
	$m_affected= "gesund"    if $m_affected == 0;
	$m_affected= "unbekannt" if $row[6] eq "";
	$m_affected= "betroffen" if $m_affected == 1;
	$m_affected= "unbekannt" if $m_affected == 2;
	$father=$row[7];
	$f_foreignid=$row[8];
	$f_affected=$row[9];
	$f_affected= "gesund"    if $f_affected == 0;
	$f_affected= "unbekannt" if $row[9] eq "";
	$f_affected= "betroffen" if $f_affected == 1;
	$f_affected= "unbekannt" if $f_affected == 2;
	push(@omimnumber,$row[10]);
	$solved=$row[11];
	push(@cogene,$row[12]);
	push(@ggene,$row[13]);
	$tmp = $row[14];
	$tmp = "pathogen" if $tmp eq "pathogenic";
	$tmp = "wahrscheinlich pathogen" if $tmp eq "likely pathogenic";
	$tmp = "unklare Signifikanz" if $tmp eq "unknown significance";
	push(@patho,$tmp);
	$tmp = $row[14];
	$tmp = "pathogen" if $tmp eq "pathogenic";
	$tmp = "wahrscheinlich pathogen" if $tmp eq "likely pathogenic";
	$tmp = "Variante unklarer Signifikanz" if $tmp eq "unknown significance";
	push(@pathoforsummary,$tmp);
	$tmp=$row[15];
	$tmp = "heterozygot" if $tmp eq "heterozygous";
	$tmp = "compound-heterozygot" if $tmp eq "compound_heterozygous";
	$tmp = "homozygot" if $tmp eq "homozygous";
	$tmp = "hemizygot" if $tmp eq "hemizygous";
	push(@genotype_g,$tmp);
	push(@genotype,$row[15]);
	$tmp=$row[16];
	$tmp = "von Mutter und Vater geerbten" if $tmp eq "mo_fa";
	$tmp = "de novo" if $tmp eq "de_novo";
	push(@inheritance,$tmp);
	push(@inheritance_orig,$row[16]); # table
	push(@chrom,$row[17]);
	push(@start,$row[18]);
	push(@end,$row[19]);
	push(@refallele,$row[20]);
	push(@altallele,$row[21]);
	$tmp = $row[22];
	$tmp =~ s/^.*(nonsense).*$/$1/;
	$tmp =~ s/^.*(frameshift).*$/$1/;
	$tmp =~ s/^.*(stoploss).*$/$1/;
	$tmp =~ s/^.*(indel).*$/$1/;
	$tmp =~ s/^.*(missense).*$/$1/;
	$tmp =~ s/^.*(nearsplice).*$/$1/;
	$tmp =~ s/^.*[^r](splice).*$/$1/;
	$tmp =~ s/^.*(5utr).*$/$1/;
	$tmp =~ s/^.*(3utr).*$/$1/;
	$tmp =~ s/^.*(syn).*$/$1/;
	$tmp =~ s/^.*(intronic).*$/$1/;
	$tmp =~ s/\,//;
	push(@func,$tmp);
	$tmp = $row[23];
	$tmp = "nicht gelistet" if $tmp eq "";
	push(@clinvar,$tmp);
	push(@omimdisease,$row[24]);
	$sex = $row[25];
	$sex_g = "m&auml;nnlich" if ($sex eq "male");
	$sex_g = "weiblich" if ($sex eq "female");
	$clinical = $row[26];
	$hpo = $row[27];
	$tmp = $row[28];
	$tmp = 0 if ($tmp eq "");
	push(@gnomad_het,$tmp);
	$tmp = $row[29];
	$tmp = 0 if ($tmp eq "");
	push(@gnomad_hom,$tmp);
	push(@coverage,$row[30]);
	push(@inhouse_het,$row[31]);
	push(@inhouse_hom,$row[32]);
	$inhouse_exomes = $row[33];
}
# get_vep_for_report
$i=0;
foreach (@patho) {
	@vep = &get_vep_for_report($chrom[$i],$start[$i],$refallele[$i],$altallele[$i]);
	#print "selected @vep<br>";
	$tmp             = $vep[6];
	$tmp = "splice-acceptor" if $tmp eq "splice_acceptor_variant";
	$tmp = "splice-donor" if $tmp eq "splice_donor_variant";
	$tmp = "nonsense" if $tmp eq "stop_gained";
	$tmp = "frameshift" if $tmp eq "frameshift_variant";
	$tmp = "stop-lost" if $tmp eq "stop_lost";
	$tmp = "start-lost" if $tmp eq "start_lost";
	$tmp = "inframe-insertion" if $tmp eq "inframe_insertion";
	$tmp = "inframe-deletion" if $tmp eq "inframe_deletion";
	$tmp = "missense" if $tmp eq "missense_variant";
	$tmp = "splice-region" if $tmp eq "splice_region_variant";
	$tmp = "synonymous" if $tmp eq "synonymous_variant";
	$tmp = "5-prime-UTR" if $tmp eq "5_prime_UTR_variant";
	$tmp = "3-prime-UTR" if $tmp eq "3_prime_UTR_variant";
	$tmp = "intron" if $tmp eq "intron_variant";
	$tmp = "" if $tmp eq "";
	$vepconseq[$i]   = $tmp;
	$vepfeature[$i]  = $vep[4];
	$vepimpact[$i]   = $vep[13];
	$vepHGVSc[$i]    = $vep[21];
	$vepHGVSp[$i]    = $vep[22];
	$vepgene[$i]     = $vep[17];
	$i++;
}

########################## table for collected data ########################
sub table_for_collected_data {
# table
$i=0;
print "<br><br>";
print "<table>";
foreach (@patho) {
print qq#
<tr>
<td>$samplename</td>
<td>$foreignid</td>
<td>$affected</td>
<td>$entered</td>
<td>$mother</td>
<td>$m_foreignid</td>
<td>$m_affected</td>
<td>$father</td>
<td>$f_foreignid</td>
<td>$f_affected</td>
<td>$omimnumber[$i]</td>
<td>$solved</td>
<td>$cogene[$i]</td>
<td>$ggene[$i]</td>
<td>$vepgene[$i]</td>
<td>$patho[$i]</td>
<td>$genotype[$i]</td>
<td>$inheritance[$i]</td>
<td>$chrom[$i]</td>
<td>$start[$i]</td>
<td>$end[$i]</td>
<td>$refallele[$i]</td>
<td>$altallele[$i]</td>
<td>$func[$i]</td>
<td>$clinvar[$i]</td>
<td>$sex</td>
<td>$vepfeature[$i]</td>
<td>$vepHGVSc[$i]</td>
<td>$vepHGVSp[$i]</td>
<td>$clinical</td>
<td>$hpo</td>
</tr> 
#;
$i++;
}
print "</table>";
}
########################## report ########################

# Report
my $width = "12.5cm";
my $td_center  = "style='text-align:center;font-family:Arial;font-size:8pt;border-top:1px solid black;border-bottom:1px solid black;border-left:0;border-right:0;'";
my $td_left    = "style='text-align:left;font-family:Arial;font-size:8pt;border-top:1px solid black;border-bottom:1px solid black;border-left:0;border-right:0;'";
my $td_left_t  = "style='text-align:left;font-family:Arial;font-size:8pt;border-top:1px solid black;border-bottom:0;border-left:0;border-right:0;'";
my $td_left_b  = "style='text-align:left;font-family:Arial;font-size:8pt;border-top:0;border-bottom:1px solid black;border-left:0;border-right:0;'";
my $td_left_wo = "style='text-align:left;font-family:Arial;font-size:8pt;border-top:0;border-bottom:0;border-left:0;border-right:0;'";
my $left       = "style='text-align:left;font-family:Arial;font-size:9pt;margin-bottom:0pt;margin-top:4pt'";
my $justify    = "style='text-align:justify;font-family:Arial;font-size:9pt;margin-bottom:0pt;margin-top:4pt'";
my $justify0   = "style='text-align:justify;font-family:Arial;font-size:9pt;margin-bottom:0pt;margin-top:0pt'";
my $sup        = "style='font-family:Arial;font-size:75%;'";
my $xxx        = "<span style='color:red'>xxx</span>";

my $mode             = "";
my $mode_of_inheritance = "";
if ($chrom[0] eq "chrX") {  #mainly for Filter and sounso vererbte Erkrankung
	$mode = "X_chromosmal";
	$mode_of_inheritance = "X-chromosomal";
}
elsif (($genotype[0] eq "homozygous") or ($genotype[0] eq "compound_heterozygous")) {
	$mode = "recessive";
	$mode_of_inheritance = "autosomal-rezessiv";
}
elsif (($genotype[0] eq "heterozygous") and ($genotype[1] eq "heterozygous")) {
	$mode = "possible_recessive";
	$mode_of_inheritance = "autosomal-rezessiv";
}
elsif ($genotype[0] eq "heterozygous") {
	$mode = "dominant";
	$mode_of_inheritance = "autosomal-dominant";
}
else {
	$mode = "mode stimmt nicht" 
}

my $probability0 = "";
my $probability1 = "";
my $probability2 = "";
if ($userprobability eq 'pathgenic') {
	$patho[0] = "pathogen";
}
elsif ($userprobability eq 'vus'){
	$patho[0] = "unklar";
}

if ($patho[0] eq "pathogen") {
	$probability0 = "";
	$probability1 = "";
	$probability2 = "gegeben";
}
elsif ($patho[0] eq "wahrscheinlich pathogen") {
	$probability0 = "";
	$probability1 = "";
	$probability2 = "wahrscheinlich";
}
else {
	$probability0 = "<li>Die Pathogenit&auml;t der Variante\/n ist unklar. Wir empfehlen eine weitergehende Ph&auml;notypisierung im Kontext der <i>$vepgene[0]</i>-Variante/n.</li>";
	$probability1 = "Wir empfehlen eine weitergehende Ph&auml;notypisierung im Kontext der <i>$vepgene[0]</i>-Variante. ";
	$probability2 = "unklar";
}

my $recommendation = "";
if (($mother eq "") and ($father eq "")) {
if ((($genotype[0] eq "heterozygous") and ($genotype[1] eq "heterozygous")) or ($genotype[0] eq "homozygous")) {
	$recommendation = "Wir empfehlen eine Testung der Anlagetr&auml;gerschaft zum Nachweis der biallelischen Lokalisation der Varianten."
}
elsif (($genotype[0] eq "heterozygous") or ($genotype[0] eq "hemizygous")){ #de novo
	$recommendation = "Wir empfehlen eine Testung der Anlagetr&auml;gerschaft zum m&ouml;glichen Nachweis der de novo Entstehung der Variante."
}
}

print "<br><br><b>Copy the white area into your report</b><br><br>";
print "<div style='width:$width;background-color:#FFFFFF'>";
print "<br><br>";

&head;
if ($solved == 2) {
	&unsolved;
}
else {
	&summary(0);
	&variant_table;
	&results(0);
	&variant_details(0);
	&opinion(0);
	&remarks(0);
}

print "<br><br>";
print "</div>";

################# subs for report ########################
sub de_novo_for_filter {

if (($mother ne "") and ($father ne "")) { 
print qq#
<p $justify0>Filter IV - de-novo-Varianten: Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
#;
}

}
##################################
sub unsolved {
my $eltern = "";
$eltern = "und seiner Eltern" if (($sex eq "male") and ($mother ne ""));
$eltern = "und ihrer Eltern" if (($sex eq "female") and ($mother ne ""));

print qq#
<p $left><b>Zusammenfassung</p>
<ul $justify>
<li>Ergebnis: unauff&auml;lliger Befund</li>
<li>Kein Nachweis (wahrscheinlich) pathogener Varianten im Kontext der Symptomatik.</li>
<li>Auf Anfrage kann eine Reanalyse der Exomdaten erfolgen. Ohne konkreten Anlass empfehlen wir dies fr&uuml;hestens nach einem Jahr. 
Sollte im Rahmen unserer internen Analysen eine f&uuml;r diesen Fall relevante Variante identifiziert werden, werden wir Sie hiervon in Kenntnis setzen.</li>
</ul></b>
<p $left><br>$salutation,</p>
<p $justify>wir bedanken uns f&uuml;r die Zusendung der Blutproben von <span style='color:red'>xxx</span> $eltern zur diagnostischen Exomsequenzierung.</p>
<p $justify>Die in den Exomdaten des Patienten identifizierten Varianten wurden unter Ber&uuml;cksichtigung verschiedener Vererbungsformen und 
Analyseverfahren ausgewertet.</p>
<p $justify0>Filter I - autosomal-rezessiv: Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
<p $justify0>Filter II - autosomal-dominant (Ph&auml;notyp-basiert): Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
<p $justify>Filter III - X-chromosomal: Kein Nachweis (wahrscheinlich) pathogener Varianten.</i>.</p>
#;
&de_novo_for_filter;
if ($cnvfilter eq "yes") {
print qq#
<p $justify0>CNVs - CNVs wurden bei der Auswertung ber&uuml;cksichtigt.</p>
<p $justify>Eine erneute Auswertung der Daten zu einem sp&auml;teren Zeitpunkt kann ggf. zur weiteren Aufkl&auml;rung eines m&ouml;glichen genetischen 
Defekts beitragen, da eine Verf&uuml;gbarkeit neuer Daten zu bislang unbekannten pathogenen Varianten eine weitergehende Beurteilung m&ouml;glich machen kann.
#;
}
&remarks(0);
}
##################################
sub opinion {
my $i = shift;
my $consequence = "";
my $clinvar     = "";
foreach (@vepconseq) {
if (($clinvar[$i] ne "") and ($clinvar[$i] ne "nicht gelistet")) {
	$clinvar = "Die Variante ist in ClinVar als \"$clinvar[$i]\" gelistet. ";
}
if ($clinvar[$i] eq "nicht gelistet") {
	$clinvar = "Die Variante ist in ClinVar nicht gelistet. ";
}
if ($vepconseq[$i] eq "frameshift") {
$consequence .= "Aufgrund der Variante $vepHGVSc[$i] wird der vorzeitige Abbruch der Proteintranslation vorhergesagt. $clinvar";
}
elsif ($vepconseq[$i] eq "nonsense") {
$consequence .= "Aufgrund der Variante $vepHGVSc[$i] werden die Verschiebung des Leserahmens und der vorzeitiger Abbruch der Proteintranslation vorhergesagt. $clinvar";
}
elsif ($vepconseq[$i] eq "missense") {
$consequence .= "Aufgrund der Variante $vepHGVSc[$i] wird der Austausch einer hochkonservierten Aminos&auml;ureposition vorhergesagt. $clinvar";
}
elsif ($vepconseq[$i] eq "splice-acceptor") {
$consequence .= "Aufgrund der Variante $vepHGVSc[$i] wird der Verlust der Splei&szlig;donorstelle von Exon $xxx vorhergesagt. $clinvar";
}
elsif ($vepconseq[$i] eq "splice-donor") {
$consequence .= "Aufgrund der Variante $vepHGVSc[$i] wird der Verlust der Splei&szlig;akzeptorstelle von Exon $xxx vorhergesagt vorhergesagt. $clinvar";
}
else {
$consequence = $xxx;
}
$i++;
}

$i = 0;
my $genefunction = "<i>$vepgene[$i]</i> kodiert f&uuml;r ein Protein $xxx.";

my $diagnosis = "";
if ($omimnumber[$i] ne "") {
$diagnosis = "Varianten in diesem Gen sind mit der $mode_of_inheritance vererbten Erkrankung 
\"$omimdisease[$i]\" (OMIM \#$omimnumber[$i]) assoziiert worden.";
}
else {
$diagnosis = "$xxx Varianten in diesem Gen sind im Zusammenhang mit $xxx beschrieben (PMID; $xxx). Diese Erkrankung ist nicht in OMIM gelistet.";
}
my $conclusion = "Klinische Ph&auml;notypen beschriebener Patienten stimmen mit denen von $xxx &uuml;berein (PMID: $xxx).
In Zusammenschau der Befunde ist nach unserer Einsch&auml;tzung eine urs&auml;chliche Assoziation der identifizierten Variante/n mit der Erkrankung 
von $xxx $probability2. $probability1";

print qq#
<p $left><b>Beurteilung</b></p>
<p $justify>
$consequence 
$genefunction 
$diagnosis 
$conclusion 
$recommendation
</p>
#;


}

##################################
sub head {
print "<p $left><b>MOLEKULARGENETISCHER BEFUND";
if (($mother ne "") and ($father ne "")) {
	print " - Trio-Exomsequenzierung</b><br><br></p>";
}
else {
	print " - Single-Exomsequenzierung</b><br><br></p>";
}

print qq#
<table style='width:$width;border-collapse:collapse;border-right:0;'>
<tr><td $td_left_t width="28%">Name,Vorname</td><td $td_left_t width="44%"></td><td $td_left_t width="12%">Material</td><td $td_left_t width="16%">EDTA-Blut</td></tr> 
<tr><td $td_left_wo>Geburtsdatum</td><td $td_left_wo></td><td $td_left_wo>Eingang</td><td $td_left_wo></td></tr> 
<tr><td $td_left_wo>Geschlecht</td><td $td_left_wo>$sex_g</td><td $td_left_wo>DNA-ID</td><td $td_left_wo>$samplename</td></tr> 
<tr><td $td_left_b>Ph&auml;notyp</td><td $td_left_b>$affected (Index)</td><td $td_left_b>Alias-ID</td><td $td_left_b>$foreignid</td></tr> 
#;
if ($mother ne "") {
print qq#
<tr><td $td_left_t width="28%">Name,Vorname</td><td $td_left_t width="44%"></td><td $td_left_t width="12%">Material</td><td $td_left_t width="16%">EDTA-Blut</td></tr> 
<tr><td $td_left_wo>Geburtsdatum</td><td $td_left_wo></td><td $td_left_wo>Eingang</td><td $td_left_wo></td></tr> 
<tr><td $td_left_wo>Geschlecht</td><td $td_left_wo>weiblich</td><td $td_left_wo>DNA-ID</td><td $td_left_wo>$mother</td></tr> 
<tr><td $td_left_b>Ph&auml;notyp</td><td $td_left_b>$f_affected (Mutter)</td><td $td_left_b>Alias-ID</td><td $td_left_b>$f_foreignid</td></tr> 
#;
}
if ($father ne "") {
print qq#
<tr><td $td_left_t width="28%">Name,Vorname</td><td $td_left_t width="44%"></td><td $td_left_t width="12%">Material</td><td $td_left_t width="16%">EDTA-Blut</td></tr> 
<tr><td $td_left_wo>Geburtsdatum</td><td $td_left_wo></td><td $td_left_wo>Eingang</td><td $td_left_wo></td></tr> 
<tr><td $td_left_wo>Geschlecht</td><td $td_left_wo>m&auml;nnlich</td><td $td_left_wo>DNA-ID</td><td $td_left_wo>$father</td></tr> 
<tr><td $td_left_b>Ph&auml;notyp</td><td $td_left_b>$m_affected (Vater)</td><td $td_left_b>Alias-ID</td><td $td_left_b>$m_foreignid</td></tr> 
#;
}
print qq#
<tr><td $td_left>Synopse</td><td colspan="3" $td_left></td></tr> 
<tr><td $td_left>Familienanamnese</td><td colspan="3" $td_left></td></tr> 
<tr><td $td_left>Genet. Vorbefunde</td><td colspan="3" $td_left></td></tr> 
<tr><td $td_left>Indikation</td><td colspan="3" $td_left></td></tr> 
<tr><td $td_left>Klinische Suchbegriffe</td><td colspan="3" $td_left>$clinical</td></tr> 
<tr><td $td_left>HPO-Termini</td><td colspan="3" $td_left>$hpo</td></tr> 
<tr><td $td_left>Auswertung</td><td $td_left></td><td $td_left>Datum</td><td $td_left>$todaysdate</td></tr> 
#;

print "</table>";
}

##################################
sub summary {
my $i = shift;
my $diagnosis = "";
if ($omimnumber[$i] ne "") {
	if ($probability2 eq "unklar") {
		$diagnosis = "Unklarer Befund: Verdacht auf \"$omimdisease[$i]\" (OMIM \#$omimnumber[$i])";
	}
	else {
		$diagnosis = "Diagnose: \"$omimdisease[$i]\" (OMIM \#$omimnumber[$i])";
	}
}
else {
	if ($probability2 eq "unklar") {
		$diagnosis = "Unklarer Befund: Verdacht auf \"<i>$vepgene[0]</i>-assoziierte Erkrankung\" (nicht in OMIM gelistet)";
	}
	else {
		$diagnosis = "Diagnose: \"<i>$vepgene[0]</i>-assoziierte Erkrankung\" (nicht in OMIM gelistet)";
	}
}

print qq#
<p $left><b>Zusammenfassung</b></p>
#;
if ($inheritance[$i] eq "de novo") {
print qq#
<ul $justify><b>
<li>$diagnosis</li>
<li>Nachweis einer $genotype_g[$i]en $vepconseq[$i]-Variante in dem Krankheitsgen <i>$vepgene[$i]</i>. Diese ist aktuell als $pathoforsummary[$i] zu klassifizieren.</li>
<li>In der Blut-DNA der Eltern konnte die Variante nicht nachgewiesen werden. Somit ist von einer de-novo-Entstehung auszugehen. </li>
$probability0
#;
}
elsif ($genotype[$i] eq "homozygous") {
print qq#
<ul $justify><b>
<li>Diagnose: $diagnosis</li>
<li>Nachweis einer $genotype_g[$i]en $vepconseq[$i]-Variante in dem Krankheitsgen <i>$vepgene[$i]</i>. Diese ist aktuell als $pathoforsummary[$i] zu klassifizieren.</li>
$probability0
#;
}
elsif ($genotype[$i] eq "compound_heterozygous") {
print qq#
<ul $justify><b>
<li>Diagnose: $diagnosis</li>
<li>Nachweis von zwei $genotype_g[$i]en Varianten ($vepconseq[$i]/$vepconseq[$i+1]) in dem Krankheitsgen <i>$vepgene[$i]</i>.</li>
$probability0
#;
}
elsif ($mode eq "possible_recessive") {
print qq#
<ul $justify><b>
<li>Diagnose: $diagnosis</li>
<li>Nachweis von zwei $genotype_g[$i]en Varianten ($vepconseq[$i]/$vepconseq[$i+1]) in dem Krankheitsgen <i>$vepgene[$i]</i>.</li>
$probability0
<li>$recommendation</li>
#;
}
elsif (($mode eq "dominant") or ($mode eq "X-chromosomal")) {
print qq#
<ul $justify><b>
<li>Diagnose: $diagnosis</li>
<li>Nachweis einer $genotype_g[$i]en $vepconseq[$i]-Variante in dem Krankheitsgen <i>$vepgene[$i]</i>. Diese ist aktuell als $pathoforsummary[$i] zu klassifizieren.</li>
$probability0
<li>$recommendation</li>
#;
}
else {
print qq#
<ul $justify><b> $xxx not appropriate
<li>Diagnose: $diagnosis</li>
<li>Nachweis einer $patho[$i]en $genotype_g[$i]en $vepconseq[$i]-Variante in dem Krankheitsgen <i>$vepgene[$i]</i>.</li>
#;
}
if ($cnvfilter eq "noquality") {
	print qq#
	<li>Eine CNV-Analyse war aufgrund schlechter Qualit&auml;t nicht m&ouml;glich.</li>
	#;
}
elsif ($cnvfilter eq "noprotocol") {
	print qq#
	<li>Eine CNV-Analyse war aufgrund der Verwendung eines anderen Sequenzierprotokolls nicht m&ouml;glich.</li>
	#;
}
print qq#
</b>
</ul>
#;
} # end summary

##################################
sub variant_table {
$i=0;
print qq#
<p $left>Nachgewiesene Varianten</p>
<table style='width:$width;border-collapse:collapse;border-right:0;'>
<tr><td $td_left>DNA ID<br>Status<br>(Ph&auml;notyp)</td><td $td_left>Gen</td><td $td_left>Variante<br>(Status)</td><td $td_left>ClinVar<br>Bewertung</td><td $td_left>Unsere<br>Einsch&auml;tzung<sup $sup>1</sup></td></tr> 
#;
foreach (@patho) {
print qq#
<tr><td $td_left>$samplename<br>$status<br>($affected)</td><td $td_left><i>$vepgene[$i]</i></td><td $td_left>hg19:$chrom[$i]_$start[$i]_$refallele[$i]/$altallele[$i]<br>$vepHGVSc[$i]<br>$vepHGVSp[$i]<br>($genotype_g[$i])</td><td $td_left>$clinvar[$i]</td><td $td_left>$patho[$i]</td></tr> 
#;
if (($inheritance_orig[$i] eq "mo_fa") or ($inheritance_orig[$i] eq "mother")) {
print qq#
<tr><td $td_left>$mother<br>Mutter<br>($m_affected)</td><td $td_left><i>$vepgene[$i]</i></td><td $td_left>hg19:$chrom[$i]_$start[$i]_$refallele[$i]/$altallele[$i]<br>$vepHGVSc[$i]<br>$vepHGVSp[$i]</td><td $td_left></td><td $td_left></td></tr> 
#;
}
if (($inheritance_orig[$i] eq "mo_fa") or ($inheritance_orig[$i] eq "father")) {
print qq#
<tr><td $td_left>$father<br>Vater<br>($f_affected)</td><td $td_left><i>$vepgene[$i]</i></td><td $td_left>hg19:$chrom[$i]_$start[$i]_$refallele[$i]/$altallele[$i]<br>$vepHGVSc[$i]<br>$vepHGVSp[$i]</td><td $td_left></td><td $td_left></td></tr> 
#;
}
$i++;
}
print "<tr><td $td_left_wo colspan='5'><sup $sup>1</sup>Siehe ausf&uuml;hrliche Informationen zur Variantenanalyse</td></tr>";
print "</table>";
} #end variant_table

##################################
sub results {
my $i = shift;
my $eltern = "";
$eltern = "und seiner Eltern" if (($sex eq "male") and ($mother ne ""));
$eltern = "und ihrer Eltern" if (($sex eq "female") and ($mother ne ""));
print qq#
<p $left><br><br>$salutation,</p>
<p $justify>wir bedanken uns f&uuml;r die Zusendung der Blutproben von <span style='color:red'>xxx</span> $eltern zur diagnostischen Exomsequenzierung.</p>
<p $left><b>Ergebnis</b></p>
<p $justify>Die in den Exomdaten des Patienten identifizierten Varianten wurden unter Ber&uuml;cksichtigung verschiedener Vererbungsformen und 
Analyseverfahren ausgewertet.</p>
#;
if ($mode eq "X-chromosomal") {
print qq#
<p $justify0>Filter I - autosomal-rezessiv: Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
<p $justify0>Filter II - autosomal-dominant (Ph&auml;notyp-basiert): Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
<p $justify><b>Filter III - X-chromosomal: Nachweis einer $genotype_g[$i]en Variante ($vepconseq[$i]) in <i>$vepgene[$i]</i>.</b></p>
<p $justify0>Filter IV - de-novo-Varianten: Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
#;
if ($cnvfilter eq "yes") {
print qq#
<p $justify0>CNVs - CNVs wurden bei der Auswertung ber&uuml;cksichtigt.</p>
#;
}
}
elsif ($inheritance[$i] eq "de novo") {
print qq#
<p $justify>Filter I - autosomal-rezessiv: Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
<p $justify0>Filter II - autosomal-dominant (Ph&auml;notyp-basiert): Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
<p $justify0>Filter III - X-chromosomal: Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
<p $justify0><b>Filter IV - de-novo-Varianten: Nachweis einer $genotype_g[$i]en $vepconseq[$i]-Variante in <i>$vepgene[$i]</i>.</b></p>
#;
if ($cnvfilter eq "yes") {
print qq#
<p $justify0>CNVs - CNVs wurden bei der Auswertung ber&uuml;cksichtigt.</p>
#;
}
}
elsif ($genotype[$i] eq "homozygous") {
print qq#
<p $justify><b>Filter I - autosomal-rezessiv: Nachweis einer homozygoten $vepconseq[$i]-Variante in <i>$vepgene[$i]</i>.</b></p>
<p $justify0>Filter II - autosomal-dominant (Ph&auml;notyp-basiert): Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
<p $justify0>Filter III - X-chromosomal: Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
#;
&de_novo_for_filter;
if ($cnvfilter eq "yes") {
print qq#
<p $justify0>CNVs - CNVs wurden bei der Auswertung ber&uuml;cksichtigt.</p>
#;
}
}
elsif ($genotype[$i] eq "compound_heterozygous") {
print qq#
<p $justify><b>Filter I - autosomal-rezessiv: Nachweis von zwei compound-heterozygoten Varianten ($vepconseq[$i]/$vepconseq[$i+1]) in <i>$vepgene[$i]</i>.</b></p>
<p $justify0>Filter II - autosomal-dominant (Ph&auml;notyp-basiert): Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
<p $justify0>Filter III - X-chromosomal: Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
#;
&de_novo_for_filter;
if ($cnvfilter eq "yes") {
print qq#
<p $justify0>CNVs - CNVs wurden bei der Auswertung ber&uuml;cksichtigt.</p>
#;
}
}
elsif ($mode eq "possible_recessive") {
print qq#
<p $justify><b>Filter I - autosomal-rezessiv: Nachweis von zwei heterzygoten Varianten ($vepconseq[$i]/$vepconseq[$i+1]) in <i>$vepgene[$i]</i>.</b></p>
<p $justify0>Filter II - autosomal-dominant (Ph&auml;notyp-basiert): Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
<p $justify0>Filter III - X-chromosomal: Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
#;
&de_novo_for_filter;
if ($cnvfilter eq "yes") {
print qq#
<p $justify0>CNVs - CNVs wurden bei der Auswertung ber&uuml;cksichtigt.</p>
#;
}
}
elsif ($mode eq "dominant") {
print qq#
<p $justify0>Filter I - autosomal-rezessiv: (Ph&auml;notyp-basiert): Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
<p $justify><b>Filter II - autosomal-dominant: Nachweis einer heterzygoten Variante ($vepconseq[$i]) in <i>$vepgene[$i]</i>.</b></p>
<p $justify0>Filter III - X-chromosomal: Kein Nachweis (wahrscheinlich) pathogener Varianten.</p>
#;
&de_novo_for_filter;
if ($cnvfilter eq "yes") {
print qq#
<p $justify0>CNVs - CNVs wurden bei der Auswertung ber&uuml;cksichtigt.</p>
#;
}
}

}

##################################
sub variant_details {
my $i = shift;
print qq#
<p $left>Details zu den Varianten</p>
<table style='width:$width;border-collapse:collapse;border-right:0;'>
<tr><td $td_center>Variante</td><td $td_center>Abdeckung<br>in Index</td><td $td_center>VEP IMPACT<sup $sup>1</sup></td><td $td_center>H&auml;ufigkeit in<br>in-house Exomen<sup $sup>2</sup></td><td $td_center>H&auml;ufigkeit in<br>gnomAD<br>European and African</td></tr> 
#;
foreach (@patho) {
print qq#
<tr><td $td_center>$vepHGVSc[$i]</td><td $td_center>$coverage[$i]-fach</td><td $td_center>$vepimpact[$i]</td><td $td_center>$inhouse_het[$i] Heterozygote<br>$inhouse_hom[$i] Homozygote</td><td $td_center>$gnomad_het[$i] Heterozygote<br>$gnomad_hom[$i] Homozygote</td></tr> 
#;
$i++;
}
print qq#
<tr><td $td_left_wo colspan='5'><sup $sup>1</sup>Gem&auml;&szlig; Ensembl Variant Effect Predictor (https://www.ensembl.org/Help/Glossary?id=535).</td></tr>
<tr><td $td_left_wo colspan='5'><sup $sup>2</sup>Derzeit $inhouse_exomes in-house Exome.</td></tr>
</table>
#;

}

##################################
sub remarks {
my $values = "";
my $query = "
SELECT module FROM $exomevcfe.textmodules 
WHERE name = 'munich_main_remarks'
";
my $out = &executeQuerySth($dbh,$query,$values);
my $text = $out->fetchrow_array;
$text =~ s/(\$\w+)/$1/gee;
print "$text";

}
##################################
sub remarks1 {
print qq#
<p $left><b>Allgemeine Bemerkungen</b></p>
<p $justify>Bei Auftreten neuer klinischer Merkmale oder der Ver&ouml;ffentlichung neuer Krankheitsgene mit &auml;hnlicher Klinik kann jederzeit 
eine erneute Auswertung der Daten erfolgen.</p>
<p $justify>Allgemein weisen wir darauf hin, dass die durchgef&uuml;hrte Exomanalyse nicht als abschlie&szlig;ende Beurteilung aller Abschnitte aller 
Gene betrachtet werden darf. So k&ouml;nnen beispielsweise Varianten in nicht angereicherten Regionen (untranslatierte Bereiche, 
Introns, Promotor- und Enhancer-Regionen), Repeat-Expansionen, Duplikationen und Deletionen nicht sicher detektiert und ausgeschlossen 
werden. Bei entsprechendem klinischem Verdacht kann eine konventionelle Analyse (Sanger-Sequenzierung, MLPA) trotz des vorliegenden 
Exombefundes indiziert sein. Hinsichtlich der Beurteilung identifizierter Varianten besteht die M&ouml;glichkeit, dass sich aufgrund der 
Verf&uuml;gbarkeit neuer Daten die Einsch&auml;tzung ihrer Pathogenit&auml;t und klinischen Relevanz zu einem sp&auml;teren Zeitpunkt 
ver&auml;ndern k&ouml;nnte. Auf Wunsch kann eine Bereitstellung des Datensatzes erfolgen.</p>
<p $justify>Gem&auml;&szlig; dem Gendiagnostikgesetz (GenDG) sollte der Befund im Rahmen eines humangenetischen Beratungsgespr&auml;chs mitgeteilt werden. 
F&uuml;r R&uuml;ckfragen stehen wir selbstverst&auml;ndlich jederzeit gerne zur Verf&uuml;gung.</p>
#;
}

} # end report

########################################################################
# execute query
########################################################################
sub executeQuerySth {
	my $dbh     = shift;
	my $query   = shift;
	my $values  = shift;
	my $out     = "";
	$out = $dbh->prepare($query) ||  die print "Can't prepare statement: $DBI::errstr";
	if($values){
		$out->execute($values) ||  die print$DBI::errstr;
		return $out;
	}
	$out->execute() ||  die print  $DBI::errstr;
	return $out;
}




########################################################################
# getvepforreport
########################################################################
sub get_vep_for_report {
my $chrom  = shift;
my $start  = shift;
my $ref    = shift;
my $alt    = shift;

my $vep_input       = $chrom . " " . $start . " . " .$ref . " " . $alt;
my $vep_input_file  = "/tmp/vep_input_$$.vcf";

open (OUT, ">", "$vep_input_file");
print OUT "$vep_input";
close OUT;

my $cmd = "
perl /usr/local/packages/seq/ensembl-tools-release-85/scripts/variant_effect_predictor/variant_effect_predictor.pl \\
-i $vep_input_file \\
-o STDOUT \\
--cache \\
--dir /data/mirror/vep \\
--fasta /data/mirror/vep/homo_sapiens/85_GRCh37/Homo_sapiens.GRCh37.75.dna.primary_assembly.fa.gz \\
--offline \\
--refseq \\
--no_stats \\
--force_overwrite \\
--species homo_sapiens \\
--hgvs \\
--shift_hgvs 1 \\
--symbol \\
--tab \\
--no_intergenic \\
--plugin GeneSplicer,/usr/local/packages/seq/GeneSplicer/bin/linux/genesplicer,/usr/local/packages/seq/GeneSplicer/human,context=200
";

delete $ENV{'PATH'};
my $result        = `$cmd`;
my @result        = split(/\n/,$result);
my @line          = ();
my @oldline       = ();
my @selected      = ();
my $selected_line = 0;
my $header        = 0;
my $i             = 1;

print "<br><b>$result[0]</b><table class='vep_table'>";
foreach (@result) {
	if (/##/) {next;} # information has two #
	if (/downstream_gene_variant/) {next;} # don't know how to get rid of these bulk of downstream variants
	if (/upstream_gene_variant/) {next;}
	$header = s/^#//; # table header has only one #
	if ($header) {next;}
	@line = split(/\t/);
	unless (/NM_/)  {next;}
	print "<tr><td>$i</td>";
	foreach (@line) {
		#print "<td>$_</td>";
		if ($header) {print "<th>$_</th>"} else {print "<td>$_</td>"};
	}
	@oldline = @line;
	if ($i == 1) {
		@selected = @line;
		$selected_line = $i;
	}
	else {
		if ($line[9]>$oldline[9]) { #longer cds
			@selected = @line;
			$selected_line = $i;
		}
	}
	print "</tr>";
	$i++;

}
print "</table>";
print "Line $selected_line was selected.<br>";

unlink($vep_input_file);

return(@selected);
}

########################################################################



1;
__END__
