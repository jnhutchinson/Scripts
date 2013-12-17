//DIRECTORIES
BASEDIR="/n/home08/jhutchin/projects/rrbs_workflows/test_bseqc/data/" //the directory with the fastq files you would like to process

//TRIM VARIABLES
QUALITY=30 //trim bases with phred quality scores lower than this

ADAPTER="GATCGGAAGAGCACACGTCTGAACTCCAGTCACNNNNNNATCTCGTATGCCGTCTTCTGCTTG" //adapter to trim, if unknown, use the first 13bp of the Illumina adapter 'CAGATCGGAAGAG' and check the FASTQC overrepresented sequences for adapters to verify
MINTRIMMEDLENGTH=30

//BSeQC VARIABLES
READLENGTH=75

//BISMARK ALIGNER VARIABLES
BUILD="hg19" //genome build
DIRECTIONVAR="--non_directional" //options are "--non_directional" OR ""
RRBSVAR="--rrbs" //options are "--rrbs" OR ""
REFERENCEGENOMEDIR="/n/hsphS10/hsphfs1/chb/biodata/genomes/Hsapiens/hg19/bismark/UCSC" //bismark prepared genome

//METHYLKIT CpG QUANTITATION VARIABLES
MINIMUMCOVERAGE=0 //minimum read coverage to call a methylation status for a base
MINIMUMQUALITY=0 //minimum phred quality score to call a methylation status for a base
MINIMUMCOVERAGE=0 //minimum read coverage to call a methylation status for a base
MINIMUMQUALITY=0 //minimum phred quality score to call a methylation status for a base
