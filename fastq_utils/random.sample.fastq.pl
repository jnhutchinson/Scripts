#!/usr/bin/perl

## print random lines of fastq data, 
#fastq=original fastq file
#denom=denominator of the fraction of reads you want to return from the original file
## i.e. ARGV[1]=4 will return a random sample of 1/4 of the reads

 
#use strict; 
use warnings;
use Getopt::Long;

GetOptions('denom=i' => \$frac,
          'fastq=s'  => \$input,
          'help!'     => \$help,) 
          or die "Incorrect usage!\n";

if( $help ) {
    print "--denom = fraction of reads to sample is 1/denom\n--fastq = original fastq file\n
    ";

} else {
    open (INPUT, $input) or die;
    my $num=int(rand($frac+1));

    while (<INPUT>) {
      if ($num <1 ){
        print $_;
        my $line1=<INPUT>;
        print $line1; 
        my $line2=<INPUT>;
        print $line2;
        my $line3=<INPUT>;
        print $line3;
        
      } else { 
        <INPUT>;
        <INPUT>;
        <INPUT>;
        }
      $num=int(rand($frac+1));
    }
   
  close INPUT;
}


