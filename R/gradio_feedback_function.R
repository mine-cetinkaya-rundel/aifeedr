#############
# Function to call the Gradio backend LLM with the homework_id and student answer
#
# note that the feedback returned is in a funky format because Gradio's API 
# only supports streaming results so we don't get nice clean JSON. 
# Instead we get a line of text with the event status followed by 
# the actual LLM with \n and " escaped something like this:
#
#   "event: complete\ndata: [\"The question is:\\n\\nThe `midwest` data frame...\n]\n\n"
#
# 
# here is an example function call:
#
# feedback <- get_assignmnent_feedback(
#     homework_name = "homework1-q1",
#     student_answer = "give me the question"
#   )
# print(feedback)
#
############

get_assignmnent_feedback <- function(homework_name, student_answer) {
  # Load required packages
  if (!require("httr")) install.packages("httr")
  if (!require("jsonlite")) install.packages("jsonlite")
  library(httr)
  library(jsonlite)
  
  # Step 1: Prepare the POST request body
  body_data <- list(
    data = c(homework_name, student_answer)
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
  



  