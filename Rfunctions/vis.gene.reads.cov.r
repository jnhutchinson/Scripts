## first import the gene model (gtf/gff) into the R envirnoment as a TranscriptDb object using import.gtf2db
## should work with either gtf or gff formats
import.gtf2db <- function(genemodel.file, exonnumber.attribute=NULL,...){
  require(GenomicFeatures) 
  require(tools)
  file.format <- file_ext(genemodel.file)
  makeTranscriptDbFromGFF(file=genemodel.file, format=file.format, exonRankAttributeName=exonnumber.attribute, dataSource=NA, species=NA)
}

## next, pass the TranscriptDb object describing your transcripts to the plotting function, along with:
# gene.of.interest <- the gene of interest, currently this uses the gene symbol to specify the gene, (character)
# genemodel.db <- the genemodel (TranscriptDb object)
# genome.build  <-  genome build (character) eg. "hg19"
# bam.files  <-  named list of the bam files (list) eg. list(bam1="/foo1/bar1.bam", bam2="foo2/bar2.bam")
# plotcoverage <- whether to plot coverage graph (logical)
# plotreads  <-  whether to plot reads (logical)
plot.cov.reads.gene <- function(gene.of.interest="GAPDH", genemodel.db, genome.build, bam.files, plotcoverage=TRUE, plotreads=TRUE) {
  ## using Gviz to visualize an RNA-seq alignment for genes of choice
  require(Gviz)
  require(GenomicFeatures)  
  require(Rsamtools)
  flattenlist <- function(x) {
    y <- list()
    rapply(x, function(x) y <<- c(y,x))
    return(y)
  }
  cbPalette <- rep(c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#000000"), 4)
  # index alignments if necessary
  lapply(bam.files, function(bam.file){
    if(!file.exists(paste(bam.file, "bai", sep="."))){indexBam(bam.file)}
  })
  ## gene location infomation
  chr <-select(genemodel.db, keys=gene.of.interest, cols="TXCHROM" , keytype="GENEID")[[2]]
  start <- select(genemodel.db, keys=gene.of.interest, cols="TXSTART", keytype="GENEID")[[2]]
  end <- select(genemodel.db, keys=gene.of.interest, cols="TXEND", keytype="GENEID")[[2]]
  ##PREP tracks
  ## Genome Axis and chromosom ideogram track
  gtrack <- GenomeAxisTrack()
  itrack <- IdeogramTrack(chromosome=chr, genome=genome.build)
  ## make GeneRegionTrack from genemodel
  grtrack <- GeneRegionTrack(genemodel.db)
  # stream bam files to determine maximum coverage
  selection.gr <- GRanges(seqnames=chr, ranges=IRanges(start=start, end=end))
  param <- ScanBamParam(what=c("pos", "qwidth"), which=selection.gr, flag=scanBamFlag(isUnmappedQuery=FALSE))
  ymax <- 0
  for (bam.file in bam.files){
    x <- scanBam(bam.file, param=param)[[1]]
    cov <- coverage(IRanges(x[["pos"]], width=x[["qwidth"]]))
    if(max(cov)>ymax){ymax <- max(cov)}
  }
  # stream bam file to get reads and coverage for each alignment (assign different color to each alignment)
  align.tracks <- list()
  for (sample in names(bam.files)) {
    n <- which(names(bam.files)==sample)
    label.readtrack <- paste("reads", sample, sep=".")
    label.covtrack <- paste("coverage", sample, sep=".")
    if (plotcoverage==TRUE){
      align.tracks[[label.covtrack]] <- DataTrack(range=bam.files[[sample]], genome=genome.build, type="l",  window=-1, chromosome=chr, col="red", lwd=2, name=" ", background.title = cbPalette[n],  grid=T, col.frame="red", ylim=c(0,ymax))
    }
    if (plotreads==TRUE){
      align.tracks[[label.readtrack]] <- AnnotationTrack(range = bam.files[[sample]], genome = genome.build, chromosome = "chr19", name=sample, background.title = cbPalette[n])
    }
  }
  ## assemble tracks
  tracks <-  list(itrack, gtrack, grtrack, align.tracks) 
  tracks <- flattenlist(tracks)
  ## plot tracks
  plotTracks(tracks, from=start, to=end, chromosome=chr, extend.left=100, extend.right=100)
}


