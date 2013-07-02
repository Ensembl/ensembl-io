use strict;
use warnings;

use Test::More;

#use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::GFF3Parser;

my $test_file = "data.gff3";

work_with_file( $test_file, "r", sub {
    my $fh = shift;
    my $parser = Bio::EnsEMBL::IO::Parser::GFF3Parser->new($fh);
    my @columns = $parser->read_record;    
    
    my @test_row = (qw(mmscl   supported_mRNA  CDS 40759   41225   .   +   .   Parent=mmscl));
    is_deeply(\@columns,\@test_row,"Test basic parsing of a row");
} );

work_with_file( $test_file, "r", sub {
    my $fh = shift;
    my $parser = Bio::EnsEMBL::IO::Parser::GFF3Parser->new($fh);
    my @columns;
    my $data_function = sub {
        my $line = shift;
        @columns = split('\t|\s\s+', $line);
        return;
    };
    $parser->set_data_function($data_function);
    $parser->read_record;
    
    my @test_row = (qw(mmscl   supported_mRNA  CDS 40759   41225   .   +   .   Parent=mmscl));
    is_deeply(\@columns,\@test_row,"Test custom data function on a row");
    
    $parser->read_record();
    @test_row = (qw(mmscl   supported_mRNA  exon    61468   61729   .   +   .   Parent=mmMAP_17));
    is_deeply(\@columns,\@test_row,"Test second record with custom data function");
});


done_testing;