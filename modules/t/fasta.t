use strict;
use warnings;

use Test::More;

#use Bio::EnsEMBL::Test::MultiTestDB;
use Bio::EnsEMBL::Utils::IO qw( work_with_file );
use Bio::EnsEMBL::IO::Parser::FastaParser;

my $test_file = "data.fasta";

work_with_file( $test_file, "r", sub {
    my $fh = shift;
    my $parser = Bio::EnsEMBL::IO::Parser::FastaParser->new($fh);
    
    # testing the default inherited reader
    my $record = $parser->read_record();    
    
    my $test_line = "";
    #is($record,$test_line,"Test single line read");
    note (scalar(@$record));
    ok(scalar(@$record) == 18,"Check size of first FASTA block");
    $record = $parser->read_record();
    ok(scalar(@$record) == 15,"Check size of second FASTA block");
    $record = $parser->read_record();
    
    ok(!defined($record), "Final attempt to read returns nothing.");
} );

work_with_file( $test_file, "r", sub {
    my $fh = shift;
    my $parser = Bio::EnsEMBL::IO::Parser::FastaParser->new($fh);
    my @meta_lines;
    
    $parser->set_metadata_function(sub {
        my $line = shift;
        $line =~ /^>(\w+)/;
        if ($1) {
            push @meta_lines,$1;
            return 1 if ($1);
        } else {
            return;
        }
        
    });
    ok(1,"Set new metadata function");
    
    my @buffer;
    $parser->set_data_function(sub {
        my $record_array = shift;
        foreach (@$record_array) {
            push @buffer,substr($_,0,1);   
        }
        return 1;
    } );
    ok (1,"Set data function");
    
    while ($parser->read_record()) {};
    note (scalar(@meta_lines)."  ".scalar(@buffer));
    ok(scalar(@meta_lines) == 2,"Check result of custom header code");
    ok(scalar(@buffer)== 31,"Check FASTA data size");
} );


done_testing;