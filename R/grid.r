#' Visualise the layout of a gtable.
#' 
#' @export
#' @param x a gtable object
gtable_show_layout <- function(x) {
  stopifnot(is.gtable(x))

  grid.show.layout(gtable_layout(x))
}

gtable_layout <- function(x) {
  stopifnot(is.gtable(x))

  grid.layout(
    nrow = nrow(x), heights = x$heights,
    ncol = ncol(x), widths = x$widths,
    respect = x$respect
  )
}

vpname <- function(row) {
  paste(row$name, ".", row$t, "-", row$r, "-", row$b, "-", row$l, sep = "")
}

#' @S3method widthDetails gtable
widthDetails.gtable <- function(x) absolute.size(gtable_width(x))

#' @S3method heightDetails gtable
heightDetails.gtable <- function(x) absolute.size(gtable_height(x))

grid.draw.gtable <- function(x, recording = TRUE) {
  # Return the viewport for a child grob in a gtable
  child_vp <- function(grob, vp_name, t, r, b, l, clip) {
    viewport(name = vp_name, layout.pos.row = t:b,
             layout.pos.col = l:r, clip = clip)
  }
  
  children_vps <- mapply(child_vp,
                         grob = x$grobs, vp_name = vpname(x$layout),
                         t = x$layout$t, r = x$layout$r, b = x$layout$b, l = x$layout$l,
                         clip = x$layout$clip,
                         SIMPLIFY = FALSE)
  
  x$grobs <- mapply(function(grob, vp) {
    grob$wrapvp <- vp
    class(grob) <- c("gTableChild", class(grob))
    grob$name <- vp$name
    grob
  },
                    x$grobs,
                    children_vps,
                    SIMPLIFY = FALSE)
  if (inherits(x, "gTableChild")) {
    gt <- gTree(children = do.call("gList", x$grobs), cl = c("gTableParent", "gTableChild"),
                vp = x$vp, wrapvp = x$wrapvp, layoutvp = viewport(layout = gtable_layout(x), name = x$name))
  }
  else {
    gt <- gTree(children = do.call("gList", x$grobs), cl = c("gTableParent"),
                vp = x$vp, layoutvp = viewport(layout = gtable_layout(x), name = x$name))
   
  }
  grid.draw(gt)
  invisible(gt)
}

preDraw.gTableChild <- function(x) {
  pushViewport(x$wrapvp, recording = FALSE)
  NextMethod()
}

postDraw.gTableChild <- function(x) {
  NextMethod()
  upViewport(recording = FALSE)
}

preDrawDetails.gTableParent <- function(x) {
  pushViewport(x$layoutvp, recording = FALSE)
}

postDrawDetails.gTableParent <- function(x) {
  upViewport(recording = FALSE)
}
