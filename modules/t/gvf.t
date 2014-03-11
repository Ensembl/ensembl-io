use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::IO::Parser::GVFParser;

my $test_file = "modules/t/data.gvf";

my $parser = Bio::EnsEMBL::IO::Parser::GVFParser->open($test_file);

print "\n# First record:\n";
ok ($parser->next(), "Loading first record");
my @test_row = (qw(Y	dbSNP	SNV	10015	10015	.	+	.	ID=1;Variant_seq=C;Dbxref=dbSNP_137:rs113469508;evidence_values=Frequency;Reference_seq=A));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");

print "\n# Test the getters (only for the first row):\n";
ok($parser->getSeqName eq 'Y', 'getSeqName');
ok($parser->getStart == 10015, 'getStart');
ok($parser->getEnd == 10015, 'getEnd');
ok($parser->getStrand == 1, 'getStrand');
ok($parser->getSource eq 'dbSNP', 'getSource');
ok($parser->getType eq 'SNV', 'getType');
ok(!defined($parser->getScore), 'getScore');
ok(!defined($parser->getPhase), 'getPhase');
ok(join(',',sort(keys(%{$parser->getAttributes}))) eq 'Dbxref,ID,Reference_seq,Variant_seq,evidence_values', 'getAttributes');
ok($parser->getID eq '1', 'getID');
ok($parser->getVariantSeq eq 'C', 'getVariantSeq');
ok($parser->getReferenceSeq eq 'A', 'getReferenceSeq');

print "\n# Second record:\n";
ok ($parser->next(), "Loading second record");
@test_row = (qw(Y	dbSNP	insertion	10035	10036	.	+	.	ID=2;Variant_seq=CC;Dbxref=dbSNP_137:rs201278642;Reference_seq=-;global_minor_allele_frequency=0|0.0535714|117));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");

print "\n# Methods to retrieve metadata:\n";
ok($parser->getMetadataKeyList eq 'data-source, feature-ontology, file-date, file-version, genome-build, gff-version, gvf-version, sequence-region, species', 'getMetadataKeyList');
ok($parser->getGVFversion eq '1.06', 'getGVFversion');
ok($parser->getGenomeBuild eq 'ensembl GRCh37', 'getGenomeBuild');
ok($parser->getSequenceRegionList->[0] eq 'Y 1 59373566', 'getSequenceRegionList');
ok($parser->getMetadataByPragma('file-version') eq '73', 'getMetadataByPragma');

print "\n";

ok ($parser->close(), "Closing file");

done_testing();
