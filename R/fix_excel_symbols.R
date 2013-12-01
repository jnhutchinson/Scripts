fix_excel_symbols = function(symbols) {
    require(gsubfn)
    regex_str = "([0-9])-(JAN|FEB|MAR|APR|MAY|JUN|JUL|AUG|SEP|OCT|NOV|DEC|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)"
    return(strapply(symbols, regex_str, fix_string, simplify=TRUE))
}


fix_string = function(x, y) {
    require(stringr)
    return(paste(toupper(y), x, sep=""))
}
