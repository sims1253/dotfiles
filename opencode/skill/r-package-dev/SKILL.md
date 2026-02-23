---
name: r-package-dev
description: >
  R package development best practices including dependency management, API design,
  DESCRIPTION/NAMESPACE configuration, roxygen2 documentation, and migration patterns
  from base R to tidyverse. Use when developing R packages or modernizing R code.
---

# Package Development Decision Guide

## Dependency Strategy

### When to Add Dependencies vs Base R

**Add dependency when:**
- Significant functionality gain
- Maintenance burden reduction
- User experience improvement
- Complex implementation (regex, dates, web)

**Use base R when:**
- Simple utility functions
- Package will be widely used (minimize deps)
- Dependency is large for small benefit
- Base R solution is straightforward

```r
# Example decisions:
str_detect(x, "pattern")    # Worth stringr dependency
length(x) > 0              # Don't need purrr for this
parse_dates(x)             # Worth lubridate dependency
x + 1                      # Don't need dplyr for this
```

### Tidyverse Dependency Guidelines

**Core tidyverse (usually worth it):**
- dplyr - Complex data manipulation
- purrr - Functional programming, parallel
- stringr - String manipulation
- tidyr - Data reshaping

**Specialized tidyverse (evaluate carefully):**
- lubridate - If heavy date manipulation
- forcats - If many categorical operations
- readr - If specific file reading needs
- ggplot2 - If package creates visualizations

**Heavy dependencies (use sparingly):**
- tidyverse - Meta-package, very heavy
- shiny - Only for interactive apps

## API Design Patterns

### Function Design Strategy

```r
# 1. Use .by for per-operation grouping
my_summarise <- function(.data, ..., .by = NULL) {
  # Support modern grouped operations
}

# 2. Use {{ }} for user-provided columns
my_select <- function(.data, cols) {
  .data |> select({{ cols }})
}

# 3. Use ... for flexible arguments
my_mutate <- function(.data, ..., .by = NULL) {
  .data |> mutate(..., .by = {{ .by }})
}

# 4. Return consistent types (tibbles, not data.frames)
my_function <- function(.data) {
  result |> tibble::as_tibble()
}
```

### Input Validation Strategy

**User-facing functions - comprehensive validation:**
```r
user_function <- function(x, threshold = 0.5) {
  if (!is.numeric(x)) stop("x must be numeric")
  if (!is.numeric(threshold) || length(threshold) != 1) {
    stop("threshold must be a single number")
  }
  # ... function body
}
```

**Internal functions - minimal validation:**
```r
.internal_function <- function(x, threshold) {
  # Assume inputs are valid (document assumptions)
  # ... function body
}
```

**Package functions with vctrs - type-stable validation:**
```r
safe_function <- function(x, y) {
  x <- vec_cast(x, double())
  y <- vec_cast(y, double())
  # Automatic type checking and coercion
}
```

## Error Handling Patterns

```r
# Good error messages - specific and actionable
if (length(x) == 0) {
  cli::cli_abort(
    "Input {.arg x} cannot be empty.",
    "i" = "Provide a non-empty vector."
  )
}

# Include function name in errors
validate_input <- function(x, call = caller_env()) {
  if (!is.numeric(x)) {
    cli::cli_abort("Input must be numeric", call = call)
  }
}

# Use consistent error styling
# cli package for user-friendly messages
# rlang for developer tools
```

## When to Create Internal vs Exported Functions

### Export Function When:
- Users will call it directly
- Other packages might want to extend it
- Part of the core package functionality
- Stable API that won't change often

### Keep Function Internal When:
- Implementation detail that may change
- Only used within package
- Complex implementation helpers
- Would clutter user-facing API

```r
# Example: main data processing functions
#' @export
user_facing_function <- function(.data, ...) {
  # Comprehensive input validation
  # Full documentation required
}

# Example: helper functions (not exported)
.internal_helper <- function(x, y) {
  # Minimal documentation
  # Can change without breaking users
}
```

## Testing and Documentation Strategy

### Testing Levels

```r
# Unit tests - individual functions
test_that("function handles edge cases", {
  expect_equal(my_func(c()), expected_empty_result)
  expect_error(my_func(NULL), class = "my_error_class")
})

# Integration tests - workflow combinations
test_that("pipeline works end-to-end", {
  result <- data |>
    step1() |>
    step2() |>
    step3()
  expect_s3_class(result, "expected_class")
})
```

### Documentation Priorities

**Must document:**
- All exported functions
- Complex algorithms or formulas
- Non-obvious parameter interactions
- Examples of typical usage

**Can skip documentation:**
- Simple internal helpers
- Obvious parameter meanings
- Functions that just call other functions

---

# Migration Reference

## From Base R to Modern Tidyverse

### Data Manipulation

| Base R | Tidyverse |
|--------|-----------|
| `subset(data, condition)` | `filter(data, condition)` |
| `data[order(data$x), ]` | `arrange(data, x)` |
| `aggregate(x ~ y, data, mean)` | `summarise(data, mean(x), .by = y)` |

### Functional Programming

| Base R | Tidyverse |
|--------|-----------|
| `sapply(x, f)` | `map(x, f)` (type-stable) |
| `lapply(x, f)` | `map(x, f)` |

### String Manipulation

| Base R | stringr |
|--------|---------|
| `grepl("pattern", text)` | `str_detect(text, "pattern")` |
| `gsub("old", "new", text)` | `str_replace_all(text, "old", "new")` |
| `substr(text, 1, 5)` | `str_sub(text, 1, 5)` |
| `nchar(text)` | `str_length(text)` |
| `strsplit(text, ",")` | `str_split(text, ",")` |
| `paste0(a, b)` | `str_c(a, b)` |
| `tolower(text)` | `str_to_lower(text)` |

## From Old to New Tidyverse Patterns

### Pipes

```r
# Old
data %>% function()

# New
data |> function()
```

### Grouping (dplyr 1.1+)

```r
# Old
group_by(data, x) |>
  summarise(mean(y)) |>
  ungroup()

# New
summarise(data, mean(y), .by = x)
```

### Column Selection

```r
# Old (for selection only)
across(starts_with("x"))

# New
pick(starts_with("x"))
```

### Joins

```r
# Old
by = c("a" = "b")

# New
by = join_by(a == b)
```

### Multi-Row Summaries

```r
# Old
summarise(data, x, .groups = "drop")

# New
reframe(data, x)
```

### Data Reshaping

```r
# Old (deprecated)
gather()
spread()

# New
pivot_longer()
pivot_wider()
```

### String Separation (tidyr 1.3+)

```r
# Old
separate(col, into = c("a", "b"))
extract(col, into = "x", regex)

# New
separate_wider_delim(col, delim = "_", names = c("a", "b"))
separate_wider_regex(col, patterns = c(x = regex))
```

## Quick Conversion Checklist

When modernizing R code:

1. [ ] Replace `%>%` with `|>`
2. [ ] Replace `group_by() |> summarise() |> ungroup()` with `.by`
3. [ ] Replace `by = c("a" = "b")` with `join_by(a == b)`
4. [ ] Replace `sapply()` with `map_*()` functions
5. [ ] Replace base string functions with stringr
6. [ ] Replace `map_dfr()` with `map() |> list_rbind()`
7. [ ] Replace `gather()/spread()` with `pivot_longer()/pivot_wider()`
