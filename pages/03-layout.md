---
title: 3. Layout y presentación
sidebar_position: 7
page_width: full
---

# 3. Layout y presentación

## 3.1 Los datos de esta página

```sql ventas_demo
select cast('2026-01-01' as date) as fecha, 'Electrónica' as categoria, 12400 as ventas, 41 as pedidos
union all select cast('2026-02-01' as date), 'Electrónica', 13150, 44
union all select cast('2026-03-01' as date), 'Electrónica', 14890, 49
union all select cast('2026-04-01' as date), 'Electrónica', 14020, 46
union all select cast('2026-05-01' as date), 'Electrónica', 15680, 52
union all select cast('2026-06-01' as date), 'Electrónica', 17230, 58
union all select cast('2026-01-01' as date), 'Hogar', 8300, 57
union all select cast('2026-02-01' as date), 'Hogar', 7920, 54
union all select cast('2026-03-01' as date), 'Hogar', 9150, 62
union all select cast('2026-04-01' as date), 'Hogar', 8870, 60
union all select cast('2026-05-01' as date), 'Hogar', 9640, 66
union all select cast('2026-06-01' as date), 'Hogar', 10120, 69
union all select cast('2026-01-01' as date), 'Deportes', 5100, 33
union all select cast('2026-02-01' as date), 'Deportes', 5480, 35
union all select cast('2026-03-01' as date), 'Deportes', 6320, 40
union all select cast('2026-04-01' as date), 'Deportes', 6010, 38
union all select cast('2026-05-01' as date), 'Deportes', 6890, 43
union all select cast('2026-06-01' as date), 'Deportes', 7410, 46
```

## 3.2 Filas y columnas

`row` coloca sus hijos en horizontal y `stack` en vertical. Si no caben, los
elementos de una fila bajan a la línea siguiente de forma automática.

```jinja
{% row align="center" %}
  {% big_value data="ventas_demo" value="sum(ventas)" fmt="usd1m" title="Ventas" /%}
  {% big_value data="ventas_demo" value="sum(pedidos)" fmt="num0" title="Pedidos" /%}
  {% big_value data="ventas_demo" value="sum(ventas) / sum(pedidos)" fmt="usd2" title="Ticket medio" /%}
{% /row %}
```

{% row align="center" %}
  {% big_value data="ventas_demo" value="sum(ventas)" fmt="usd1m" title="Ventas" /%}
  {% big_value data="ventas_demo" value="sum(pedidos)" fmt="num0" title="Pedidos" /%}
  {% big_value data="ventas_demo" value="sum(ventas) / sum(pedidos)" fmt="usd2" title="Ticket medio" /%}
{% /row %}

`row` acepta `align` (`top`, `center`, `bottom`, `stretch`) para alinear en vertical;
`stack` acepta `align` (`left`, `center`, `right`, `stretch`) para alinear en
horizontal. Dentro de un `row` puedes anidar un `stack` para agrupar dos gráficos en
una columna:

```jinja
{% row %}
  {% stack %}
    {% line_chart data="ventas_demo" x="fecha" y="sum(ventas)" date_grain="month" /%}
    {% line_chart data="ventas_demo" x="fecha" y="sum(pedidos)" date_grain="month" /%}
  {% /stack %}
  {% table data="ventas_demo" /%}
{% /row %}
```

## 3.3 Formatos de valor

El atributo `fmt` (y sus variantes `y_fmt`, `x_fmt`) formatea los números sin tocar
el SQL. Los códigos más usados:

| Código | Resultado | Código | Resultado |
| --- | --- | --- | --- |
| `num0` / `num2` | 11 / 11.23 | `usd` | $412 |
| `num0k` / `num1k` | 64k / 64.2k | `usd2` | $412.12 |
| `num0m` / `num1m` | 43M / 42.5M | `usd0k` / `usd1m` | $412k / $412.1m |
| `pct0` / `pct1` | 25% / 25.1% | `eur2`, `gbp2`, `jpy0` | otras divisas |
| `id` | 921594675 | `mult` | 5.3x |
| `mmm-yy` | Jan-26 | `shortdate` / `longdate` | Jan 9/26 / January 9, 2026 |

Compara el mismo número con tres formatos:

