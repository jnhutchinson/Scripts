base_name = function(txt, ext="") {
    #return base name of a filename, if an optional ext is given,
    #strip it off first
    require(stringr)
    if (ext == "") {
        return(basename(txt))
    }
    else {
        return(basename(str_split(txt, ext)[[1]][[1]]))
    }
}
