# Content Guidelines

Guidelines for writing release post content including breaking changes, deprecations, and contributor acknowledgments.

## Breaking Changes

### When to Announce

Announce breaking changes when code that worked previously no longer works:

- Removing or renaming functions/arguments
- Changing default behavior
- Modifying return values
- Changing function signatures

### How to Present

**Clear warning in the title:**

```markdown
# dplyr 1.1.0

## Breaking changes

### `group_by()` now requires `.data` pronoun

Calling `group_by()` with bare column names now requires the `.data` pronoun:

```r
# Old way (deprecated)
group_by(df, column)

# New way (required)
group_by(df, .data[["column"]])
```
```

**Explain the rationale:**

```markdown
This change improves consistency with other tidyverse functions and prepares for future enhancements to scoped verbs.
```

**Provide migration steps:**

```markdown
## Migration guide

### Updating your code

1. Identify usages of bare column names in `group_by()`
2. Replace with `.data[["column_name"]]`
3. Or use `across()` for multiple columns:

```r
# Single column
df |> group_by(.data[["species"]])

# Multiple columns
df |> group_by(across(species, sex))
```
```

**Show before and after:**

```markdown
```r
# Before (dplyr 1.0.0)
mtcars |> group_by(cyl) |> summarise(mpg = mean(mpg))

# After (dplyr 1.1.0)
mtcars |> group_by(.data[["cyl"]]) |> summarise(mpg = mean(mpg))
# Or
mtcars |> group_by(across(cyl)) |> summarise(mpg = mean(mpg))
```
```

## Deprecations

### Deprecation Stages

Use consistent terminology:

- **Soft deprecated** - Warns only when called directly
- **Deprecated** - Warns when called, will be removed
- **Defunct** - No longer works, removed from package

### Announcing Deprecations

```markdown
## Deprecations

### `mutate_each()` is soft deprecated

`mutate_each()` is now soft deprecated as of dplyr 1.1.0. Use `across()` instead:

```r
# Old way (soft deprecated)
mtcars |> mutate_each(funs(mean), mpg, cyl)

# New way
mtcars |> mutate(across(c(mpg, cyl), mean))
```

Soft deprecation means you'll only see a warning when:
- Calling from the console
- Running tests

You won't see a warning when:
- Called from another package
- Used in knitr documents

### `arrange_each()` is deprecated

`arrange_each()` is now deprecated and will be removed in a future version. Use `arrange(across(...))`:

```r
# Old way (deprecated)
arrange_each(df, desc(mpg))

# New way
arrange(df, across(everything(), desc))
```

### `rename_each()` is defunct

`rename_each()` has been removed from dplyr. Use `rename(across(...))`:

```r
# Old way (no longer works)
rename_each(df, tolower)

# New way
rename(df, across(everything(), tolower))
```
```

### Deprecation Timeline

Provide clear timeline:

```markdown
## Deprecation timeline

This function follows our standard deprecation cycle:

1. **dplyr 1.1.0** - Soft deprecated (warns only in console/tests)
2. **dplyr 1.2.0** - Deprecated (warns everywhere)
3. **dplyr 2.0.0** - Defunct (throws error)

We recommend updating to the new syntax now.
```

## New Features

### Announcing New Functions

```markdown
## New features

### `consecutive_id()`

Creates a unique ID for each group of consecutive identical values:

```r
df <- tibble(x = c(1, 1, 1, 2, 2, 1, 1))

df |> mutate(group = consecutive_id(x))
#> # A tibble: 7 x 2
#>       x group
#>   <dbl> <int>
#> 1     1     1
#> 2     1     1
#> 3     1     1
#> 4     2     2
#> 5     2     2
#> 6     1     3
#> 7     1     3
```

This is useful for identifying runs of consecutive values in time series.
```

### Announcing New Arguments

```markdown
### New `.by` argument

All dplyr verbs now support `.by` for grouping within the call:

```r
# Before (needed separate group_by)
mtcars |> group_by(cyl) |> summarise(mpg = mean(mpg))

