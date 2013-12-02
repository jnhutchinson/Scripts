fix_excel_symbols = function(symbols) {
    return(unlist(lapply(as.character(symbols), fix_string)))
#    return(strapply(symbols, regex_str, fix_string, simplify=TRUE))
}

fix_string = function(x) {
    regex_str = "([0-9])-(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)"
    return(if(any(grep(regex_str, x))) date_fixer(x) else x)
}

date_fixer = function(x) {
    tokens = str_split(x, "-")
    return(paste(toupper(tokens[[1]][2]), tokens[[1]][1], sep=""))
}

   
