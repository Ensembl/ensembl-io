=head1 LICENSE

See the NOTICE file distributed with this work for additional information
regarding copyright ownership.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <dev@ensembl.org>.

  Questions may also be sent to the Ensembl help desk at
  <helpdesk@ensembl.org>.

=cut

=head1 NAME

Bio::EnsEMBL::Utils::IO::FileFaidx

=head1 DESCRIPTION

This object provides an implementation of the .fai index lookup as defined by samtools. 
This format assumes that all lines in a FASTA file are the same length (bytes and bases) 
and this information is held in a file called .fai (held in the same directory
as the FASTA file). The format is tab delimited like so:

    RecordID    RecordLength(bp)   File offset (bytes)       bp per line      bytes per line

For example:

    MT    16571   6       50      51
    1    247249719       16915   50      51

The columns are sequence ID, sequence length, offset in file, bases per line 
and bytes per line. This module will read this format (if the file is available)
or will generate it from a FASTA file. It is recommnded that you pre-generate this
by using this module with the C<write_index_to_disk()> flag on or by using the
samtools faidx binary.

Please note that we do not handle RAZF compressed indexes or FASTA files.

We recommend you use this adaptor with the fully assembled chromsome files available from 
our FTP site (primary assembly).

=cut

package Bio::EnsEMBL::Utils::IO::FileFaidx;

use strict;
use warnings;

use Bio::EnsEMBL::Utils::Exception qw/throw warning/;
use Bio::EnsEMBL::Utils::IO qw/iterate_lines work_with_file slurp/;
use English qw/-no_match_vars/;
use IO::Uncompress::Gunzip qw($GunzipError);
require bytes;

=head2 new
  
  Arg [1]     : String; $file. Path to the FASTA file
  Arg [2]     : Boolean; $write_index_to_disk. Write the index to disk
  Arg [3]     : Boolean; $persist_fh. Persist the file handle between requests for sequence
  Arg [4]     : Boolean; $no_generation. Stop index generation and force the reading of an index from disk
  Arg [5]     : Boolean; $uppercase_sequence. Uppercase sequence returned from the code. Defaults to true
  Description : Builds an instance of the FaidxFasta object

=cut

sub new {
  my ($class, $fasta_file, $write_index_to_disk, $persist_fh, $no_generation, $uppercase_sequence) = @_;
  throw 'No file given; cannot continue without one' unless $fasta_file;
  $uppercase_sequence //= 1;
  my $self = bless({}, ref($class)||$class);
  $self->file($fasta_file);
  $self->check_if_compressed();
  $self->set_seek_read_handler();
  $self->write_index_to_disk($write_index_to_disk);
  $self->persist_fh($persist_fh);
  $self->no_generation($no_generation);
  $self->uppercase_sequence($uppercase_sequence);
  return $self;
}

=head2 check_if_compressed

  Description : Checks if the file name ends with '.gz',
                if so treats it as a  BGZIP compressed one
                and checks for FAI and GZI indeces presence
  Exception   : Thrown if the FAI or GZI index files cannot be found

=cut

sub check_if_compressed {
  my ($self) = @_;

  $self->{_is_compressed} = 0;

  my $file = $self->{file};
  return 0 if ($file !~ m/\.gz$/);

  my $index_suffix = $self->index_suffix();
  throw "No FAI index file found at '${file}.${index_suffix}'. Required for compressed FASTA." unless -f $self->index_path($file);

  my $gzi_index_suffix = $self->gzi_index_suffix();
  throw "No GZI index file found at '${file}.${gzi_index_suffix}'. Required for compressed FASTA." unless -f $self->gzi_index_path($file);

  $self->load_gzi_index($self->gzi_index_path($file));

  $self->{_is_compressed} = 1;
}

=head2 set_seek_read_handler

  Description : Pikcs the `_seek_read_handler` for raw or compressed fasta
                to be called from `_read_from_source`

=cut

sub set_seek_read_handler {
  my ($self) = @_;

  $self->{_seek_read_handler} = \&_seek_read;
  $self->{_seek_read_handler} = \&_seek_read_gz if ($self->{_is_compressed});
}

