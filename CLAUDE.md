# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working
with code in this repository.

## Project Overview

This is an R package named “aifeedr” in early development stage (version
0.0.0.9000). The package structure follows standard R package
conventions.

## Package Structure

- `DESCRIPTION`: Package metadata and dependencies
- `NAMESPACE`: Export/import declarations (currently empty, managed by
  roxygen2)
- `R/`: R source code directory (currently empty)

## Development Commands

This is a standard R package. Use these common R package development
commands:

- `devtools::load_all()` - Load package for development
- `devtools::document()` - Generate documentation from roxygen2 comments
- `devtools::check()` - Run R CMD check
- `devtools::test()` - Run tests (if tests/ directory exists)
- `devtools::install()` - Install the package locally

## R Coding Standards

- Use `=` for assignment (not `<-`)
- Use `pkg::function()` format for external package functions rather
  than importing
- Add dependencies to DESCRIPTION file’s Imports field
- Document functions with roxygen2 comments