# After (group within call)
mtcars |> summarise(mpg = mean(mpg), .by = cyl)
```
```

### Announcing Improved Behavior

```markdown
### Performance improvements

`group_by()` is now 10x faster for large grouped data:

```r
library(dplyr)
library(microbenchmark)

df <- tibble(
  group = rep(1:10000, each = 10),
  x = rnorm(100000)
)

microbenchmark(
  old = df |> group_by(group) |> summarise(x = mean(x)),
  new = df |> group_by(group) |> summarise(x = mean(x)),
  times = 3
)
#> Unit: milliseconds
#>  expr       min    lq   mean median    uq    max neval cld
#>  old  152.345 155.2 160.3 158.04 165.4 172.8     3   b
#>  new   15.234  15.5  16.1  15.77  16.5  17.2     3  a
```
```

## Bug Fixes

### Categorize by Impact

```markdown
## Bug fixes

### High impact fixes

- Fixed `left_join()` failing when both data frames had the same column name for the join key (#6543)
- Fixed `pivot_longer()` incorrectly handling columns with list-cols (#6501)

### Medium impact fixes

- Fixed `slice_head()` and `slice_tail()` not respecting `n` for empty data frames (#6432)
- Fixed `nest_join()` producing incorrect output when joining with zero-row data frames (#6398)

### Low impact fixes

- Fixed documentation typos in `relocate()` examples
- Fixed minor formatting issue in `count()` output
```

### Include GitHub References

```markdown
- Fixed error when using `across()` with `.names` argument (#6521)
- Fixed compatibility issue with R 4.3.0 (#6489)
```

## Performance Improvements

### Measurable Claims

Always back up performance claims with benchmarks:

```markdown
## Performance improvements

### join improvements

Joins are now faster for large data frames:

```r
# Setup
library(dplyr)
df1 <- tibble(key = 1:100000, value1 = rnorm(100000))
df2 <- tibble(key = 50001:150000, value2 = rnorm(100001))

# Benchmark
microbenchmark(
  left_join(df1, df2, by = "key"),
  times = 10
)
#> Unit: milliseconds
#>  expr      min   lq  mean median   uq  max neval
#>  join  45.23 46.1 48.5  47.23 49.8 55.1    10
```

The new implementation is approximately 2x faster than dplyr 1.0.0.
```

### Explain the Improvement

```markdown
This improvement comes from:
1. More efficient hash table implementation
2. Better memory allocation strategy
3. Reduced copying of intermediate results
```

## Contributor Acknowledgments

### Format

```markdown
## Contributors

Thank you to the following contributors who contributed to this release:

- [@cpurvert](https://github.com/cpurvert) for the `across()` improvement (#6523)
- [@hadley](https://github.com/hadley) for the join performance fix (#6543)
- [@jennybc](https://github.com/jennybc) for documentation improvements
- [@t州州州](https://github.com/t州州州) for the bug fix in `pivot_longer()` (#6501)
```

### Using the Script

Use `scripts/get_contributors.R` to generate contributor lists:

```r
source("scripts/get_contributors.R")

# Get all contributors since last release
contributors <- get_contributors(
  from = "2023-01-01",  # Last release date
  to = "2023-12-31",    # Current date
  package = "dplyr"
)

# Format for blog post
format_contributors(contributors)
```

### First-Time Contributors

Highlight new contributors:

```markdown
## New contributors

This release includes contributions from 8 new contributors:

- [@alice](https://github.com/alice) made their first contribution in #6521
- [@bob](https://github.com/bob) made their first contribution in #6505
- [@charlie](https://github.com/charlie) made their first contribution in #6489

Welcome to the tidyverse!
```

### Community Contributions

Acknowledge significant community contributions:

```markdown
## Community contributions

Special thanks to:

- [@cpurvert](https://github.com/cpurvert) for implementing the `.by` argument across all dplyr verbs
- [@data-tamer](https://github.com/data-tamer) for extensive testing and feedback on the join performance improvements
```

## Lifecycle Announcements

### Experimental Features

