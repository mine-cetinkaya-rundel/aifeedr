# app.R
library(stringi)

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

###### shiny app follows #########

library(shiny)

# Define UI for the application
ui <- fluidPage(
  # Application title
  titlePanel("Assignment Feedback System"),
  
  # Homework name input
  textInput("homework_name", "Enter Homework Name"),
  
  # Student answer input
  textAreaInput("student_answer", "Enter Student Answer", rows = 6, cols = 80),
  
  # Submit button
  actionButton("submit", "Submit for Feedback"),
  
  # Feedback display area
  br(),
  h4("Feedback Result:"),
  # textOutput("feedback_result")
  uiOutput("feedback_result")
)

# Define server logic
server <- function(input, output, session) {
  
  # Define the feedback function 
  get_assignmnent_feedback <- function(homework_name, student_answer) {
    # Load required packages
    if (!require("httr")) install.packages("httr")
    if (!require("jsonlite")) install.packages("jsonlite")
    library(httr)
    library(jsonlite)
    
    body_data <- list(
      data = c(homework_name, student_answer)
    )
    json_body <- toJSON(body_data, auto_unbox = TRUE)
    post_url <- "https://chatbot-az-00.oit.duke.edu:5443/gradio_api/call/predict/"  # Replace with actual URL
    post_result <- tryCatch({
      # Attempt the POST request
      response <- POST(
        url = post_url,
        body = json_body,
        content_type("application/json"),
        accept("application/json")
      )
      if (status_code(response) != 200) {
        stop("POST request failed with status code: ", status_code(response))
      }
      response_content <- content(response, "text")
      result <- fromJSON(response_content)
      list(event_id = result$event_id)
    }, error = function(e) {
      list(error = "POST request or parsing error", message = e$message)
    })
    if (!is.null(post_result$error)) {
      return(post_result)
    }
    event_id <- post_result$event_id
    
    get_url <- paste0("https://chatbot-az-00.oit.duke.edu:5443/gradio_api/call/predict/", event_id)
    get_result <- tryCatch({
      response <- GET(url = get_url)
      if (status_code(response) != 200) {
        stop("GET request failed with status code: ", status_code(response))
      }
      result <- content(response, "text")
      result
    }, error = function(e) {
      return( list(error = "GET request or parsing error", message = e$message) )
    })
    
    return(get_result)
  }
  #### end of get_assignmnent_feedback function
  
  # strip the superfluous garbage off the LLM feedback
  clean_result <- function(dirty_input) {
    semi_clean = ''
    prefix <- 'event: complete\ndata: ["'
    suffix <- '"]\n\n'
    if (startsWith(dirty_input, prefix) && endsWith(dirty_input, suffix)) {
      # remove prefix and suffix
      semi_clean <- substr(dirty_input, nchar(prefix) + 1, nchar(dirty_input) - nchar(suffix))
    } else {
      return(dirty_input)
    }
    # extra cleanup for the errors
    e_prefix <- "('Error', \\\""
    e_suffix <- '\\")'
    if (startsWith(semi_clean, e_prefix) && endsWith(semi_clean, e_suffix)) {
      # remove prefix and suffix
      better_clean <- substr(semi_clean, nchar(e_prefix) + 1, nchar(semi_clean) - nchar(e_suffix))
      super_clean <- stri_unescape_unicode(better_clean)
      return(super_clean)
    }
    very_clean <-gsub("\\\\n", "\n", semi_clean)
    return(very_clean)
  }
  
  feedback_value <- reactiveVal("")
  
  observeEvent(input$submit, {
    homework_name <- input$homework_name
    student_answer <- input$student_answer
    raw_result <- get_assignmnent_feedback(homework_name, student_answer)
    
    cleaned_result <- clean_result(raw_result)
    feedback_value(cleaned_result)
  })
  
  # Render Markdown using renderText and HTML
  output$feedback_result <- renderUI({
    # fix the escaped unicode strings before rendering
    md_string <- stri_unescape_unicode( req(feedback_value()) )
    # Convert markdown -> HTML and return as HTML
    HTML(markdown::markdownToHTML(text = md_string, fragment.only = TRUE))
  })
}


# Start the Shiny app
shinyApp(ui = ui, server = server)
