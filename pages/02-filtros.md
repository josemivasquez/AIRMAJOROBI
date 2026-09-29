---
title: 2. Filtros e interacción
sidebar_position: 6
empresa:
  nombre: ACME S.L.
  sector: Distribución
---

# 2. Filtros e interacción

## 2.1 Los datos de esta página

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

## 2.2 Un dropdown que alimenta al resto de la página

Las opciones pueden salir de la propia base de datos: el componente consulta los
valores distintos de una columna y guarda lo que el usuario elija bajo su `id`.

{% dropdown
  id="filtro_categoria"
  data="ventas_demo"
  value_column="categoria"
  title="Categoría"
/%}

El enganche a los demás componentes se hace con el atributo `filters`, que recibe
una lista de ids de filtros:

```jinja
{% table
  data="ventas_demo"
  filters=["filtro_categoria"]
/%}
```

Prueba a cambiar el desplegable: estos dos componentes se recalculan solos, sin
escribir una línea de JavaScript.

{% table
  data="ventas_demo"
  filters=["filtro_categoria"]
  title="Tabla filtrada por el dropdown"
/%}

{% bar_chart
  data="ventas_demo"
  x="fecha"
  y="sum(ventas)"
  series="categoria"
  date_grain="month"
  filters=["filtro_categoria"]
  title="Evolución mensual filtrada"
/%}

## 2.3 La variable del filtro dentro del SQL

El mismo filtro se puede usar **dentro** de una consulta interpolando su nombre. Así
puedes construir agregaciones propias que ya vengan filtradas:

```sql ventas_por_categoria
select
    categoria,
    sum(ventas) as total,
    sum(pedidos) as pedidos,
    sum(ventas) / sum(pedidos) as ticket_medio
from ventas_demo
where 1 = 1
[[ and categoria = {{ filtro_categoria }} ]]
group by categoria
order by total desc
```

{% table data="ventas_por_categoria" title="Ventas por categoría (usa el filtro)" /%}

Dos detalles importantes:

- El bloque `[[ ... ]]` solo se incluye en el SQL si la variable tiene valor. Es la
  forma idiomática de escribir filtros opcionales sin romper la consulta.
- Un dropdown puede permitir varios valores; en ese caso la interpolación devuelve
  una lista SQL del tipo `('Hogar', 'Deportes')`, lista para un `in`.

## 2.4 Propiedades de la variable de un filtro

Cuando interpolas un filtro, Evidence elige el formato según el contexto (SQL, texto
o atributo). También puedes pedir una propiedad concreta:

| Propiedad | Devuelve | Sin selección | Con "Hogar" seleccionado |
| --- | --- | --- | --- |
| `.selected` | valor entrecomillado para SQL | `''` | `'Hogar'` |
| `.filter` | expresión completa de `where` | `true` | `categoria = 'Hogar'` |
| `.literal` | texto plano, sin comillas | vacío | `Hogar` |
| `.label` | etiqueta visible de la opción | vacío | `Hogar` |

Ejemplo de uso de `.filter` (incluye `true` cuando no hay selección, así que nunca
rompe la consulta):

```jinja
{% table data="ventas_demo" where="{{ filtro_categoria.filter }}" /%}
```

## 2.5 Filtro de rango de fechas

```jinja
{% range_calendar id="filtro_fechas" title="Periodo" value_column="fecha" /%}
```

{% range_calendar id="filtro_fechas" title="Periodo" value_column="fecha" /%}

Su variable aporta sobre todo el fragmento `between`, que encaja directamente en un
`where` (cuando no hay selección se resuelve como `is not null`):

```sql ventas_periodo
select fecha, sum(ventas) as total
from ventas_demo
where fecha {{ filtro_fechas.between }}
group by fecha
order by fecha
```

{% line_chart
  data="ventas_periodo"
  x="fecha"
  y="sum(total)"
  y_fmt="usd0k"
  title="Ventas del periodo seleccionado"
/%}

Además de `filters=["filtro_fechas"]`, un filtro de fechas se puede aplicar sin SQL
con el atributo `date_range` de cualquier componente:

```jinja
{% big_value
  data="ventas_demo"
  value="sum(ventas)"
  fmt="usd1m"
  date_range={ range="last 6 months" date="fecha" }
/%}
```

## 2.6 Variables de la página

Cualquier clave del frontmatter que no sea un ajuste se convierte en variable y se
referencia con el prefijo `$`. Esta página declara `empresa.nombre` y
`empresa.sector`, así que podemos usarlas:

## Informe de {{ $empresa.nombre }}

Sector: **{{ $empresa.sector }}**.

{% big_value
  data="ventas_demo"
  value="sum(ventas)"
  fmt="usd1m"
  title="Ventas totales de {{ $empresa.nombre }}"
/%}

También funcionan en atributos y admiten arrays y objetos:

```yaml
---
title: Mi página
empresa:
  nombre: ACME S.L.
colores: [red, green, blue]
---
```

## 2.7 Varios filtros a la vez

`filters` acepta una lista, y los filtros se pueden apilar:

```jinja
{% table data="ventas_demo" filters=["filtro_categoria", "filtro_fechas"] /%}
```

Para juntar muchos filtros en una barra flotante arriba de la página existe el
componente `filter_bar`, y `button_group`, `toggle`, `slider` o `text_input`
cubren el resto de casos de interacción.