{% row %}
  {% big_value data="ventas_demo" value="sum(ventas)" fmt="usd2" title="usd2" /%}
  {% big_value data="ventas_demo" value="sum(ventas)" fmt="usd1k" title="usd1k" /%}
  {% big_value data="ventas_demo" value="sum(ventas) / sum(pedidos)" fmt="usd0" title="usd0" /%}
{% /row %}

## 3.4 Series temporales

Con `date_grain` agrupas por mes, trimestre, día de la semana o mes del año sin
escribir SQL. Con `series` generas una serie por cada valor de la columna.

{% line_chart
  data="ventas_demo"
  x="fecha"
  y="sum(ventas)"
  series="categoria"
  date_grain="month"
  y_fmt="usd0k"
  title="Ventas mensuales por categoría"
  subtitle="Suma de la columna ventas"
/%}

{% area_chart
  data="ventas_demo"
  x="fecha"
  y="sum(ventas)"
  series="categoria"
  date_grain="month"
  stacked=true
  title="Composición de ventas (área apilada)"
/%}

Otros valores útiles de `date_grain`: `quarter`, `year`, `day of week`,
`month of year`, `week of year`, `day of month`.

## 3.5 Tablas con dimensiones y medidas

Además de la tabla simple, `table` admite **hijos** que declaran columnas con
nombre, formato, comparativas o pivotes:

```jinja
{% table data="ventas_demo" title="Categorías y ticket medio" %}
  {% dimension value="categoria" /%}
  {% measure value="sum(ventas)" fmt="usd1m" /%}
  {% measure value="sum(pedidos)" fmt="num0" /%}
  {% measure value="sum(ventas) / sum(pedidos) as ticket_medio" fmt="usd2" /%}
{% /table %}
```

{% table data="ventas_demo" title="Categorías y ticket medio" %}
  {% dimension value="categoria" /%}
  {% measure value="sum(ventas)" fmt="usd1m" /%}
  {% measure value="sum(pedidos)" fmt="num0" /%}
  {% measure value="sum(ventas) / sum(pedidos) as ticket_medio" fmt="usd2" /%}
{% /table %}

Y con `pivot` conviertes una dimensión temporal en columnas:

```jinja
{% table data="ventas_demo" %}
  {% dimension value="categoria" /%}
  {% pivot value="fecha" date_grain="month" /%}
  {% measure value="sum(ventas)" fmt="usd0k" /%}
{% /table %}
```

{% table data="ventas_demo" %}
  {% dimension value="categoria" /%}
  {% pivot value="fecha" date_grain="month" /%}
  {% measure value="sum(ventas)" fmt="usd0k" /%}
{% /table %}

## 3.6 Big values con sparkline y comparación

```jinja
{% big_value
  data="ventas_demo"
  value="sum(ventas)"
  fmt="usd1m"
  sparkline={ type="line" x="fecha" }
  title="Ventas con tendencia"
/%}
```

{% big_value
  data="ventas_demo"
  value="sum(ventas)"
  fmt="usd1m"
  sparkline={ type="line" x="fecha" }
  title="Ventas con tendencia"
/%}

La comparación se configura con `comparison` y necesita que los datos cubran también
el periodo de comparación, por eso aquí solo se muestra el código:

```markdown
{% big_value
  data="ventas_demo"
  value="sum(ventas)"
  fmt="usd1m"
  date_range={ date="fecha" range="last 12 months" }
  comparison={ compare_vs="prior year" }
/%}
```

## 3.7 Bloques de contenido

{% callout %}
Un `callout` sirve para destacar una idea dentro del informe.
{% /callout %}

{% note %}
Una `note` añade una nota al margen, menos llamativa que el callout.
{% /note %}

También hay `details` (plegable), `accordion`, `tabs` con `tab`, `modal`, `download`
(botón de descarga a Excel), `image`, `link_button` o `info` (icono con tooltip).
Ejemplo de pestañas:

```jinja
{% tabs %}
  {% tab title="Resumen" %}
    Contenido de la primera pestaña.
  {% /tab %}
  {% tab title="Detalle" %}
    {% table data="ventas_demo" /%}
  {% /tab %}
{% /tabs %}
```
