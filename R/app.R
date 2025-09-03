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

get_assignmnent_feedback <- function(homework_name, student_answer, container_name) {
  # Load required packages
  if (!require("httr")) install.packages("httr")
  if (!require("jsonlite")) install.packages("jsonlite")
  library(httr)
  library(jsonlite)
  
  # Step 1: Prepare the POST request body
  body_data <- list(
    data = c(homework_name, student_answer, container_name)
  )
  
  # Step 2: Convert to JSON
  json_body <- toJSON(body_data, auto_unbox = TRUE)
  
  # Step 3: Send POST request with exception handling
  post_url <- "https://chatbot-az-00.oit.duke.edu:5443/gradio_api/call/predict/"  # Replace with actual URL
  post_result <- tryCatch({
    # Attempt the POST request
    response <- POST(
      url = post_url,
      body = json_body,
      content_type("application/json"),
      accept("application/json")
    )
    
    # Check for HTTP success
    if (status_code(response) != 200) {
      stop("POST request failed with status code: ", status_code(response))
    }
    
    # Parse the JSON response
    response_content <- content(response, "text")
    result <- fromJSON(response_content)
    list(event_id = result$event_id)
    
  }, error = function(e) {
    # Handle errors during POST request or parsing
    list(error = "POST request or parsing error", message = e$message)
  })
  
  # If an error occurred in POST, return it
  if (!is.null(post_result$error)) {
    return(post_result)
  }
  
  # Step 4: Extract event_id from POST result
  event_id <- post_result$event_id
  
  # Step 5: Send GET request with exception handling
  get_url <- paste0("https://chatbot-az-00.oit.duke.edu:5443/gradio_api/call/predict/", event_id)
  get_result <- tryCatch({
    # Attempt the GET request
    response <- GET(url = get_url)
    
    # Check for HTTP success
    if (status_code(response) != 200) {
      stop("GET request failed with status code: ", status_code(response))
    }
    
    # return the response
    result <- content(response, "text")
    result
    
  }, error = function(e) {
    # Handle errors during GET request or parsing
    return( list(error = "GET request or parsing error", message = e$message) )
  })
  
  # Step 6: Return the final result
  return(get_result)
}
