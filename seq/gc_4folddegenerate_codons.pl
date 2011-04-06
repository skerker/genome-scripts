#!/usr/bin/perl -w
use strict;
use Getopt::Long;
use Bio::SeqIO;
use List::Util qw(sum);
use Bio::Tools::CodonTable;

my $pergene;

GetOptions('g|pergene!' => \$pergene);

my $infile = shift;

my $in = Bio::SeqIO->new(-format => 'fasta', -file => $infile);

my $codontable = Bio::Tools::CodonTable->new();
my %aa;

my @bases = qw(A C G T);
for my $firstbase ( @bases ) {
  for my $secondbase ( @bases ) {
    for my $thirdbase ( @bases ) {
      my $codon = $firstbase . $secondbase . $thirdbase;
      push @{$aa{$codontable->translate($codon)}}, $codon;
    }
  }
}
my %degenerate;
while ( my ($aa,$codons) = each %aa ) {
  if ( @$codons >= 4 ) { # 4fold or 6fold degenerate
    for my $codon ( @$codons)  {
      $degenerate{$codon}++;
    }
  }
}
my %gc;
while (my $seq = $in->next_seq ) {
  my $str = $seq->seq;
  if ( ($seq->length % 3) != 0 ) {
    warn($seq->id, " coding sqeuence is not multiple of 3 ", $seq->length, "\n");
    next;
  } else {
#    warn($seq->id, " ok\n");
  }
  my %gene_count;
  while ( $str )  {
   my $codon = substr($str,0,3,'');
   if ( $degenerate{$codon} ) {
     my $synon = uc substr($codon,2,1);
#     warn("$synon for $codon\n");
     $gc{$synon}++;
     $gene_count{$synon}++;
   }
 }
  next if ! keys %gene_count;
  if ( $pergene ) {
    printf "%s\t%.3f\n",$seq->id, 
      ( $gene_count{'G'} || 0 + $gene_count{'C'} || 0 ) / 
	sum(map { $gene_count{$_} || 0} @bases);
  }
}

my $gc = $gc{'G'} || 0  + $gc{'C'} || 0;
my $total = sum ( map { $gc{$_} } @bases);
printf "%.3f %% (%s=%d,%s=%d,%s=%d,%s=%d)\n", $gc / $total,
  map { $_,$gc{$_} } @bases;
