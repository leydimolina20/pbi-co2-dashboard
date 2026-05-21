# ============================================================
#  Dashboard: PBI per Cápita vs Emisiones de CO₂
#  Fuente: Banco Mundial (WDI)
#  Librerías: shiny + bslib + wbstats + ggplot2 + plotly
# ============================================================

library(shiny)
library(bslib)
library(wbstats)
library(ggplot2)
library(plotly)
library(dplyr)
library(scales)
library(DT)

# ── Paleta y tema ────────────────────────────────────────────
clr_bg       <- "#0D1117"
clr_surface  <- "#161B22"
clr_card     <- "#1C2128"
clr_border   <- "#30363D"
clr_accent   <- "#2EA043"   # verde "tierra viva"
clr_accent2  <- "#388BFD"   # azul datos
clr_warn     <- "#D29922"
clr_text     <- "#E6EDF3"
clr_muted    <- "#8B949E"

app_theme <- bs_theme(
  version      = 5,
  bg           = clr_bg,
  fg           = clr_text,
  primary      = clr_accent,
  secondary    = clr_accent2,
  base_font    = font_google("IBM Plex Sans"),
  heading_font = font_google("Space Grotesk", wght = "700"),
  code_font    = font_google("IBM Plex Mono"),
  "card-bg"             = clr_card,
  "card-border-color"   = clr_border,
  "navbar-bg"           = clr_surface,
  "body-bg"             = clr_bg,
  "border-radius"       = "10px",
  "box-shadow"          = "0 4px 24px rgba(0,0,0,.45)"
)

# ── Indicadores WDI ─────────────────────────────────────────
IND_GDP  <- "NY.GDP.PCAP.CD"   # PBI per cápita (US$ corrientes)
IND_CO2  <- "EN.GHG.CO2.PC.CE.AR5"   # CO₂ per cápita (t) - nuevo indicador WB
IND_POP  <- "SP.POP.TOTL"      # Población total

# Regiones disponibles
REGIONS <- c(
  "Todo el mundo"       = "all",
  "América Latina"      = "LAC",
  "Europa & Asia Central" = "ECS",
  "Asia Oriental & Pacífico" = "EAS",
  "Asia Meridional"     = "SAS",
  "África Subsahariana" = "SSF",
  "Medio Oriente & N. África" = "MEA",
  "América del Norte"   = "NAC"
)

# ── Carga de datos (cache) ───────────────────────────────────
load_data <- function() {
  raw <- wb_data(
    indicator = c("gdp_pc" = IND_GDP,
                  "co2_pc" = IND_CO2,
                  "pop"    = IND_POP),
    start_date = 1990,
    end_date   = 2022,
    return_wide = TRUE
  )

  # wb_data ya trae columna 'country'; solo tomamos metadata extra de wb_countries
  meta <- wb_countries() |>
    select(iso3c, region_iso3c, region, income_level, income_level_iso3c)

  raw |>
    left_join(meta, by = "iso3c") |>
    filter(!is.na(gdp_pc), !is.na(co2_pc), !is.na(region)) |>
    mutate(
      country     = country,   # columna ya existe desde wb_data
      log_gdp     = log10(gdp_pc),
      gdp_pc_fmt  = dollar(gdp_pc, accuracy = 1),
      co2_pc_fmt  = paste0(round(co2_pc, 2), " t"),
      pop_fmt     = number(pop, scale_cut = cut_short_scale())
    )
}

