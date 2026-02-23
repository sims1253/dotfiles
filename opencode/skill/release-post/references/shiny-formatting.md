# Shiny Formatting

Formatting conventions for Shiny-related content in tidyverse release posts and documentation.

## Shiny Code Examples

### Basic App Structure

```r
library(shiny)

ui <- fluidPage(
  titlePanel("My App"),
  
  sidebarLayout(
    sidebarPanel(
      sliderInput("n", "Number of points", 10, 100, 50)
    ),
    
    mainPanel(
      plotOutput("distPlot")
    )
  )
)

server <- function(input, output) {
  output$distPlot <- renderPlot({
    hist(rnorm(input$n), breaks = 30, col = "steelblue", border = "white")
  })
}

shinyApp(ui = ui, server = server)
```

### Modular App Structure

```r
library(shiny)

# Module UI
mod_example_ui <- function(id) {
  ns <- NS(id)
  
  tagList(
    selectInput(ns("var"), "Select variable", names(mtcars)),
    plotOutput(ns("plot"))
  )
}

# Module server
mod_example_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$plot <- renderPlot({
      plot(mtcars[[input$var]])
    })
  })
}

# App
ui <- fluidPage(mod_example_ui("example"))
server <- function(input, output) {
  mod_example_server("example")
}
shinyApp(ui, server)
```

## Reactive Code Patterns

### Reactive Values

```r
server <- function(input, output) {
  # Create reactive values
  rv <- reactiveValues(data = NULL)
  
  # Update reactive values
  observeEvent(input$load, {
    rv$data <- read_data(input$file)
  })
  
  # Use reactive values
  output$summary <- renderTable({
    req(rv$data)  # Ensure data is available
    summary(rv$data)
  })
}
```

### Reactive Expressions

```r
server <- function(input, output) {
  # Create reactive expression
  filtered_data <- reactive({
    req(input$filter_var)  # Require input
    dplyr::filter(mtcars, .data[[input$filter_var]] > input$threshold)
  })
  
  # Use reactive expression
  output$plot <- renderPlot({
    ggplot(filtered_data(), aes(x = .data[[input$x_var]], y = .data[[input$y_var]])) +
      geom_point()
  })
}
```

### Observe vs. Reactive

```r
server <- function(input, output) {
  # Observer - side effects
  observeEvent(input$save, {
    write_csv(input$data, "data.csv")
    showNotification("Saved!")
  })
  
  # Reactive expression - returns value
  processed_data <- reactive({
    input$data |>
      dplyr::mutate(new_col = old_col * 2)
  })
}
```

## UI Components

### Input Controls

```r
# Text input
textInput("name", "Your name", placeholder = "Enter name")

# Numeric input
numericInput("age", "Your age", value = 30, min = 0, max = 150)

# Select input
selectInput("species", "Select species",
            choices = unique(iris$Species),
            selected = "setosa")

# Multiple select
selectInput("vars", "Select variables",
            choices = names(iris),
            multiple = TRUE)

# Slider
sliderInput("range", "Range",
            min = 0, max = 10, value = c(2, 8))

# File input
fileInput("file", "Upload CSV", accept = ".csv")

# Action button
actionButton("run", "Run Analysis", icon = icon("play"))

# Go button
actionButton("go", "Go!", class = "btn-primary")
```

### Output Controls

```r
# Plot output
plotOutput("myPlot", width = "600px", height = "400px")

# Table output
tableOutput("myTable")

# Data table
dataTableOutput("myDataTable")

# Text output
textOutput("myText")

# HTML output
htmlOutput("myHTML")

# UI output
uiOutput("myUI")
```

### Layout Functions

```r
# Fluid page
fluidPage(
  titlePanel("Title"),
  fluidRow(
    column(4, ...),
    column(8, ...)
  )
)

# Sidebar layout
sidebarLayout(
  sidebarPanel(...),
  mainPanel(...)
)

# Tabset
tabsetPanel(
  tabPanel("Tab 1", ...),
  tabPanel("Tab 2", ...)
)

# Navbar
navbarPage(
  "Title",
  tabPanel("Page 1", ...),
  tabPanel("Page 2", ...)
)

# Vertical layout
verticalLayout(
  ...
)
```

## Plotting in Shiny

### ggplot2

```r
output$plot <- renderPlot({
  req(input$x_var, input$y_var)
  
  ggplot(iris, aes(x = .data[[input$x_var]], y = .data[[input$y_var]])) +
    geom_point(alpha = input$alpha) +
    labs(title = input$title)
})
```

### Base R plots

```r
output$plot <- renderPlot({
  req(input$x_var)
  
  hist(iris[[input$x_var]],
       breaks = input$breaks,
       col = input$color,
       main = input$title)
})
```

### Plot sizing

```r
# In UI
plotOutput("plot", width = "800px", height = "600px")

# Or with responsive sizing
plotOutput("plot", width = "100%", height = "400px")
```

## Tables in Shiny

### DT::datatable

```r
output$table <- DT::renderDT({
  iris |>
    DT::datatable(
      selection = "single",
      rownames = FALSE,
      options = list(pageLength = 10)
    )
})
```

### reactable

```r
output$table <- reactable::renderReactable({
  reactable(iris, filterable = TRUE)
})
```

### Simple table

```r
output$table <- renderTable({
  head(iris)
})
```

## Notification Messages

### Show notification