```markdown
## Lifecycle

### `consecutive_id()` is experimental

`consecutive_id()` is marked as **experimental**, which means:

- The interface may change without warning
- Performance characteristics are not yet optimized
- We welcome feedback on the API design

We'll promote to stable once we've gathered enough user feedback.
```

### Promotions

```markdown
### `across()` promoted to stable

`across()` was experimental in dplyr 1.0.0. Based on user feedback, we're now promoting it to stable.

The API is now frozen and we expect no breaking changes in future 1.x releases.
```

## Migration Guides

### Comprehensive Migration

```markdown
## Migration guide

### From dplyr 0.8.x to 1.0.0

If you're upgrading from dplyr 0.8.x, here's what you need to know:

#### Updated functions

| Old function     | New function                 |
|------------------|------------------------------|
| `mutate_each()`  | `mutate(across(...))`        |
| `summarise_each()`| `summarise(across(...))`    |
| `group_by_each()`| `group_by(across(...))`      |
| `select_each()`  | `select(across(...))`        |

#### Changed defaults

The default for `na.rm` in `summarise()` is now `FALSE`:

```r
# dplyr 0.8.x
summarise(mtcars, mean(mpg))
#> [1] 20.09

# dplyr 1.0.0
summarise(mtcars, mean(mpg))
#> [1] NA
#> Warning: Removed 4 rows containing NAs

# Explicit request for old behavior
summarise(mtcars, mean(mpg, na.rm = TRUE))
#> [1] 20.09
```
```

## Code Examples

### Complete Examples

```markdown
## Examples

### Using `.by` for within-group operations

```r
library(dplyr)

# Calculate mean horsepower by cylinder count
mtcars |> 
  summarise(mean_hp = mean(hp), .by = cyl)
#> # A tibble: 3 x 2
#>     cyl mean_hp
#>   <dbl>   <dbl>
#> 1     6    122.
#> 2     4     83.6
#> 3     8    209.

# Equivalent to (but more concise than)
mtcars |>
  group_by(cyl) |>
  summarise(mean_hp = mean(hp)) |>
  ungroup()
```
```

### Minimal Examples

For short examples:

```markdown
The `.data` pronoun makes it easier to program with dplyr:

```r
var <- "mpg"
mtcars |> summarise(mean(.data[[var]]))
#> # A tibble: 1 x 1
#>   `mean(.data[[var]])`
#>                   <dbl>
#> 1                  20.1
```
```

## Writing Style

### Active Voice

```markdown
# Good
"We improved the performance"
"We fixed a bug"

# Bad
"The performance was improved"
"A bug was fixed"
```

### Clear and Concise

```markdown
# Good
This release adds 5 new features, fixes 12 bugs, and improves performance.

# Bad
We are very excited to announce that this release comes with many new features and improvements that we think you'll really enjoy...
```

### Technical but Accessible

```markdown
# Good
The new hash join algorithm reduces memory usage by 40% for large data frames.

# Bad
We've refactored the join implementation to use a more memory-efficient hash table data structure with better cache locality.
```

## Common Mistakes

### Don't Over-Promise

```markdown
# Good
This improvement makes joins approximately 2x faster in our benchmarks.

# Bad
This improvement makes joins lightning fast! You'll never wait for joins again!
```

### Don't Be Vague

```markdown
# Good
Fixed a bug where `left_join()` could incorrectly match rows when the join key contained NA values.

# Bad
Fixed a bug in joins.
```

### Don't Bury the Lead

```markdown
# Good
## Breaking change
The `.data` pronoun is now required when using bare column names in `group_by()`.

# Bad
This release includes many improvements to `group_by()`. We've made it more consistent with other tidyverse functions. We've also updated the documentation. One minor change is that...
```

## Resources

- [tidyverse.org](https://www.tidyverse.org/blog/)
- [Previous release posts](https://www.tidyverse.org/blog/categories/#release)
- [lifecycle package](https://lifecycle.r-lib.org/)
- [dplyr NEWS](https://github.com/tidyverse/dplyr/blob/master/NEWS.md)
