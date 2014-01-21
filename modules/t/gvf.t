use strict;
use warnings;

use Test::More;
use Bio::EnsEMBL::IO::Parser::GVFParser;

my $test_file = "data.gvf";

my $parser = Bio::EnsEMBL::IO::Parser::GVFParser->open($test_file);
ok ($parser->next(), "Loading first record");
my @test_row = (qw(Y	dbSNP	SNV	10015	10015	.	+	.	ID=1;Variant_seq=C;Dbxref=dbSNP_137:rs113469508;evidence_values=Frequency;Reference_seq=A));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
ok ($parser->next(), "Loading second record");
@test_row = (qw(Y	dbSNP	insertion	10035	10036	.	+	.	ID=2;Variant_seq=CC;Dbxref=dbSNP_137:rs201278642;Reference_seq=-;global_minor_allele_frequency=0|0.0535714|117));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
ok ($parser->close(), "Closing file");

done_testing();