=head2 load_gzi_index

  Arg [1]     : String; $index_file. Path to the GZI index file
  Description : Checks if the file name ends with '.gz', if so treats it as a  BGZIP compressed one
                and checks for FAI and GZI indeces presence.
                See https://www.htslib.org/doc/bgzip.html#GZI_FORMAT for the binary index description
                At the momemt of writing that was
                    uint64_t number_entries (N.B. can be 0 !)
                followed by number_entries pairs of:
                    uint64_t compressed_offset
                    uint64_t uncompressed_offset
               N.B. Pair (0, 0) is ommitted
  Exception   : Thrown if the GZI index file cannot be found,
                or if the index file has format
=cut

sub load_gzi_index {
  my ($self, $index_file) = @_;

  $self->{_gzi_index_raw} = $self->empty_gzi_index();

  work_with_file($index_file, '<:raw', sub {
    my ($fh) = @_;

    my $bytes;
    my $bytes_in = read($fh, $bytes, 8);
    throw("Cannot get number of entries from index file ${index_file}") if $bytes_in != 8;

    my ($entries) = unpack('Q', $bytes);

    # initialise the first block, not included in GZI
    $self->put_gzi_index_block($self->{_gzi_index_raw}, 0, 0);

    for (my $i = 1; $i < $entries+1; $i++) {
      $bytes_in = read $fh, $bytes, 16;
      throw("Cannot get pair $i") if $bytes_in != 16;
      my ($compressed_offset, $uncompressed_offset) = unpack('QQ', $bytes);
      $self->update_gzi_index_prev_follower($self->{_gzi_index_raw}, $uncompressed_offset);
      $self->put_gzi_index_block($self->{_gzi_index_raw}, $uncompressed_offset, $compressed_offset, 0);
    }
    $self->{_gzi_index_raw}->{blocks} = [ sort { $a->{uncompressed_offset} <=> $b->{uncompressed_offset} } @{ $self->{_gzi_index_raw}->{blocks} } ];
    $self->update_gzi_index_meta($self->{_gzi_index_raw});

    my $index_size = $self->{_gzi_index_raw}->{size};
    my $uncompressed_block_size = $self->{_gzi_index_raw}->{uncompressed_block_size};
    warning("index file has $entries entries, index size $index_size, estimated uncompressed block size: $uncompressed_block_size");

    return;
  });
}

=head2 empty_gzi_index

  Description : Returns empty structure to store GZI index metada and blocks
  Returntype  : Hash with the GZI index struct:
                `blocks` -- reference to an empty list to store GZI index bblocks to
                `uncompressed_offset_start` -- ucompressed offset of the first block
                `uncompressed_block_size` -- estimated size of the uncompressed block to speed up hopping
                `size` --  number of `blocks`
                `name` --  name/tag of the structure
=cut

sub empty_gzi_index {
  my ($self) = @_;
  # prepare gzi_index_structure
  return {
    blocks => [],
    uncompressed_offset_start => 0,
    uncompressed_block_size => 0,
    size   => 0,
    name   => "",
  };
}

=head2 put_gzi_index_block

  Arg [1]     : Hash ref; $index. Reference to the GZI index structure being filled
  Arg [2]     : Integer; $uncompressed_offset. Block's `uncompressed_offset`
  Arg [3]     : Integer; $compressed_offset. Block's `compressed_offset`
  Arg [4]     : Integer; $uncompressed_offset_next, default 0. `uncompressed_offset` of the following block, 0 -- for the last block
  Description : Push a block with the specified values to the `$index->{blocks}` list

=cut

sub put_gzi_index_block {
  my ($self, $index, $uncompressed_offset, $compressed_offset, $uncompressed_offset_next) = @_;
  $uncompressed_offset_next //= 0;

  push @{$index->{blocks}}, {
    uncompressed_offset => $uncompressed_offset,
    compressed_offset => $compressed_offset,
    uncompressed_offset_next => $uncompressed_offset_next,
  };
}

