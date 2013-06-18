////////////////////////////////////////////////////////////////////////////////////////////////
//VARIABLES

//DIRECTORIES
BASEDIR="/n/hsphS10/hsphfs1/chb/projects/rw_pilot2_miseq/data/" //the directory with the fastq files you would like to process
TMPDIR="/n/hsphS10/hsphfs1/tmp"
SCRIPTDIR="/n/home08/jhutchin/Scripts/pipelines/RRBS_methylkit" //directory where you have place the scripts
PICARDDIR="/n/HSPH/local/share/java/picard" //directory where the Picard tools are located

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
	bismark -n 1 ${DIRECTIONVAR} ${REFERENCEGENOMEDIR}/ $input
	"""	
}

// sort sam 
@Filter("coordsorted")
sortsam = {
exec 	"""
	grep -v '^[[:space:]]*@' $input | sort -k3,3 -k4,4n  > $output

	"""
}

//quantitate methylation with methylkit, sam files will be parsed and CpG C/T conversions counted for each individual sample
@Transform("methylkit.md")
quantmeth = {
exec	"""
		${SCRIPTDIR}/knitr_quant_meth_methylkit.r $input $BASEDIR $BUILD $SCRIPTDIR $MINIMUMCOVERAGE $MINIMUMQUALITY
		"""
}

//Compile individual reports
compile_individual_reports = {
exec	"""
		bash ${SCRIPTDIR}/compile_results.sh $input
		"""
}


Bpipe.run {"%.fastq" * [ setupdirs + fastqc + trim_galore + bismarkalign + sortsam + quantmeth + compile_individual_reports ]}
