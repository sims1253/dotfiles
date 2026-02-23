---
name: r-tidyverse
description: >
  Modern tidyverse patterns including dplyr 1.1+ (native pipe, join_by, .by grouping,
  pick, across, reframe), stringr string manipulation, and purrr functional programming.
  Use when writing data manipulation code, working with dplyr, tidyr, stringr, or purrr.
---

# Modern Tidyverse Patterns

## Pipe Usage (`|>` not `%>%`)

**Always use native pipe `|>` instead of magrittr `%>%`** - R 4.3+ provides all needed features.

```r
# Good - Modern native pipe
data |>
  filter(year >= 2020) |>
  summarise(mean_value = mean(value))

# Avoid - Legacy magrittr pipe
data %>%
  filter(year >= 2020) %>%
  summarise(mean_value = mean(value))
```

## Join Syntax (dplyr 1.1+)

**Use `join_by()` instead of character vectors for joins.**

### Basic Joins
```r
# Good - Modern join syntax
transactions |>
  inner_join(companies, by = join_by(company == id))

# Avoid - Old character vector syntax
transactions |>
  inner_join(companies, by = c("company" = "id"))
```

### Inequality Joins
```r
transactions |>
  inner_join(companies, join_by(company == id, year >= since))
```

### Rolling Joins (closest match)
```r
transactions |>
  inner_join(companies, join_by(company == id, closest(year >= since)))
```

### Multiple Match Handling
```r
# Expect 1:1 matches, error on multiple
inner_join(x, y, by = join_by(id), multiple = "error")

# Allow multiple matches explicitly
inner_join(x, y, by = join_by(id), multiple = "all")

# Ensure all rows match
inner_join(x, y, by = join_by(id), unmatched = "error")
```

## Modern Grouping and Column Operations

### Per-Operation Grouping with `.by` (dplyr 1.1+)

**Use `.by` for per-operation grouping** - always returns ungrouped result.

```r
# Good - Per-operation grouping
data |>
  summarise(mean_value = mean(value), .by = category)

# Good - Multiple grouping variables
data |>
  summarise(total = sum(revenue), .by = c(company, year))

# Avoid - Old persistent grouping pattern
data |>
  group_by(category) |>
  summarise(mean_value = mean(value)) |>
  ungroup()
```

### Column Selection with `pick()`

Use `pick()` for column selection inside data-masking functions:

```r
data |>
  summarise(
    n_x_cols = ncol(pick(starts_with("x"))),
    n_y_cols = ncol(pick(starts_with("y")))
  )
```

### Applying Functions with `across()`

```r
data |>
  summarise(across(where(is.numeric), mean, .names = "mean_{.col}"), .by = group)
```

### Multi-Row Summaries with `reframe()`

```r
# Good - reframe() for multi-row results
data |>
  reframe(quantiles = quantile(x, c(0.25, 0.5, 0.75)), .by = group)
```

## Data Masking and Tidy Selection

### Understanding the Difference

- **Data masking functions**: `arrange()`, `filter()`, `mutate()`, `summarise()`
- **Tidy selection functions**: `select()`, `relocate()`, `across()`

### Embrace with `{{}}`

Use `{{}}` for function arguments:

```r
my_summary <- function(data, group_var, summary_var) {
  data |>
    group_by({{ group_var }}) |>
    summarise(mean_val = mean({{ summary_var }}))
}
```

### Character Vectors with `.data[[]]`

```r
for (var in names(mtcars)) {
  mtcars |> count(.data[[var]]) |> print()
}
```

### Multiple Columns with `across()`

```r
data |>
  summarise(across({{ summary_vars }}, ~ mean(.x, na.rm = TRUE)))
```

---

# stringr Patterns

**Use stringr over base R string functions** - consistent `str_` prefix and string-first argument order.

## Common Patterns

```r
# Good - stringr (consistent, pipe-friendly)
text |>
  str_to_lower() |>
  str_trim() |>
  str_replace_all("pattern", "replacement") |>
  str_extract("\\d+")

# Common patterns
str_detect(text, "pattern")     # vs grepl("pattern", text)
str_extract(text, "pattern")    # vs complex regmatches()
str_replace_all(text, "a", "b") # vs gsub("a", "b", text)
str_split(text, ",")            # vs strsplit(text, ",")
str_length(text)                # vs nchar(text)
str_sub(text, 1, 5)             # vs substr(text, 1, 5)
```

## String Combination and Formatting

```r
str_c("a", "b", "c")            # vs paste0()
str_glue("Hello {name}!")       # templating
str_pad(text, 10, "left")       # padding
str_wrap(text, width = 80)      # text wrapping
```

## Case Conversion

```r
str_to_lower(text)              # vs tolower()
str_to_upper(text)              # vs toupper()
str_to_title(text)              # vs tools::toTitleCase()
```

## Pattern Helpers

```r
str_detect(text, fixed("$"))    # literal match
str_detect(text, regex("\\d+")) # explicit regex
str_detect(text, coll("é", locale = "fr")) # collation
```

---

# purrr Patterns

## Data Frame Row Binding (purrr 1.0+)

**Use `map() |> list_rbind()` instead of superseded `map_dfr()`:**

```r
# Modern pattern
models <- data_splits |>
  map(\(split) train_model(split)) |>
  list_rbind()  # Replaces map_dfr()

# Column binding
summaries <- data_list |>
  map(\(df) get_summary_stats(df)) |>
  list_cbind()  # Replaces map_dfc()
```

## Side Effects with walk()

```r
plots <- walk2(data_list, plot_names, \(df, name) {
  p <- ggplot(df, aes(x, y)) + geom_point()
  ggsave(name, p)
})
```

## Parallel Processing (purrr 1.1.0+)

```r
library(mirai)
daemons(4)
results <- large_datasets |>
  map(in_parallel(expensive_computation))
daemons(0)
```

## Type-Stable Map Functions

```r
# Good - Type-stable purrr functions
map_dbl(data, mean)    # always returns double
map_chr(data, class)   # always returns character
map_lgl(data, is.null) # always returns logical

# Avoid - Type-unstable base functions
sapply(data, mean)     # might return list or vector
```

## Superseded purrr Functions (purrr 1.0+)

| Old (Superseded) | New (Preferred) |
|------------------|-----------------|
| `map_dfr(x, f)` | `map(x, f) \|> list_rbind()` |
| `map_dfc(x, f)` | `map(x, f) \|> list_cbind()` |
| `map2_dfr(x, y, f)` | `map2(x, y, f) \|> list_rbind()` |
| `pmap_dfr(list, f)` | `pmap(list, f) \|> list_rbind()` |
| `imap_dfr(x, f)` | `imap(x, f) \|> list_rbind()` |

## Common Patterns

```r
# Iterate over list with index
imap(data_list, \(df, name) {
  df |> mutate(source = name)
})

# Iterate over multiple inputs
map2(data_list, model_list, \(data, model) {
  predict(model, data)
})

# Iterate over rows of data frame
pmap(params_df, \(param1, param2, ...) {
  run_simulation(param1, param2)
})
```

---

# Style Guide Essentials

## Object Names

- **Use snake_case for all names**
- **Variable names = nouns, function names = verbs**
- **Avoid dots except for S3 methods**

```r
# Good
day_one
calculate_mean
user_data

# Avoid
DayOne
calculate.mean
userData
```

## Spacing and Layout

```r
# Good spacing
x[, 1]
mean(x, na.rm = TRUE)
if (condition) {
  action()
}

# Pipe formatting
data |>
  filter(year >= 2020) |>
  group_by(category) |>
  summarise(
    mean_value = mean(value),
    count = n()
  )
```
