---
title: 4. Flujo de trabajo
sidebar_position: 8
---

# 4. Flujo de trabajo

## 4.1 La CLI de Evidence

Todo se hace desde el terminal, en la raíz del proyecto:

| Comando | Para qué sirve |
| --- | --- |
| `evidence help` | Lista todos los comandos disponibles |
| `evidence dev` | Servidor local con recarga en caliente |
| `evidence validate` | Valida la sintaxis Markdown/componentes (sin conexión) |
| `evidence query "select ..."` | Ejecuta SQL suelto (`--file`, `--limit`, `--all`, `-o`) |
| `evidence tables` | Lista las tablas disponibles |
| `evidence describe <tabla>` | Esquema de una tabla |
| `evidence schema` | Todas las tablas y sus columnas |
| `evidence connectors` | Conectores configurados y su estado |
| `evidence models` | Modelos y estado de refresco |
| `evidence lineage` | Dónde se usa cada conexión y tabla |
| `evidence login` | Autenticarse con Evidence Studio (Evidence Warehouse) |
| `evidence launch` | Conectar el repo con Evidence Studio y publicar |
| `evidence serve` | Servidor de producción (necesita `connection.yaml`) |
| `evidence docs` | Buscar en la documentación desde el terminal |
| `evidence migrate` | Convertir un proyecto antiguo a la sintaxis nueva |
| `evidence upgrade` | Actualizar la CLI |

Ejemplos:

```bash
evidence query "select count(*) from ventas"
evidence query --file analisis.sql --limit 50 -o salida.csv
evidence describe ventas
```

## 4.2 Conectar tus datos

Hay dos caminos:

1. **Warehouse propio (sin cuenta).** Un fichero `connection.yaml` en la raíz. La CLI
   consulta tu base de datos directamente desde tu máquina. Es lo recomendado si ya
   tienes un warehouse.
2. **Evidence Warehouse (con cuenta).** Si no hay `connection.yaml`, las consultas van
   al warehouse gestionado de Evidence, y necesitas `evidence login`.

Para generar el esqueleto de `connection.yaml` con valores de ejemplo:

```bash
evidence init mi-proyecto --warehouse snowflake
evidence init mi-proyecto --warehouse bigquery
```

El fichero `connection.yaml` contiene credenciales y **no debe ir a Git** (añádelo a
`.gitignore`; `evidence init` ya lo hace por ti). Ejemplos de configuración:

```yaml
# connection.yaml — ClickHouse
type: clickhouse
host: abc123.us-east-1.aws.clickhouse.cloud
port: 8443
secure: true
username: default
password: mi-password
database: default
```

```yaml
# connection.yaml — Postgres
type: postgres
host: localhost
port: 5432
database: analytics
user: evidence_reader
password: mi-password
```

También admiten `schemas: [public, analytics]` para limitar lo que se ve en el
navegador de esquemas. Los conectores directos disponibles son Snowflake, Microsoft
Fabric, ClickHouse, BigQuery, Databricks, Postgres, Cube y MotherDuck.

## 4.3 Consultas reutilizables: `queries/`

Si una consulta se usa en varias páginas, sácala a un fichero `.sql`:

```text
queries/
└── ingresos_mensuales.sql
```

Y referénciala por ruta (una barra inicial significa "desde la raíz del proyecto"):

```markdown
{% line_chart data="/queries/ingresos_mensuales" x="mes" y="sum(ingresos)" /%}
```

Dentro de una consulta inline puedes encadenar un fichero `.sql` escribiendo su ruta
entre llaves dobles, igual que haces con el nombre de otra consulta de la página
(útil para filtrar o transformar por encima del fichero compartido).

Diferencia clave: los ficheros `.sql` **no** interpolan variables de la página; para
eso usa consultas inline.

## 4.4 Modelos y métricas

- **Modelos** (`Models` en la barra lateral, en fase beta): consultas SQL que se
  ejecutan en segundo plano y materializan el resultado. Se usan igual que una tabla
  (`data="mi_modelo"`) y son el sitio para joins, casts y lógica de negocio
  reutilizable.
- **Métricas** (`metrics/*.yaml`): definen una métrica una sola vez y luego la
  referencias por nombre desde cualquier componente con el atributo `metric` en lugar
  de `data` + `value`.

Regla práctica: en los modelos va la transformación (joins, agregaciones, `case`);
en las páginas, filtrar, ordenar y presentar.

## 4.5 Ajustes del proyecto

- `evidence.config.yaml`: nombre del proyecto, carpeta de páginas y opciones de
  layout globales.
- `theme.yaml`: colores (con variantes clara/oscura), paletas categóricas, escalas
  secuenciales y tokens de estilo (tipografía, radio, densidad...). Guárdalo junto
  al código: el tema se versiona en Git.
- Frontmatter de cada página: `title`, `sidebar_position`, `page_width`, `cards`,
  `table_of_contents`, `auto_refresh`, `theme` (override local) y `workflow.period`
  para informes periódicos con selector de periodo.

Ejemplo de informe periódico, que añade un selector de mes y la variable `period`:

````markdown
---
title: Informe mensual
workflow:
  period:
    grain: month
    periods: 12
---

# Informe del periodo en cifras
````

Con ese frontmatter la página gana un selector de periodo, y obtienes la variable
`period` con propiedades como `period.between` (fragmento `between` listo para el
`where`), `period.label` (texto del tipo "Jul 2026"), `period.start`, `period.end`,
`period.key` y `period.grain`. Se usa igual que un filtro: su nombre entre llaves
dobles, tanto en SQL como en el texto.

- `access.yaml`: permisos de páginas, solo relevante al publicar en Evidence Studio.

## 4.6 Git y publicación

Evidence es "BI como código": el repositorio es la fuente de verdad.

```bash
git add .
git commit -m "Añade informe de ventas"
git push
```

Para publicar online, conecta el repo con Evidence Studio (necesita `evidence login`
y un repositorio de GitHub; a partir de ahí, cada `git push` despliega):

```bash
evidence launch
```

Si prefieres tu propia infraestructura, `evidence serve` levanta el servidor de
producción (requiere `connection.yaml`).

## 4.7 Chuleta de sintaxis

| Necesito... | Escribo... |
| --- | --- |
| Definir una consulta | bloque de código con lenguaje `sql` y un nombre |
| Usar esa consulta | `data="nombre_de_la_consulta"` |
| Reutilizar otra consulta | `{{ nombre_consulta }}` dentro del SQL |
| Un valor suelto | `{% value data="q" value="sum(x)" fmt="usd1m" /%}` |
| Un KPI con tendencia | `{% big_value ... sparkline={ type="line" x="fecha" } /%}` |
| Una tabla | `{% table data="q" /%}` |
| Un gráfico | `{% bar_chart data="q" x="dim" y="sum(metric)" /%}` |
| Un filtro | `{% dropdown id="f" data="q" value_column="col" /%}` |
| Aplicar un filtro | `filters=["f"]` en el componente |
| Filtrar dentro del SQL | `where 1 = 1 [[ and col = {{ f }} ]]` |
| Un rango de fechas | `{% range_calendar id="d" /%}` y `where fecha {{ d.between }}` |
| Poner cosas en fila | `{% row %} ... {% /row %}` |
| Una constante de página | clave en el frontmatter y `{{ $clave }}` |
| Formatear un número | `fmt="usd1m"`, `fmt="num0k"`, `fmt="pct1"` |

## Siguiente paso

Cuando tengas tu `connection.yaml`, sustituye las consultas de ejemplo por las tuyas
y ejecuta:

```bash
evidence validate && evidence dev
```

