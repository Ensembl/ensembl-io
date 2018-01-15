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

use Test::More;

use Bio::EnsEMBL::IO::ListBasedParser;
use IO::Uncompress::Gunzip qw/$GunzipError/;

my $test_file = "modules/t/input/data.txt";

note 'Processing file '.$test_file;
test_parser($test_file);
{
  note 'Processing open filehandle to '.$test_file;
  # Now check working with an already open file handle
  open my $fh, '<', $test_file or fail "Cannot open $test_file: $!";
  test_parser($fh);
}
{
  note 'Processing slurped data';
  my $content;
  { #Need this otherwise the undef local of $/ perists into the parser
    open my $fh, '<', $test_file or fail "Cannot open $test_file: $!";
    local $/ = undef;
    $content = <$fh>;
    close $fh;
  }
  my $parser = Bio::EnsEMBL::IO::ListBasedParser->open_content($content);
  test_parser_content($parser);
}
{
  # Also check a gzipped version
  my $test_gz_file = $test_file.'.gz';
  note 'Processing open gzip filehandle to '.$test_gz_file;
  my $z = IO::Uncompress::Gunzip->new($test_file) or fail "Cannot open $test_gz_file: $GunzipError";
  test_parser($z);
}

sub test_parser {
  my ($file) = @_;
  my $parser = Bio::EnsEMBL::IO::ListBasedParser->open($file);
  test_parser_content($parser);
  return;
}

sub test_parser_content {
  my ($parser) = @_;
  ok($parser->next(), "Loading first record");
  is($parser->get_value(), 'ENSMUST00000062783', 'ID as expected');
  ok($parser->next(), "Loading second record");
  ok($parser->close(), "Closing file");
  return;
}

done_testing();
