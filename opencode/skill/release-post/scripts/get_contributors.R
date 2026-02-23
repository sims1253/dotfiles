#' Get Contributors for a Release Post
#'
#' This script generates a formatted list of contributors for tidyverse release blog posts.
#' It fetches commit history from GitHub and identifies contributors.
#'
#' @param from Start date (YYYY-MM-DD)
#' @param end End date (YYYY-MM-DD)
#' @param package Package name (e.g., "dplyr", "ggplot2")
#' @param repo Repository owner/package (defaults to "tidyverse/{package}")
#' @return A data frame with contributor information
#' @examples
#' \dontrun{
#' # Get contributors for a release
#' contributors <- get_contributors(
#'   from = "2023-01-01",
#'   to = "2023-12-31",
#'   package = "dplyr"
#' )
#'
#' # Format for blog post
#' formatted <- format_contributors(contributors)
#' cat(formatted)
#' }

get_contributors <- function(
  from,
  to,
  package,
  repo = paste0("tidyverse/", package)
) {
  # Check required packages
  if (!requireNamespace("gh", quietly = TRUE)) {
    cli_abort("Please install the 'gh' package: install.packages('gh')")
  }

  if (!requireNamespace("lubridate", quietly = TRUE)) {
    cli_abort(
      "Please install the 'lubridate' package: install.packages('lubridate')"
    )
  }

  cli_inform("Fetching commit history from {repo}...")

  # Fetch commits
  commits <- gh::gh(
    "GET /repos/{repo}/commits",
    owner = strsplit(repo, "/")[[1]][1],
    repo = strsplit(repo, "/")[[1]][2],
    since = from,
    until = to,
    .limit = 500
  )

  cli_inform("Found {length(commits)} commits")

  # Extract contributors
  contributors <- purrr::map_dfr(
    commits,
    ~ {
      tibble::tibble(
        author = .x$commit$author$name,
        username = if (!is.null(.x$author$login)) {
          .x$author$login
        } else {
          NA_character_
        },
        date = as.Date(.x$commit$author$date),
        message = .x$commit$message,
        pr_number = NA_integer_
      )
    }
  )

  # Try to get PR numbers from commit messages
  contributors <- contributors |>
    dplyr::mutate(
      pr_number = dplyr::case_when(
        stringr::str_detect(message, "\\(#\\d+\\)") ~
          stringr::str_extract(message, "\\(#\\d+\\)") |>
          stringr::str_remove_all("[()]") |>
          as.integer(),
        TRUE ~ NA_integer_
      )
    )

  # Get PR authors if we have PR numbers
  pr_contributors <- contributors |>
    dplyr::filter(!is.na(pr_number)) |>
    dplyr::distinct(pr_number, .keep_all = TRUE)

  if (nrow(pr_contributors) > 0) {
    cli_inform(
      "Fetching PR author information for {nrow(pr_contributors)} PRs..."
    )

    pr_authors <- purrr::map_dfr(
      pr_contributors$pr_number,
      ~ {
        tryCatch(
          {
            pr <- gh::gh(
              "GET /repos/{repo}/pulls/{pull_number}",
              owner = strsplit(repo, "/")[[1]][1],
              repo = strsplit(repo, "/")[[1]][2],
              pull_number = .
            )
            tibble::tibble(
              pr_number = .,
              pr_author = if (!is.null(pr$user$login)) {
                pr$user$login
              } else {
                NA_character_
              }
            )
          },
          error = function(e) {
            tibble::tibble(pr_number = ., pr_author = NA_character_)
          }
        )
      }
    )

    # Merge PR authors
    contributors <- contributors |>
      dplyr::left_join(pr_authors, by = "pr_number") |>
      dplyr::mutate(
        username = dplyr::coalesce(username, pr_author)
      ) |>
      dplyr::select(-pr_author)
  }

  # Remove duplicates based on username
  contributors <- contributors |>
    dplyr::filter(!is.na(username)) |>
    dplyr::distinct(username, .keep_all = TRUE) |>
    dplyr::arrange(date)

  cli_inform("Found {nrow(contributors)} unique contributors")

  contributors
}


#' Get First-Time Contributors
#'
#' Identifies contributors making their first contribution to a repository.
#'
#' @param contributors Data frame from get_contributors()
#' @param repo Repository in "owner/repo" format
#' @return Data frame of first-time contributors
#' @examples
#' \dontrun{
#' contributors <- get_contributors("2023-01-01", "2023-12-31", "dplyr")
#' first_time <- get_first_time_contributors(contributors, "tidyverse/dplyr")
#' }

