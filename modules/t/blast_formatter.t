# Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
# Copyright [2016-2018] EMBL-European Bioinformatics Institute
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#      http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

use strict;
use warnings;

use FindBin;
use Test::More;
use Test::Exception;

BEGIN { use_ok('Bio::EnsEMBL::IO::Parser::BLASTFormatter'); } 

my $prefix = $FindBin::Bin;
my $parser;
my $test_file = "$prefix/input/blast_test.6.default.tab";

###########################################
#
# Test invalid argument exception handling
#
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open() }
	  qr/Must provide name/, 'No file name argument caught';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open('non_existant_file') }
	  qr/Check file/, 'Non existant or unreadable file caught';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file) }
	  qr/Must provide format/, 'No format argument caught';

my $outfmt = 'aaa';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt) }
	  qr/must begin with number/, 'Non numeric output format argument caught';
$outfmt = '1';
throws_ok { $parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt) }
	  qr/must be either/, 'Invalid format argument caught';
#
###########################################

################################################################
#
# Test parsing of format specifiers from output format argument
#
$outfmt = 6; # default format specifiers
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
is($parser->{delimiter}, '\t', 'Tab delimiter');

my $default_fields = [ qw/qseqid sseqid pident length mismatch gapopen qstart qend sstart send evalue bitscore/ ];
my $got_fields = $parser->get_fields();
is_deeply($got_fields, $default_fields, 'Default format specifiers with tab-separated values');

$outfmt = '7 qacc sacc evalue score nident pident qstart qend sstart send length positive ppos qseq sseq';
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
is($parser->{delimiter}, '\t', 'Tab delimiter');
my $compara_fields = [ qw/qacc sacc evalue score nident pident qstart qend sstart send length positive ppos qseq sseq/ ];
$got_fields = $parser->get_fields();
is_deeply($got_fields, $compara_fields, 'Compara format specifiers');

$outfmt = 10;
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
is($parser->{delimiter}, ',', 'Comma-delimiter');
$got_fields = $parser->get_fields();
is_deeply($got_fields, $default_fields, 'Default format specifiers with comma-separated values');
#
################################################################

#################################################################
#
# Test invalid calls to automatically generated accessor methods
#
$outfmt = 6; # default format specifiers
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
throws_ok { $parser->get_raw_qacc() }
	  qr/Invalid attribute method/, 'Invalid attribute getter call caught';
throws_ok { $parser->get_score() }
	  qr/Invalid attribute method/, 'Invalid attribute getter call caught';
throws_ok { $parser->get_gapopen() }
	  qr/Cannot get attribute/, 'Invalid attribute getter call caught';

$outfmt = '7 qacc sacc evalue score rident pident qstart qend sstart send length positive ppos qseq sseq';
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
throws_ok { $parser->get_raw_sseqid() }
	  qr/Invalid attribute method/, 'Invalid attribute getter call caught';
throws_ok { $parser->get_mismatch() }
	  qr/Invalid attribute method/, 'Invalid attribute getter call caught';
#
#################################################################

#######################################################
#
# Test parsing tabular format with default specifiers
#
note("Test tabular format with default specifiers");
$outfmt = 6; # default format specifiers
$test_file = "$prefix/input/blast_test.6.default.tab";
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
ok($parser->next(), "Loading first record");
my @expected_record = ( qw/gnl|MYDB|1	gi|405832|gb|U00001.1|HSCDC27	100.00	720	0	0	1	720	1	720	0.0	1330/ );
is_deeply($parser->{record}, \@expected_record, "First record");
is($parser->get_qseqid, 'gnl|MYDB|1', 'Query seq-id');
is($parser->get_length, 720, 'Alignment length');
ok($parser->get_evalue == 0.0, 'E-value');
ok($parser->get_bitscore == 1330, 'Bit score');

# seek to sixth record
map { $parser->next() } (1 .. 5);
@expected_record = ( qw/gnl|MYDB|1	gi|578831755|ref|XR_429935.1|	100.00	714	0	0	7	720	76	789	0.0	1319/);
is_deeply($parser->{record}, \@expected_record, "Sixth record");
ok($parser->get_pident == 100, 'Percentage of identical matches');
is($parser->get_length, 714, 'Alignment length');
is($parser->get_qstart, 7, 'Start of alignment in query');
is($parser->get_send, 789, 'End of alignment in query');

