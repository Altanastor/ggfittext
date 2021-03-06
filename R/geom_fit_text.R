#' A 'ggplot2' geom to fit text inside a box
#'
#' \code{geom_fit_text} shrinks, grows or wraps text to fit inside a defined
#' rectangular area.
#'
#' @details
#'
#' Except where noted, \code{geom_fit_text} behaves more or less like
#' \code{ggplot2::geom_text}.
#'
#' In addition to the normal \code{geom_text} aesthetics, \code{geom_fit_text}
#' requires you to specify the box in which you wish to fit the text, usually
#' with 'xmin', 'xmax', 'ymin' and 'ymax' aesthetics. Alternatively, you can
#' specify the centre of the box with 'x' and/or 'y', and the height and/or
#' width of the box with 'height' and/or 'width' arguments. This can be useful
#' when one or both axes are discrete. 'height' and 'width' should be provided
#' as `grid::unit()` objects, and both default to 40 mm.
#'
#' By default, the text will be drawn as if with \code{geom_text}, unless it is
#' too big for the box, in which case it will be shrunk to fit the box. With
#' \code{grow = TRUE}, the text will be made to fill the box completely whether
#' that requires shrinking or growing.
#'
#' \code{reflow = TRUE} will cause the text to be reflowed (wrapped) to better
#' fit in the box. When \code{grow = FALSE} (default), text that fits the box
#' will be drawn as if with \code{geom_text}; text that doesn't fit the box will
#' be reflowed until it does. If the text cannot be made to fit by reflowing
#' alone, it will be reflowed to match the aspect ratio of the box as closely as
#' possible, then be shrunk to fit the box. When \code{grow = TRUE}, the text
#' will be reflowed to best match the aspect ratio of the box, then made to fill
#' the box completely whether that requires growing or shrinking. Existing line
#' breaks ('\\n') in the text will be respected when reflowing.
#'
#' @section Aesthetics:
#'
#' \itemize{
#'   \item label (required)
#'   \item xmin, xmax OR x (required)
#'   \item ymin, ymax OR y (required)
#'   \item alpha
#'   \item angle
#'   \item colour
#'   \item family
#'   \item fontface
#'   \item lineheight
#'   \item size
#' }
#'
#' @param padding.x,padding.y Amount of horizontal and vertical padding around
#' the text, expressed as \code{grid::unit()} objects. Default to 1 mm and 0.1
#' lines respectively.
#' @param min.size Minimum font size, in points. If provided, text that would
#' need to be shrunk below this size to fit the box will not be drawn. Defaults
#' to 4 pt.
#' @param place Where inside the box to place the text. Default is 'centre';
#' other options are 'topleft', 'top', 'topright', etc.
#' @param grow If 'TRUE', text will be grown as well as shrunk to fill the box.
#' See Details.
#' @param reflow If 'TRUE', text will be reflowed (wrapped) to better fit the
#' box. See Details.
#' @param width,height When using `x` and/or `y` aesthetics, these will be used
#' to determine the width and/or height of the box. These should be
#' `grid::unit()` objects. Both default to 40 mm.
#' @param mapping \code{ggplot2::aes()} object as standard in 'ggplot2'. Note
#' that aesthetics specifying the box must be provided. See Details.
#' @param data,stat,position,na.rm,show.legend,inherit.aes,... Standard geom
#' arguments as for \code{ggplot2::geom_text()}.
#'
#' @examples
#'
#' ggplot2::ggplot(ggplot2::presidential, ggplot2::aes(ymin = start, ymax = end,
#'     label = name, fill = party, xmin = 0, xmax = 1)) +
#'   ggplot2::geom_rect(colour = 'black') +
#'   geom_fit_text(grow = TRUE)
#'
#' @export
geom_fit_text <- function(
  mapping = NULL,
  data = NULL,
  stat = "identity",
  position = "identity",
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE,
  padding.x = grid::unit(1, "mm"),
  padding.y = grid::unit(0.1, "lines"),
  place = "centre",
  min.size = 4,
  grow = F,
  reflow = F,
  width = grid::unit(40, "mm"),
  height = grid::unit(40, "mm"),
  ...
) {
  ggplot2::layer(
    geom = GeomFitText,
    mapping = mapping,
    data = data,
    stat = stat,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = list(
      na.rm = na.rm,
      padding.x = padding.x,
      padding.y = padding.y,
      place = place,
      min.size = min.size,
      grow = grow,
      reflow = reflow,
      width = width,
      height = height,
      ...
    )
  )
}