=head2 update_gzi_index_prev_follower

  Arg [1]     : Hash ref; $index. Reference to the GZI index structure being filled
  Arg [2]     : Integer; $uncompressed_offset_next. Value for `uncompressed_offset_next` of the last block an a list.
  Description : Update `uncompressed_offset_next` of the last block an a list.

=cut

sub update_gzi_index_prev_follower {
  my ($self, $index, $uncompressed_offset_next) = @_;

  if (scalar(@{$index->{blocks}}) > 0) {
    $index->{blocks}->[-1]->{uncompressed_offset_next} = $uncompressed_offset_next
  }
}

=head2 update_gzi_index_meta

  Arg [1]     : Hash ref; $index. Reference to the GZI index structure being filled
  Arg [2]     : String; $name, defaults to "_raw_index". Index name/tag.
  Description : Update GZI index metadata such as `size`, `uncompressed_offset_start`, `uncompressed_block_size`.

=cut

sub update_gzi_index_meta {
  my ($self, $index, $name) = @_;
  $index->{size} = scalar(@{$index->{blocks}});
  if ($index->{size} > 0) {
    $index->{uncompressed_offset_start} = $index->{blocks}->[0]->{uncompressed_offset};
    $index->{uncompressed_block_size} = $self->estimate_gzi_index_block_size($index);
    $index->{name} = $name // "_raw_index";
  }
}

=head2 estimate_gzi_index_block_size

  Description : Estimates the diference between adjacent GZI index blocks in the uncompressed stream
  Returntype  : Integer; the estimated block size.
                Returns 0 if there's only one on no blocks on the list.

=cut

sub estimate_gzi_index_block_size {
  my ($self, $index) = @_;

  return 0 if ($index->{size} < 2);

  my $block_size = 0;
  for (my $i = 0; $i < $index->{size} - 1; $i++) {
    my $block = $index->{blocks}->[$i];
    $block_size += ($block->{uncompressed_offset_next} - $block->{uncompressed_offset});
  }

  return int($block_size / ($index->{size} - 1));
}

=head2 update_gzi_index_meta

  Arg [1]     : String; `id` of the sequence to get the GZI index descriptor for.
  Description : Returns GZI index descriptor from `$seld->{lookup_gzi}` hash for existing `id`, undef otherwise.

=cut

sub get_gzi_index {
  my ($self, $id) = @_;

  return undef if (!exists $self->{lookup_gzi}->{$id});
  return $self->{lookup_gzi}->{$id};
}

=head2 can_access_id

  Description : Checks the lookup to see if we have access to the id

=cut

sub can_access_id {
  my ($self, $id) = @_;
  return exists $self->lookup()->{$id} ? 1 : 0;
}

=head2 file
  
  Arg [1]     : String; $file. Path to the FASTA file
  Description : Location of the FASTA file
  Exception   : Thrown if the file cannot be found

=cut

sub file {
  my ($self, $file) = @_;
  if(defined $file) {
    throw "No file found at '${file}'" unless -f $file;
    $self->{'file'} = $file;
  }
  return $self->{'file'};
}

=head2 write_index_to_disk
  
  Arg [1]     : Boolean; $write_index_to_disk. Controls if we write the index back to disk
  Description : Controls if we can write back to disk. Only run to generate the indexes. Resets to 0 for the compressed files

=cut

sub write_index_to_disk {
  my ($self, $write_index_to_disk) = @_;
  $self->{'write_index_to_disk'} = $write_index_to_disk if defined $write_index_to_disk;
  if ($self->{_is_compressed}) {
    warning("Reverting 'write_index_to_disk' to 0 for compressed files") if ($self->{write_index_to_disk});
    $self->{write_index_to_disk} = 0;
  }
  $self->{'write_index_to_disk'} = 0 if ($self->{_is_compressed});
  return $self->{'write_index_to_disk'};
}

=head2 persist_fh
  
  Arg [1]     : Boolean; $persist_fh
  Description : Controls if we leave a file handle open between sequence reads

=cut

sub persist_fh {
  my ($self, $persist_fh) = @_;
  $self->{'persist_fh'} = $persist_fh if defined $persist_fh;
  return $self->{'persist_fh'};
}

