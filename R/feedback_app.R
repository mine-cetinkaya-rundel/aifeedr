#' @import shiny
#' @importFrom stringi stri_unescape_unicode
#' @importFrom markdown markdownToHTML
library(shiny)

feedback_app <- function() {
  # Define UI for the application
  ui <- fluidPage(
    # Application title
    titlePanel("Assignment Feedback System"),

    # Homework name input
    numericInput("homework_number", "Homework number", value = "1", min = 1, step = 1),
    numericInput("question_number", "Question number", value = "1", min = 1, step = 1),
    
    # Student answer input
    textAreaInput("student_answer", "Your answer", value = capture_selection(), rows = 6, cols = 80),

    # Submit button
    actionButton("reset", "Copy selection to answer"),
    actionButton("submit", "Get feedback"),

    # Feedback display area
    br(),
    h4("Feedback Result:"),
    uiOutput("feedback_result")
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
      return(very_clean)
    }

    feedback_value <- reactiveVal("")

    observeEvent(input$submit, {
      # get the name of the container (host) we are running in
      container_hostname <- Sys.info()[["nodename"]]
      print(container_hostname)

      feedback_value("")
      homework_name <- paste0("homework", input$homework_number, "-q", input$question_number)
      student_answer <- input$student_answer
      raw_result <- get_assignmnent_feedback(homework_name, student_answer, container_hostname)

      cleaned_result <- clean_result(raw_result)
      feedback_value(cleaned_result)
    })

    # Reset button: clear text input & reset from capture_selection()
    observeEvent(input$reset, {
      updateTextInput(session, "student_answer", value = capture_selection())
      feedback_value("") # also clear the display
    })


    # Render Markdown using renderText and HTML
    output$feedback_result <- renderUI({
      # fix the escaped unicode strings before rendering
      md_string <- stri_unescape_unicode(req(feedback_value()))
      # Convert markdown -> HTML and return as HTML
      HTML(markdownToHTML(text = md_string, fragment.only = TRUE))
    })
  }


  # Start the Shiny app
  shinyApp(ui = ui, server = server)
}