#' GeomFitText
#' @noRd
GeomFitText <- ggplot2::ggproto(
  "GeomFitText",
  ggplot2::Geom,
  required_aes = c("label"),
  default_aes = ggplot2::aes(
    alpha = 1,
    angle = 0,
    colour = "black",
    family = "",
    fontface = 1,
    lineheight = 0.9,
    size = 12,
    x = NULL,
    y = NULL,
    xmin = NULL,
    xmax = NULL,
    ymin = NULL,
    ymax = NULL
  ),
  draw_key = ggplot2::draw_key_text,
  draw_panel = function(
    data,
    panel_scales,
    coord,
    padding.x = grid::unit(1, "mm"),
    padding.y = grid::unit(0.1, "lines"),
    min.size = 4,
    grow = F,
    reflow = F,
    width = grid::unit(40, "mm"),
    height = grid::unit(40, "mm"),
    place = "centre"
  ) {

    data <- coord$transform(data, panel_scales)

    # Check that width and height are `grid::unit()` objects
    if(! class(width) == "unit") {
      stop("'width' should be a `grid::unit()` object",
           .call = F
      )
    }
    if(! class(height) == "unit") {
      stop("'height' should be a `grid::unit()` object",
           .call = F
      )
    }

    # Check that valid aesthetics have been supplied for each dimension
    if (!(
      ("xmin" %in% names(data) & "xmax" %in% names(data)) |
      ("x" %in% names(data))
    )) {
      stop(
        "geom_fit_text needs either 'xmin' and 'xmax', or 'x'",
        .call = F
      )
    }
    if (!(
      "ymin" %in% names(data) & "ymax" %in% names(data) |
      "y" %in% names(data)
    )) {
      stop(
        "geom_fit_text needs either 'ymin' and 'ymax', or 'y'",
        .call = F
      )
    }

    gt <- grid::gTree(
      data = data,
      padding.x = padding.x,
      padding.y = padding.y,
      place = place,
      min.size = min.size,
      grow = grow,
      reflow = reflow,
      width = width,
      height = height,
      cl = "fittexttree"
    )
    gt$name <- grid::grobName(gt, "geom_fit_text")
    gt
  }
)

