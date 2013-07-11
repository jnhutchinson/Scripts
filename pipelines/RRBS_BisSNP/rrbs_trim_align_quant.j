////////////////////////////////////////////////////////////////////////////////////////////////
//VARIABLES

//DIRECTORIES
BASEDIR="/n/hsphS10/hsphfs1/chb/projects/rw_pilot2_miseq/data/" //the directory with the fastq files you would like to process
TMPDIR="/n/hsphS10/hsphfs1/tmp"
SCRIPTDIR="/n/home08/jhutchin/Scripts/pipelines/RRBS_methylkit" //directory where you have place the scripts
PICARDDIR="/n/HSPH/local/share/java/picard" //directory where the Picard tools are located

//EXECUTABLES
BISSNPJAR="/n/home08/jhutchin/.local/bin/BisSNP/BisSNP-0.73.jar"

//TRIM VARIABLES
QUALITY=30 //trim bases with phred quality scores lower than this

ADAPTER="GATCGGAAGAGCACACGTCTGAACTCCAGTCACNNNNNNATCTCGTATGCCGTCTTCTGCTTG" //adapter to trim, if unknown, use the first 13bp of the Illumina adapter 'CAGATCGGAAGAG' and check the FASTQC overrepresented sequences for adapters to verify
MINTRIMMEDLENGTH=30

//BISMARK ALIGNER VARIABLES
BUILD="hg19" //genome build
NONDIRECTIONAL_LIB="NO"
REFERENCEGENOMEDIR="/n/hsphS10/hsphfs1/chb/biodata/genomes/Hsapiens/hg19/bismark/UCSC" //bismark prepared genome

//METHYLKIT CpG QUANTITATION VARIABLES
MINIMUMCOVERAGE=0 //minimum read coverage to call a methylation status for a base
MINIMUMQUALITY=0 //minimum phred quality score to call a methylation status for a base
MINIMUMCOVERAGE=0 //minimum read coverage to call a methylation status for a base
MINIMUMQUALITY=0 //minimum phred quality score to call a methylation status for a base

//BISSNP RESOURCES
SNP135="/n/hsphS10/hsphfs1/chb/biodata/genomes/Hsapiens/hg19/variation/dbsnp_135.vcf"

if (NONDIRECTIONAL_LIB=='YES') {
    DIRECTIONVAR="--directional"  
} else {
    DIRECTIONVAR=""
 }


////////////////////////////////////////////////////////////////////////////////////////////////
// ANALYSES
//filelist
makefilelist = {
exec 	"""
		echo $input >>filelist.txt
		"""
forward input
}

//setupdirectories
setupdirs = {
exec	"""mkdir -p ${BASEDIR}/fastqc/${input}/pretrim/"""
exec	"""mkdir -p ${BASEDIR}/fastqc/${input}/posttrim/"""
forward input
	}

//run fastqc on untrimmed
fastqc = {
exec	"""
	fastqc --o ${BASEDIR}/fastqc/${input}/pretrim/ $input
	"""
forward input
	}

// Trim and FastQC
@Transform("trimmed.fq")
trim_galore = {
exec 	"""
	trim_galore --rrbs ${DIRECTIONVAR} --fastqc --fastqc_args "--outdir ${BASEDIR}/fastqc/${input}/posttrim" --adapter ${ADAPTER} --length ${MINTRIMMEDLENGTH} --quality ${QUALITY} $input
	"""
	}

// Align
@Transform("fq_bismark.sam")
bismarkalign = {
exec 	"""
	bismark -n 1 --unmapped ${DIRECTIONVAR} ${REFERENCEGENOMEDIR}/ $input
	"""	
	}

// make bam 
@Transform("bam")
makebam = {
exec 	"""
		java -Xmx2g -Djava.io.tmpdir=${TMPDIR} -jar ${PICARDDIR}/SamFormatConverter.jar INPUT=$input OUTPUT=$output
		"""
	}

// add read groups
@Filter("RG")
addreadgroups = {
exec 	"""
		java -Xmx2g -Djava.io.tmpdir=${TMPDIR} 
		-jar ${PICARDDIR}/AddOrReplaceReadGroups.jar
		INPUT=$input
		OUTPUT=$output
		RGLB=RRBS_LIB
		RGPL=Illumina
		RGPU=R1
		RGID=$input
		RGSM=$input
		CREATE_INDEX=true 
		VALIDATION_STRINGENCY=SILENT 
		SORT_ORDER=coordinate
		"""
	}

// reorder_contigs
@Filter("RO")
reorder_contigs = {
exec 	"""
 		java -Xmx2g -Djava.io.tmpdir=${TMPDIR} -jar ${PICARDDIR}/ReorderSam.jar 
 		INPUT=$input
  		OUTPUT=$output
  		REFERENCE=${REFERENCEGENOMEDIR}/genome.fa
  		"""
  	}

// Remove duplicates
@Filter("deduped")
dedupe = {
exec 	"""
      	java -Xmx2g -jar ${PICARDDIR}/MarkDuplicates.jar           
		MAX_FILE_HANDLES_FOR_READ_ENDS_MAP=1000
		METRICS_FILE=out.metrics 
        REMOVE_DUPLICATES=true 
        ASSUME_SORTED=true  
        VALIDATION_STRINGENCY=LENIENT 
        INPUT=$input 
        OUTPUT=$output
		"""
	}
		
// indexbam
@Transform("bai")
indexbam = {
        exec """samtools index $input"""
        forward input
	}



// count_covars
@Transform("recal1.csv")
count_covars = {
	exec """
		java -Xmx10g -jar ${BISSNPJAR} 
		-R ${REFERENCEGENOMEDIR}/genome.fa 
		-I $input 
		-T BisulfiteCountCovariates 
		-knownSites $SNP135
		-cov ReadGroupCovariate 
		-cov QualityScoreCovariate 
		-cov CycleCovariate 
		-recalFile $output
		-nt 8
		"""
		forward input
	}
		
// write_recal_BQscore_toBAM
@Filter("recal1")
write_recal_BQscore_toBAM = {
		from("bam","csv") {
			exec """
			java -Xmx10g -jar $BISSNPJAR 
			-R ${REFERENCEGENOMEDIR}/genome.fa 
			-I $input1 
			-o $output 
			-T BisulfiteTableRecalibration 
			-recalFile $input2 
			-maxQ 60
			"""
		}
	}


// call_meth
call_meth = {
	transform("rawcpg.vcf", "rawsnp.vcf"){
		exec """
		java -Xmx10g -jar $BISSNPJAR 
		-R ${REFERENCEGENOMEDIR}/genome.fa 
		-T BisulfiteGenotyper 
		-I $input
		-vfn1 $output1 
		-vfn2 $output2
		-stand_call_conf 20 
		-stand_emit_conf 0 
		-mmq 30 
		-mbq 0 
		"""
	}
}





//Bpipe.run {"%.fastq" * [ setupdirs + fastqc + trim_galore + bismarkalign + makebam + addreadgroups + reorder_contigs + dedupe +indexbam +count_covars + write_recal_BQscore_toBAM]}
Bpipe.run {"%.fastq" * [ setupdirs + fastqc + trim_galore + bismarkalign + makebam + addreadgroups + reorder_contigs + dedupe +count_covars + write_recal_BQscore_toBAM + call_meth]}