=head2 no_generation
  
  Arg [1]     : Boolean; $no_generation
  Description : Controls if we will attempt an index generation if a .fai file is missing. Resets to 1 for the compressed files

=cut

sub no_generation {
  my ($self, $no_generation) = @_;
  $self->{'no_generation'} = $no_generation if defined $no_generation;
  if ($self->{_is_compressed}) {
    warning("Reverting 'no_generation' to 1 for compressed files") if (!$self->{no_generation});
    $self->{no_generation} = 1;
  }
  return $self->{'no_generation'};
}

=head2 uppercase_sequence
  
  Arg [1]     : Boolean; $uppercase_sequence
  Description : Controls if always uppercase sequence or not. Defaults to true

=cut

sub uppercase_sequence {
  my ($self, $uppercase_sequence) = @_;
  $self->{'uppercase_sequence'} = $uppercase_sequence if defined $uppercase_sequence;
  return $self->{'uppercase_sequence'};
}

=head2 index_suffix

  Description : Returns the index suffix normally used (fai)
  Returntype  : String of the index suffix

=cut

sub index_suffix {
  my ($class) = @_;
  return 'fai';
}

=head2 index_path

  Arg [1]     : String; $path. Path of the current index
  Description : Returns the index path (normally the given path plus an .fai extension)
  Returntype  : Path to the index file

=cut

sub index_path {
  my ($class, $path) = @_;
  my $suffix = $class->index_suffix();
  return "${path}.${suffix}";
}

=head2 gzi_index_suffix

  Description : Returns the GZI index suffix normally used (gzi)
  Returntype  : String of the GZI index suffix

=cut

sub gzi_index_suffix {
  my ($class) = @_;
  return 'gzi';
}

=head2 gzi_index_path

  Arg [1]     : String; $path. Path of the current gzi_index
  Description : Returns the GZI index path (normally the given path plus an .gzi extension)
  Returntype  : Path to the GZI index file

=cut

sub gzi_index_path {
  my ($class, $path) = @_;
  my $suffix = $class->gzi_index_suffix();
  return "${path}.${suffix}";
}

=head2 lookup
  
  Description : Attempts to load the index from disk or create 
                it from the FASTA file in question. Once loaded it is 
                cached locally. The lookup will be written to disk
                if the write_index_to_disk attribute is true.
  Returntype  : HashRef of FASTA ID to ArrayRef of attributes
                [size, file start position, bases per line, bytes per line]
  Exception   : Thrown if we could not generate a lookup from the FASTA file or
                .fai index
=cut

sub lookup {
  my ($self) = @_;
  return $self->{lookup} if exists $self->{lookup};
  my $faindex_lookup = $self->load_from_faindex();
  if(! %{$faindex_lookup}) {
    if(!$self->no_generation()) {
      $faindex_lookup = $self->load_faindex_from_fasta();
    }
    if(! %{$faindex_lookup}) {
      throw "Cannot generate a lookup from a .fai file or from the fasta file ".$self->file();
    }
    $self->{lookup} = $faindex_lookup;
    if($self->write_index_to_disk()) {
      $self->write_faindex();
    }
  }
  else {
    $self->{lookup} = $faindex_lookup;
  }
  return $self->{lookup};
}

=head2 load_from_faindex

  Description : Loads the lookup index from a .fai file. This must be in the same location
                as the fasta file with a .fai extension. Please see samtools for more format
                information or the module description.

=cut

sub load_from_faindex {
  my ($self) = @_;
  my $index = $self->index_path($self->file());
  return {} if ! -f $index;
  my $contents = slurp($index);
  open my $fh, '<', \$contents or throw "Cannot open contents as an in-memory file: $!";
  my $lookup = $self->_load_faindex_from_fh($fh);
  close $fh;

  $self->fill_lookup_gzi($lookup);

  return $lookup;
}

=head2 _load_faindex_from_fh

  Description : Loads the .fai index from a given file handle

=cut