# ── UI ───────────────────────────────────────────────────────
ui <- page_navbar(
  title = tags$span(
    tags$img(src = "https://img.icons8.com/fluency/28/globe-earth.png",
             style = "vertical-align:middle; margin-right:8px;"),
    "PBI per Cápita  vs  Emisiones de CO₂"
  ),
  theme    = app_theme,
  fillable = TRUE,

  # CSS personalizado
  header = tags$head(
    tags$style(HTML(glue::glue("
      body {{ background-color: {clr_bg}; }}
      .navbar {{ border-bottom: 1px solid {clr_border}; }}
      .kpi-value {{ font-size: 2rem; font-weight: 700; color: {clr_accent}; }}
      .kpi-label {{ font-size: .78rem; color: {clr_muted}; letter-spacing:.06em; text-transform:uppercase; }}
      .sidebar {{ background: {clr_surface} !important; border-right: 1px solid {clr_border}; }}
      .form-label {{ color: {clr_muted}; font-size:.82rem; }}
      .card-header {{ border-bottom: 1px solid {clr_border}; font-weight:600; }}
      hr {{ border-color: {clr_border}; }}
      .badge-region {{ background:{clr_accent2}; color:#fff; border-radius:4px;
                       padding:2px 7px; font-size:.75rem; }}
      .source-note {{ font-size:.72rem; color:{clr_muted}; margin-top:6px; }}
    ")))
  ),

  # ── Pestaña 1: Dispersión ────────────────────────────────
  nav_panel(
    title = "Dispersión",
    icon  = icon("circle-dot"),
    layout_sidebar(
      fillable = TRUE,
      sidebar = sidebar(
        width = 280,
        title = "Filtros",

        selectInput("year", "Año",
                    choices  = 2022:1990,
                    selected = 2019),

        selectInput("region", "Región",
                    choices  = REGIONS,
                    selected = "all"),

        selectInput("income", "Nivel de ingreso",
                    choices  = c("Todos" = "all",
                                 "Alto"         = "High income",
                                 "Medio-alto"   = "Upper middle income",
                                 "Medio-bajo"   = "Lower middle income",
                                 "Bajo"         = "Low income"),
                    selected = "all"),

        hr(),
        checkboxInput("log_x", "Eje X logarítmico (PBI)", TRUE),
        checkboxInput("show_trend", "Mostrar línea de tendencia", TRUE),
        checkboxInput("size_pop", "Tamaño = Población", TRUE),

        hr(),
        div(class = "source-note",
          icon("database"), " ",
          tags$a("Banco Mundial – WDI",
                 href = "https://databank.worldbank.org/source/world-development-indicators",
                 target = "_blank",
                 style = glue::glue("color:{clr_accent2};")),
          br(), "Indicadores: NY.GDP.PCAP.CD · EN.GHG.CO2.PC.CE.AR5"
        )
      ),

      # KPIs + gráfico
      layout_columns(
        col_widths = c(4, 4, 4),
        value_box(
          title    = "Países incluidos",
          value    = textOutput("kpi_n"),
          showcase = icon("globe"),
          theme    = value_box_theme(bg = clr_card, fg = clr_text)
        ),
        value_box(
          title    = "PBI per cápita mediano",
          value    = textOutput("kpi_gdp"),
          showcase = icon("dollar-sign"),
          theme    = value_box_theme(bg = clr_card, fg = clr_text)
        ),
        value_box(
          title    = "CO₂ per cápita mediano",
          value    = textOutput("kpi_co2"),
          showcase = icon("smog"),
          theme    = value_box_theme(bg = clr_card, fg = clr_text)
        )
      ),

      card(
        full_screen = TRUE,
        card_header("Relación PBI per Cápita ↔ Emisiones de CO₂"),
        plotlyOutput("scatter", height = "480px")
      )
    )
  ),

  # ── Pestaña 2: Serie temporal ────────────────────────────
  nav_panel(
    title = "Serie Temporal",
    icon  = icon("chart-line"),
    layout_sidebar(
      fillable = TRUE,
      sidebar = sidebar(
        width = 280,
        title = "Países a comparar",
        selectizeInput(
          "countries_ts",
          "Selecciona países (máx. 8)",
          choices  = NULL,
          multiple = TRUE,
          options  = list(maxItems = 8,
                          placeholder = "Escribe el nombre…")
        ),
        hr(),
        radioButtons("metric_ts", "Métrica",
                     choices  = c("PBI per cápita (US$)" = "gdp_pc",
                                  "CO₂ per cápita (t)"   = "co2_pc"),
                     selected = "co2_pc")
      ),
      card(
        full_screen = TRUE,
        card_header("Evolución histórica 1990–2022"),
        plotlyOutput("timeseries", height = "500px")
      )
    )
  ),

  # ── Pestaña 3: Tabla ─────────────────────────────────────
  nav_panel(
    title = "Datos",
    icon  = icon("table"),
    card(
      full_screen = TRUE,
      card_header("Tabla de datos – último año disponible por país"),
      DTOutput("tabla")
    )
  ),

  # ── Pestaña 4: Metodología ───────────────────────────────
  nav_panel(
    title = "Metodología",
    icon  = icon("info-circle"),
    layout_columns(
      col_widths = c(8, 4),
      card(
        card_header("¿Qué mide este dashboard?"),
        card_body(
          h5("PBI per Cápita"),
          p("Producto Interior Bruto dividido entre la población total, expresado en dólares
            estadounidenses corrientes (NY.GDP.PCAP.CD). Refleja el nivel de desarrollo
            económico promedio por habitante."),
          h5("Emisiones de CO₂ per Cápita"),
          p("Toneladas métricas de dióxido de carbono emitidas por habitante
            (EN.ATM.CO2E.PC). Incluye emisiones por quema de combustibles fósiles y
            fabricación de cemento."),
          h5("La hipótesis de la Curva de Kuznets Ambiental (EKC)"),
          p("La EKC propone que la contaminación ambiental primero aumenta con el
            crecimiento económico y luego disminuye una vez que se supera cierto umbral de
            ingreso. El gráfico de dispersión permite explorar visualmente esta relación
            para distintos años y regiones."),
          h5("Fuente de datos"),
          p(tags$a("World Development Indicators (WDI) – Banco Mundial",
                   href = "https://databank.worldbank.org/source/world-development-indicators",
                   target = "_blank"))
        )
      ),
      card(
        card_header("Indicadores utilizados"),
        card_body(
          tags$ul(
            tags$li(tags$b("NY.GDP.PCAP.CD"),       " – PBI per cápita (US$ corrientes)"),
            tags$li(tags$b("EN.GHG.CO2.PC.CE.AR5"), " – CO₂ per cápita (toneladas, excl. LULUCF)"),
            tags$li(tags$b("SP.POP.TOTL"),          " – Población total")
          ),
          hr(),
          p(class = "source-note",
            "Datos descargados en tiempo real vía el paquete ",
            tags$code("wbstats"), " de R.")
        )
      )
    )
  )
)

# ── SERVER ───────────────────────────────────────────────────
server <- function(input, output, session) {

  # Carga inicial (spinner automático de Shiny)
  all_data <- reactive({
    withProgress(message = "Descargando datos del Banco Mundial…",
                 value = 0.3, {
      d <- load_data()
      incProgress(0.7)
      d
    })
  })

  # Poblar selector de países para Serie Temporal
  observe({
    paises <- sort(unique(all_data()$country))
    updateSelectizeInput(session, "countries_ts",
                         choices  = paises,
                         selected = c("Peru", "Chile", "Brazil",
                                      "Germany", "China", "United States"),
                         server   = TRUE)
  })

  # ── Datos filtrados para dispersión ──────────────────────
  filt <- reactive({
    df <- all_data() |>
      filter(date == as.integer(input$year))

    if (input$region != "all")
      df <- df |> filter(region_iso3c == input$region)

    if (input$income != "all")
      df <- df |> filter(income_level == input$income)

    df
  })

  # ── KPIs ─────────────────────────────────────────────────
  output$kpi_n <- renderText({
    nrow(filt())
  })
  output$kpi_gdp <- renderText({
    dollar(median(filt()$gdp_pc, na.rm = TRUE), accuracy = 1)
  })
  output$kpi_co2 <- renderText({
    paste0(round(median(filt()$co2_pc, na.rm = TRUE), 2), " t")
  })

  # ── Scatter ───────────────────────────────────────────────
  output$scatter <- renderPlotly({
    df <- filt()
    req(nrow(df) > 0)

    x_var  <- if (input$log_x) "log_gdp" else "gdp_pc"
    x_lab  <- if (input$log_x) "PBI per capita (log10 US$)" else "PBI per capita (US$)"
    df$sz_var <- if (input$size_pop) df$pop else rep(5e7, nrow(df))

    p <- ggplot(df, aes(
      x      = .data[[x_var]],
      y      = co2_pc,
      color  = region,
      size   = sz_var,
      text   = paste0("<b>", country, "</b><br>",
                      "PBI pc: ", gdp_pc_fmt, "<br>",
                      "CO2 pc: ", co2_pc_fmt, "<br>",
                      "Poblacion: ", pop_fmt)
    )) +
      geom_point(alpha = .72) +
      scale_size(range = c(2, 18), guide = "none") +
      scale_color_brewer(palette = "Set2", name = "Región") +
      labs(x = x_lab, y = "CO2 per capita (toneladas)", title = NULL) +
      theme_minimal(base_family = "IBM Plex Sans") +
      theme(
        plot.background  = element_rect(fill = clr_card,    color = NA),
        panel.background = element_rect(fill = clr_card,    color = NA),
        panel.grid.major = element_line(color = clr_border,  linewidth = .4),
        panel.grid.minor = element_blank(),
        axis.text        = element_text(color = clr_muted),
        axis.title       = element_text(color = clr_text),
        legend.background = element_rect(fill = clr_card, color = NA),
        legend.text      = element_text(color = clr_muted),
        legend.title     = element_text(color = clr_text)
      )

    if (input$show_trend)
      p <- p + geom_smooth(aes(group = 1), method = "loess",
                           color  = clr_warn, fill = clr_warn,
                           alpha  = .15, se = TRUE, linewidth = .9,
                           show.legend = FALSE)

    ggplotly(p, tooltip = "text") |>
      layout(
        paper_bgcolor = clr_card,
        plot_bgcolor  = clr_card,
        font          = list(color = clr_text),
        legend        = list(font = list(color = clr_muted))
      ) |>
      config(displayModeBar = FALSE)
  })

  # ── Serie temporal ────────────────────────────────────────
  output$timeseries <- renderPlotly({
    req(length(input$countries_ts) > 0)

    df <- all_data() |>
      filter(country %in% input$countries_ts) |>
      select(country, date, val = all_of(input$metric_ts))

    y_lab <- if (input$metric_ts == "gdp_pc") "PBI per cápita (US$)"
             else "CO₂ per cápita (toneladas)"

    fmt_val <- if (input$metric_ts == "gdp_pc") {
      dollar(df$val, accuracy = 1)
    } else {
      paste0(round(df$val, 2), " t")
    }

    p <- ggplot(df, aes(x = date, y = val, color = country,
                        text = paste0(country, " \u2013 ", date, ": ", fmt_val))) +
      geom_line(linewidth = 1.1) +
      geom_point(size = 1.8) +
      scale_color_brewer(palette = "Paired", name = NULL) +
      labs(x = NULL, y = y_lab) +
      theme_minimal(base_family = "IBM Plex Sans") +
      theme(
        plot.background  = element_rect(fill = clr_card, color = NA),
        panel.background = element_rect(fill = clr_card, color = NA),
        panel.grid.major = element_line(color = clr_border, linewidth = .4),
        panel.grid.minor = element_blank(),
        axis.text        = element_text(color = clr_muted),
        axis.title       = element_text(color = clr_text),
        legend.background = element_rect(fill = clr_card, color = NA),
        legend.text      = element_text(color = clr_muted)
      )

    ggplotly(p, tooltip = "text") |>
      layout(
        paper_bgcolor = clr_card,
        plot_bgcolor  = clr_card,
        font          = list(color = clr_text),
        legend        = list(font = list(color = clr_muted),
                             orientation = "h", y = -0.15)
      ) |>
      config(displayModeBar = FALSE)
  })

  # ── Tabla ─────────────────────────────────────────────────
  output$tabla <- renderDT({
    df <- all_data() |>
      group_by(iso3c) |>
      filter(date == max(date)) |>
      ungroup() |>
      select(
        País       = country,
        Región     = region,
        Ingreso    = income_level,
        Año        = date,
        `PBI pc (US$)`   = gdp_pc_fmt,
        `CO₂ pc (t)`     = co2_pc_fmt,
        Población  = pop_fmt
      )

    datatable(
      df,
      rownames = FALSE,
      filter   = "top",
      options  = list(
        pageLength = 15,
        dom        = "frtip",
        language   = list(url = "//cdn.datatables.net/plug-ins/1.10.11/i18n/es-ES.json")
      ),
      class = "display compact"
    ) |>
      formatStyle(
        columns    = "CO₂ pc (t)",
        background = styleColorBar(range(0, 20), clr_accent2),
        color      = clr_text
      )
  })
}

shinyApp(ui, server)

# Instalar gert si no lo tienes (manejo de Git desde R)
install.packages("gert")

library(gert)
