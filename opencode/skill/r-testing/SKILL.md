---
name: r-testing
description: >
  testthat 3rd edition testing patterns with describe/it BDD organization, test fixtures
  using withr, snapshot testing, mocking with local_mocked_bindings, and custom expectations.
  Use when writing R tests, organizing test suites, or using testthat.
---

# Modern testthat Patterns

## testthat 3rd Edition

**Always use edition 3** - activate in DESCRIPTION:
```
Config/testthat/edition: 3
```

### Key Changes from Edition 2
- `context()` deprecated → use file names
- `expect_is()` deprecated → use `expect_type()`, `expect_s3_class()`, `expect_s4_class()`
- `setup()`/`teardown()` deprecated → use test fixtures
- Warnings/messages must be explicitly handled (no silent ignoring)
- Better diffs via waldo package

## BDD Organization with describe/it

**Use `describe()` and `it()` for readable, nested test organization.**

### Basic Structure

```r
describe("my_function()", {

  it("returns expected output type", {
    expect_s3_class(my_function(mtcars), "tbl_df")
  })

  it("preserves row count", {
    result <- my_function(mtcars)
    expect_equal(nrow(result), nrow(mtcars))
  })
})
```

### Nested describe Blocks

```r
describe("calculate_stats()", {
  # Shared setup for all tests in this block
  test_data <- tibble(x = 1:10, y = rnorm(10))

  describe("with default parameters", {
    it("returns mean and sd", {
      result <- calculate_stats(test_data)
      expect_named(result, c("mean", "sd"))
    })

    it("handles single column", {
      result <- calculate_stats(test_data["x"])
      expect_length(result, 2)
    })
  })

  describe("edge cases", {
    it("handles empty input", {
      expect_equal(nrow(calculate_stats(tibble())), 0)
    })

    it("handles NA values", {
      data_with_na <- tibble(x = c(1, NA, 3))
      expect_no_error(calculate_stats(data_with_na))
    })
  })

  describe("error handling", {
    it("errors on non-data.frame input", {
      expect_error(calculate_stats("not a df"), class = "error")
    })

    it("errors on missing required columns", {
      expect_error(calculate_stats(tibble(z = 1)), "required")
    })
  })
})
```

### Benefits of describe/it

- **Shared fixtures**: Variables in parent block accessible to all nested tests
- **Logical grouping**: Organize by feature, edge cases, errors
- **Readable output**: Test failures show full path through describe blocks
- **TDD-friendly**: Empty `it()` blocks auto-skip (write specs before code)
- **Easy refactoring**: Rename function once with `f <- my_function` pattern

### Pattern: Function Alias for Refactoring

```r
describe("process_data()", {
  f <- process_data

  it("transforms input correctly", {
    expect_equal(f(1:3), c(2, 4, 6))
  })

  # If function is renamed, only change the alias
})
```

## Test Fixtures

**Use `withr::local_*` functions instead of setup/teardown.**

### Common Fixtures

```r
describe("file operations", {
  it("writes data correctly", {
    # Temporary file auto-cleaned after test
    path <- withr::local_tempfile(fileext = ".csv")
    write_csv(mtcars, path)
    expect_true(file.exists(path))
  })

  it("respects digits option", {
    withr::local_options(digits = 2)
    expect_equal(format(pi), "3.1")
  })

  it("uses test API endpoint", {
    withr::local_envvar(API_URL = "https://test.example.com")
    expect_equal(get_api_url(), "https://test.example.com")
  })
})
```

### Available withr Fixtures

| Function | Purpose |
|----------|---------|
| `local_tempfile()` | Temporary file (auto-deleted) |
| `local_tempdir()` | Temporary directory |
| `local_options()` | Modify R options |
| `local_envvar()` | Set environment variables |
| `local_dir()` | Change working directory |
| `local_seed()` | Set RNG seed |
| `local_locale()` | Change locale |

### Custom Fixtures