sub _load_faindex_from_fh {
  my ($self, $fh) = @_;
  throw "No file handle given" unless $fh;
  my %lookup;
  iterate_lines($fh, sub {
    my ($line) = @_;
    chomp $line;
    my ($id,$size,$location,$bases_per_line,$bytes_per_line) = $line =~ /^(.+) \s+ (\d+) \s+ (\d+) \s+ (\d+) \s+ (\d+) $/xms;
    # force numerification. Remember these values are from a text file
    $lookup{$id} = [$size+0, $location+0, $bases_per_line+0, $bytes_per_line+0, $id];
  });
  return \%lookup;
}

=head2 fill_lookup_gzi

  Description : Loads the .fai index from a given file handle,
                updates `$self->{lookup_gzi}` map.

=cut

sub fill_lookup_gzi {
  my ($self, $lookup) = @_;

  return if (!$self->{_is_compressed});

  $self->{lookup_gzi} = {};

  my $gzi_raw = $self->{_gzi_index_raw};
  my $gzi_size = $gzi_raw->{size};

  my $seq_starts = [ map { { id => $_, start => $lookup->{$_}->[1] } } keys %$lookup ];
  $seq_starts = [ sort { $a->{start} <=> $b->{start} } @$seq_starts ];

  my $gzi_i = 0;
  my $i;
  # preprocess all blocks but last
  for ($i = 0; $i < scalar(@$seq_starts) - 1; $i++) {
    my $id = $seq_starts->[$i]->{id};
    my $seq_start = $seq_starts->[$i]->{start};
    my $seq_end = $seq_starts->[$i+1]->{start};

    # initialize index struct
    $self->{lookup_gzi}->{$id} = $self->empty_gzi_index();
    my $blocks = $self->{lookup_gzi}->{$id}->{blocks};

    # there could be several seq_regions in one block
    # assume uncompressed_offset_next == 0 only for the last block
    while ($gzi_i < $gzi_size) {
      my $block = $gzi_raw->{blocks}->[$gzi_i];
      my $gzi_start = $block->{uncompressed_offset};
      my $gzi_end = $block->{uncompressed_offset_next};

      # if not the last gzi block
      if ($gzi_end) {
        # [ ]  )( -- in the middle
        if ($gzi_end <= $seq_end ) {
          push @$blocks, $block;
          $gzi_i++;
          next;
        }
        # $gzi_end > $seq_end
        # [  )(  ] -- next sequnce start within the block
        if ($gzi_start < $seq_end) {
          push @$blocks, $block;
          # switch to next sequence
          last;
        }
        #   )([  ] -- start of the next block
        if ($gzi_start >= $seq_end) {
          # switch to next sequence
          last;
        }
      } else {
        # dealing with the last index block
          push @$blocks, $block;
          # switch to next sequence
          last;
      }
    }
    $self->update_gzi_index_meta( $self->{lookup_gzi}->{$id}, $id);
  }

  # keep the rest for the remaining sequence
  {
    my $id = $seq_starts->[$i]->{id};
    $self->{lookup_gzi}->{$id} = $self->empty_gzi_index();
    my $blocks = $self->{lookup_gzi}->{$id}->{blocks};
    for (; $gzi_i < $gzi_size; $gzi_i++) {
      my $block = $gzi_raw->{blocks}->[$gzi_i];
      push @$blocks, $block;
    }
    $self->update_gzi_index_meta($self->{lookup_gzi}->{$id}, $id);
  }
}

=head2 load_faindex_from_fasta

  Description : Iterates the given FASTA file looking for occurances of
                fasta record headers. We then record the start of DNA
                as a file offset, the size of the sequence, the number of
                bases per line and the number of bytes per line. This is
                identical to samtool's faidx command. Please note that
                samtools will do this a lot faster than this implementation
                as that's C and this is not.

=cut

