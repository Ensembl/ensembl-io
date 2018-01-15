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
use Data::Dumper;

use Test::More;
use Test::Warn;

use Bio::EnsEMBL::IO::Parser::EMF;


########
# TESTS
########
## Resequencing
subtest 'EMF Resequencing format', sub {
	my $test_file = 'modules/t/input/Homo_sapiens.GRCh37.73.resequencing.chromosome.21.emf';
	my $parser = Bio::EnsEMBL::IO::Parser::EMF->open($test_file);
	isa_ok($parser, 'Bio::EnsEMBL::IO::Parser::EMF', "correct class");
	my $next_record = $parser->next;
	ok($next_record, "can next");
	is($parser->format, "resequencing", "correct format");
	warning_like {$parser->tree} qr/No TREE is allowed in 'resequencing' EMF format/, "No tree allowed";
	my $releases = $parser->releases;
	isa_ok($releases, 'ARRAY', "releases");
	is(scalar @$releases, 5, "number of releases");
	my $date = $parser->date;
	is($date, 'Thu Oct  4 19:08:14 2012', "date");

	my $sequences = $parser->get_sequences;
	is(scalar @$sequences, 15, "number of seqs");

	my $score_types = $parser->get_score_types;
	is(scalar @$score_types, 14, "number of scores"); 

	my $next_column = $parser->get_next_column();
	is(scalar @{$next_column->{'sequence'}}, scalar @$sequences, "correct number of nts in column");
	is(scalar @{$next_column->{'scores'}}, scalar @$score_types, "correct number of scores in column");
};

## Compara
subtest 'Compara format', sub {
	my $test_file = 'modules/t/input/Compara.13_eutherian_mammals_EPO.chr1_26.emf';
	my $parser = Bio::EnsEMBL::IO::Parser::EMF->open($test_file);	
	isa_ok($parser, 'Bio::EnsEMBL::IO::Parser::EMF', "correct class");
	my $next_record = $parser->next;
	ok($next_record, "can next");
	is($parser->format, "compara", "correct format");
	my $tree = $parser->tree;
	like($parser->tree, qr/Hsap_1_249138388_249212440/, "Tree looks good");

	my $releases = $parser->releases;
	isa_ok($releases, 'ARRAY', "releases");
	is(scalar @$releases, 1, "number of releases");
	my $date = $parser->date;
	is($date, 'Wed Dec 12 10:32:29 2012', "date");

	my $sequences = $parser->get_sequences;
	is(scalar @$sequences, 5, "number of seqs");

	my $score_types = $parser->get_score_types;
	isa_ok($score_types, "ARRAY", "score_types is an array");
	is(scalar @$score_types, 0, "score_types is empty");

	my $next_column = $parser->get_next_column();
	is(scalar @{$next_column->{'sequence'}}, scalar @$sequences, "correct number of nts in column");
	is(scalar @{$next_column->{'scores'}}, scalar @$score_types, "correct number of scores in column");
};
done_testing;