```r
# In tests/testthat/helper-fixtures.R
local_test_db <- function(env = parent.frame()) {
  db <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
  DBI::dbWriteTable(db, "test_data", test_data)
  withr::defer(DBI::dbDisconnect(db), envir = env)
  db
}

# Usage in tests
describe("database operations", {
  it("queries correctly", {
    db <- local_test_db()
    result <- DBI::dbGetQuery(db, "SELECT * FROM test_data")
    expect_equal(nrow(result), 10)
  })
})
```

### Shared Fixtures in describe Blocks

```r
describe("data pipeline", {
  # Fixture available to all nested tests
  withr::local_options(dplyr.summarise.inform = FALSE)
  test_data <- tibble(x = 1:100, group = rep(letters[1:10], 10))

  it("filters correctly", {
    result <- test_data |> filter(group == "a")
    expect_equal(nrow(result), 10)
  })

  it("summarizes correctly", {
    result <- test_data |> summarise(n = n(), .by = group)
    expect_equal(nrow(result), 10)
  })
})
```

## Snapshot Testing

**Use snapshots for complex output that's hard to specify inline.**

### When to Use Snapshots

- Complex error messages
- Formatted text output
- Large data structures
- Plot/image output

### Basic Snapshots

```r
describe("error messages", {
  it("shows informative error for bad input", {
    expect_snapshot(error = TRUE, {
      validate_input("not a number")
    })
  })

  it("shows helpful warning", {
    expect_snapshot({
      result <- process_with_warning(NA)
    })
  })
})
```

### Snapshot with Variable Content

```r
it("reports file path in error", {
  path <- withr::local_tempfile()
  expect_snapshot(
    error = TRUE,
    read_special_file(path),
    transform = \(lines) gsub(path, "<tempfile>", lines, fixed = TRUE)
  )
})
```

### Value Snapshots

```r
it("returns expected structure", {
  result <- build_complex_object()
  expect_snapshot_value(result, style = "json2")
})
```

### Managing Snapshots

```r
# Accept all changes after review
snapshot_accept()

# Review changes interactively (Shiny app)
snapshot_review()
```

## Mocking

**Use mocking as a last resort when you can't control external state.**

### Basic Mocking

```r
describe("package checks", {
  it("errors when package missing", {
    local_mocked_bindings(
      requireNamespace = function(...) FALSE
    )
    expect_error(check_installed("fakepkg"), "not installed")
  })
})
```

### Mocking Time

```r
describe("rate limiter", {
  it("blocks requests within window", {
    current_time <- 0
    local_mocked_bindings(
      Sys.time = function() as.POSIXct(current_time, origin = "1970-01-01")
    )

    limiter <- create_limiter(window = 60)
    expect_true(limiter$allow())

    current_time <- 30
    expect_false(limiter$allow())

    current_time <- 61
    expect_true(limiter$allow())
  })
})
```

### Mocking User Input

```r
describe("interactive prompts", {
  it("accepts y for yes", {
    local_mocked_bindings(
      readline = function(...) "y"
    )
    expect_true(confirm_action("Delete?"))
  })

  it("retries on invalid input", {
    responses <- c("x", "maybe", "y")
    i <- 0
    local_mocked_bindings(
      readline = function(...) {
        i <<- i + 1
        responses[i]
      }
    )
    expect_true(confirm_action("Delete?"))
    expect_equal(i, 3)
  })
})
```

### When NOT to Mock

- Core logic (test real implementation)
- Simple functions you control
- When fixtures can provide the same isolation

## Skipping Tests

### Built-in Skip Helpers

```r
describe("platform-specific features", {
  it("uses Windows API", {
    skip_on_os(c("mac", "linux"))
    # Windows-only test
  })

  it("requires vctrs 0.5+", {
    skip_if_not_installed("vctrs", "0.5.0")
    # Test using new vctrs features
  })

  it("calls external API", {
    skip_on_cran()
    skip_on_ci()
    # Integration test with real API
  })
})
```

