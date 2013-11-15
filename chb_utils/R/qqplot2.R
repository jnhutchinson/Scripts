

qqplot2 <- function(x, y) {
    # lifted from http://stats.stackexchange.com/questions/12392/how-to-compare-two-datasets-with-q-q-plot-using-ggplot2
    sx <- sort(x)
    sy <- sort(y)
    lenx = length(sx)
    leny = length(sy)
    if (leny < lenx) {
        sx = approx(1L:lenx, sx, n = leny)$y
    }
    if (leny > lenx) {
        sy = approx(1L:leny, sy, n = lenx)$y
    }
    df = data.frame(sx=sx, sy=sy)
    require(ggplot2)
    g = ggplot(df) + geom_point(aes(x=sx, y=sy))
    return(g)
}
