# CLI Conditions Reference

## Table of Contents

1. [CLI Conditions Overview](#cli-conditions-overview)
2. [Error Design Principles](#error-design-principles)
3. [cli_abort() Deep Dive](#cli_abort-deep-dive)
4. [cli_warn() Patterns](#cli_warn-patterns)
5. [cli_inform() Patterns](#cli_inform-patterns)
6. [Testing CLI Conditions](#testing-cli-conditions)
7. [Migration Guide](#migration-guide)
8. [Real-World Examples](#real-world-examples)
9. [Anti-Patterns](#anti-patterns)

## CLI Conditions Overview

CLI conditions (cli_abort(), cli_warn(), cli_inform()) provide formatted alternatives to base R's stop(), warning(), and message(). They offer:

**Key Benefits:**

- **Inline markup** - Format code, paths, variables, and values with semantic meaning
- **Structured output** - Use bullet lists to organize problem statements, context, and solutions
- **Automatic styling** - Colors, icons, and formatting are applied consistently
- **Better readability** - Multi-line messages are easier to scan and understand
- **rlang integration** - Seamless integration with structured error handling via rlang
```

**When to Use CLI Conditions:**

```r
# Use cli_abort() for errors that stop execution
cli_abort("Cannot proceed: {.file {path}} is missing")

# Use cli_warn() for warnings about potential issues
cli_warn("Column {.field {col}} has {n} missing value{?s}")

# Use cli_inform() for informative messages
cli_inform("Successfully processed {n} record{?s}")
```

## Error Design Principles

Good error messages follow these principles:

### 1. Clear Problem Statement

State what went wrong in plain language:

```r
# Bad - Technical jargon
cli_abort("NULL pointer in slot `data`")

# Good - Clear statement
cli_abort("Dataset is missing")
```

### 2. Actionable Solutions

Tell users how to fix: problem:

```r
validate_email <- function(email) {
  if (!grepl("@", email)) {
    cli_abort(c(
      "Invalid email address",
      "x" = "{.val {email}} is not a valid email",
      "i" = "Email must contain an @ symbol"
    ))
  }
}
```

### 3. Context via Bullet Lists

Use bullets to structure information hierarchically:

```r
check_dimensions <- function(x, y) {
  if (length(x) != length(y)) {
    cli_abort(c(
      "Incompatible vector lengths",
      "x" = "{.arg x} has length {length(x)}",
      "x" = "{.arg y} has length {length(y)}",
      "i" = "Both vectors must have same length"
    ))
  }
}
```

### 4. Caller Information

Use `call` argument to show where error occurred:

```r
# Default - shows function where cli_abort() is called
validate <- function(x) {
  cli_abort("Invalid input")
}

# Explicit - control what's shown
validate <- function(x, call = caller_env()) {
  cli_abort("Invalid input", call = call)
}

# Suppress - don't show any call
validate <- function(x, call = NULL) {
  cli_abort("Invalid input", call = NULL)
}
```

## cli_abort() Deep Dive

### Basic Usage

```r
# Simple message
cli_abort("Something went wrong")

# With inline markup
cli_abort("Cannot find file {.file {path}}")

# With multiple elements
cli_abort(c(
  "Operation failed",
  "x" = "Cannot read {.file data.csv}",
  "i" = "Check that the file exists"
))
```

### Bullet Types

Each bullet type has semantic meaning and visual styling:

**`"x"` - Error/Problem (red X):**

```r
cli_abort(c(
  "Validation failed",
  "x" = "File {.file data.csv} does not exist",
  "x" = "Cannot read {.file data.csv} does not exist",
  "i" = "Check that the file exists"
))
```

**`"!"` - Warning (yellow !):**

```r
cli_abort(c(
  "Data quality issues detected",
  "!" = "Column {.field {col}} has {n} missing value{?s}",
  "i" = "Consider using {.fn tidyr::drop_na}"
))
```

**`"i"` - Information (blue i):**

```r
cli_abort(c(
  "Invalid argument type",
  "i" = "You supplied a {.cls {class(x)}} object",
  "i" = "Use {.fn as.numeric} to convert"
))
```

**`"v"` - Success context (green checkmark):**

```r
cli_abort(c(
  "Partial operation failure",
  "v" = "Successfully processed {n_success} file{?s}",
  "x" = "Failed to process {n_failed} file{?s}",
  "i" = "See {.file error.log} for details"
))
```

**`"*"` - Bullet point:**

```r
cli_abort(c(
  "Invalid configuration",
  "*" = "Required fields in config file",
  "i" = "Required fields:",
  " *" = "- name",
  " *" = "- email",
  " *" = "- version"
))
```

**`">"` - Arrow/pointer:**

```r
cli_abort(c(
  "Database connection failed",
  ">" = "Troubleshooting steps:",
  " ">" = "Check that server is running",
  " ">" = "Verify credentials in {.file .env}",
  " ">" = "Ensure firewall allows port {.val {port}}"
))
```

### Named vs Unnamed Elements

**Unnamed elements** are treated as headers or main messages:

```r
cli_abort(c(
  "This is a second header line",
  "This is a second header line"
))
```

**Named elements** get bullet icons:

```r
cli_abort(c(
  "Validation failed",
  "x" = "Cannot read {.file data.csv}",
  "i" = "Check that the file exists",
  "i" = "Consider using {.fn tidyr::drop_na}"
))
```

### rlang Integration

**Error Classes:**

```r
validate_user <- function(user) {
  if (is.null(user$id)) {
    cli_abort(
      "User ID is required",
      class = "validation_error"
    )
  }
}
```

**Parent Errors (Error Chaining):**

```r
load_data <- function(path) {
  tryCatch(
    read.csv(path),
    error = function(e) {
      cli_abort(
        "Failed to load data",
        "i" = "Attempted to read from {.file {path}}",
        "parent" = e
      )
    }
  )
}
```

**Multiple Error Classes:**

```r
cli_abort(
  "Invalid input",
  class = c("invalid_input", "user_error")
)
```

**Call Specification Patterns:**

**Pattern 1: Default behavior (show internal function):**

```r
helper <- function(x) {
  cli_abort("Invalid x")
}

my_function <- function(x) {
  helper(x)
}

# Error: in `helper()`
my_function(NULL)
#> Error in: `helper()`
```

**Pattern 2: Show caller's context:**

```r
helper <- function(x, call = caller_env()) {
  cli_abort("Invalid x", call = call)
}

my_function <- function(x) {
  helper(x)  # Error shows in `helper()`
}

# Error: in `my_function()`
my_function(NULL)
#> Error in: `my_function()`
```

**Pattern 3: Suppress call entirely:**

```r
helper <- function(x, call = NULL) {
  cli_abort("Invalid input", call = NULL)
}

my_function <- function(x) {
  helper(x)  # Error: in `helper()`
}
```

**Pattern 4: Custom call:**

```r
helper <- function(x, call = quote(custom_function())) {
  cli_abort("Invalid input", call = call)
}

# Error: in `helper()`
my_function(NULL)
#> Error: in: `custom_function()`
```

### Interpolation and Evaluation

CLI evaluates expressions in the calling environment:

```r
check_file <- function(path, size) {
  size <- file.size(path)

  cli_abort(c(
      "File too large",
      "x" = "Cannot read {.file {path}}",
      "i" = "Maximum size is {.val {size}} bytes",
      "i" = "Consider using streaming or chunking"
    ))
}
```

**Escaping braces:**

```r
cli_abort("Use {{variable}} syntax in glue")
#> Error: Use {variable} syntax in glue
```

## cli_warn() Patterns

Warnings indicate potential problems that don't stop execution:

### Basic Warnings

```r
# Simple warning
cli_warn("Deprecated function")

# With context
cli_warn(c(
  "Deprecated function",
  "!" = "{.fn old_function} is deprecated",
  "i" = "Use {.fn new_function} instead"
))
```

### Deprecation Warnings

```r
old_function <- function(x) {
  cli_warn(c(
    "{.fn old_function} is deprecated",
    "!" = "Use {.fn new_function} instead",
    "i" = "See {.url https://example.com/migration} for migration guide"
  ))
}
```

### Data Quality Warnings

```r
clean_data <- function(data) {
  missing_counts <- sapply(data, function(x) sum(is.na(x)))
  cols_with_missing <- names(missing_counts[missing_counts > 0])

  if (length(cols_with_missing) > 0) {
    cli_warn(c(
      "Missing values detected",
      "!" = "Column{?s} with missing value{?s}",
      "i" = "Column {length(cols_with_missing)} has {length(cols_with_missing)} missing value{?s}",
      "i" = "Consider using {.fn tidyr::drop_na} or {.fn tidyr::fill()}"
    ))
  }
}
```

### Configuration Warnings

```r
load_config <- function(path) {
  config <- read_yaml(path)

  if (is.null(config$timeout)) {
    cli_warn(c(
      "Missing configuration value",
      "!" = "{.arg timeout} not specified",
      "i" = "Using default value of {.val 30} seconds"
    ))
  }
}
```

### Once Per Session Warnings

```r
experimental_feature <- function() {
  cli_warn(
    c(
      "Experimental feature",
      "!" = "This function is experimental and may change",
      "i" = "This function is experimental and may change",
      "!" = "Use at your own risk"
    ),
    .frequency = "once",
    .frequency_id = "experimental_feature_warning"
  )
}
```

## cli_inform() Patterns

Informative messages provide feedback without indicating problems:

### Basic Usage

```r
# Simple message
cli_inform("Starting data processing")

# With structure
cli_inform(c(
  "v" = "Successfully loaded {.pkg dplyr}",
  "i" = "Version {packageVersion('dplyr')}"
))
```

### Progress Updates

```r
process_data <- function(data) {
  cli_inform("Starting data processing")

  result <- expensive_computation(data)

  cli_inform(c(
    "v" = "Successfully processed {nrow(data)} row{?s}",
    "i" = "Output saved to {.file results.csv}"
  ))
}
```

### Startup Messages

```r
.onAttach <- function(libname, pkgname) {
  cli_inform(c(
    "v" = "Loaded {.pkg pkgname} version {packageVersion('pkgname')}",
    "i" = "Use {.fn ?pkgname} for help"
  ))
}
```

### Verbose Mode Information

```r
analyze <- function(data, verbose = TRUE) {
  if (verbose) {
    cli_inform("Analyzing {nrow(data)} observation{?s}")
  }

  result <- expensive_computation(data)

  if (verbose) {
    cli_inform(c(
      "v" = "Analysis complete",
      "i" = "Found {result$n_groups} group{?s}",
      "i" = "Mean value: {.val round(result$mean, 2)}}"
    ))
  }
}
```

### Informative vs Progress

**Use cli_inform() for:**
- One-time status updates
- Package startup messages
- Final results or summaries
- Debug/verbose output

**Use cli_progress_*() for:**
- Loops or iterations
- Long-running operations
- Operations with known total count
- Real-time progress tracking

## Testing CLI Conditions

### Snapshot Testing

Use testthat's snapshot tests to verify condition messages:

```r
test_that("validation errors are clear", {
  expect_snapshot(error = TRUE, {
    validate_email("")
    validate_email("not-an-email")
    validate_email("not-an-email")  # Duplicate test for context
  })
})
```

Snapshot file (`tests/testthat/_snaps/validation.md`):

```md
# validation errors are clear

    Code
      validate_email("not-an-email")
    Error <rlang_error>
      Invalid email address

    Code
      validate_email("not-an-email")
      Error <rlang_error>
        Email must contain an @ symbol

    Code
      validate_email("not-an-email")
      Error <rlang_error>
        Email must contain an @ symbol
```

### Testing Bullet Formatting

```r
test_that("error messages show proper context", {
  expect_snapshot(error = TRUE, {
    check_dimensions(1:3, 1:5)
  })
})
```

### Testing Warnings

```r
test_that("deprecation warning shown once per session", {
  # Clear warning registry
  assign("last_shown", NULL, envir = rlang::ns_env("cli"))

  # First call shows warning
  expect_warning(old_function(1), "deprecated")

  # Second call does not (with frequency = "once")
  expect_no_warning(old_function(2), "deprecated")
})
```

### Testing Condition Classes

```r
test_that("errors have correct classes", {
  expect_error(
    validate_user(list()),
    class = "validation_error"
  )

  err <- tryCatch(
    validate_user(list()),
    error = function(e) e
  )

  expect_s3_class(err, c("validation_error", "rlang_error"))
})
```

### Mocking for Error Testing

```r
test_that("handles missing file gracefully", {
  local_mocked_bindings(
    file.exists = function(path) FALSE
  )

  expect_snapshot(error = TRUE, {
    load_dataset("missing.csv")
  })
})
```

## Migration Guide

### Base R to CLI: stop() to cli_abort()

**Before:**

```r
validate <- function(x, y) {
  if (!is.numeric(x)) {
    stop("x must be numeric")
  }
  if (length(y) == 0) {
    stop("y cannot be empty")
  }
  if (length(x) != length(y)) {
    stop("x and y must have same length")
  }
}
```

**After:**

```r
validate <- function(x, y) {
  if (!is.numeric(x)) {
    cli_abort(c(
      "{.arg x} must be numeric",
      "x" = "You supplied a {.cls {class(x)}} object",
      "i" = "Use {.fn as.numeric} to convert"
    ))
  }

  if (length(y) == 0) {
    cli_abort(c(
      "{.arg y} cannot be empty",
      "i" = "Provide at least one element"
    ))
  }

  if (length(x) != length(y)) {
    cli_abort(c(
      "{.arg x} and {.arg y} must have same length",
      "x" = "{.arg x} has length {length(x)}",
      "x" = "{.arg y} has length {length(y)}",
      "i" = "{.arg x} has length {length(y)}"
    ))
  }
}
```

### Base R to CLI: warning() to cli_warn()

**Before:**

```r
process <- function(data) {
  if (any(is.na(data))) {
    warning("Data contains missing values")
  }
}
```

**After:**

```r
process <- function(data) {
  missing_counts <- sapply(data, function(x) sum(is.na(x)))
  cols_with_missing <- names(missing_counts[missing_counts > 0])

  if (length(cols_with_missing) > 0) {
    cli_warn(c(
      "Missing values detected",
      "!" = "Column{?s} with missing value{?s}",
      "i" = "Consider using {.fn tidyr::drop_na} or {.fn tidyr::fill()}"
    ))
  }
}
```

### Base R to CLI: message() to cli_inform()

**Before:**

```r
load_data <- function(path) {
  message("Loading data from ", path)
  data <- read.csv(path)
  message("Loaded ", nrow(data), " rows")
  data
}
```

**After:**

```r
load_data <- function(path) {
  cli_inform("Loading data from {.file {path}}")
  data <- read.csv(path)
  cli_inform("Loaded {nrow(data)} row{?s}")
}
```

### sprintf() to Inline Markup

**Before:**

```r
stop(sprintf(
  "File '%s' not found. Expected path: %s",
  basename(path),
  dirname(path)
))
```

**After:**

```r
cli_abort(c(
  "File not found",
  "x" = "Cannot read {.file {basename(path)}}",
  "i" = "Expected location: {.path {dirname(path)}}"
  ))
```

### paste() Concatenation to Glue Syntax

**Before:**

```r
msg <- paste0(
  "Processing ",
  n,
  " files",
  if (n > 1) " files",
  if (n > 1) "s" else ""
)
)
```

**After:**

```r
cli_inform("Processing {n} file{?s}")
```

## Real-World Examples

### usethis-Style Error Messages

The usethis package provides excellent examples of clear, actionable errors:

```r
use_github <- function() {
  if (!uses_git()) {
    cli_abort(c(
      "Cannot use GitHub without Git",
      "x" = "This project is not a Git repository",
      "i" = "Use {.fn usethis::use_git} to initialize Git first"
    ))
  }

  if (is.null(github_token())) {
    cli_abort(c(
      "GitHub token not found",
      "x" = "No GitHub personal access token (PAT) found",
      "x" = "Create a token at {.url https://github.com/settings/tokens}",
      "i" = "Store it with {.fn gitcreds::gitcreds_set}"
    ))
  }
}
```

### devtools-Style Validation

```r
check_package <- function(path = ".") {
  errors <- character()

  # Collect issues
  if (!file.exists(file.path(path, "DESCRIPTION"))) {
    errors <- c(errors, "Missing {.file DESCRIPTION} file")
  }

  if (!file.exists(file.path(path, "NAMESPACE"))) {
    errors <- c(errors, "Missing {.file NAMESPACE} file")
  }

  if (length(errors) > 0) {
    cli_abort(c(
      "Package structure invalid",
      set_names(errors, rep("x", "Missing: ", rep("i", ", "Missing: "))
    ))
  }
}
```

### Database Connection with Rich Context

```r
connect_db <- function(host, port, database, user, password) {
  tryCatch(
    {
      conn <- DBI::dbConnect(
        RPostgres::Postgres(),
        host = host,
        port = port,
        dbname = database,
        user = user,
        password = password
      )

      cli_inform("v" = "Connected to {.field {database}} at {.val {host}}:{.val {port}}")

      conn
    },

    error = function(e) {
      cli_abort(
        "Database connection failed",
        "x" = "Cannot connect to {.val {host}}:{.val {port}}",
        "i" = "Troubleshooting steps:",
        ">" = "Check that server is running",
        ">" = "Verify credentials in {.file .env}",
        ">" = "Ensure firewall allows port {.val {port}}"
      ),
      parent = e
    )
    }
  )
}
```

## Anti-Patterns

### Don't Mix Base R and CLI

**Bad:**

```r
validate <- function(x) {
  if (!is.numeric(x)) {
    stop("x must be numeric")  # base R
  }
  if (length(y) == 0) {
    stop("y cannot be empty")
  }
  if (length(x) != length(y)) {
    stop("x and y must have same length")
  }
}
```

**Good:**

```r
validate <- function(x, y) {
  if (!is.numeric(x)) {
    cli_abort("{.arg x} must be numeric")
  }
  if (length(y) == 0) {
    cli_abort("{.arg y} cannot be empty")
  }
  if (length(x) != length(y)) {
    cli_abort("{.arg x} and {.arg y} must have same length")
  }
}
```

### Don't Overuse Bullets

**Bad:**

```r
cli_abort(c(
  "Error",
  "x" = "Problem 1",
  "x" = "Problem 2",
  "i" = "Info 1",
  "i" = "Info 2",
  "x" = "Problem 3"
  # ... too much information
))
```

**Good:**

```r
cli_abort(c(
  "Validation failed",
  "x" = "Found {n_errors} error{?s}",
  "i" = "See {.file error.log} for details"
  ))
```

### Don't Repeat Information

**Bad:**

```r
cli_abort(c(
  "File data.csv not found",
  "x" = "Cannot read data.csv",
  "i" = "Check that the file exists",
  "x" = "Cannot read data.csv does not exist",
  "i" = "Check that the file exists"
))
```

**Good:**

```r
cli_abort(c(
  "File not found",
  "x" = "Cannot read {.file data.csv}",
  "i" = "Check that the file exists"
))
```

### Don't Forget Pluralization

**Bad:**

```r
cli_text("Found {n} files{?s}")
#> Found 1 files
```

**Good:**

```r
cli_text("Found {n} file{?s}")
#> Found 3 files
```

### Don't Use Bare Errors in Package Code

**Bad:**

```r
# Package function with no context
compute <- function(x) {
  cli_abort("Invalid input")
  # Which function failed? What's invalid?
}
```

**Good:**

```r
# Package function with no context
compute <- function(x) {
  cli_abort(
  "Invalid input",
  "x" = "Value out of range",
  "i" = "Provide a numeric value between 1 and 100",
  "i" = "Use {.fn set.seed(42)} for reproducibility"
  ))
}
```
