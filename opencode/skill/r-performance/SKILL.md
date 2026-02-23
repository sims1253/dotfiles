---
name: r-performance
description: >
  R performance optimization including profiling with profvis, benchmarking with bench,
  vectorization patterns, parallel processing, and vctrs type stability.
  Use when optimizing R code, profiling, benchmarking, or building type-stable functions.
---

# Performance Best Practices

## Performance Tool Selection

### When to Use Each Tool

| Tool | Use When | Don't Use When | What It Shows |
|------|----------|----------------|---------------|
| **`profvis`** | Complex code, unknown bottlenecks | Simple functions, known issues | Time per line, call stack |
| **`bench::mark()`** | Comparing alternatives | Single approach | Relative performance, memory |
| **`system.time()`** | Quick checks | Detailed analysis | Total runtime only |
| **`Rprof()`** | Base R only environments | When profvis available | Raw profiling data |

## Step-by-Step Performance Workflow

```r
# 1. Profile first - find the actual bottlenecks
library(profvis)
profvis({
  # Your slow code here
})

# 2. Focus on the slowest parts (80/20 rule)
# Don't optimize until you know where time is spent

# 3. Benchmark alternatives for hot spots
library(bench)
bench::mark(
  current = current_approach(data),
  vectorized = vectorized_approach(data),
  parallel = map(data, in_parallel(func))
)

# 4. Consider tool trade-offs based on bottleneck type
```

## When Each Tool Helps vs Hurts

### Parallel Processing (`in_parallel()`)

**Helps when:**
- CPU-intensive computations
- Embarrassingly parallel problems
- Large datasets with independent operations
- I/O bound operations (file reading, API calls)

**Hurts when:**
- Simple, fast operations (overhead > benefit)
- Memory-intensive operations (may cause thrashing)
- Operations requiring shared state
- Small datasets

```r
# Example decision point:
expensive_func <- function(x) Sys.sleep(0.1)  # 100ms per call
fast_func <- function(x) x^2                   # microseconds

# Good for parallel
map(1:100, in_parallel(expensive_func))  # ~10s -> ~2.5s on 4 cores

# Bad for parallel (overhead > benefit)
map(1:100, in_parallel(fast_func))       # 100μs -> 50ms (500x slower!)
```

### Data Backend Selection

**Use data.table when:**
- Very large datasets (>1GB)
- Complex grouping operations
- Reference semantics desired
- Maximum performance critical

**Use dplyr when:**
- Readability and maintainability priority
- Complex joins and window functions
- Team familiarity with tidyverse
- Moderate sized data (<100MB)

**Use base R when:**
- No dependencies allowed
- Simple operations
- Teaching/learning contexts

## Profiling Best Practices

```r
# 1. Profile realistic data sizes
profvis({
  real_data |> your_analysis()
})

# 2. Profile multiple runs for stability
bench::mark(
  your_function(data),
  min_iterations = 10,
  max_iterations = 100
)

# 3. Check memory usage too
bench::mark(
  approach1 = method1(data),
  approach2 = method2(data),
  check = FALSE,
  filter_gc = FALSE  # Include GC time
)

# 4. Profile realistic usage patterns
```

## Performance Anti-Patterns to Avoid

```r
# Don't optimize without measuring
# ✗ "This looks slow" -> immediately rewrite
# ✓ Profile first, optimize bottlenecks

# Don't over-engineer for performance
# ✗ Complex optimizations for 1% gains
# ✓ Focus on algorithmic improvements

# Don't assume - measure
# ✗ "for loops are always slow in R"
# ✓ Benchmark your specific use case

# Don't ignore readability costs
# ✗ Unreadable code for minor speedups
# ✓ Readable code with targeted optimizations
```

## Vectorization

```r
# Good - vectorized operations
result <- x + y

# Good - Type-stable purrr functions
map_dbl(data, mean)    # always returns double
map_chr(data, class)   # always returns character

# Avoid - Type-unstable base functions
sapply(data, mean)     # might return list or vector

# Avoid - Growing objects in loops
result <- c()
for(i in 1:n) {
  result <- c(result, compute(i))  # Slow!
}

# Good - Pre-allocate
result <- vector("list", n)
for(i in 1:n) {
  result[[i]] <- compute(i)
}

# Better - Use purrr
result <- map(1:n, compute)
```

---

# vctrs for Type Stability

