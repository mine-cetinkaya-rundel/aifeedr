# app.R
library(stringi)

# get the container hostname we are running inside
get_hostname <- function() {
  Sys.info()[["nodename"]]
}


#' Capture Selected Text
#'
#' An RStudio addin that captures the currently selected text in the editor
#' or console and returns it as a character vector.
#'
#' @return A character vector containing the selected text. If no text is
#'   selected, returns an empty character vector.
#' @export
capture_selection = function() {
  if (!rstudioapi::isAvailable()) {
    stop("This function requires RStudio")
  }
  
  # Get the selected text using selectionGet()
  selected_text = rstudioapi::selectionGet()
  
  # selectionGet() returns a list with 'value' containing the text
  if (length(selected_text) > 0 && "value" %in% names(selected_text)) {
    result = selected_text$value
  } else {
    result = character(0)
  }
  
  # Return the result and also print it for immediate feedback
#  if (length(result) > 0) {
#    cat("Captured text:\n")
#    cat(paste(result, collapse = "\n"))
#    cat("\n")
#  } else {
#    cat("No text selected\n")
#  }
  
  invisible(result)
}