get_first_time_contributors <- function(contributors, repo) {
  if (!requireNamespace("gh", quietly = TRUE)) {
    cli_abort("Please install the 'gh' package: install.packages('gh')")
  }

  cli_inform("Checking first-time contributors for {repo}...")

  first_time <- purrr::map_dfr(
    contributors$username,
    ~ {
      tryCatch(
        {
          # Get first contribution date for this user
          events <- gh::gh(
            "GET /repos/{repo}/events",
            owner = strsplit(repo, "/")[[1]][1],
            repo = strsplit(repo, "/")[[1]][2],
            .limit = 100
          )

          user_events <- purrr::keep(
            events,
            ~ {
              if (!is.null(.x$actor$login) && .x$actor$login == .x) {
                TRUE
              } else if (!is.null(.x$actor_login) && .x$actor_login == .x) {
                TRUE
              } else {
                FALSE
              }
            }
          )

          if (length(user_events) == 0) {
            # User has no events, likely first-time
            tibble::tibble(
              username = .x,
              first_contribution = TRUE
            )
          } else {
            tibble::tibble(
              username = .x,
              first_contribution = FALSE
            )
          }
        },
        error = function(e) {
          tibble::tibble(username = .x, first_contribution = NA)
        }
      )
    }
  )

  dplyr::filter(first_time, first_contribution == TRUE)
}


#' Format Contributors for Blog Post
#'
#' Creates formatted contributor list for tidyverse release posts.
#'
#' @param contributors Data frame from get_contributors()
#' @param style Style of output: "bullet" or "paragraph"
#' @return Formatted text string
#' @examples
#' \dontrun{
#' contributors <- get_contributors("2023-01-01", "2023-12-31", "dplyr")
#' formatted <- format_contributors(contributors)
#' cat(formatted)
#' }

format_contributors <- function(contributors, style = "bullet") {
  if (!requireNamespace("glue", quietly = TRUE)) {
    cli_abort("Please install the 'glue' package: install.packages('glue')")
  }

  links <- purrr::map_chr(
    contributors$username,
    ~ {
      glue::glue("[@{.}](https://github.com/{.})")
    }
  )

  if (style == "bullet") {
    formatted <- paste0("- ", links, collapse = "\n")
  } else if (style == "paragraph") {
    formatted <- paste(links, collapse = ", ")
  }

  formatted
}


#' Generate Complete Contributor Section
#'
#' Creates a complete contributor section for a release post.
#'
#' @param from Start date (YYYY-MM-DD)
#' @param to End date (YYYY-MM-DD)
#' @param package Package name
#' @param repo Repository (defaults to tidyverse/{package})
#' @return Complete markdown section
#' @examples
#' \dontrun{
#' section <- generate_contributor_section(
#'   from = "2023-01-01",
#'   to = "2023-12-31",
#'   package = "dplyr"
#' )
#' cat(section)
#' }

generate_contributor_section <- function(
  from,
  to,
  package,
  repo = paste0("tidyverse/", package)
) {
  cli_inform("Generating contributor section for {repo}...")

  # Get all contributors
  contributors <- get_contributors(from, to, package, repo)

  if (nrow(contributors) == 0) {
    cli_inform("No contributors found")
    return("## Contributors\n\nNo contributors for this release.")
  }

  # Get first-time contributors
  first_time <- get_first_time_contributors(contributors, repo)

  # Format contributor lists
  all_contributors <- format_contributors(contributors)
  first_time_contributors <- format_contributors(first_time)

  # Build section
  section <- c(
    "## Contributors",
    "",
    glue::glue(
      "Thank you to the following {nrow(contributors)} contributors who made this release possible:"
    ),
    "",
    all_contributors
  )

  if (nrow(first_time) > 0) {
    section <- c(
      section,
      "",
      glue::glue(
        "A warm welcome to the {nrow(first_time)} first-time contributors:"
      ),
      "",
      first_time_contributors
    )
  }

  paste(section, collapse = "\n")
}


#' Main Function - Run This to Generate Section
#'
#' @param from Start date (YYYY-MM-DD)
#' @param to End date (YYYY-MM-DD)
#' @param package Package name
#' @param repo Repository (optional, defaults to tidyverse/{package})
#' @export
#' @examples
#' \dontrun{
#' # Run interactively to generate contributor section
#' generate_release_contributors(
#'   from = "2023-01-01",
#'   to = "2023-12-31",
#'   package = "dplyr"
#' )
#' }

generate_release_contributors <- function(
  from,
  to,
  package,
  repo = paste0("tidyverse/", package)
) {
  section <- generate_contributor_section(from, to, package, repo)

  # Print to console
  cat(section)

  # Also return invisibly
  invisible(section)
}


# Example usage and documentation
if (FALSE) {
  # Basic usage - get all contributors since last release
  contributors <- get_contributors(
    from = "2023-01-01", # Update with your last release date
    to = "2023-12-31", # Update with current date
    package = "dplyr" # Update with package name
  )

  # Get first-time contributors
  first_time <- get_first_time_contributors(contributors, "tidyverse/dplyr")

  # Format for blog post (bullet list)
  formatted_bullets <- format_contributors(contributors, style = "bullet")

  # Format for blog post (paragraph)
  formatted_paragraph <- format_contributors(contributors, style = "paragraph")

  # Generate complete section
  section <- generate_contributor_section(
    from = "2023-01-01",
    to = "2023-12-31",
    package = "dplyr"
  )

  # Run interactively
  generate_release_contributors(
    from = "2023-01-01",
    to = "2023-12-31",
    package = "dplyr"
  )
}