sub load_faindex_from_fasta {
  my ($self) = @_;
  my %lookup;
  my $fasta_file = $self->file();
  my $current_values;
  work_with_file($fasta_file, 'r', sub {
    my ($fh) = @_;
    my ($line_number, $offset, $blank_line, $mismatched_lengths) = (0,0,0,0);
    while(my $line = <$fh>) {
      $line_number++;
      my $length = bytes::length($line);

      # Check for a header
      if($line =~ /^>(.+?)\s+/) {
        my $id = $1;
        # Reset the blank line and mismatched booleans since we're starting a new record
        ($blank_line, $mismatched_lengths) = (0,0);
        # Create a new current values array & add it to the hash
        # values are [sequence length, offset, bases per line, bytes per line, fasta id]
        $current_values = [0,-1,-1,-1,$id];
        $lookup{$id} = $current_values;
      }
      #Check for a blank line
      elsif(! $current_values && $line =~ /^\s+$/) {
        # Blank!
        warning "Found whitespace at line $line_number. Consider trimming";
      }
      #If not either we must be in sequence
      else {
        
        # If current record offset is set to -1 then we must set it to the current offset
        if ($current_values->[1] == -1) {
          $current_values->[1] = $offset;
        }
        
        # Minus whitespace gives us bp length
        my $bp_length = ($length-1);
        $current_values->[0] += $bp_length;
        
        # Already seen a line in the record
        if($current_values->[2] > -1) {
          # Check if we've seen a problem. Only way out of this is to continue
          # seeing blank lines until we hit another record. If not instant fail
          if($blank_line || $mismatched_lengths) {
            if($bp_length == 0) {
              # set the line number of blank line for later error reporting
              $blank_line = $line_number;
            }
            else {
              my $id = $current_values->[4];
              if($blank_line) {
                throw "FASTA record $id is misformatted. Line $blank_line is blank and embedded within a record. Please fix before rerunning this command";
              }
              my $recorded_length = $current_values->[2];
              throw "FASTA record $id is misformatted. Line $mismatched_lengths is different to the detected record length $recorded_length. Please fix before rerunning";
            }
          }
          
          # Mismatched length detection
          if($current_values->[2] != $bp_length) {
            $mismatched_lengths = $line_number;
            if($bp_length == 0) {
              $blank_line = $line_number;
            }
          }
        }
        # First line in the FASTA record
        else {
          $current_values->[2] = $bp_length; #bases per line
          $current_values->[3] = $length; #bytes per line
        }
      }
      $offset += $length;
    }
  });
  return \%lookup;
}

=head2 write_faindex

  Description : Writes the .fai index out to disk. Each line is a tab separated record recording 
                the id, size, location (file offset), bases per line and bytes per line of each
                FASTA record. This is compatible with samtools faidx. Values are stored according
                to their position in the file.

=cut

sub write_faindex {
  my ($self) = @_;
  my $lookup = $self->lookup();
  my $fasta_file = $self->file();
  my $index = $fasta_file.'.'.$self->index_suffix();
  work_with_file($index, 'w', sub {
    my ($fh) = @_;
    my @entries = sort { $a->[1] <=> $b->[1] } values %{$lookup};
    foreach my $entry (@entries) {
      my ($size, $location, $bases_per_line, $bytes_per_line, $id) = @{$entry};
      print $fh sprintf("%s\t%d\t%d\t%d\t%d\n", $id, $size, $location, $bases_per_line, $bytes_per_line);
    }
    return;
  });
  return;
}

=head2 fetch_seq

  Arg [1]     : String; $id. Identifier of the sequence in the FASTA file
  Arg [2]     : Integer; $q_start. The start of the region to find
  Arg [3]     : Integer; $q_length. The length of the region to fetch
  Description : The guts. We convert the requested start and length for an ID into
                a file position start and end. We seek to the start and read the
                requested sequence as a single operation. Line terminators are then
                substituted out and a Scalar reference handed back (de-reference to
                get to the DNA).
                
                All sequence is uppercased before returning.

=cut

