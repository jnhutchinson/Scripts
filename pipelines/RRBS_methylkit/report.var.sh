echo "sampleID	numprocessed_reads	%_trimmed_reads	%_quality_truncated_reads	%_reads_tooshort_after_trimming	posttrim_basic_statistics	overrepresented_seq	mapping_efficiency	%_methylated_CpG	%_methylated_CHG	%_methylated_CHH"

while read inputfile
do
	sampleID=${inputfile%".fastq"}
	
	#extract metrics from trimming report
	trim_report=${inputfile}_trimming_report.txt
	length_trim_report=$(wc -l $trim_report | sed 's/ .*$//')
	if [ -f $trim_report ] && [ $length_trim_report -gt 15 ] # check if file exists and is fully generated (should be 102 lines)
		then
		 sample_id=$(grep Input\ filename: $trim_report | sed 's/^.*: //g') 
		 num_processed_reads=$(grep Processed\ reads: $trim_report | sed 's/Processed reads://g' |sed 's/^.*\s//') 
		 perc_trimmed_reads=$(grep Trimmed\ reads:  $trim_report | sed 's/^.*(//' | sed 's/%)//') 
		 perc_quality_truncated_reads=$(grep Sequences\ were\ truncated  $trim_report | sed 's/^.*(//' | sed 's/%)//') 
		 perc_reads_tooshort_after_trimming=$(grep length\ cutoff\ of\ 30\ bp  $trim_report | sed 's/S.*bp://g'| sed 's/^.*(//g'| sed 's/%)//g') 
		else
		 sample_id=$inputfile 
		 num_processed_reads="NA"
		 perc_trimmed_reads="NA"
		 perc_quality_truncated_reads="NA" 
		 perc_reads_tooshort_after_trimming="NA" 
	fi
	
#	metrics from fastqc post-trim results
	fastqc_data=./fastqc/${inputfile}/posttrim/${sampleID}.trimmed.fq_fastqc/fastqc_data.txt
	if  [ -f $fastqc_data ] # check if file exists
	 then
		posttrim_basic_statistics=$(grep "Basic" $fastqc_data | sed 's/^.*Statistics.//')
		overrepresented_seq=$(grep Overrepresented\ sequences $fastqc_data  | sed 's/^.*sequences.//')

	else 
	 	posttrim_basic_statistics="NA" 
	 	overrepresented_seq="NA"
	fi

#	 metrics from Bismark mapping
	 bismark_report=./${sampleID}.trimmed.fq_Bismark_mapping_report.txt
	 if [ -f $bismark_report ] # check if file exists
	 then 
	       	map_eff=$(grep Mapping\ efficiency $bismark_report | sed 's/^.*:.//'| sed 's/%//') 
	       	perc_meth_CpG=$(grep C\ methylated\ in\ CpG\ context: $bismark_report | sed 's/^.*:.//' | sed 's/%//')
               	perc_meth_CHG=$(grep C\ methylated\ in\ CHG\ context: $bismark_report | sed 's/^.*:.//' | sed 's/%//')
		perc_meth_CHH=$(grep C\ methylated\ in\ CHH\ context: $bismark_report | sed 's/^.*:.//' | sed 's/%//') 
	 else
		map_eff="NA"
 		perc_meth_CpG="NA"
 		perc_meth_CHG="NA"
		perc_meth_CHH="NA"
	 fi
        

	#output
	echo "$sample_id	$num_processed_reads	$perc_trimmed_reads	$perc_quality_truncated_reads	$perc_reads_tooshort_after_trimming	$posttrim_basic_statistics	$overrepresented_seq	$map_eff	$perc_meth_CpG	$perc_meth_CHG	$perc_meth_CHH"


done < $1



## test code to get adapter trim length histogram data
#awk '/Histogram/,/RUN/' C554_ACTTGA_L003_R1.fastq_trimming_report.txt | sed '/Histogram/d' | sed '/RUN/d' |sed '/^$/d'