# seek to last record
note("Parse last record");
map { $parser->next() } (1 .. 245); 
ok($parser->get_pident == 92.79, 'Percentage of identical matches');
is($parser->get_mismatch, 46, 'Number of mismatches');
is($parser->get_bitscore, 924, 'Bit score');
ok(!$parser->next(), 'No more records');
#
#######################################################

#####################################################################################
# Test parsing tabular format with comment lines, compara-specific format specifiers 
#
note("Test Compara format specifiers");
$outfmt = '7 qacc sacc evalue score nident pident qstart qend sstart send length positive ppos qseq sseq';
$test_file = "$prefix/input/blast_test.7.compara.tab";
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
ok($parser->next(), 'Loading first record');
is($parser->get_qacc, 'gnl|MYDB|1', 'Query accession');
is($parser->get_sacc, 'U00001', 'Subject accession');
ok($parser->get_evalue == 0, 'E-value');
ok($parser->get_score == 720, 'Score');
ok($parser->get_nident == 720, 'Number of identical matches');
ok($parser->get_pident == 100, 'Percentage identity');
is($parser->get_qstart, 1, 'Query start');
is($parser->get_qend, 720, 'Query end');
is($parser->get_sstart, 1, 'Subject start');
is($parser->get_send, 720, 'Subject end');
is($parser->get_length, 720, 'Alignment length');
is($parser->get_positive, 720, 'Positives');
ok($parser->get_ppos == 100, 'Percentage positives');
ok($parser->get_qseq eq 'GAATTCCCGCTACAGGGGGGGCCTGAGGCACTGCAGAAAGTGGGCCTGAGCCTCGAGGATGACGGTGCTGCAGGAACCCGTCCAGGCTGCTATATGGCAAGCACTAAACCACTATGCTTACCGAGATGCGGTTTTCCTCGCAGAACGCCTTTATGCAGAAGTACACTCAGAAGAAGCCTTGTTTTTACTGGCAACCTGTTATTACCGCTCAGGAAAGGCATATAAAGCATATAGACTCTTGAAAGGACACAGTTGTACTACACCGCAATGCAAATACCTGCTTGCAAAATGTTGTGTTGATCTCAGCAAGCTTGCAGAAGGGGAACAAATCTTATCTGGTGGAGTGTTTAATAAGCAGAAAAGCCATGATGATATTGTTACTGAGTTTGGTGATTCAGCTTGCTTTACTCTTTCATTGTTGGGACATGTATATTGCAAGACAGATCGGCTTGCCAAAGGATCAGAATGTTACCAAAAGAGCCTTAGTTTAAATCCTTTCCTCTGGTCTCCCTTTGAATCATTATGTGAAATAGGTGAAAAGCCAGATCCTGACCAAACATTTAAATTCACATCTTTACAGAACTTTAGCAACTGTCTGCCCAACTCTTGCACAACACAAGTACCTAATCATAGTTTATCTCACAGACAGCCTGAGACAGTTCTTACGGAAACACCCCAGGACACAATTGAATTAAACAGATTGAATTTAGAATCTTCCAA', 'Query sequence');
ok($parser->get_sseq eq 'GAATTCCCGCTACAGGGGGGGCCTGAGGCACTGCAGAAAGTGGGCCTGAGCCTCGAGGATGACGGTGCTGCAGGAACCCGTCCAGGCTGCTATATGGCAAGCACTAAACCACTATGCTTACCGAGATGCGGTTTTCCTCGCAGAACGCCTTTATGCAGAAGTACACTCAGAAGAAGCCTTGTTTTTACTGGCAACCTGTTATTACCGCTCAGGAAAGGCATATAAAGCATATAGACTCTTGAAAGGACACAGTTGTACTACACCGCAATGCAAATACCTGCTTGCAAAATGTTGTGTTGATCTCAGCAAGCTTGCAGAAGGGGAACAAATCTTATCTGGTGGAGTGTTTAATAAGCAGAAAAGCCATGATGATATTGTTACTGAGTTTGGTGATTCAGCTTGCTTTACTCTTTCATTGTTGGGACATGTATATTGCAAGACAGATCGGCTTGCCAAAGGATCAGAATGTTACCAAAAGAGCCTTAGTTTAAATCCTTTCCTCTGGTCTCCCTTTGAATCATTATGTGAAATAGGTGAAAAGCCAGATCCTGACCAAACATTTAAATTCACATCTTTACAGAACTTTAGCAACTGTCTGCCCAACTCTTGCACAACACAAGTACCTAATCATAGTTTATCTCACAGACAGCCTGAGACAGTTCTTACGGAAACACCCCAGGACACAATTGAATTAAACAGATTGAATTTAGAATCTTCCAA', 'Subject sequence');

