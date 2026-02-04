# Capture selected text and launch Shiny app for feedback

An RStudio addin that captures the currently selected text in the editor
or console, returns it as a character vector that is stored as a system
variable, that is then passed on to the feedback getting Shiny app that
is launched.

## Usage

``` r
get_feedback()
```

## Value

A character vector containing the selected text. If no text is selected,
returns an empty character vector.

## Details

Users interact with this function through the Get feedback addin.
