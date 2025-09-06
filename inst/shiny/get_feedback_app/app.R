library(aifeedr)
library(shiny)
library(stringi)
library(markdown)
library(shinycssloaders)

# force Shiny apps to open in the Viewer pane
options(shiny.launch.browser = rstudioapi::viewer)

# Define UI for the application
ui <- fluidPage(
  
  tags$style(HTML("
    #student_answer {
      font-family: monospace;
    }
  ")),
  
  # Application title
  titlePanel(HTML("Get feedback from AI &#129302")),
  
  # Instructions
  br(),
  
  p(
    strong("Instructions:"), 
    "Select homework number and input question number, 
      then click the", 
    em("Get feedback"),
    "button to get AI-generated feedback based on a rubric 
      designed by a human -- your course instructor.
      Please be patient, feedback generation can take 
      a few seconds. Once you read the feedback, you can 
      go back to your Quarto document to improve your 
      answer based on the feedback. You will then need
      to click the red X on the top left corner of the Viewer
      pane to stop the feedback app from running
      before you can re-render your Quarto document.", 
    style = "font-size:16px"
  ),
  
  br(),
  
  p(
    strong("Warning:"), 
    "AI can make mistakes, so read the feedback carefully and critically."
  ),
  
  br(),
  
  # Homework name input
  radioButtons("homework_number", "Homework number:", choices = 1:6, selected = 1, inline = TRUE),
  numericInput("question_number", "Question number:", value = "1", min = 1, step = 1),
  
  # Student answer input, not editable
  #textAreaInput("student_answer", "Your answer", value = Sys.getenv("captured_text_for_feedback"), rows = 6, cols = 80),
  tags$div(
    class = "form-group",
    tags$label(`for` = "student_answer", "Your answer:"),
    tags$textarea(
      id = "student_answer",
      class = "form-control",
      readonly = "readonly",
      rows = 10, cols = 80,
      Sys.getenv("captured_text_for_feedback")
    )
  ),
  
  # Submit button
  actionButton("submit", "Get feedback"),
  
  # Feedback display area
  br(),
  br(),
  withSpinner(uiOutput("feedback_result"), type = 4, color = "#3b3b3b"),
  br()
)

# Define server logic
server <- function(input, output, session) {
  
  # strip the superfluous garbage off the LLM feedback
  clean_result <- function(dirty_input) {
    semi_clean <- ""
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
    very_clean <- gsub("\\\\n", "\n", semi_clean)
    very_clean <- gsub("Feedback:", "", very_clean)
    return(very_clean)
  }
  
  feedback_value <- reactive({
    
    # get the name of the container (host) we are running in
    container_hostname <- Sys.info()[["nodename"]]

    homework_name <- paste0("homework", input$homework_number, "-q", input$question_number)
    student_answer <- input$student_answer
    raw_result <- get_feedback_call(homework_name, student_answer, container_hostname)
    
    clean_result(raw_result)

  }) |>
    bindEvent(input$submit)
  
  # Render Markdown using renderText and HTML
  output$feedback_result <- renderUI({
    # fix the escaped unicode strings before rendering
    md_string <- stringi::stri_unescape_unicode(req(feedback_value()))
    # Convert markdown -> HTML and return as HTML
    list(
      h4("AI-generated feedback:"),
      HTML(markdown::markdownToHTML(text = md_string, fragment.only = TRUE))
    )
  })
  
  session$onSessionEnded(stopApp)
}

# Start the Shiny app
shinyApp(ui = ui, server = server)
