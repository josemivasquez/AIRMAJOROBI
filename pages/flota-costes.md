---
title: Flota y estructura de costes
sidebar_position: 2
page_width: full
---

# Flota y estructura de costes

Cruce de tres fuentes: `dwh.static_airplanes` (flota), `dwh.moves` (ingresos y costes
directos por centro de coste = matrícula) y `dwh.newview` (contabilidad de gastos por
grupo, en formato ancho con `anio`/`mes_num`).

Porcentaje de margen por aeronave frente a la estructura de gasto del grupo.

```sql dim_empresas
select distinct company as empresa
from dwh.moves
order by 1
```

{% dropdown id="empresa" data="dim_empresas" value_column="empresa" title="Empresa" /%}

{% range_calendar id="fechas" title="Periodo" value_column="doc_date" /%}

## Rentabilidad por aeronave

```sql flota
with mov as (
  select
    m.cost_center,
    m.company,
    m.doc_date,
    m.move_type,
    case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end as importe_pen
  from dwh.moves m
  left join dwh.calendar c on c.date = m.doc_date
),
por_matricula as (
  select
    cost_center,
    round(sum(case when move_type = 'Ventas' then importe_pen else 0 end)::numeric, 0) as ingresos,
    round(abs(sum(case when move_type = 'Compras' then importe_pen else 0 end))::numeric, 0) as costes_directos,
    round(sum(case when move_type = 'Ventas' then importe_pen else -importe_pen end)::numeric, 0) as margen
  from mov
  where 1 = 1
  [[ and company = {{ empresa }} ]]
  [[ and doc_date {{ fechas.between }} ]]
  group by 1
)
select
  coalesce(p.model, 'Otros / no flota') || ' · ' || coalesce(p.base, '-') as aeronave,
  coalesce(p.business_unit, '-') as unidad_negocio,
  m.ingresos,
  m.costes_directos,
  m.margen
from por_matricula m
left join dwh.static_airplanes p on p.registration = m.cost_center
where m.cost_center is not null
order by m.margen desc
```

{% bar_chart
  data="flota"
  x="aeronave"
  y="sum(margen)"
  y_fmt="num0k"
  order="sum(margen) desc"
  title="Margen por aeronave (S/)"
  subtitle="Barras negativas = matrículas que cuestan más de lo que facturan en el periodo"
/%}

{% table data="flota" title="Detalle por aeronave (S/)" /%}

## Estructura de gasto del grupo

```sql grupos_gasto
select
  grupo,
  round(abs(sum(importe))::numeric, 0) as gasto,
  round(abs(sum(case when anio = 2026 then importe else 0 end))::numeric, 0) as gasto_2026
from dwh.newview
where importe < 0
group by 1
order by gasto desc
```

{% horizontal_bar_chart
  data="grupos_gasto"
  y="grupo"
  x="sum(gasto)"
  y_sort="data"
  x_fmt="num0k"
  title="Gasto acumulado por grupo contable (S/)"
  subtitle="Coste de ventas, personal y otros gastos concentran el 80% del gasto"
/%}

## Gasto mensual por grupo y tipo de cambio

```sql gasto_mes
select
  to_char(make_date(anio, mes_num, 1), 'YYYY-MM') as mes,
  grupo,
  round(abs(sum(importe))::numeric, 0) as gasto
from dwh.newview
where importe < 0
group by 1, 2
order by 1
```

{% bar_chart
  data="gasto_mes"
  x="mes"
  y="sum(gasto)"
  series="grupo"
  y_fmt="num0k"
  title="Gasto mensual por grupo contable (S/)"
  subtitle="Fuente: dwh.newview (contabilidad de gastos)"
/%}

```sql tipo_cambio
select date, exchange_rate_sale as venta, exchange_rate_purchase as compra
from dwh.calendar
where date >= '2025-01-01'
order by date
```

{% line_chart
  data="tipo_cambio"
  x="date"
  y="avg(venta)"
  y2="avg(compra)"
  y_fmt="num2"
  title="Tipo de cambio USD/PEN usado en la conversión"
  subtitle="dwh.calendar: es la tabla que convierte los importes en dólares a soles"
/%}