note("Parse last record");
map { $parser->next() } (1 .. 250);
is($parser->get_qacc, 'gnl|MYDB|1', 'Query accession');
is($parser->get_sacc, 'XM_006247536', 'Subject accession');
ok($parser->get_evalue == 0, 'E-value');
ok($parser->get_score == 500, 'Score');
ok($parser->get_nident == 592, 'Number of identical matches');
ok($parser->get_pident == 92.79, 'Percentage identity');
is($parser->get_qstart, 83, 'Query start');
is($parser->get_qend, 720, 'Query end');
is($parser->get_sstart, 79, 'Subject start');
is($parser->get_send, 716, 'Subject end');
is($parser->get_length, 638, 'Alignment length');
is($parser->get_positive, 592, 'Positives');
ok($parser->get_ppos == 92.79, 'Percentage positives');
ok($parser->get_qseq eq 'CAGGCTGCTATATGGCAAGCACTAAACCACTATGCTTACCGAGATGCGGTTTTCCTCGCAGAACGCCTTTATGCAGAAGTACACTCAGAAGAAGCCTTGTTTTTACTGGCAACCTGTTATTACCGCTCAGGAAAGGCATATAAAGCATATAGACTCTTGAAAGGACACAGTTGTACTACACCGCAATGCAAATACCTGCTTGCAAAATGTTGTGTTGATCTCAGCAAGCTTGCAGAAGGGGAACAAATCTTATCTGGTGGAGTGTTTAATAAGCAGAAAAGCCATGATGATATTGTTACTGAGTTTGGTGATTCAGCTTGCTTTACTCTTTCATTGTTGGGACATGTATATTGCAAGACAGATCGGCTTGCCAAAGGATCAGAATGTTACCAAAAGAGCCTTAGTTTAAATCCTTTCCTCTGGTCTCCCTTTGAATCATTATGTGAAATAGGTGAAAAGCCAGATCCTGACCAAACATTTAAATTCACATCTTTACAGAACTTTAGCAACTGTCTGCCCAACTCTTGCACAACACAAGTACCTAATCATAGTTTATCTCACAGACAGCCTGAGACAGTTCTTACGGAAACACCCCAGGACACAATTGAATTAAACAGATTGAATTTAGAATCTTCCAA', 'Query sequence');
ok($parser->get_sseq eq 'CAGGCTGCTATATGGCAAGCACTAAACCACTATGCTTACCGAGACGCAGTTTTCCTCGCAGAACGACTATATGCAGAAGTACATTCAGAAGAAGCCTTGTTTCTACTGGCGACCTGTTACTACCGCTCAGGAAAGGCCTATAAAGCCTATAGACTCTTGAAAGGACACAGTTGTACCACCCCGCAGTGTAAATACCTGCTTGCAAAATGTTGTGTTGACCTCAGCAAGCTTGCAGAAGGGGAACAAATCTTATCTGGTGGAGTGTTTAATAAGCAAAAAAGCCATGACGACCTTGTCACTGAGTTTGGTGATTCAGCTTGCTTCACTCTTTCCTTGTTGGGACATGTATATTGCAAGACAGATCGGCTTGCCAAAGGATCAGAATGTTACCAAAAGAGCCTTAGTTTAAATCCTTTCCTCTGGTCTCCCTTTGAATCGTTATGTGAAATAGGTGAGAAGCCAGATCCTGACCAAACATTTAAATTAACATCTCTACAGAATTTTAGCAGTTGTCTTCCCAACACGTGTACAGCTCTAGTATCTAACCACAGTTTATCTCACAGACAGCCTGAGACAGTCCTTACAGAAACTCCCCAAGACACGATTGAATTAAACAGACTGAACTTAGAATCTTCCAA', 'Subject sequence');
ok(!$parser->next(), 'No more records');
#
#####################################################################################

