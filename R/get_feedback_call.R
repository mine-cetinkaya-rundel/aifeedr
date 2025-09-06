#' Call the Gradio backend
#' 
#' Function to call the Gradio backend LLM with the 
#' homework_name and student answer.
#' 
#' The feedback returned is in a funky format because 
#' Gradio's API only supports streaming results so we 
#' don't get nice clean JSON. Instead we get a line of 
#' text with the event status followed by the actual 
#' LLM with `\n` and `"` escaped something like the following:
#' 
#' ```r
#' "event: complete\ndata: [\"The question is:\\n\\nThe `midwest` data frame...\n]\n\n"
#' ```
#' @param homework_name Homework name of format homeworkXqY 
#' where X is the homework number and Y is the question number.
#' @param student_answer Student answer.
#' @param container_name Name of container.
#' @examples
#' feedback <- get_feedback_call(
#'   homework_name = "homework1-q1",
#'   student_answer = "give me the question",
#'   container_name = "container_hostname_as_a_session_id"
#' )
#' feedback
#' @importFrom httr POST GET status_code content_type accept content
#' @importFrom jsonlite fromJSON toJSON
#' @export
get_feedback_call <- function(homework_name, student_answer, container_name) {
  
  # Step 1: Prepare the POST request body
  body_data <- list(
    data = c(homework_name, student_answer, container_name)
  )
  
  # Step 2: Convert to JSON
  json_body <- toJSON(body_data, auto_unbox = TRUE)
  
  # Step 3: Send POST request with exception handling
  post_url <- "https://chatbot-az-00.oit.duke.edu:5443/gradio_api/call/predict/"  # Deploy
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
  get_url <- paste0("https://chatbot-az-00.oit.duke.edu:5443/gradio_api/call/predict/", event_id) # Deploy
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
