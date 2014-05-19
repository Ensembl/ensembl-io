use strict;
use warnings;

use Test::More;

#use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::GFF3;

my $test_file = "data.gff3";

my $parser = Bio::EnsEMBL::IO::Parser::GFF3->open($test_file);
ok ($parser->next(), "Loading first record");
my @test_row = (qw(mmscl   supported_mRNA  CDS 40759   41225   .   +   .   Parent=mmscl));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
ok ($parser->next(), "Loading second record");
@test_row = (qw(mmscl   supported_mRNA  exon    61468   61729   .   +   .   Parent=mmMAP_17));
is_deeply($parser->{'record'},\@test_row,"Test basic parsing of a row");
ok ($parser->close(), "Closing file");

done_testing();
