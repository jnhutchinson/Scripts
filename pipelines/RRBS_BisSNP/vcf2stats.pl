
## adapted from Yaping Liu's vcf2bed.pl script
## transfer TCGA VCF 4.1 to file in bed 6+6 format(TCGA level II data): chr + start + end  + C reads + T reads + C/T reads + number methylation_value(100%)+ strand
## numC+numT==0 sites are not included. 
## author: Yaping Liu  lyping1986@gmail.com


my $input_file_name = $ARGV[0];
my $type = $ARGV[1];

my $use_age = "USAGE: perl vcf2bed6plus6.pl input_file_name [CG]";
if($ARGV[0] eq ""){
	print "$use_age\n";
	exit(1);
}
my $cpg_name_output = $input_file_name;
$cpg_name_output =~ s/\.vcf//;
$cpg_name_output = $cpg_name_output."$type.stats.tab";
open(OUT,">$cpg_name_output") or die;
my $descript;
if($type eq "CG"){
	$type = "CG"; 
	$descript = "CG"; ##only output homozygous CpG
}
else{
	if($type eq ""){
		$descript = "Cytosine";
		$type = "\\w+"; ##by default, output all sites in VCF file
	}
	else{
		$descript = $type;
	}
	
}

my $head_line = "chr\tstart\tend\tnum_reads\tnum_C\tnum_T\tperc_meth\tstrand";
print OUT "$head_line\n";

open(FH,"<$input_file_name") or die;
while(<FH>){
	$line=$_;
	chomp($line);
	next if $line =~ /^#/;
	my @splitin = split "\t", $line;
	next unless ($splitin[6] eq "PASS");

	if($splitin[9] =~ /\d+,\d+,\d+,(\d+),(\d+),\d+:(\d+):($type):(\d+):/){
			#print "ok";
		my $num_g = $1;
		my $num_a = $2;
		my $num_c = $3;
		my $context = $4;
		my $num_t = $5;
		my $strand=".";
		
		#my $SNPcall = $context;
		
		if($splitin[7] =~ /CS=([+|-])/){
			$strand = $1;
		}
		if($num_c + $num_t != 0){
			$methy = $num_c/($num_c + $num_t);
			$methy = sprintf("%.2f",100*$methy);
			my $chr = $splitin[0];
			my $start = $splitin[1]-1;
			my $end = $splitin[1];
		 	my $reads_num = $num_c + $num_t;
		 	
			my $out_line = "$chr\t$start\t$end\t$reads_num\t$num_c\t$num_t\t$methy\t$strand";
			print OUT "$out_line\n";
		}
		
	}
	
}

close(FH);
close(OUT);
print "finished!\n";