#########################################################################################
# Test parsing tabular format with comment lines, ensembl web-specific format specifiers 
#
note("Test Ensembl Web format specifiers");
$outfmt = '7 qseqid qstart qend sseqid sstart send score evalue pident length qframe sframe';
$test_file = "$prefix/input/blast_test.7.web.tab";
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
ok($parser->next(), 'Loading first record');
is($parser->get_qseqid, 'gnl|MYDB|1', 'Query seq-id');
is($parser->get_qstart, 1, 'Query start');
is($parser->get_qend, 720, 'Query end');
is($parser->get_sseqid, 'gi|405832|gb|U00001.1|HSCDC27', 'Subject id');
is($parser->get_sstart, 1, 'Subject start');
is($parser->get_send, 720, 'Subject end');
ok($parser->get_score == 720, 'Score');
ok($parser->get_evalue == 0, 'E-value');
ok($parser->get_pident == 100, 'Percentage identity');
is($parser->get_length, 720, 'Alignment length');
is($parser->get_qframe, 1, 'Query frame');
ok($parser->get_sframe == 1, 'Subject frame');

note("Parse last record");
map { $parser->next() } (1 .. 250);
is($parser->get_qseqid, 'gnl|MYDB|1', 'Query seq-id');
is($parser->get_qstart, 83, 'Query start');
is($parser->get_qend, 720, 'Query end');
is($parser->get_sseqid, 'gi|564374743|ref|XM_006247536.1|', 'Subject id');
is($parser->get_sstart, 79, 'Subject start');
is($parser->get_send, 716, 'Subject end');
ok($parser->get_score == 500, 'Score');
ok($parser->get_evalue == 0, 'E-value');
ok($parser->get_pident == 92.79, 'Percentage identity');
is($parser->get_length, 638, 'Alignment length');
is($parser->get_qframe, 1, 'Query frame');
ok($parser->get_sframe == 1, 'Subject frame');
ok(!$parser->next(), 'No more records');
#
#########################################################################################

########################################################
# Test parsing comma-separated format, no comment lines
#
note("Test comma-separated format with default specifiers");
$outfmt = '10';
$test_file = "$prefix/input/blast_test.10.default.csv";
$parser = Bio::EnsEMBL::IO::Parser::BLASTFormatter->open($test_file, $outfmt);
ok($parser->next(), 'Loading first record');
is($parser->get_qseqid, 'gnl|MYDB|1', 'Query seq-id');
is($parser->get_sseqid, 'gi|405832|gb|U00001.1|HSCDC27', 'Subject seq-id');
ok($parser->get_pident == 100, 'Percentage identity');
ok($parser->get_length == 720, 'Alignment length');
ok($parser->get_mismatch == 0, 'Mismatch');
ok($parser->get_gapopen == 0, 'Gap open');
is($parser->get_qstart, 1, 'Query start');
is($parser->get_qend, 720, 'Query end');
is($parser->get_sstart, 1, 'Subject start');
is($parser->get_send, 720, 'Subject end');
ok($parser->get_evalue == 0, 'Alignment length');
is($parser->get_bitscore, 1330, 'Bit score');

note("Parse last record");
map { $parser->next() } (1 .. 250);
is($parser->get_qseqid, 'gnl|MYDB|1', 'Query seq-id');
is($parser->get_sseqid, 'gi|564374743|ref|XM_006247536.1|', 'Subject seq-id');
ok($parser->get_pident == 92.79, 'Percentage identity');
ok($parser->get_length == 638, 'Alignment length');
ok($parser->get_mismatch == 46, 'Mismatch');
ok($parser->get_gapopen == 0, 'Gap open');
is($parser->get_qstart, 83, 'Query start');
is($parser->get_qend, 720, 'Query end');
is($parser->get_sstart, 79, 'Subject start');
is($parser->get_send, 716, 'Subject end');
ok($parser->get_evalue == 0, 'Alignment length');
is($parser->get_bitscore, 924, 'Bit score');
ok(!$parser->next(), 'No more records');
#
########################################################

done_testing();
