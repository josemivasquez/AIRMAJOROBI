---
title: 1. Fundamentos
sidebar_position: 5
---

# 1. Fundamentos

## 1.1 Una página es Markdown

Cualquier fichero `.md` dentro de `pages/` es una página del informe. El bloque
delimitado por `---` al principio es el **frontmatter** y define ajustes de página:

```yaml
---
title: Ventas 2026      # nombre en la barra lateral y en la pestaña del navegador
sidebar_position: 3     # orden dentro de su grupo (menor = antes)
page_width: full        # article (por defecto) | full
---
```

Cualquier clave del frontmatter que **no** sea un ajuste de página se convierte en
una **variable** reutilizable (lo veremos en la página 2).

## 1.2 Las consultas SQL son bloques de código

Un bloque de código marcado como `sql` **se ejecuta** contra tu warehouse. El nombre
que escribes detrás de `sql` es el identificador de la consulta, y así es como los
componentes la referencian. Ese nombre debe ser único dentro de la página.

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

El dialecto por defecto es **ClickHouse SQL**; si usas un conector directo a tu
warehouse, se ejecuta el SQL nativo de ese motor. Por eso este ejemplo usa
`cast(... as date)` y no funciones específicas de un motor.

## 1.3 Tu primer componente: un valor suelto

Los componentes se escriben entre llaves y porcentajes, en `snake_case`, y su
resultado se conecta a una consulta con el atributo `data`. Este muestra la suma de
ventas de la consulta que acabamos de definir:

{% value data="ventas_demo" value="sum(ventas)" fmt="usd0k" /%}

## 1.4 Una tabla

```jinja
{% table
  data="ventas_demo"
  title="Ventas por mes y categoría"
  limit=50
/%}
```

Así se ve:

{% table
  data="ventas_demo"
  title="Ventas por mes y categoría"
  limit=50
/%}

## 1.5 Un gráfico

```jinja
{% bar_chart
  data="ventas_demo"
  x="categoria"
  y="sum(ventas)"
  order="sum(ventas) desc"
  title="Ventas por categoría"
/%}
```

Así se ve:

{% bar_chart
  data="ventas_demo"
  x="categoria"
  y="sum(ventas)"
  order="sum(ventas) desc"
  title="Ventas por categoría"
/%}

Fíjate en el patrón: `x` es la dimensión, `y` una **agregación SQL** que Evidence
añade al `GROUP BY` de la consulta. No hace falta escribir el `group by` a mano.

## 1.6 Reutilizar una consulta dentro de otra

Dentro de un bloque `sql` puedes referenciar otra consulta de la misma página por su
nombre; Evidence la sustituye entre paréntesis:

```sql top_categorias
select categoria, sum(ventas) as total
from {{ventas_demo}} as v
group by categoria
order by total desc
limit 2
```

```sql ventas_top
select categoria, sum(ventas) as total, sum(pedidos) as pedidos
from {{ventas_demo}} as v
where categoria in (select t.categoria from {{top_categorias}} as t)
group by categoria
```

{% table data="ventas_top" title="Solo las 2 categorías con más ventas" /%}

## 1.7 Ver los cambios en vivo

Con el servidor de desarrollo abierto, cada vez que guardas un `.md` la página se
refresca sola:

```bash
evidence dev
```

Y antes de hacer commit, valida la sintaxis de todo el proyecto (no necesita conexión):

```bash
evidence validate
```
