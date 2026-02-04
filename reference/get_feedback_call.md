# Call the Gradio backend

Function to call the Gradio backend LLM with the homework_name and
student answer.

## Usage

``` r
get_feedback_call(homework_name, student_answer, container_name)
```

## Arguments

- homework_name:

  Homework name of format homeworkXqY where X is the homework number and
  Y is the question number.

- student_answer:

  Student answer.

- container_name:

  Name of container.

## Details

The feedback returned is in a funky format because Gradio's API only
supports streaming results so we don't get nice clean JSON. Instead we
get a line of text with the event status followed by the actual LLM with
`\n` and `"` escaped something like the following:

    "event: complete\ndata: [\"The question is:\\n\\nThe `midwest` data frame...\n]\n\n"

## Examples

``` r
feedback <- get_feedback_call(
  homework_name = "homework1-q1",
  student_answer = "give me the question",
  container_name = "container_hostname_as_a_session_id"
)
feedback
#> $error
#> [1] "POST request or parsing error"
#> 
#> $message
#> [1] "Timeout was reached [chatbot-az-00.oit.duke.edu]:\nFailed to connect to chatbot-az-00.oit.duke.edu port 5443 after 10002 ms: Timeout was reached"
#> 
```
