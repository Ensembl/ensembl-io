# Copyright [2020-2021] EMBL-European Bioinformatics Institute
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

use Test::More;
use Bio::EnsEMBL::IO::Parser::BCF;
use Cwd qw(getcwd);

use FindBin qw( $Bin );

my $test_file = $Bin . '/input/test.bcf';

# Test standard functions on a BCF file
ok (my $parser = Bio::EnsEMBL::IO::Parser::BCF->open($test_file), "BCF file open");
is ($parser->num_variants(), 9, 'correct number of variants identified in file');

#test open with $location
my $currentDir = getcwd();
chdir('/');
ok ($parser = Bio::EnsEMBL::IO::Parser::BCF->open($test_file, $currentDir), "BCF file open with location");
is ($parser->num_variants(), 9, 'correct number of variants identified in file');
chdir($currentDir);


ok (my $h = $parser->header(), "Got header");
my $header_str = <<HEADER;
##fileformat=VCFv4.0
##FILTER=<ID=PASS,Description="All filters passed">
##fileDate=20090805
##source=myImputationProgramV3.1
##reference=1000GenomesPilot-NCBI36
##phasing=partial
##INFO=<ID=NS,Number=1,Type=Integer,Description="Number of Samples With Data">
##INFO=<ID=AN,Number=1,Type=Integer,Description="Total number of alleles in called genotypes">
##INFO=<ID=AC,Number=.,Type=Integer,Description="Allele count in genotypes, for each ALT allele, in the same order as listed">
##INFO=<ID=DP,Number=1,Type=Integer,Description="Total Depth">
##INFO=<ID=AF,Number=.,Type=Float,Description="Allele Frequency">
##INFO=<ID=AA,Number=1,Type=String,Description="Ancestral Allele">
##INFO=<ID=TT,Number=0,Type=String,Description="Test">
##INFO=<ID=DB,Number=0,Type=Flag,Description="dbSNP membership, build 129">
##INFO=<ID=H2,Number=0,Type=Flag,Description="HapMap2 membership">
##FILTER=<ID=q10,Description="Quality below 10">
##FILTER=<ID=s50,Description="Less than 50% of samples have data">
##FILTER=<ID=MQ45,Description="MQ45 info">
##FILTER=<ID=DP50,Description="DP50 info">
##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">
##FORMAT=<ID=GQ,Number=1,Type=Integer,Description="Genotype Quality">
##FORMAT=<ID=DP,Number=1,Type=Integer,Description="Read Depth">
##FORMAT=<ID=HQ,Number=2,Type=Integer,Description="Haplotype Quality">
##ALT=<ID=DEL:ME:ALU,Description="Deletion of ALU element">
##ALT=<ID=CNV,Description="Copy number variable region">
##contig=<ID=19>
##contig=<ID=20>
##contig=<ID=X>
##bcftools_viewVersion=1.3.1+htslib-1.3.1
##bcftools_viewCommand=view -o test.bcf -O b test.vcf.gz
#CHROM	POS	ID	REF	ALT	QUAL	FILTER	INFO	FORMAT	NA00001	NA00002	NA00003
HEADER

is ($h->fmt_text, $header_str, "Header formatted string");
is ($h->version(), "VCFv4.0", "VCF Header version matches");
is ($h->num_samples(), 3, "Number of samples");
is_deeply ($h->get_sample_names(), ['NA00001','NA00002','NA00003'], "sample names correct");
is ($h->num_seqnames(), 3, "Number of seqnames");
is_deeply ($h->get_seqnames(), ['19','20','X'], "sequence names correct");
ok ($parser->next(), "Next row");
ok (my $row = $parser->read_record, "Get row");
is ($parser->get_seqname($h), "19", "Chromosome value read");
is ($parser->get_start(), "111", "Position value read");
my $ids = $parser->get_IDs();
is ($ids->[0], "testid", "ID value read");
is ($row->num_filters(), 2, "Num Filters OK");
is ($row->has_filter($h, "DP50"), 1, "Actual Filter present");
is ($row->has_filter($h, "."), 0, "PASS filter absent");
is ($row->get_variant_type(1), 1, "Variant type matches");

# info related tests
ok (my $info_result = $row->get_info($h), "Got info");
is_deeply ($info_result, {
  AF => [0.5],
  DB => [1],
  DP => [14],
  H2 => [1],
  NS => [3],
  TT => ['TESTSTRING']
}, 'info read correctly');
$info_result = $row->get_info($h, "DB") ;
isa_ok ($info_result, 'ARRAY');
is_deeply ($info_result, [1], 'info flag read correctly');
is ($row->get_info_type($h, "DB"), "Flag", "info flag type correct");
$info_result = $row->get_info($h, "AF");
isa_ok ($info_result, 'ARRAY');
is_deeply ($info_result, [0.5], 'info float read correctly');
is ($row->get_info_type($h, "AF"), "Float", "info float type correct");
$info_result = $row->get_info($h, "TT");
isa_ok ($info_result, 'ARRAY');
is_deeply ($info_result, ["TESTSTRING"], 'info string read correctly');
is ($row->get_info_type($h,"TT"), "String", "info String type correct");
$info_result = $row->get_info($h, "NS");
isa_ok ($info_result, 'ARRAY');
is_deeply ($info_result, [3], 'info ints read correctly');
is ($row->get_info_type($h, "NS"), "Integer", "info int type correct");