```r
# Simple notification
showNotification("Analysis complete!")

# With type
showNotification("Warning message", type = "warning")
showNotification("Error!", type = "error")

# With duration
showNotification("Auto-hide", duration = 5)

# With action
showNotification(
  "Data saved",
  action = a("View", href = "#", onclick = "Shiny.setInputValue('view', true)")
)
```

### Modal dialogs

```r
observeEvent(input$click, {
  showModal(modalDialog(
    title = "Confirm",
    "Are you sure?",
    footer = tagList(
      modalButton("Cancel"),
      actionButton("confirm", "Confirm", class = "btn-primary")
    )
  ))
})
```

### Progress indicators

```r
withProgress(message = "Processing", value = 0, {
  n <- 10
  for (i in 1:n) {
    incProgress(1/n, detail = paste("Step", i))
    Sys.sleep(0.1)
  }
})
```

## Error Handling

### req() for required inputs

```r
output$plot <- renderPlot({
  req(input$x_var, input$y_var)  # Stop if missing
  
  ggplot(iris, aes(x = .data[[input$x_var]])) +
    geom_histogram()
})
```

### validate() for checks

```r
output$summary <- renderTable({
  req(input$file)
  
  # Validate input
  validate(
    need(file.exists(input$file$datapath), "File not found"),
    need(file.size(input$file$datapath) > 0, "Empty file")
  )
  
  read_csv(input$file$datapath)
})
```

### tryCatch() for errors

```r
observeEvent(input$run, {
  tryCatch({
    result <- slow_calculation(input$params)
    output$result <- renderText(result)
  }, error = function(e) {
    showNotification(paste("Error:", e$message), type = "error")
  })
})
```

## Testing Shiny Apps

### Test structure

```
tests/
├── testthat/
│   ├── test-app.R
│   ├── test-module.R
│   └── test-reactive.R
└── shinytest/
    ├── app.R
    └── test-expected/
```

### testthat tests

```r
test_that("app loads without error", {
  app <- shinytest2::test_server(my_app)
  expect_s3_class(app, "shiny.appobj")
})

test_that("slider input updates plot", {
  app <- shinytest2::test_app(my_app)
  
  app |>
    set_inputs(n = 100) |>
    expect_ui_output(plot_height = "400px")
})
```

### Manual testing checklist

- [ ] App loads without errors
- [ ] All inputs work correctly
- [ ] Reactive dependencies update properly
- [ ] Error states display correctly
- [ ] Loading states show during computation
- [ ] Works on different screen sizes

## Performance Optimization

### Cache expensive computations

```r
server <- function(input, output) {
  cached_data <- reactive({
    req(!is.null(input$dataset))
    
    cached_data <- memoise::memoise(function() {
      slow_database_query(input$dataset)
    })
    
    cached_data()
  })
}
```

### Lazy loading

```r
server <- function(input, output) {
  # Only load heavy data when needed
  observeEvent(input$show_analysis, {
    output$analysis <- renderPlot({
      heavy_plot(input$data)
    })
  })
}
```

### Progress for long operations

```r
observeEvent(input$run, {
  withProgress(message = "Running analysis", {
    result <- for_loop_with_progress(
      input$data,
      progress_inc = 1/length(input$data)
    )
  })
})
```

## Shiny in Documentation

### Example apps

Use `shinyApp()` to create runnable examples:

```r
#' @examples
#' if (interactive()) {
#'   # Full working app
#'   library(ggplot2)
#'   
#'   ui <- fluidPage(
#'     selectInput("var", "Variable", names(mtcars)),
#'     plotOutput("plot")
#'   )
#'   
#'   server <- function(input, output) {
#'     output$plot <- renderPlot({
#'       plot(mtcars[[input$var]])
#'     })
#'   }
#'   
#'   shinyApp(ui, server)
#' }
```

### App components

Show isolated components:

```r
# Show just the UI
fluidPage(
  selectInput("var", "Variable", names(mtcars))
)

# Show just the server logic
function(input, output) {
  output$plot <- renderPlot({
    plot(mtcars[[input$var]])
  })
}
```

## Common Patterns

### Download button

```r
# UI
downloadButton("download", "Download Data")

# Server
output$download <- downloadHandler(
  filename = function() {
    paste0("data-", Sys.Date(), ".csv")
  },
  content = function(file) {
    write_csv(reactive_data(), file)
  }
)
```

### Filtered data table

```r
server <- function(input, output) {
  # Reactive filtered data
  filtered_data <- reactive({
    req(input$filter_var)
    
    iris |>
      dplyr::filter(Species == input$filter_var)
  })
  
  # Display filtered data
  output$table <- DT::renderDT({
    filtered_data()
  })
  
  # Download filtered data
  output$download <- downloadHandler(
    filename = "filtered_data.csv",
    content = function(file) {
      write_csv(filtered_data(), file)
    }
  )
}
```

### Dynamic UI

```r
output$dynamic_ui <- renderUI({
  ns <- session$ns
  
  tagList(
    selectInput(ns("var"), "Variable", names(input$data)),
    sliderInput(ns("bin"), "Bins", 5, 50, 20)
  )
})
```

## Resources

- [Shiny documentation](https://shiny.posit.co/)
- [Shiny tutorials](https://shiny.posit.co/r/get-started/)
- [Shiny JS API](https://shiny.posit.co/r/reference/)
- [testthat for Shiny](https://github.com/r-lib/shinytest2)
