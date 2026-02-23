# Tidyverse Formatting

Formatting conventions for tidyverse release posts and technical documentation.

## Code Formatting

### Inline Code

Use single backticks for inline code:

```markdown
Use `mutate()` to create new columns.
The `dplyr` package provides data manipulation verbs.
Call `library(tidyverse)` to load all packages.
```

### Code Blocks

Use fenced code blocks with language:

````markdown
```r
library(dplyr)

df <- tibble(x = 1:10, y = x^2)
df |> filter(x > 5)
```
````

### Code Highlighting

Syntax highlighting is automatic for common languages:

```r
# R code
library(ggplot2)
ggplot(mtcars, aes(mpg, wt)) + geom_point()
```

```python
# Python code
import pandas as pd
df = pd.read_csv("data.csv")
```

```bash
# Shell commands
R CMD build mypackage
R CMD check mypackage_1.0.0.tar.gz
```

### Code Output

Show output in separate blocks:

```r
# Example
1 + 1
#> [1] 2

# Or with explicit output comment
mean(c(1, 2, 3, 4, 5))
# [1] 3
```

### Long Code Lines

Break long lines at natural points:

```r
# Good
df |>
  group_by(species) |>
  summarise(
    mean_mass = mean(body_mass_g, na.rm = TRUE),
    n = n()
  )

# If line is still too long, break at pipe
df |>
  group_by(species) |>
  summarise(mean_mass = mean(body_mass_g, na.rm = TRUE),
            n = n())
```

## Link Formatting

### External Links

```markdown
- [dplyr documentation](https://dplyr.tidyverse.org)
- [R for Data Science](https://r4ds.had.co.nz)
```

### Links to tidyverse.org

Use relative links where possible:

```markdown
- See [vignette("colwise")](articles/colwise.html) for more details.
- Check out the [new vignette](articles/dplyr.html) for examples.
```

### Links to GitHub

```markdown
- Report issues at https://github.com/tidyverse/dplyr/issues
- See [PR #1234](https://github.com/tidyverse/dplyr/pull/1234)
```

### Links to Functions

For function references, use backticks and appropriate linking:

```markdown
- `mutate()` for creating new variables
- `across()` for applying functions across columns
- Use `filter()` to subset rows
```

## Text Formatting

### Emphasis

- *Italic* for emphasis (use `*`, not `_` in R code)
- **Bold** for strong emphasis

```markdown
This function is **experimental** and may change.
Use `mutate()` to *transform* your data.
```

### Lists

Use consistent list markers:

```markdown
- First item
- Second item
  - Nested item
  - Another nested item
- Third item
```

Numbered lists for sequences:

```markdown
1. First step
2. Second step
3. Third step
```

### Notes and Warnings

Use blockquotes for notes:

```markdown
> Note: This feature requires dplyr 1.1.0 or later.
```

For callouts, use divs (see callouts reference):

```markdown
::: {.callout-note}
This is a note callout for additional information.
:::
```

## Headings

Use sentence case for headings:

```markdown
# Getting started with dplyr

## Selecting columns

### Selecting with helpers
```

### Heading Structure

