////////////////////////////////////////////////////////////////////////////////////////////////
//DEPENDENCIES

//Bismark directory must be in PATH
//Reference genomes must be preprepared with bismark
//module load bio/cutadapt-1
//module load bio/bowtie
//module load hpc/pandoc-1.9.3_ghc-7.4.1 


////////////////////////////////////////////////////////////////////////////////////////////////
//VARIABLES

//DIRECTORIES
BASEDIR="/n/home08/jhutchin/projects/lk_rrbs/data"
TMPDIR="/n/scratch00/hsph/tmp"
SCRIPTDIR="/n/home08/jhutchin/projects/lk_rrbs/scripts/RRBS_methylkit"
QUANTMETHSCRIPT="/n/home08/jhutchin/projects/lk_rrbs/scripts/RRBS_methylkit/knitr_quant_meth_methylkit.r"
PICARDDIR="/n/HSPH/local/share/java/picard"

//TRIM VARIABLES
QUALITY=30 //trim bases with phred quality scores lower than this
ADAPTER="GATCGGAAGAGCACACGTCTGAACTCCAGTCACCTTGTAATCTCGTATGCCGTCTTCTGCTTG" //adapter to trim

//BISMARK ALIGNER VARIABLES
BUILD="hg19" //genome build
DIRECTIONVAR="non_directional" //options are directional or non_directional
REFERENCEGENOMEDIR="/n/scratch00/hsph/biodata/genomes/Hsapiens/hg19/bismark/UCSC"

//METHYLKIT CpG QUANTITATION VARIABLES
MINIMUMCOVERAGE=10 //minimum read coverage to call a methylation status for a base
MINIMUMQUALITY=20 //minimum phred quality score to call a methylation status for a base


////////////////////////////////////////////////////////////////////////////////////////////////
// ANALYSES

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
		trim_galore --rrbs --fastqc --fastqc_args "--outdir ${BASEDIR}/fastqc/${input}/posttrim" --quality ${QUALITY} $input
		"""
}

// Align
@Transform("fq_bismark.sam")
bismarkalign = {
exec 	"""
	bismark -n 1 -l 50 --$DIRECTIONVAR ${REFERENCEGENOMEDIR}/ $input
	"""	
}

// sort sam 
@Filter("coordsorted")
sortsam = {
exec 	"""
		java -Xmx2g -Djava.io.tmpdir=${TMPDIR} -jar ${PICARDDIR}/SortSam.jar INPUT=$input OUTPUT=$output SORT_ORDER=coordinate
		"""
}

//quantitate methylation with methylkit, sam files will be parsed and CpG C/T conversions counted for each individual sample
quantmeth = {
exec	"""
		$QUANTMETHSCRIPT $input $BASEDIR $BUILD $SCRIPTDIR $MINIMUMCOVERAGE $MINIMUMQUALITY
		"""
}

compile_results = {
exec	"""
		bash ${SCRIPTDIR}/compile_results.sh $input.md
		"""
}


Bpipe.run {"%.fastq" * [setupdirs + fastqc + trim_galore + bismarkalign + sortsam + quantmeth + compile_results]}