### Custom Skip Helpers

```r
# In tests/testthat/helper-skip.R
skip_if_no_api_key <- function() {
  skip_if(
    Sys.getenv("MY_API_KEY") == "",
    "MY_API_KEY environment variable not set"
  )
}

skip_if_offline <- function() {
  skip_if_not(
    curl::has_internet(),
    "No internet connection"
  )
}

# Usage
describe("API integration", {
  it("fetches data", {
    skip_if_no_api_key()
    skip_if_offline()
    result <- fetch_from_api()
    expect_s3_class(result, "tbl_df")
  })
})
```

## Custom Expectations

### Basic Structure

```r
# In tests/testthat/helper-expectations.R
expect_tibble <- function(object, n_rows = NULL, n_cols = NULL) {
  act <- quasi_label(rlang::enquo(object), arg = "object")

  if (!inherits(act$val, "tbl_df")) {
    fail(sprintf("%s is not a tibble (class: %s)", act$lab, class(act$val)[1]))
  }

  if (!is.null(n_rows) && nrow(act$val) != n_rows) {
    fail(sprintf("%s has %d rows, not %d", act$lab, nrow(act$val), n_rows))
  }

  if (!is.null(n_cols) && ncol(act$val) != n_cols) {
    fail(sprintf("%s has %d columns, not %d", act$lab, ncol(act$val), n_cols))
  }

  succeed()
  invisible(act$val)
}

# Usage
it("returns correct dimensions", {
  result <- process_data(input)
  expect_tibble(result, n_rows = 10, n_cols = 5)
})
```

### Chainable Expectations

```r
expect_positive <- function(object) {
  act <- quasi_label(rlang::enquo(object), arg = "object")

  if (any(act$val <= 0, na.rm = TRUE)) {
    fail(sprintf("%s contains non-positive values", act$lab))
  }

  succeed()
  invisible(act$val)  # Return for chaining
}

# Chain expectations
it("returns positive percentages", {
  result <- calculate_percentages(data)
  result |>
    expect_type("double") |>
    expect_positive() |>
    expect_length(10)
})
```

## File Organization

```
tests/
├── testthat.R                 # Boilerplate (don't edit)
└── testthat/
    ├── helper-expectations.R  # Custom expect_* functions
    ├── helper-fixtures.R      # Custom local_* fixtures
    ├── helper-skip.R          # Custom skip_* helpers
    ├── setup.R                # Environment setup (tests only)
    ├── _snaps/                # Snapshot files (auto-generated)
    │   └── test-process.md
    ├── test-process.R         # Tests for R/process.R
    ├── test-validate.R        # Tests for R/validate.R
    └── test-utils.R           # Tests for R/utils.R
```

### File Naming Convention

- Mirror `R/` structure: `R/process.R` → `tests/testthat/test-process.R`
- Helper files: `helper-{purpose}.R`
- One `setup.R` file for environment configuration

## Handling Warnings and Messages

### Edition 3 Strictness

```r
# Warnings must be handled
it("handles expected warning", {
  expect_warning(
    risky_operation(),
    "potential issue"
  )
})

# Multiple warnings
it("handles multiple warnings", {
  risky_operation() |>
    expect_warning("first") |>
    expect_warning("second")
})

# Suppress unimportant warnings
it("focuses on result despite warnings", {
  result <- suppressWarnings(noisy_function())
  expect_equal(result, expected)
})

# Snapshot all output
it("produces expected output", {
  expect_snapshot({
    verbose_function()
  })
})
```

## Quick Reference

### describe/it vs test_that

| Feature | describe/it | test_that |
|---------|-------------|-----------|
| Nesting | Natural, hierarchical | Possible but less idiomatic |
| Shared setup | Variables in parent block | Must use fixtures |
| Output | Full path in failures | Single description |
| Philosophy | BDD - specify behavior | TDD - verify correctness |
| Best for | Feature specifications | Unit tests |
