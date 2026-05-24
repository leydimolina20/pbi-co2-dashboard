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


## 🌱 La Curva de Kuznets Ambiental (EKC)

La hipótesis de la EKC sostiene que la contaminación ambiental primero **aumenta** con el desarrollo económico y luego **disminuye** una vez superado un umbral de ingreso, formando una curva en forma de ∩. Este dashboard permite explorar visualmente esta relación.

---


*Datos: [World Development Indicators – Banco Mundial](https://databank.worldbank.org/source/world-development-indicators)*
