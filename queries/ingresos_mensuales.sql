select
  to_char(date_trunc('month', m.doc_date), 'YYYY-MM') as mes,
  round(sum(case when m.currency = 'USD' then m.amnt_taxable * c.exchange_rate_sale else m.amnt_taxable end)::numeric, 0) as ingresos
from dwh.moves m
left join dwh.calendar c on c.date = m.doc_date
where m.move_type = 'Ventas'
group by 1
order by 1