#' @importFrom grid makeContent
#' @export
makeContent.fittexttree <- function(x) {

  data <- x$data

  # Determine which aesthetics to use for the bounding box
  # Rules: if xmin/xmax are available, use these in preference to x UNLESS
  # xmin == xmax, because this probably indicates position = "stack"; in this
  # case, use x if it is available

  # If xmin/xmax are not provided, or all xmin == xmax, generate boundary box from width
  if (!("xmin" %in% names(data)) | (all(data$xmin == data$xmax) & "x" %in% names(data))) {
    data$xmin <- data$x - (
      grid::convertWidth(grid::unit(x$width, "mm"), "native", valueOnly = T) / 2
    )
    data$xmax <- data$x + (
      grid::convertWidth(grid::unit(x$width, "mm"), "native", valueOnly = T) / 2
    )
  }

  # If ymin/ymax are not provided, or all ymin == ymax, generate boundary box from height
  if (!("ymin" %in% names(data)) | (all(data$ymin == data$ymax) & "y" %in% names(data))) {
    data$ymin <- data$y - (
      grid::convertHeight(grid::unit(x$height, "mm"), "native", valueOnly = T) / 2
    )
    data$ymax <- data$y + (
      grid::convertHeight(grid::unit(x$height, "mm"), "native", valueOnly = T) / 2
    )
  }

  # Padding around text
  paddingx <- grid::convertWidth(x$padding.x, "native", valueOnly = TRUE)
  paddingy <- grid::convertHeight(x$padding.y, "native", valueOnly = TRUE)

  # Prepare grob for each text label
  grobs <- lapply(1:nrow(data), function(i) {

    # Convenience
    text <- data[i, ]

    # Place text within bounding box according to 'place' aesthetic
    if (x$place == "topleft") {
      text$x <- text$xmin + paddingx
      text$y <- text$ymax - paddingy
      text$hjust <- 0
      text$vjust <- 1

    } else if (x$place == "top") {
      text$x <- mean((c(text$xmin, text$xmax)))
      text$y <- text$ymax - paddingy
      text$hjust <- 0.5
      text$vjust <- 1

    } else if (x$place == "topright") {
      text$x <- text$xmax - paddingx
      text$y <- text$ymax - paddingy
      text$hjust <- 1
      text$vjust <- 1

    } else if (x$place == "right") {
      text$x <- text$xmax - paddingx
      text$y <- mean(c(text$ymin, text$ymax))
      text$hjust <- 1
      text$vjust <- 0.5

    } else if (x$place == "bottomright") {
      text$x <- text$xmax - paddingx
      text$y <- text$ymin + paddingy
      text$hjust <- 1
      text$vjust <- 0

    } else if (x$place == "bottom") {
      text$x <- mean((c(text$xmin, text$xmax)))
      text$y <- text$ymin + paddingy
      text$hjust <- 0.5
      text$vjust <- 0

    } else if (x$place == "bottomleft") {
      text$x <- text$xmin + paddingx
      text$y <- text$ymin + paddingy
      text$hjust <- 0
      text$vjust <- 0

    } else if (x$place == "left") {
      text$x <- text$xmin + paddingx
      text$y <- mean(c(text$ymin, text$ymax))
      text$hjust <- 0
      text$vjust <- 0.5

    } else if (x$place == "centre" | x$place == "center" | x$place == "middle") {
      text$x <- mean((c(text$xmin, text$xmax)))
      text$y <- mean(c(text$ymin, text$ymax))
      text$hjust <- 0.5
      text$vjust <- 0.5

    } else {
      stop(
        "geom_fit_text does not recognise place '",
        x$place,
        "' (try something like 'topright' or 'centre')",
        call. = F
      )
    }

    # Create textGrob
    tg <- grid::textGrob(
      label = text$label,
      x = text$x,
      y = text$y,
      default.units = "native",
      hjust = text$hjust,
      vjust = text$vjust,
      rot = text$angle,
      gp = grid::gpar(
        col = ggplot2::alpha(text$colour, text$alpha),
        fontsize = text$size,
        fontfamily = text$family,
        fontface = text$fontface,
        lineheight = text$lineheight
      )
    )

    # Hide if below minimum font size
    if (tg$gp$fontsize < x$min.size) { return() }

    # Get textGrob dimensions
    labelw <- function(tg) {
      grid::convertWidth(grid::grobWidth(tg), "native", TRUE)
    }
    labelh <- function(tg) {
      grid::convertHeight(
        grid::grobHeight(tg) + (2 * grid::grobDescent(tg)),
        "native",
        TRUE
      )
    }

    # Get x and y dimensions of bounding box
    xdim <- abs(text$xmin - text$xmax) - (2 * paddingx)
    ydim <- abs(text$ymin - text$ymax) - (2 * paddingy)

    # Resize text to fit bounding box
    if (
      # Standard condition - is text too big for box?
      (labelw(tg) > xdim | labelh(tg) > ydim) |
      # grow = TRUE condition - is text too small for box?
      (x$grow & labelw(tg) < xdim & labelh(tg) < ydim)
    ) {

      # Reflow text if requested
      if (x$reflow) {

        # Try reducing the text width, one character at a time, and see if it
        # fits the bounding box
        best_aspect_ratio <- Inf
        best_width <- stringi::stri_length(tg$label)
        label <- unlist(stringi::stri_split(tg$label, regex = "\n"))
        stringwidth <- sum(unlist(lapply(label, stringi::stri_length)))
        for (w in (stringwidth - 1):1) {

          # Reflow text to this width
          # By splitting the text on whitespace and passing normalize = F,
          # line breaks in the original text are respected
          tg$label <- paste(
            stringi::stri_wrap(label, w, normalize = F),
            collapse = "\n"
          )

          # Calculate aspect ratio and update if this is the new best ratio
          aspect_ratio <- labelw(tg) / labelh(tg)
          diff_from_box_ratio <- abs(aspect_ratio - (xdim / ydim))
          best_diff_from_box_ratio <- abs(best_aspect_ratio - (xdim / ydim))
          if (diff_from_box_ratio < best_diff_from_box_ratio) {
            best_aspect_ratio <- aspect_ratio
            best_width <- w
          }

          # If the text now fits the bounding box (and we are not trying to grow
          # the text), good to stop and return the grob
          if (labelw(tg) < xdim & labelh(tg) < ydim & !x$grow) {
            return(tg)
          }
        }

        # If all reflow widths have been tried and none is smaller than the box
        # (i.e. some shrinking is still required), pick the reflow width that
        # produces the aspect ratio closest to that of the bounding box. In the
        # condition that we are trying to grow the text, this will also ensure
        # the text is grown with the best aspect ratio.
        tg$label <- paste(
          stringi::stri_wrap(label, best_width, normalize = F),
          collapse = "\n"
        )
      }

      # Get the slopes of the relationships between font size and label
      # dimensions
      fs1 <- tg$gp$fontsize
      lw1 <- labelw(tg)
      lh1 <- labelh(tg)
      tg$gp$fontsize <- tg$gp$fontsize * 2
      slopew <- fs1 / (labelw(tg) - lw1)
      slopeh <- fs1 / (labelh(tg) - lh1)

      # Calculate the target font size required to fit text to box along each
      # dimension
      targetfsw <- xdim * slopew
      targetfsh <- ydim * slopeh

      # Set to smaller of target font sizes
      tg$gp$fontsize <- ifelse(targetfsw < targetfsh, targetfsw, targetfsh)

    }

    # Hide if below minimum font size
    if (tg$gp$fontsize < x$min.size) { return() }

    # Return the textGrob
    tg
  })

  class(grobs) <- "gList"
  grid::setChildren(x, grobs)
}

#' geom_fit_text
#' @noRd
geom_grow_text <- function(...) {
  .Deprecated("geom_fit_text(grow = T, ...)")
}

#' geom_fit_text
#' @noRd
geom_shrink_text <- function(...) {
  .Deprecated("geom_fit_text(grow = F, ...)")
}
