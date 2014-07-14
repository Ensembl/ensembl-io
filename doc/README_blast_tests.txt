This is how the input files for the blast parser tests have been obtained:

1. Create single entry FASTA file called nt.00001 with this content:

>gnl|MYDB|1 this is sequence 1
GAATTCCCGCTACAGGGGGGGCCTGAGGCACTGCAGAAAGTGGGCCTGAGCCTCGAGGATGACGGTGCTGCAGGAACCCG
TCCAGGCTGCTATATGGCAAGCACTAAACCACTATGCTTACCGAGATGCGGTTTTCCTCGCAGAACGCCTTTATGCAGAA
GTACACTCAGAAGAAGCCTTGTTTTTACTGGCAACCTGTTATTACCGCTCAGGAAAGGCATATAAAGCATATAGACTCTT
GAAAGGACACAGTTGTACTACACCGCAATGCAAATACCTGCTTGCAAAATGTTGTGTTGATCTCAGCAAGCTTGCAGAAG
GGGAACAAATCTTATCTGGTGGAGTGTTTAATAAGCAGAAAAGCCATGATGATATTGTTACTGAGTTTGGTGATTCAGCT
TGCTTTACTCTTTCATTGTTGGGACATGTATATTGCAAGACAGATCGGCTTGCCAAAGGATCAGAATGTTACCAAAAGAG
CCTTAGTTTAAATCCTTTCCTCTGGTCTCCCTTTGAATCATTATGTGAAATAGGTGAAAAGCCAGATCCTGACCAAACAT
TTAAATTCACATCTTTACAGAACTTTAGCAACTGTCTGCCCAACTCTTGCACAACACAAGTACCTAATCATAGTTTATCT
CACAGACAGCCTGAGACAGTTCTTACGGAAACACCCCAGGACACAATTGAATTAAACAGATTGAATTTAGAATCTTCCAA

2. Use blastn remote service to search the query against the nt database and produce 
   a standard BLAST report:

$ blastn -db nt -query nt.00001 -out blast_test.out -remote

3. Find the RID of the previous search

$ grep RID blast_test.out
RID: VU5FZ4D2015

4. The RID is used with blast_formatter to print out the result in the formats
   the parser understand

  4.1 Tabular output with comment lines used by Compara, file: blast_test.7.compara.tab:
      $ blast_formatter -rid VU5FZ4D2015 -out blast_test.7.compara.tab -outfmt '7 qacc sacc evalue score nident pident qstart qend sstart send length positive ppos qseq sseq'

  4.2 Tabular output with comment lines and default format specifiers, file: blast_test.7.default.tab
      $ 

  4.3 Tabular output with default format specifiers, file: blast_test.6.default.tab
      $ blast_formatter -rid VU5FZ4D2015 -out blast_test.6.default.tab -outfmt 6

  4.3 CSV output with default format specifiers, file: blast_test.10.default.csv
      $ blast_formatter -rid VU5FZ4D2015 -out blast_test.10.default.csv -outfmt 10

