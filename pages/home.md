---
title: Torre de Control
page_width: full
---

# Torre de Control · Air Majoro

Panel financiero del grupo (**Air Majoro** + **Air Majoro Selva**) sobre el DWH
`dwh_aim_db`. Los importes en dólares se convierten a soles con el tipo de cambio
diario de `dwh.calendar`, para que todas las cifras sean comparables.

## Filtros globales

```sql dim_empresas
select distinct company as empresa
from dwh.moves
order by 1
```

{% dropdown id="empresa" data="dim_empresas" value_column="empresa" title="Empresa" /%}

{% range_calendar id="fechas" title="Periodo" value_column="doc_date" /%}

## Resumen del periodo

```sql kpis
with mov as (
  select
    m.move_type,
    m.company,
    m.doc_date,
    case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end as importe_pen
  from dwh.moves m
  left join dwh.calendar c on c.date = m.doc_date
)
select
  round(sum(case when move_type = 'Ventas' then importe_pen else 0 end)::numeric, 0) as ingresos,
  round(abs(sum(case when move_type = 'Compras' then importe_pen else 0 end))::numeric, 0) as costes,
  round(sum(case when move_type = 'Ventas' then importe_pen else -importe_pen end)::numeric, 0) as margen,
  round((sum(case when move_type = 'Ventas' then importe_pen else -importe_pen end)
        / nullif(sum(case when move_type = 'Ventas' then importe_pen else 0 end), 0))::numeric, 4) as margen_pct,
  count(*) as documentos,
  round((sum(case when move_type = 'Ventas' then importe_pen else 0 end)
        / nullif(count(case when move_type = 'Ventas' then 1 end), 0))::numeric, 0) as ticket_medio
from mov
where 1 = 1
[[ and company = {{ empresa }} ]]
[[ and doc_date {{ fechas.between }} ]]
```

{% row %}
{% big_value data="kpis" value="sum(ingresos)" fmt="num0" title="Ingresos (S/)" /%}
{% big_value data="kpis" value="sum(costes)" fmt="num0" title="Costes (S/)" /%}
{% big_value data="kpis" value="sum(margen)" fmt="num0" title="Margen bruto (S/)" /%}
{% big_value data="kpis" value="avg(margen_pct)" fmt="pct1" title="Margen sobre ingresos" /%}
{% big_value data="kpis" value="sum(documentos)" fmt="num0" title="Documentos" /%}
{% big_value data="kpis" value="avg(ticket_medio)" fmt="num0" title="Ticket medio (S/)" /%}
{% /row %}

## Ingresos frente a costes

```sql flujo_mes
with mov as (
  select
    m.move_type,
    m.company,
    m.doc_date,
    case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end as importe_pen
  from dwh.moves m
  left join dwh.calendar c on c.date = m.doc_date
)
select
  to_char(date_trunc('month', doc_date), 'YYYY-MM') as mes,
  'Ingresos' as tipo,
  round(sum(case when move_type = 'Ventas' then importe_pen else 0 end)::numeric, 0) as importe
from mov
where 1 = 1
[[ and company = {{ empresa }} ]]
[[ and doc_date {{ fechas.between }} ]]
group by 1
union all
select
  to_char(date_trunc('month', doc_date), 'YYYY-MM') as mes,
  'Costes' as tipo,
  round(abs(sum(case when move_type = 'Compras' then importe_pen else 0 end))::numeric, 0) as importe
from mov
where 1 = 1
[[ and company = {{ empresa }} ]]
[[ and doc_date {{ fechas.between }} ]]
group by 1
order by mes
```

{% bar_chart
  data="flujo_mes"
  x="mes"
  y="sum(importe)"
  series="tipo"
  y_fmt="num0k"
  title="Ingresos y costes por mes (S/)"
  subtitle="2025 fue un año plano y con márgenes ajustados; 2026 arranca con un salto de facturación"
/%}

## Margen bruto

```sql margen_mes
with mov as (
  select
    m.move_type,
    m.company,
    m.doc_date,
    case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end as importe_pen
  from dwh.moves m
  left join dwh.calendar c on c.date = m.doc_date
)
select
  to_char(date_trunc('month', doc_date), 'YYYY-MM') as mes,
  round(sum(case when move_type = 'Ventas' then importe_pen else 0 end)::numeric, 0) as ingresos,
  round(abs(sum(case when move_type = 'Compras' then importe_pen else 0 end))::numeric, 0) as costes,
  round(sum(case when move_type = 'Ventas' then importe_pen else -importe_pen end)::numeric, 0) as margen
from mov
where 1 = 1
[[ and company = {{ empresa }} ]]
[[ and doc_date {{ fechas.between }} ]]
group by 1
order by 1
```

{% line_chart
  data="margen_mes"
  x="mes"
  y="sum(margen)"
  y_fmt="num0k"
  title="Margen bruto mensual (S/)"
/%}

{% table data="margen_mes" title="Ingresos, costes y margen por mes (S/)" /%}

## ¿De dónde sale el negocio?

```sql lineas
select
  coalesce(a.cuenta, 'Sin clasificar') as linea,
  round(sum(case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end)::numeric, 0) as ingresos
from dwh.moves m
left join dwh.calendar c on c.date = m.doc_date
left join dwh.static_master_accounts a on a.codigo_pcge = m.account
where m.move_type = 'Ventas'
[[ and m.company = {{ empresa }} ]]
[[ and m.doc_date {{ fechas.between }} ]]
group by 1
order by ingresos desc
```

{% horizontal_bar_chart
  data="lineas"
  y="linea"
  x="sum(ingresos)"
  y_sort="data"
  x_fmt="num0k"
  title="Ingresos por línea de negocio (S/)"
  subtitle="Ambulancia aérea, SISA Lima y Selva sostienen la facturación"
/%}

## Ritmo diario de facturación

```sql ventas_dia
select
  m.doc_date as fecha,
  round(sum(case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end)::numeric, 0) as ingresos
from dwh.moves m
left join dwh.calendar c on c.date = m.doc_date
where m.move_type = 'Ventas'
[[ and m.company = {{ empresa }} ]]
[[ and m.doc_date {{ fechas.between }} ]]
group by 1
order by 1
```

{% calendar_heatmap
  data="ventas_dia"
  date="fecha"
  value="sum(ingresos)"
  value_fmt="num0k"
  title="Ingresos diarios (S/)"
  subtitle="Los picos corresponden a servicios de ambulancia y chárter"
/%}

## Sigue explorando

- [Comercial · Rutas y clientes](/comercial): rutas, ticket medio y top clientes.
- [Flota y estructura de costes](/flota-costes): margen por aeronave y grupos de gasto.
- [Tutorial de Evidence](/00-tutorial): aprende la sintaxis desde cero.

