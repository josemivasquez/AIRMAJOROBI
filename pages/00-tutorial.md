---
title: Tutorial de Evidence
sidebar_position: 4
page_width: full
---

# Evidence, en la práctica

Guía interactiva para aprender **Evidence** dentro de este proyecto (`dashboardaim`).

Evidence es *BI como código*: cada informe es un fichero **Markdown** que contiene
consultas **SQL** en bloques de código y **componentes** para visualizarlos.
Todo vive en Git, se previsualiza con `evidence dev` y se publica con `evidence launch`.

> **Conexión de datos:** este proyecto ya está conectado al DWH Postgres `dwh_aim_db`
> mediante `connection.yaml` (esquema `dwh`, tablas `moves`, `newview`, `partners`,
> `static_airplanes`, `calendar`...). Las páginas de los dashboards consultan datos
> reales; las de este tutorial usan `select` con literales para que el foco esté en la
> sintaxis.

## Recorrido del tutorial

| Página | Qué aprendes |
| --- | --- |
| [1. Fundamentos](/01-fundamentos) | Página = Markdown + SQL + componentes |
| [2. Filtros e interacción](/02-filtros) | Dropdowns, variables y `filters` |
| [3. Layout y presentación](/03-layout) | Filas, tablas, gráficos y formatos |
| [4. Flujo de trabajo](/04-flujo-de-trabajo) | CLI, conexiones, modelos y publicación |

## Dashboards con datos reales

| Página | Qué muestra |
| --- | --- |
| [Torre de Control](/home) | KPIs, ingresos vs. costes, líneas de negocio |
| [Comercial · Rutas y clientes](/comercial) | Rutas, ticket medio, top clientes |
| [Flota y estructura de costes](/flota-costes) | Margen por aeronave, grupos de gasto, tipo de cambio |

## Estructura del proyecto

```text
dashboardaim/
├── evidence.config.yaml   # nombre del proyecto, carpetas, layout
├── theme.yaml             # colores, paletas y tokens de estilo
├── access.yaml            # permisos de páginas (solo al publicar)
├── connection.yaml        # credenciales del warehouse (va en .gitignore)
└── pages/
    └── *.md               # una página por informe
```

## El ciclo de trabajo

```bash
evidence validate   # comprueba la sintaxis de todas las páginas
evidence dev        # servidor local con recarga en caliente
evidence launch     # conecta el repo con Evidence Studio y publica
```

```bash
evidence schema     # tablas y columnas disponibles
evidence query "select count(*) from dwh.moves"
```
