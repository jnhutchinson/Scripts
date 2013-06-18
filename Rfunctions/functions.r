PCAplot <- function(eset=NULL, categories=NULL, title=NULL, colorpalette=NULL, alpha=1){
  alpha <- sprintf("%x", ceiling(alpha*255))
  colorpalette <- paste(colorpalette, alpha, sep="")
  eset.core <- exprs(eset) 
  myPca.core <- prcomp(t(eset.core))
  tmpPCAData.core <- as.data.frame(myPca.core$x[,1:4])
  pd <- pData(eset)
  colors <- colorpalette[factor(as.character(unlist(pd[,categories])))]
  legend_values=unique(cbind(colors, as.character(pd[,categories])))
  pairs(tmpPCAData.core, bg=colors, col="#606060", cex=2, pch=21, main=title, oma=c(8,5,5,14))
  legend("right", cex=0.7, col="#606060", pt.bg=legend_values[,1], pt.cex=1.5, legend=legend_values[,2],  pch=21, bty="n", x.intersp=1)
}
rownames2col <- function(df, colname) {
  output <- cbind(row.names(df), df)
  colnames(output)[1] <- colname
  return(output)
}
col2rownames <- function(df, colname, removecol=FALSE){
  row.names(df) <- df[,colname]
  if(removecol){df[,colname] <- NULL}
  return(df)
}
ezheatmap <- function(eset, probes, pData_col, sample_types, annot_palettes, title="", rowfont, colorpalette=rev(brewer.pal(11,"RdBu")), annot_package,...) {
  ## will subset by both probeID and sample, and output an annotated heatmap
  ## eset = ExpressionSet with associated metadata
  ## probes = character vector of probeIDs to subset to
  ## pData_col = heading of the metadata column you wish to subset samples by
  ## sample_types = character vector of sample categories that you wish to subset to
  ## annot_categories = headings of the metadata columns you wish to use for annotations
  ## annot_palettes = list where the list names are the headings of the metadata columns you wish to use for annotations and the list contents are color palettes for each of these categories
  if(missing(eset)){warning("No ExpressionSet specified")}
  if(missing(probes)){warning("No Vector of probe IDs specified")}
  if(missing(annot_palettes)){warning("No annotation categories specified")}
  if(missing(sample_types)){warning("No sample types specified")}
  if(missing(pData_col)){warning("No metadata selection specified")}
  if(missing(annot_package)){warning("No annotation database specified")}
  # subset expression set to probes and samples of interest
  eset.sub <- eset[probes, which(pData(eset)[,pData_col] %in% sample_types)]
  # setup expression value matrix
  eset.sub.exprs <- exprs(eset.sub)
  # rename rownames to have the probeID and gene symbol
  symbols <- as.vector(unlist(mget(probes, get(paste(annot_package, "SYMBOL", sep="")), ifnotfound=NA)))
  row.names(eset.sub.exprs) <- paste(row.names(eset.sub.exprs), symbols, sep="_")
  # setup annotations
  pd.sub <- pData(eset.sub)
  heatmap.annots <- pd.sub[,names(annot_palettes)]
  heatmap.annots <- as.data.frame(apply(heatmap.annots, 2, unlist))
  row.names(heatmap.annots) <- sampleNames(eset.sub)
  ann_cols <- list()
  for (annot_category in names(annot_palettes)){
    colors <- annot_palettes[[annot_category]][1:length(unique(unlist(pd.sub[, annot_category])))]
    names(colors) <- unique(unlist(pd.sub[, annot_category]))
    ann_cols[[annot_category]]=colors
  }
  if(missing(rowfont)) {  
    rowfont=20-(round(length(probes)/10, digits=1))
    print(rowfont)}
  if(rowfont<8){showrows=FALSE}else{showrows=TRUE}
  pheatmap(eset.sub.exprs, cluster_rows = TRUE,  color=colorpalette, show_colnames=F, show_rownames=showrows, annotation=heatmap.annots, annotation_colors=ann_cols, fontsize=18, main=title,fontsize_row=rowfont )
}

#ezheatmap(mic.norm.eset, probes=probesIDs[1:120], pData_col="gender", sample_types=c("FEMALE", "MALE"), annot_package="hgu133plus2", annot_palettes=list(gender=c("pink", "cyan"),stage=cbPalette), title="fuckme")


