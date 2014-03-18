use strict;
use warnings;

use Test::More;

use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::VEP_output;

my $test_file = "modules/t/data.vepo";

my $parser = Bio::EnsEMBL::IO::Parser::VEP_output->open($test_file);
ok ($parser->next(), "Loading first record");
ok ($parser->get_uploaded_variation() eq '11_224088_C/A');
ok ($parser->get_seqname() eq '11');
ok ($parser->get_start() == 224088);
ok ($parser->get_end() == 224088);
ok ($parser->get_allele() eq 'A');
ok ($parser->get_gene() eq 'ENSG00000142082');
ok ($parser->get_feature() eq 'ENST00000525319');
ok ($parser->get_feature_type() eq 'Transcript');
ok ($parser->get_consequence() eq 'missense_variant');
ok ($parser->get_cdna_position() == 742);
ok ($parser->get_cds_position() == 716);
ok ($parser->get_protein_position() == 239);
ok ($parser->get_aa_change() eq 'T/N');
ok ($parser->get_codon_change() eq 'aCc/aAc');
ok ($parser->get_colocated() eq '-');
my $extra = $parser->get_extra;
ok ($extra->{'SIFT'} eq 'deleterious(0)');
ok ($parser->next(), "Loading second record");
ok ($parser->close(), "Closing file");

done_testing();
