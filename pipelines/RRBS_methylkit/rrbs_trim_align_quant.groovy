load("system.groovy")
load("sample.groovy")

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

// sort sam 
@Filter("coordsorted")
sortsam = {
exec 	"""
	grep -v '^[[:space:]]*@' $input | sort -k3,3 -k4,4n  > $output

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


Bpipe.run {"%.fastq" * [ setupdirs + fastqc + trim_galore + bismarkalign + sortsam + dedupe + quantmeth + compile_individual_reports ]}
