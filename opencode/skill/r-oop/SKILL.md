---
name: r-oop
description: >
  R OOP systems comparison and decision guide for S3, S4, S7, R6, and vctrs-based classes.
  Use when choosing an OOP system, defining classes, creating methods, or migrating between systems.
---

# OOP System Decision Guide

## S7 vs vctrs vs S3/S4 Decision Tree

**Start here:** What are you building?

### 1. Vector-like Objects

Objects that behave like atomic vectors (factor-like, date-like, numeric-like):

**Use vctrs when:**
- Need data frame integration (columns/rows)
- Want type-stable vector operations
- Building factor-like, date-like, or numeric-like classes
- Need consistent coercion/casting behavior
- Working with existing tidyverse infrastructure

### 2. General Objects (complex data structures)

**Use S7 when:**
- NEW projects that need formal classes
- Want property validation and safe property access (@)
- Need multiple dispatch (beyond S3's double dispatch)
- Converting from S3 and want better structure
- Building class hierarchies with inheritance
- Want better error messages and discoverability

**Use S3 when:**
- Simple classes with minimal structure needs
- Maximum compatibility and minimal dependencies
- Quick prototyping or internal classes
- Contributing to existing S3-based ecosystems
- Performance is absolutely critical (minimal overhead)

**Use S4 when:**
- Working in Bioconductor ecosystem
- Need complex multiple inheritance
- Existing S4 codebase that works well

## S7: Modern OOP for New Projects

S7 combines S3 simplicity with S4 structure.

### Class Definition

```r
Range <- new_class("Range",
  properties = list(
    start = class_double,
    end = class_double
  ),
  validator = function(self) {
    if (self@end < self@start) {
      "@end must be >= @start"
    }
  }
)

# Usage
x <- Range(start = 1, end = 10)
x@start  # 1
x@end <- 20  # automatic validation
```

### Methods

```r
inside <- new_generic("inside", "x")
method(inside, Range) <- function(x, y) {
  y >= x@start & y <= x@end
}
```

## Detailed S7 vs S3 Comparison

| Feature | S3 | S7 | When S7 wins |
|---------|----|----|--------------|
| Class definition | Informal | Formal (`new_class()`) | Need guaranteed structure |
| Property access | `$` or `attr()` (unsafe) | `@` (safe, validated) | Property validation matters |
| Validation | Manual, inconsistent | Built-in validators | Data integrity important |
| Method discovery | Hard to find | Clear method printing | Developer experience matters |
| Multiple dispatch | Limited | Full support | Complex method dispatch needed |
| Inheritance | Informal, `NextMethod()` | Explicit `super()` | Predictable inheritance |
| Performance | Fastest | ~Same as S3 | Negligible difference |
| Compatibility | Full S3 | Full S3 + S7 | Need both patterns |

## Practical Guidelines

### Choose S7 When You Have:

```r
# Complex validation needs
Range <- new_class("Range",
  properties = list(start = class_double, end = class_double),
  validator = function(self) {
    if (self@end < self@start) "@end must be >= @start"
  }
)

# Multiple dispatch needs
method(generic, list(ClassA, ClassB)) <- function(x, y) ...

# Class hierarchies with clear inheritance
Child <- new_class("Child", parent = Parent)
```

### Choose vctrs When You Need:

```r
# Vector-like behavior in data frames
percent <- new_vctr(0.5, class = "percentage")
data.frame(x = 1:3, pct = percent(c(0.1, 0.2, 0.3)))

# Type-stable operations
vec_c(percent(0.1), percent(0.2))
vec_cast(0.5, percent())
```

### Choose S3 When You Have:

```r
# Simple classes without complex needs
new_simple <- function(x) structure(x, class = "simple")
print.simple <- function(x, ...) cat("Simple:", x)
```

## S3 Patterns

### Basic S3 Class

```r
# Constructor
new_person <- function(name, age) {
  stopifnot(is.character(name), is.numeric(age))
  structure(
    list(name = name, age = age),
    class = "person"
  )
}

# Method
print.person <- function(x, ...) {
  cat("Person:", x$name, "(", x$age, "years)\n")
}

# Generic
introduce <- function(x, ...) UseMethod("introduce")
introduce.person <- function(x, ...) {
 cat("Hi, I'm", x$name, "\n")
}
```

### S3 Method Dispatch

```r
# Single dispatch on first argument
my_generic <- function(x, ...) UseMethod("my_generic")

# Call next method in hierarchy
my_method.child <- function(x, ...) {
  # Do child-specific work
  NextMethod()  # Call parent method
}
```

## S4 Patterns (for Bioconductor)

### Basic S4 Class

```r
setClass("Gene",
  slots = c(
    symbol = "character",
    chromosome = "numeric"
  ),
  prototype = list(
    symbol = NA_character_,
    chromosome = NA_real_
  )
)

# Constructor
Gene <- function(symbol, chromosome) {
  new("Gene", symbol = symbol, chromosome = chromosome)
}

# Method
setMethod("show", "Gene", function(object) {
  cat("Gene:", object@symbol, "on chr", object@chromosome, "\n")
})
```

## Migration Strategy

1. **S3 → S7**: Usually 1-2 hours work, keeps full compatibility
2. **S4 → S7**: More complex, evaluate if S4 features are needed
3. **Base R → vctrs**: Significant benefits for vector-like classes
4. **Combining approaches**: S7 classes can use vctrs principles internally

## Quick Reference

| Need | Use |
|------|-----|
| Vector-like objects, data frame columns | **vctrs** |
| New projects needing formal classes | **S7** |
| Simple classes, max compatibility | **S3** |
| Bioconductor, complex inheritance | **S4** |
| Mutable state, reference semantics | **R6** |
