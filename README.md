# 🌍 Dashboard: PBI per Cápita vs Emisiones de CO₂

Dashboard interactivo construido con **R Shiny** y **bslib** que explora la relación entre el PBI per cápita y las emisiones de CO₂ per cápita a nivel mundial, usando datos en tiempo real del **Banco Mundial (WDI)**.

---

## 📊 Características

| Sección | Descripción |
|---|---|
| **Dispersión** | Gráfico interactivo con filtros por año, región y nivel de ingreso. Opción de eje logarítmico y curva LOESS (Curva de Kuznets). |
| **Serie Temporal** | Evolución 1990–2022 para hasta 8 países seleccionados. |
| **Datos** | Tabla completa y filtrable con el último año disponible por país. |
| **Metodología** | Descripción de indicadores y la hipótesis EKC. |

---

## 🚀 Instalación y uso

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU_USUARIO/pbi-co2-dashboard.git
cd pbi-co2-dashboard
```

### 2. Instalar dependencias en R

```r
install.packages(c(
  "shiny",
  "bslib",
  "wbstats",
  "ggplot2",
  "plotly",
  "dplyr",
  "scales",
  "DT",
  "glue"
))
```

### 3. Ejecutar la app

```r
shiny::runApp("app.R")
```

O desde la terminal:

```bash
Rscript -e "shiny::runApp('app.R')"
```

---

## 📦 Dependencias

| Paquete | Uso |
|---|---|
| `shiny` | Framework web reactivo |
| `bslib` | Temas Bootstrap 5 modernos |
| `wbstats` | Descarga de datos del Banco Mundial |
| `ggplot2` | Visualizaciones base |
| `plotly` | Interactividad en los gráficos |
| `dplyr` | Manipulación de datos |
| `scales` | Formato numérico |
| `DT` | Tabla interactiva |
| `glue` | Interpolación de strings |

---

## 📡 Indicadores del Banco Mundial

| Código | Descripción |
|---|---|
| `NY.GDP.PCAP.CD` | PBI per cápita (US$ corrientes) |
| `EN.ATM.CO2E.PC` | Emisiones de CO₂ per cápita (toneladas métricas) |
| `SP.POP.TOTL` | Población total |

> Los datos se descargan en tiempo real al iniciar la app usando el paquete `wbstats`. Se requiere conexión a internet.

---

## 🌱 La Curva de Kuznets Ambiental (EKC)

La hipótesis de la EKC sostiene que la contaminación ambiental primero **aumenta** con el desarrollo económico y luego **disminuye** una vez superado un umbral de ingreso, formando una curva en forma de ∩. Este dashboard permite explorar visualmente esta relación.

---

## 🖥️ Deploy en shinyapps.io

```r
install.packages("rsconnect")
rsconnect::deployApp(".")
```

---

## 📄 Licencia

MIT License — libre para usar, modificar y distribuir.

---

*Datos: [World Development Indicators – Banco Mundial](https://databank.worldbank.org/source/world-development-indicators)*