Start with H1 (#) for title, use H2 (##) for major sections:

```markdown
# Package Release Notes

## New features

### Function improvements

Details here.

## Bug fixes

Details here.
```

## Images and Figures

### Image Syntax

```markdown
![Alt text](path/to/image.png)
```

### Figure with Caption

```markdown
::: {#fig-performance}
![Performance comparison](performance-chart.png)

Comparison of performance between v1.0 and v1.1.
:::
```

### Image Attributes

```markdown
![Alt text](image.png){width=50%}

![Alt text](image.png){fig-align="center"}

![Alt text](image.png){.lightbox}
```

### Image Placement

Prefer figures in their own blocks:

```markdown
## Performance results

::: {#fig-scaling}

![Scaling test](scaling.png)

Performance scales linearly with data size.

:::
```

## Tables

### Simple Tables

```markdown
| Package | Version | Status |
|---------|---------|--------|
| dplyr   | 1.1.0   | Release|
| tidyr   | 1.3.0   | Release|
| ggplot2 | 3.4.0   | Release|
```

### Tables with Formatting

```markdown
| Function      | Description                        | Version |
|---------------|------------------------------------|---------|
| `mutate()`    | Create new variables               | 1.0.0   |
| `across()`    | Apply functions to columns         | 1.0.0   |
| `relocate()`  | Change column order                | 1.1.0   |
```

### Table Alignment

```markdown
| Column 1 | Column 2 | Column 3 |
|:---------|:--------:|:--------:|
| Left     | Center   | Right    |
| align    | align    | align    |
```

## Math and Formulas

### Inline Math

```markdown
The mean is calculated as $\bar{x} = \frac{1}{n}\sum_{i=1}^{n}x_i$.
```

### Display Math

```markdown
$$\hat{y} = \beta_0 + \beta_1 x_1 + \beta_2 x_2 + \epsilon$$
```

### Equations

```markdown
::: {#eq-variance}

$$\sigma^2 = \frac{1}{N} \sum_{i=1}^{N} (x_i - \mu)^2$$

where $\sigma^2$ is the variance.

:::
```

## Special Characters

### Escaping

Use backslash to escape special characters:

```markdown
\* Asterisk
\_ Underscore
\# Hash
\` Backtick
```

### Unicode

Use Unicode characters where appropriate:

```markdown
- dplyr → tibble → tidyr → ggplot2
- Use → for "leads to"
- Use × for multiplication
```

### In Code Blocks

Code blocks don't need escaping, but be careful with backticks:

````markdown
```r
# This is a comment
x <- c(1, 2, 3)  # Vector
```
````

## Spacing

### Paragraph Spacing

Separate paragraphs with blank lines:

```markdown
First paragraph here.

Second paragraph here.
```

### After Headings

Add a blank line after headings:

```markdown
## Section Title

Content starts here.
```

### Around Code Blocks

Blank lines before and after code blocks:

```markdown
Here's how to use the function:

```r
mutate(df, new_col = x + y)
```

This creates a new column.
```

## File Paths

### Relative Paths

```markdown
- See `R/imports.R` for package imports
- Check `inst/extdata/` for example files
- Read `NEWS.md` for release notes
```

### Absolute Paths

```markdown
- Configuration file: `/etc/R/Renviron`
- User home: `~/.Rprofile`
```

### URLs

```markdown
- CRAN: https://cran.r-project.org
- GitHub: https://github.com/tidyverse/dplyr
```

## Version Numbers

### Package Versions

```markdown
- dplyr 1.1.0
- ggplot2 3.4.0
- R 4.2.0
```

### Version Ranges

```markdown
- Requires R >= 4.0.0
- Compatible with ggplot2 >= 3.3.0
- Suggests tidyr >= 1.2.0 (for testing)
```

### Version Comparison

```markdown
- Breaking change in 1.0.0
- New feature added in 1.1.0
- Deprecated in 1.2.0, removed in 2.0.0
```

## R Objects

### Function Names

```markdown
- `mutate()` function
- `across()` helper
- `select()` verb
```

### Package Names

```markdown
- The **dplyr** package
- The **tidyverse**
- **rlang** utilities
```

### Variable Names

```markdown
- `df` for data frame
- `x` for vector
- `result` for output
```

### Class Names

```markdown
- `tbl_df` class
- `grouped_df` object
- `ggplot` object
```

## Comments in Examples

### Comment Style

Use full sentences in comments:

```r
# Create a new column with the square of x
df |> mutate(x_squared = x^2)

# Filter to keep only rows where value is positive
df |> filter(value > 0)
```

### Inline Comments

```r
df |>
  group_by(species) |>  # Group by species
  summarise(avg_mass = mean(body_mass_g))  # Calculate mean mass
```

## Resources

- [tidyverse style guide](https://style.tidyverse.org/)
- [Quarto markdown basics](https://quarto.org/docs/authoring/markdown-basics.html)
- [R code style guide](https://style.tidyverse.org/r-code.html)
