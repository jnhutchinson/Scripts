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
	produce("${BASEDIR}/fastqc/${input.fastq}/pretrim","${BASEDIR}/fastqc/${input.fastq}/posttrim") {
	 	exec	"""
	 		mkdir -p ${BASEDIR}/fastqc/${input}/pretrim/
	 		"""
		exec	"""
			mkdir -p ${BASEDIR}/fastqc/${input}/posttrim/
			"""
	}
 }


//run fastqc on untrimmed
fastqc_pretrim = {
    doc 	"Run FASTQC to generate QC metrics for the untrimmed reads"
    output.dir = "${BASEDIR}/fastqc/${input.fastq}/pretrim/"
    transform('.fastq')  to('_fastqc.zip')  {
		exec 	"""
			fastqc -o $output.dir $input.fastq
			"""
    }
}

// Trim & fastqc
trim_galore = {
	doc 	"Trim adapters and low quality bases from all reads"
	output.dir = "${BASEDIR}"
	from("fastq") {
		transform('.fastq') to ('.trimmed.fq'){
			exec 	"""
				trim_galore ${RRBSVAR} ${DIRECTIONVAR} 
				--fastqc 
				--fastqc_args "--outdir ${BASEDIR}/fastqc/${input.fastq}/posttrim" 
				--adapter ${ADAPTER} 
				--length ${MINTRIMMEDLENGTH} 
				--quality ${QUALITY} $input.fastq
				"""
		}
	}
}	

// Align
//@Transform("fq_bismark.sam")
bismarkalign = {
	doc 	"Align to genome with Bismark"
	from('trimmed.fq') {	
		transform('trimmed.fq') to ('trimmed.fq_bismark.sam') {
			exec 	"""
				bismark -n 1 --unmapped ${DIRECTIONVAR} ${REFERENCEGENOMEDIR}/ $input
				"""	
		}
	}
}

// sort sam 
@Filter("coordsorted")
sortsam = {
	doc	"Sort alignment by coordinates"
	exec 	"""
		grep -v '^[[:space:]]*@' $input | sort -k3,3 -k4,4n  > $output
		""", "sortsam"
}

//quantitate methylation with methylkit, sam files will be parsed and CpG C/T conversions counted for each individual sample
@Transform("methylkit.md")
quantmeth = {
	doc "Quantitate methylation with methylKit"
	exec	"""
		${SCRIPTDIR}/knitr_quant_meth_methylkit.r $input $BASEDIR $BUILD $SCRIPTDIR $MINIMUMCOVERAGE $MINIMUMQUALITY
		""", "quantmeth"
}

//Compile individual reports
compile_individual_reports = {
	doc "Compile pipeline report for sample"
	exec	"""
		bash ${SCRIPTDIR}/compile_results.sh $input
		"""
}

Bpipe.run {makefilelist + "%.fastq" * [ mkfastqcdirs + fastqc_pretrim +  trim_galore + bismarkalign + sortsam + quantmeth + compile_individual_reports ]}
