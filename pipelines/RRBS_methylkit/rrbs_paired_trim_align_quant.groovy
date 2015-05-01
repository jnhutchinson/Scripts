load("system.groovy")
load("sample.groovy")

////////////////////////////////////////////////////////////////////////////////////////////////
// ANALYSES

///make list of all input files
makefilelist = {
	doc 	"Make a list of files processed"
     produce("filelist.txt") {
     	exec 	"""
		>filelist.txt
     		"""
	for (i in inputs) {
		exec 	"""
			echo $i >>filelist.txt
			"""
		}
	}
}

//setup fastqc directories
mkfastqcdirs = {
	doc 	"Setup output directories for Fastqc"
	produce("${BASEDIR}/fastqc/pretrim","${BASEDIR}/fastqc/posttrim") {
	 	exec	"""
	 		mkdir -p ${BASEDIR}/fastqc/pretrim/
	 		"""
		exec	"""
			mkdir -p ${BASEDIR}/fastqc/posttrim/
			"""
	}
 }

//run fastqc on untrimmed
fastqc_pretrim = {
	doc 	"Run FASTQC to generate QC metrics for the untrimmed reads"
    	output.dir = "${BASEDIR}/fastqc/pretrim/"
    	transform('.fastq')  to('_fastqc.zip')  {
		multi 	"fastqc -o $output.dir $input1.fastq",
			"fastqc -o $output.dir $input2.fastq"
    	}
	forward input
}

// Trim & fastqc
trim_galore = {
	doc 	"Trim adapters and low quality bases from all reads"
	output.dir = "${BASEDIR}"
		produce (input1.prefix+".val_1.fq", input2.prefix+".val_2.fq"){
			exec 	"""
				trim_galore ${RRBSVAR} ${DIRECTIONVAR} 
				--paired
				--retain_unpaired
				--fastqc 
				--fastqc_args "--outdir ${BASEDIR}/fastqc/posttrim" 
				--adapter ${ADAPTER} 
				--a2 ${ADAPTER}
				--length ${MINTRIMMEDLENGTH}
				--quality ${QUALITY} $input1.fastq $input2.fastq
				"""
		}
}

// Align
bismarkalign = {
	doc 	"Align to genome with Bismark"
	from('.val_*.fq')	transform('fq_bismark_pe.sam') {
			exec 	"""
				bismark -n 1 --unmapped ${DIRECTIONVAR} ${REFERENCEGENOMEDIR}/ -1 $input1 -2 $input2
				"""	
		}
}

// sort sam 
@ Filter("coordsorted")
sortsam = {
	doc	"Sort alignment by coordinates"
	exec 	"""
		grep -v '^[[:space:]]*@' $input | sort -k3,3 -k4,4n  > $output
		""", "sortsam"
}

//quantitate methylation with methylkit, sam files will be parsed and CpG C/T conversions counted for each individual sample
quantmeth = {
	doc "Quantitate methylation with methylKit"
	transform('.fq_bismark_pe.coordsorted.sam') to ('.fq_bismark_pe.coordsorted.methylkit.md') {
		exec	"""
			${SCRIPTDIR}/knitr_paired_quant_meth_methylkit.r $input $BASEDIR $BUILD $SCRIPTDIR $MINIMUMCOVERAGE $MINIMUMQUALITY
			""", "quantmeth"
	}
}

//Compile individual reports
compile_individual_reports = {
	doc "Compile pipeline report for sample"
	exec	"""
		bash ${SCRIPTDIR}/compile_paired_results.sh $input
		"""
}

Bpipe.run {makefilelist + mkfastqcdirs + "%_R*.fastq" * [ fastqc_pretrim + trim_galore + bismarkalign + sortsam + quantmeth + compile_individual_reports]} 
//Bpipe.run {makefilelist + "%_R*.fastq" * [ mkfastqcdirs + fastqc_pretrim +  trim_galore + bismarkalign + sortsam + quantmeth + compile_individual_reports ]}
