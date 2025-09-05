#' Capture selected text and launch Shiny app for feedback
#'
#' An RStudio addin that captures the currently selected text in the editor
#' or console, returns it as a character vector that is stored as a 
#' system variable, that is then passed on to the feedback getting
#' Shiny app that is launched.
#' 
#' Users interact with this function through the Get feedback addin.
#'
#' @return A character vector containing the selected text. If no text is
#'   selected, returns an empty character vector.
#' @importFrom shiny runApp
#' @importFrom rstudioapi isAvailable selectionGet
#' @importFrom markdown markdownToHTML
#' @importFrom stringi stri_unescape_unicode
#' @export
get_feedback = function() {
  if (!rstudioapi::isAvailable()) {
    stop("This function requires RStudio!")
  }
  
  # Get the selected text using selectionGet()
  selected_text = rstudioapi::selectionGet()
  
  # Error if no text is selected
  if (selected_text$value == ""){
    stop("No text selected. Select your answer and try again.", call. = FALSE)
  }
  
  # selectionGet() returns a list with 'value' containing the text
  if (length(selected_text) > 0 && "value" %in% names(selected_text)) {
    result = selected_text$value
  } else {
    result = character(0)
  }

  Sys.setenv(captured_text_for_feedback = result)
  
  app_dir = system.file("shiny", "get_feedback_app", package = "aifeedr")
  shiny::runApp(app_dir, display.mode = "normal")
  
}
