# ensembl-io

![Build Status](https://travis-ci.org/Ensembl/ensembl-io.svg)

## File parsing and writing code for Ensembl

The ensembl-io repo is intended as a shared codebase for handling 
the parsing and writing of popular biological formats used by Ensembl, 
such as BED, BigWig and FASTA. For a full list of supported formats,
see the child objects in modules/Bio/EnsEMBL/IO/Parser/.

As the code matures, it is anticipated that various teams within the
Ensembl project will begin to integrate Bio::EnsEMBL::IO modules into
their pipelines; it will also be used in future releases of the Ensembl
website to handle parsing of uploaded data and output of exported data.

All parsers should have associated unit tests, which can also serve as
simple tutorials on how to use ensembl-io.
