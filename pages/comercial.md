---
title: Comercial · Rutas y clientes
sidebar_position: 1
page_width: full
---

# Comercial · Rutas y clientes

¿Quién y por dónde genera los ingresos? Todo sale de `dwh.moves` (movimiento 1 = 1
documento de venta), enlazado con `dwh.partners` (razón social) y `dwh.static_master_accounts`
(línea de negocio contable).

```sql dim_empresas
select distinct company as empresa
from dwh.moves
order by 1
```

{% dropdown id="empresa" data="dim_empresas" value_column="empresa" title="Empresa" /%}

{% range_calendar id="fechas" title="Periodo" value_column="doc_date" /%}

## Ingresos por línea de negocio

```sql lineas
select
  coalesce(a.cuenta, 'Sin clasificar') as linea,
  round(sum(case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end)::numeric, 0) as ingresos,
  count(*) as documentos
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
  subtitle="Ambulancia aérea, SISA y Selva son las tres patas del negocio"
/%}

## Rutas: dinero vs. volumen

```sql rutas
select
  coalesce(nullif(m.serv_org_airport, ''), 'Sin origen') || ' → ' ||
  coalesce(nullif(m.serv_dest_airport, ''), 'Sin destino') as ruta,
  count(*) as servicios,
  round(sum(case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end)::numeric, 0) as ingresos,
  round(avg(case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end)::numeric, 0) as ticket_medio
from dwh.moves m
left join dwh.calendar c on c.date = m.doc_date
where m.move_type = 'Ventas'
  and coalesce(m.serv_org_airport, '') <> ''
[[ and m.company = {{ empresa }} ]]
[[ and m.doc_date {{ fechas.between }} ]]
group by 1
order by ingresos desc
limit 20
```

{% scatter_chart
  data="rutas"
  x="sum(servicios)"
  y="sum(ingresos)"
  title="Volumen vs. facturación por ruta"
  subtitle="Arriba a la izquierda: pocos servicios de alto valor (ambulancia). Abajo a la derecha: rutas regulares de alto volumen"
/%}

{% table data="rutas" title="Detalle por ruta" /%}

## Quién paga: clientes

```sql clientes
select
  coalesce(p.descripcion, 'Pasajeros (mostrador)') as cliente,
  count(*) as documentos,
  round(sum(case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end)::numeric, 0) as ingresos,
  round(avg(case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end)::numeric, 0) as ticket_medio
from dwh.moves m
left join dwh.calendar c on c.date = m.doc_date
left join dwh.partners p on p.codigo = m.partner_doc
where m.move_type = 'Ventas' and m.amnt_taxable is not null
[[ and m.company = {{ empresa }} ]]
[[ and m.doc_date {{ fechas.between }} ]]
group by 1
order by ingresos desc nulls last
limit 15
```

{% horizontal_bar_chart
  data="clientes"
  y="cliente"
  x="sum(ingresos)"
  y_sort="data"
  x_fmt="num0k"
  title="Top 15 clientes por facturación (S/)"
  subtitle="El mostrador es el mayor 'cliente'; entre las empresas dominan las instituciones de salud"
/%}

{% table data="clientes" title="Detalle de clientes" /%}

## Evolución mensual por empresa

```sql empresas_mes
select
  to_char(date_trunc('month', m.doc_date), 'YYYY-MM') as mes,
  m.company as empresa,
  round(sum(case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end)::numeric, 0) as ingresos
from dwh.moves m
left join dwh.calendar c on c.date = m.doc_date
where m.move_type = 'Ventas'
[[ and m.company = {{ empresa }} ]]
[[ and m.doc_date {{ fechas.between }} ]]
group by 1, 2
order by 1
```

{% bar_chart
  data="empresas_mes"
  x="mes"
  y="sum(ingresos)"
  series="empresa"
  y_fmt="num0k"
  title="Ingresos por mes y empresa (S/)"
  subtitle="Air Majoro factura el chárter y la ambulancia; Air Majoro Selva, las rutas regulares"
/%}