## Core Benefits

- **Type stability** - Predictable output types regardless of input values
- **Size stability** - Predictable output sizes from input sizes
- **Consistent coercion rules** - Single set of rules applied everywhere
- **Robust class design** - Proper S3 vector infrastructure

## When to Use vctrs

### Building Custom Vector Classes

```r
# Good - vctrs-based vector class
new_percent <- function(x = double()) {
  vec_assert(x, double())
  new_vctr(x, class = "pkg_percent")
}

# Automatic data frame compatibility, subsetting, etc.
```

### Type-Stable Functions in Packages

```r
# Good - Guaranteed output type
my_function <- function(x, y) {
  vec_cast(result, double())  # Always returns double
}

# Avoid - Type depends on data
sapply(x, function(i) if(condition) 1L else 1.0)
```

### Consistent Coercion/Casting

```r
# Good - Explicit casting with clear rules
vec_cast(x, double())

# Good - Common type finding
vec_ptype_common(x, y, z)  # Finds richest compatible type

# Avoid - Base R inconsistencies
c(factor("a"), "b")  # Unpredictable behavior
```

### Size/Length Stability

```r
# Good - Predictable sizing
vec_c(x, y)  # size = vec_size(x) + vec_size(y)
vec_rbind(df1, df2)  # size = sum of input sizes

# Avoid - Unpredictable sizing
c(env_object, function_object)
```

## vctrs vs Base R Decision Matrix

| Use Case | Base R | vctrs | When to Choose vctrs |
|----------|--------|-------|---------------------|
| Simple combining | `c()` | `vec_c()` | Need type stability |
| Custom classes | S3 manually | `new_vctr()` | Want data frame compatibility |
| Type conversion | `as.*()` | `vec_cast()` | Need explicit, safe casting |
| Finding common type | N/A | `vec_ptype_common()` | Combining heterogeneous inputs |
| Size operations | `length()` | `vec_size()` | Working with non-vector objects |

## Implementation Patterns

### Basic Vector Class

```r
# Constructor (low-level)
new_percent <- function(x = double()) {
  vec_assert(x, double())
  new_vctr(x, class = "pkg_percent")
}

# Helper (user-facing)
percent <- function(x = double()) {
  x <- vec_cast(x, double())
  new_percent(x)
}

# Format method
format.pkg_percent <- function(x, ...) {
  paste0(vec_data(x) * 100, "%")
}
```

### Coercion Methods

```r
# Self-coercion
vec_ptype2.pkg_percent.pkg_percent <- function(x, y, ...) {
  new_percent()
}

# With double
vec_ptype2.pkg_percent.double <- function(x, y, ...) double()
vec_ptype2.double.pkg_percent <- function(x, y, ...) double()

# Casting
vec_cast.pkg_percent.double <- function(x, to, ...) {
  new_percent(x)
}
vec_cast.double.pkg_percent <- function(x, to, ...) {
  vec_data(x)
}
```

## vctrs Performance Considerations

### When vctrs Adds Overhead
- Simple operations (`vec_c(1, 2)` vs `c(1, 2)`)
- One-off scripts where type safety is less critical
- Small vectors

### When vctrs Improves Performance
- Package functions (type stability prevents re-computation)
- Complex classes (consistent behavior reduces debugging)
- Data frame operations (robust column type handling)
- Repeated operations (predictable types enable optimization)

## Package Development with vctrs

### Exports and Dependencies

```r
# DESCRIPTION
Imports: vctrs

# NAMESPACE - Import what you need
importFrom(vctrs, vec_assert, new_vctr, vec_cast, vec_ptype_common)
```

### Testing vctrs Classes

```r
# Test type stability
test_that("my_function is type stable", {
  expect_equal(vec_ptype(my_function(1:3)), vec_ptype(double()))
  expect_equal(vec_ptype(my_function(integer())), vec_ptype(double()))
})

# Test coercion
test_that("coercion works", {
  expect_equal(vec_ptype_common(new_percent(), 1.0), double())
  expect_error(vec_ptype_common(new_percent(), "a"))
})
```

## Don't Use vctrs When

- Simple one-off analyses
- No custom classes needed
- Performance critical + simple operations
- External API constraints requiring base R types

**Key insight**: vctrs is most valuable in package development where type safety, consistency, and extensibility matter more than raw speed for simple operations.