sub fetch_seq {
  my ($self, $id, $q_start, $q_length) = @_;

  my $lookup = $self->lookup();
  my $info = $lookup->{$id};
  if(! $info) {
    throw "Cannot convert the $id into a valid lookup. Abort!";
  }
  my ($size, $location, $bases_per_line, $bytes_per_line) = @{$info};

  my $q_end = ($q_start + $q_length) - 1;
  # We can never request a region larger than the sequence length
  if($q_end > $size) {
    $q_end = $size;
  }
  
  my $file = $self->file();

  my $line_start = int(($q_start - 1) / $bases_per_line);
  my $line_start_position = ($q_start-1) % $bases_per_line;

  my $line_end = int(($q_end - 1) / $bases_per_line);
  my $line_end_position = ($q_end-1) % $bases_per_line;
  
  my $offset = $location + ($line_start * $bytes_per_line) + $line_start_position;
  my $end = $location + ($line_end * $bytes_per_line) + $line_end_position;
  my $length = ($end - $offset)+1;

  # get list of blocks for the given $id
  my $gzi_index = $self->get_gzi_index($id) if ($self->{_is_compressed});

  #Get sequence. ATMO this is a FH but why not a HTTP server in the future?
  my $seq_ref = $self->_read_from_source($file, $offset, $length, $gzi_index);
  #Cleanup
  chomp ${$seq_ref};
  ${$seq_ref} =~ s/$INPUT_RECORD_SEPARATOR//g;
  ${$seq_ref} = uc(${$seq_ref}) if $self->uppercase_sequence();
  return $seq_ref;
}

# Open file, seek, read length and close filehandle.
# Override to read from alternative sources of FASTA formatted data
# indexed using FAIDX from sources like HTTP
sub _read_from_source {
  my ($self, $location, $offset, $length, $gzi_index) = @_;
  my $persist_fh = $self->persist_fh();
  my $fh;
  if($persist_fh && exists $self->{fh}) {
    $fh = $self->{fh};
  }
  else {
    open $fh, '<', $location or throw "Cannot open $location for reading: $!";
    $self->{fh} = $fh if $persist_fh;
  }
  
  my $seq;
  $self->{_seek_read_handler}->($self, $fh, \$seq, $offset, $length, $gzi_index);
  close $fh if ! $persist_fh;
  
  return \$seq;
}

=head2 _seek_read

  Arg [1]     : File handle; $fh. File handle of the raw or bgzip compressed fasta file
  Arg [2]     : Reference; $buf. Buffer to store the sequence to
  Arg [3]     : Integer; $offset. The original (uncompressed) offset of the sequence
  Arg [4]     : Integer; $length. The length of the sequence to retrieve
  Arg [5]     : Dict ref; $gzi_index. Gzi index descriptor
  Description : Seek to the exact offset in the  the uncompressed string and read data
                into the bufer $buf. If working with compressed data fall through into
                the _seek_read_gz sub.

=cut

sub _seek_read {
  my ($self, $fh, $buf, $offset, $length, $gzi_index) = @_;

  seek($fh, $offset, 0);
  read($fh, $$buf, $length);
}

=head2 _seek_read_gz

  Arg [1]     : File handle; $fh. File handle of the bgzip compressed fasta file
  Arg [2]     : Reference; $buf. Buffer to store the sequence to
  Arg [3]     : Integer; $offset. The original (uncompressed) offset of the sequence
  Arg [4]     : Integer; $length. The length of the sequence to retrieve
  Arg [5]     : Dict ref; $gzi_index. Gzi index descriptor
  Description : For the given uncompressed offset find the corresponding block offset
                in the compressed file. Read from the begining of the block until the
                end of the fragment of interest, Splice away the leading prefix up to
                the given uncompressed offset

=cut

sub _seek_read_gz {
  my ($self, $fh, $buf, $offset, $length, $gzi_index) = @_;

  my ($gz_block_start, $uncompressed_offset) = $self->_compressed_block_offset($gzi_index, $offset);

  # we loose quite some time on IO::Uncompress::Gunzip construction / destruction
  # unfortunatly, it's not possible to change the offfset (backwards), once IO::Uncompress::Gunzip is initialise
  # so we have to seek first and then recreate deflater for each compressed read
  seek($fh, $gz_block_start, 0);

  my $gz = IO::Uncompress::Gunzip->new($fh, -AutoClose => 0, -MultiStream => 1);
  my $bytes_read = $gz->read($$buf, $length + $uncompressed_offset);
  if ( $bytes_read != ($length + $uncompressed_offset) ) {
      my $file = $self->{file};
      throw "failed to read $length + $uncompressed_offset bytes from $file at $gz_block_start (uncompressed: $offset)";
  }
  $gz->close(); # no $fh closed, as '-AutoClose => 0'

  $$buf = substr($$buf, -$length) if $uncompressed_offset;
}