# format related tests
is_deeply ($row->get_format($h, "GT"), [2, 3, 2, 3, 2, 4], 'format int read');
is_deeply ($row->get_format($h, "HQ"), [10, 10, 10, 10, 3, 3], 'format int read');
is ($row->get_format($h, "INVALID"), "ID_NOT_FOUND", 'format ID not present');
is_deeply ($row->get_format($h), {
  GT => [2, 3, 2, 3, 2, 4],
  HQ => [10, 10, 10, 10, 3, 3]
}, "format read");
ok ($parser->next(), "Next row");
ok ($row = $parser->read_record, "Get row");
is ($parser->get_seqname($h), "19", "Chromosome value read");
is ($parser->get_start(), "112", "Position value read");
is ($parser->get_score(), "10", "Quality value read");
is ($row->reference(), "A", "Reference value read");
is ($row->num_alleles(), 1, "Num Alleles");
is ($row->is_snp(), 1, "Is SNP");
ok (my $a_team = $row->get_alleles(), "Get alleles");
isa_ok ($a_team, 'ARRAY');
is_deeply ($a_team, ['G'], 'alleles are correct');
is ($row->num_filters(), 1, "Num Filters OK");
is ($row->has_filter($h,"PASS"), 1, "PASS Filter present");
is ($row->has_filter($h,"DP50"), 0, "Actual Filter absent");
is ($row->has_filter($h,"sdkjsdf"), -1, "Made up filter not existing");
$info_result = $row->get_info($h);
is_deeply ($info_result, {}, 'info read correctly');

# format related tests
is_deeply ($row->get_format($h, "GT"), [2, 3, 2, 3, 2, 4], 'format int read');
is_deeply ($row->get_format($h, "HQ"), [10, 10, 10, 10, 3, 3], 'format int read');
is ($row->get_format($h, "INVALID"), "ID_NOT_FOUND", 'format ID not present');
is_deeply ($row->get_format($h), {
  GT => [2, 3, 2, 3, 2, 4],
  HQ => [10, 10, 10, 10, 3, 3]
}, "format read");

# format and genotype tests
ok ($parser->next(), "Next row");
ok ($row = $parser->read_record, "Get row");
is ($parser->get_seqname($h), "20", "Chromosome value read");
is ($row->get_format_type($h, "DP"), "Integer", "int format type correct");
is_deeply ($row->get_format($h, "GT"), [2,3,4,3,4,4], 'format int read');
is_deeply ($row->get_format($h, "GQ"), [48,48,43], 'format int read');
is_deeply ($row->get_format($h, "DP"), [1,8,5], 'format int read');
is_deeply ($row->get_format($h, "HQ"), [51,51,51,51,'-2147483648','-2147483648'], 'format int read');
is_deeply ($row->get_format($h), {
  GT => [2,3,4,3,4,4],
  GQ => [48,48,43],
  DP => [1,8,5],
  HQ => [51,51,51,51,'-2147483648','-2147483648']
}, "format read");

ok (my $fmt_result = $row->get_genotypes($h), "Get genotypes");
isa_ok ($fmt_result, 'ARRAY');
is_deeply ($fmt_result, [2,3,4,3,4,4], 'genotypes read correctly');
is ($row->get_format($h,"IDONTEXIST"), 'ID_NOT_FOUND', 'format id not found');
is ($row->get_info($h,"IDONTEXIST"), 'ID_NOT_FOUND', 'info id not found');
$info_result = $row->get_info($h);
is_deeply ($info_result, {
  NS => [3],
  DP => [14],
  AF => [0.5],
  DB => [1],
  H2 => [1]
}, 'info read correctly');

# Query tests
is ($parser->seek(0,0,0), 0, "Returns 0 on querying non existing region");
is ($parser->seek(20,1000000,1231000), 1, "Returns 1 on querying existing region");
ok ($row = $parser->read_record, "Get row");

# 20	1110696	rs6040355	A	G,T	67	PASS	NS=2;DP=10;AF=0.333,0.667;AA=T;DB	GT:GQ:DP:HQ	1|2:21:6:23,27	2|1:2:0:18,2	2/2:35:4:.,.
is ($parser->get_seqname($h), 20, 'chr');
is ($parser->get_start, 1110696, 'position');
$ids = $parser->get_IDs();
is ($ids->[0], 'rs6040355', 'id');
is ($row->reference, 'A', 'reference');
is_deeply ($row->get_info($h, 'NS'), [2], 'info');
is_deeply ($row->get_info($h, 'DP'), [10], 'info');
is_deeply ($row->get_info($h, 'AA'), ['T'], 'info');
is_deeply ($row->get_info($h, 'DB'), [1], 'info');

ok ($parser->next(), "Next row");
ok ($row = $parser->read_record, "Get row");
# 20	1230237	.	T	.	47	PASS	NS=3;DP=13;AA=T	GT:GQ:DP:HQ	0|0:54:.:56,60	0|0:48:4:51,51	0/0:61:2:.,.
is ($parser->get_seqname($h), 20, 'chr');
is ($parser->get_start, 1230237, 'position');
$ids = $parser->get_IDs();
is ($ids->[0], '.', 'id');
is ($row->reference, 'T', 'reference');
is_deeply ($row->get_info($h), {
  NS => [3],
  DP => [13],
  AA => ['T']
}, 'info');

ok ($parser->close(), "Close successful");

done_testing();