=head2 _compressed_block_offset

  Arg [1]     : Dict ref; $gzi_index. Gzi index descriptor
  Arg [2]     : Integer; $offset. Original offset in the uncompressed file
  Description : For the given uncompressed offset find the corresponding block offset
                in the compressed file. First estimate by dividing by _uncompressed_block_size.
                Then try to fix by looking at the adjacent blocks.
                Then give up and do the proper binary search.
  Returntype  : (Integer, Integer): (Offset of the block in the compressed file, length of the prefix to skip).

=cut

sub _compressed_block_offset {
  my ($self, $index, $offset) = @_;

  my $index_size = $index->{size};
  my $index_blocks = $index->{blocks};

  my $i = 0;
  if ($index_size > 1) {
    # initial estimate, assuming $offset >= $index->{uncompressed_offset_start}
    $i = int( ($offset - $index->{uncompressed_offset_start}) / $index->{uncompressed_block_size} );
    $i = 0 if ($i < 0);
    $i = ($index_size - 1) if ($i > $index_size - 1);
    my $dir = $self->_offset_is_not_in_block($offset, $index_blocks->[$i]);
    if ($dir) {
      # check if we have offset outside of the index boundaries
      if ( ($dir < 0 && $i == 0) || ($dir > 0 && $i == $index_size-1) ) {
        my $index_name = $index->{name};
        my $block = $index_blocks->[$i];
        my $bl_start = $block->{uncompressed_offset};
        my $bl_end = $block->{uncompressed_offset_next}; # can be 0 for the last block
        throw "wrong direction $dir for offset $offset not in block $i [$bl_start:$bl_end), index $index_name has $index_size block(s) in total\n";
      }

      # +/- 1 for a start if we missed a bit
      $i += $dir;

      # proper binary search
      my ($start, $end) = (0, $index_size-1);
      # warn "before iter offset $offset i $i start $start end $end dir $dir\n";
      while (($dir = $self->_offset_is_not_in_block($offset, $index_blocks->[$i])) && $start != $end) {
        # warn "offset $offset i $i start $start end $end dir $dir\n";
        ($start, $end) = $dir > 0 ? ($i+1, $end) : ($start, $i-1);
        $start = $end if $start > $end;
        $end = $start if $end < $start;
        $i = int(($start + $end) / 2);
      }
      # check if missed something
      if($start == $end && $dir != 0) {
        throw "failed to locate offset $offset in block $i start $start end $end dir $dir\n";
      }
    }
  }

  my $block = $index_blocks->[$i];
  my $compressed_offset = $block->{compressed_offset};
  my $uncompressed_offset = $block->{uncompressed_offset};

  return ($compressed_offset, $offset - $uncompressed_offset);
}

=head2 _offset_is_not_in_block

  Arg [1]     : Integer; $offset. Original offset in the uncompressed file
  Arg [2]     : Reference; $block. Block to check.
  Description : Check if the offset is not within the block entry at index $i.
  Returntype  : Iinteger, (-1, 0 ,1)
                If the $offset is in the block, return 0.
                If the $offset is less then the block uncompressed offset return -1.
                Otherwise return 1.

=cut

sub _offset_is_not_in_block {
  my ($self, $offset, $block) = @_;
  my $start = $block->{uncompressed_offset};
  my $end = $block->{uncompressed_offset_next};

  # warn "offset $offset in block $i [$start, $end)\n";

  return -1 if ($offset < $start);
  return 1 if ($end && $offset >= $end);
  return 0;
}

sub DESTROY {
  my ($self) = @_;
  close $self->{fh} if $self->{fh};
}

1;
