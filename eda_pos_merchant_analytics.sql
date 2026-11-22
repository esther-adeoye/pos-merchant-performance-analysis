-- POS TERMINAL & MERCHANT PERFORMANCE ANALYTICS(EDA)--
-- Reporting Period: October 2025 - September 2026
-- Channels: POS_CARD and POS_TRANSFER

--EDA 1: TRANSACTION PERFORMANCE--

--1.1 Overall POS Transaction Performance

select count(*) as total_transactions,
       count (*) filter (where transaction_status= 'Success')as successful_transactions,
	   count(*) filter(where transaction_status= 'Failed')as failed_transactions,
	   count(*) filter(where transaction_status= 'Pending')as Pending_transactions,
	   count(*) filter(where transaction_status='Abandoned')as abandoned_transactions,
	   round(100.0 * count (*) filter (where transaction_status= 'Success')/ nullif (count(*),0),2) as success_rate_pct,
	   sum(amount) filter(where transaction_status= 'Success') as successful_tpv
from transactions
where transaction_at>= '2025-10-01'
    and transaction_at< '2026-10-01'
	and payment_channel in ('POS_CARD','POS_TRANSFER');

-- EDA 1.2: MONTHLY POS TRANSACTION PERFORMANCE

-- How transaction volume, success rate,
-- and successful TPV changed month by month
     
select
    date_trunc('month', transaction_at)::date as month,
    count(*) as total_transactions,
    count(*) filter (
        where transaction_status = 'Success'
    ) as successful_transactions,
    count(*) filter (
        where transaction_status = 'Failed'
    ) as failed_transactions,
    count(*) filter (
        where transaction_status = 'Pending'
    ) as pending_transactions,
    count(*) filter (
        where transaction_status = 'Abandoned'
    ) as abandoned_transactions,
    round(
        100.0 * count(*) filter (
            where transaction_status = 'Success'
        ) / nullif(count(*), 0), 2
    ) as success_rate_pct,
    sum(amount) filter (
        where transaction_status = 'Success'
    ) as successful_tpv
from transactions
where transaction_at >= '2025-10-01'
    and transaction_at < '2026-10-01'
    and payment_channel in ('POS_CARD', 'POS_TRANSFER')
group by date_trunc('month', transaction_at)
order by month;

------1.2b Month-on-Month Growth Analysis------

with monthly_performance as(
  select 
        date_trunc('month',transaction_at)::date as month,
		count(*) as total_transactions,
		sum(amount)filter(where transaction_status='Success')as successful_tpv
  from transactions
  where transaction_at>='2025-10-01'and transaction_at<'2026-10-01'
        and payment_channel in( 'POS_CARD', 'POS_TRANSFER')
  GROUP BY 1
), 
 monthly_growth as(
  select 
        month,
		total_transactions,
		successful_tpv,
		lag(total_transactions)over(order by month)as prev_transactions,
		lag(successful_tpv)over(order by month)as prev_tpv
  from monthly_performance
)
 select 
      month,
	  total_transactions,
	  prev_transactions,
	  round(100.0*(total_transactions-prev_transactions)/nullif(prev_transactions,0),2)as transaction_mom_pct,
	  round(100.0*(successful_tpv-prev_tpv)/nullif(prev_tpv,0),2)as tpv_mom_pct
 from monthly_growth
 order by month;
 
-----EDA 1.3 POS Terminal Performance Analysis----

select 
     terminal_id,
	 count(*) as total_transactions,
	 count(*) filter(where transaction_status='Success') as successful_txn,
	 count(*) filter(where transaction_status='Pending') as pending_txn,
	 count(*) filter(where transaction_status='Abandoned') as abandoned_txn,
	 count(*) filter(where transaction_status='Failed') as failed_txn,
	 sum(amount) filter(where transaction_status='Success') as successful_tpv,
     sum(amount) filter(where transaction_status='Pending') as pending_tpv,
	 sum(amount) filter(where transaction_status='Abandoned') as abandoned_tpv,
	 sum(amount) filter(where transaction_status='Failed') as failed_tpv,
	 round(100.0 * count(*) filter(where transaction_status='Success')/nullif(count(*),0),2) as success_rate,
	 round(100.0 * count(*) filter(where transaction_status='Pending')/nullif(count(*),0),2) as pending_rate,
	 round(100.0 * count(*) filter(where transaction_status='Abandoned')/nullif(count(*),0),2) as abandoned_rate,
	 round(100.0 * count(*) filter(where transaction_status='Failed')/nullif(count(*),0),2) as failure_rate
from transactions
where payment_channel in('POS_CARD', 'POS_TRANSFER')
      and transaction_at>='2025-10-01' and transaction_at<'2026-10-01'
group by terminal_id
order by total_transactions desc;

-----EDA 1.3B Terminal TPV and Productivity----

select
      terminal_id,
      count(*) as total_transactions,
	  count(*) filter(where transaction_status='Success') as successful_txn,
	  (sum(amount) filter(where transaction_status='Success') as successful_tpv,
	  round(avg(amount) filter(where transaction_status='Success'),2) as avg_successful_tpv
from transactions
where payment_channel in ('POS_CARD','POS_TRANSFER')
      and transaction_at >='2025-10-01' and transaction_at <'2026-10-01'
group by terminal_id
order by total_transactions desc;

----EDA 1.3C Underperforming Terminals and Failure Outliers----

select terminal_id,
       count(*)as total_transactions,
	   count(*) filter(where transaction_status='Failed') as failed_txn,
	   sum(amount)filter(where transaction_status='Failed') as failed_attempted_value,
	   round(100.0 *  count(*) filter(where transaction_status='Failed')/nullif(count(*),0),2) as failure_rate
from transactions
where  payment_channel in ('POS_CARD','POS_TRANSFER')
      and transaction_at >='2025-10-01' and transaction_at <'2026-10-01'
group by terminal_id
having count(*)>=100
order by failure_rate desc;

-----EDA 1.3D Terminal Activity and Utilization-----
-----Percentage of deployed POS terminals, active in September 2026-----

with terminal_activity as (
select
     te.terminal_id,
	 count(tr.transaction_id) as september_txn,
	 case when count(tr.transaction_id)>0 then'Active' else 'Inactive' end as activity_status

from terminals te
left join transactions tr
      on te. terminal_id = tr.terminal_id
      and tr.payment_channel in ('POS_CARD','POS_TRANSFER')
     and tr.transaction_at>='2026-09-01' and tr.transaction_at<'2026-10-01'
group by te.terminal_id
)
select
    count(september_txn) as total_terminals,
	count(september_txn)filter(where activity_status= 'Active') as active_terminals,
	count(september_txn)filter(where activity_status= 'Inactive') as inactive_terminals,
	round(100.0 * count(september_txn)filter(where activity_status= 'Active')/nullif(count(september_txn),0),2) as active_terminal_pct
from terminal_activity;

----EDA 2.1 Merchant Transaction Performance----

----Which merchants generate the most successful POS transaction value----
----which have relatively poor transaction success rates?-----

select
    merchant_id,
    count(*) as total_attempts,
    count(*) filter (where transaction_status = 'Success') as successful_txns,
    count(*) filter (where transaction_status = 'Failed') as failed_txns,
    round(
        100.0 * count(*) filter (where transaction_status = 'Success')
        / nullif(count(*), 0), 2
    ) as success_rate_pct
from transactions
where payment_channel in ('POS_CARD', 'POS_TRANSFER')
    and transaction_at >= '2025-10-01'
    and transaction_at < '2026-10-01'
group by merchant_id
order by total_attempts desc;

----EDA 2.2 Merchant Transaction Value (TPV)----

select
    merchant_id,
    count(*) filter (where transaction_status = 'Success') as successful_txn,
    sum(amount) filter (where transaction_status = 'Success') as successful_tpv,
    round(
        sum(amount) filter (where transaction_status = 'Success')
        / nullif(count(*) filter (where transaction_status = 'Success'), 0), 2
    ) as avg_successful_txn_value
from transactions
where payment_channel in ('POS_CARD', 'POS_TRANSFER')
    and transaction_at >= '2025-10-01'
    and transaction_at < '2026-10-01'
group by merchant_id
order by successful_tpv desc nulls last
limit 10;

----EDA 3.1 Terminal Activation Rate----
----Of all deployed POS terminals, how many are actively processing transactions?----

with deployed as (
                 select distinct terminal_id
				 from terminal_assignments
				 where assigned_at<'2026-10-01' and (unassigned_at is null or unassigned_at>='2026-10-01')
),
  active as (
     select 
     distinct terminal_id
from transactions
where transaction_status = 'Success'
  and transaction_at>='2026-09-01' and transaction_at<'2026-10-01'
  and payment_channel in ('POS_CARD', 'POS_TRANSFER')
  )
  select
       count(d.terminal_id) as deployed_terminals,
	   count(a.terminal_id) as active_terminals,
	   count(d.terminal_id)-count(a.terminal_id) as inactive_terminals,
	   round(100.0 * count(a.terminal_id)/nullif(count(d.terminal_id),0),2) as activation_rate_pct
  from deployed d
  left join active a
       on d.terminal_id=a.terminal_id;

----EDA 3.2 Terminal Inactivity Analysis----

----Business question: Of the 1,679 deployed terminals that recorded no successful POS transactions in September 2026----
----How many had unsuccessful transaction attempts----
----How many had no activity whatsoever?----

with deployed as (
         select distinct terminal_id
         from terminal_assignments
         where assigned_at<'2026-10-01' and (unassigned_at is null or unassigned_at>='2026-10-01')
),
  active as (
     select distinct terminal_id
     from transactions
     where transaction_status='Success'
             and transaction_at>='2026-09-01' and transaction_at<'2026-10-01'
             and payment_channel in ('POS_CARD','POS_TRANSFER')
),
inactive as (
      select distinct d.terminal_id
      from deployed d
      left join active a
           on d.terminal_id=a.terminal_id
      where a.terminal_id is null
),
unsuccessful_attempts as (
         select terminal_id,
		        count(*) as total_attempts,
                count(*) filter (where transaction_status='Failed')as failed_txn,
	            count(*) filter (where transaction_status='Abandoned')as abandoned_txn,
		        count(*) filter (where transaction_status='Pending')as Pending_txn
         from transactions
         where transaction_at>='2026-09-01' and transaction_at <'2026-10-01'
               and payment_channel in('POS_CARD','POS_TRANSFER')
	           and transaction_status in('Abandoned','Pending','Failed')
         group by terminal_id
)
select
  case when u.terminal_id is not null then 'unsuccessful_terminal_attempts' 
  else 'no_transaction_activity' end as inactivity_category,
  count(*) as terminal_count,
  coalesce(sum(u.total_attempts),0) as total_attempts,
  coalesce(sum(u.failed_txn),0) as failed_txns,
  coalesce(sum(u.abandoned_txn),0) as abandoned_txns,
  coalesce(sum(u.Pending_txn),0) as Pending_txns
  
from inactive i
left join unsuccessful_attempts u
   on i.terminal_id=u.terminal_id
group by case when u.terminal_id is not null then 'unsuccessful_terminal_attempts' 
  else 'no_transaction_activity' end
order by terminal_count desc;

-----4.1 Gross Revenue, Effective Fee Yield, and Revenue Reconciliation-----

select table_name, column_name, data_type
from information_schema.columns
where table_name in (
    'transactions',
    'transaction_fee_ledger',
    'merchant_fee_contracts'
)
order by table_name, ordinal_position;

select entry_type,
       count(*) as entry_count,
       sum(amount) as total_amount,
       min(amount) as minimum_amount,
       max(amount) as maximum_amount
from transaction_fee_ledger
group by entry_type
order by entry_count desc;

select transaction_id,
       count(*) filter (where entry_type = 'Assessment') as assessment_count,
       count(*) filter (where entry_type = 'Collection') as collection_count
from transaction_fee_ledger
group by transaction_id
having count(*) filter (where entry_type = 'Assessment') <> 1
    or count(*) filter (where entry_type = 'Collection') <> 1;

	select transaction_id,
       sum(amount) filter (where entry_type = 'Assessment') as assessed_fee,
       sum(amount) filter (where entry_type = 'Collection') as collected_fee,
       sum(amount) filter (where entry_type = 'Assessment')
       - sum(amount) filter (where entry_type = 'Collection') as fee_difference
from transaction_fee_ledger
group by transaction_id
having sum(amount) filter (where entry_type = 'Assessment')
       <> sum(amount) filter (where entry_type = 'Collection')
order by fee_difference desc;

select entry_type,
       adjustment_reason,
       count(*) as entry_count
from transaction_fee_ledger
group by entry_type, adjustment_reason
order by entry_count desc;

with fee_comparison as (
    select transaction_id,
           sum(amount) filter (where entry_type = 'Assessment') as assessed_fee,
           sum(amount) filter (where entry_type = 'Collection') as collected_fee
    from transaction_fee_ledger
    group by transaction_id
)
select round(collected_fee / nullif(assessed_fee, 0) * 100, 2) as collection_percentage,
       count(*) as transaction_count,
       sum(assessed_fee - collected_fee) as total_difference
from fee_comparison
group by collection_percentage
order by transaction_count desc;

with fee_comparison as (
    select transaction_id,
           sum(amount) filter (where entry_type = 'Assessment') as assessed_fee,
           sum(amount) filter (where entry_type = 'Collection') as collected_fee
    from transaction_fee_ledger
    group by transaction_id
)
select t.merchant_id,
       t.payment_channel,
       count(*) as affected_transactions,
       sum(f.assessed_fee - f.collected_fee) as fee_difference
from fee_comparison f
join transactions t on f.transaction_id = t.transaction_id
where f.assessed_fee <> f.collected_fee
    and transaction_at>='2025-10-01' and transaction_at<'2026-10-01'
group by t.merchant_id, t.payment_channel
order by fee_difference desc;

select payment_channel,
       contract_status,
       count(*) as total_contracts,
       count(distinct merchant_id) as merchants,
       min(percentage_rate) as min_rate,
       max(percentage_rate) as max_rate,
       min(fixed_fee) as min_fixed_fee,
       max(fixed_fee) as max_fixed_fee
from merchant_fee_contracts
group by payment_channel, contract_status
order by payment_channel, contract_status;

select payment_channel,
       fee_cap,
       minimum_fee,
       fee_exempt,
       count(*) as contract_count
from merchant_fee_contracts
group by payment_channel, fee_cap, minimum_fee, fee_exempt
order by payment_channel, contract_count desc;

with fee_comparison as (
    select transaction_id,
           sum(amount) filter (where entry_type = 'Assessment') as assessed_fee,
           sum(amount) filter (where entry_type = 'Collection') as collected_fee
    from transaction_fee_ledger
    group by transaction_id
)
select
    count(*) as total_transactions,
    count(*) filter (
        where t.actual_fee = f.assessed_fee
    ) as matches_assessment,
    count(*) filter (
        where t.actual_fee = f.collected_fee
    ) as matches_collection,
    count(*) filter (
        where t.actual_fee <> f.assessed_fee
          and t.actual_fee <> f.collected_fee
    ) as matches_neither
from fee_comparison f
join transactions t
    on f.transaction_id = t.transaction_id;

select date_trunc('month', transaction_at)::date as month,
       count(*) as fee_transactions,
       sum(actual_fee) as gross_fee_revenue
from transactions
where transaction_status = 'Success'
    and transaction_at>='2025-10-01' and transaction_at<'2026-10-01'
group by 1
order by 1;

select terminal_id,
       count(*) as successful_txns,
	   sum(amount) as successful_tpv,
	   sum(actual_fee) as gross_fee_revenue
from transactions
where transaction_status='Success'
  and transaction_at>='2025-10-01' and transaction_at<'2026-10-01'
  and payment_channel in ('POS_CARD','POS_TRANSFER')
group by terminal_id
order by gross_fee_revenue desc;

-----EDA 4.2 Revenue per Terminal-----

with terminal_revenue as (
    select terminal_id,
           count(*) as successful_transactions,
           sum(amount) as successful_tpv,
           sum(actual_fee) as gross_fee_revenue
    from transactions
    where transaction_status = 'Success'
      and transaction_at >= '2025-10-01'
      and transaction_at < '2026-10-01'
      and payment_channel in ('POS_CARD', 'POS_TRANSFER')
    group by terminal_id
)
select count(*) as revenue_generating_terminals,
       sum(successful_transactions) as successful_transactions,
       sum(successful_tpv) as total_successful_tpv,
       sum(gross_fee_revenue) as total_gross_fee_revenue,
       round(avg(gross_fee_revenue), 2) as revenue_per_active_terminal,
       round(avg(successful_tpv), 2) as tpv_per_active_terminal
from terminal_revenue;

-----EDA 4.2B Revenue per Merchant-----

select merchant_id,
       count(*) as successful_transactions,
       sum(amount) as successful_tpv,
       sum(actual_fee) as gross_fee_revenue
from transactions
where transaction_status = 'Success'
  and transaction_at >= '2025-10-01'
  and transaction_at < '2026-10-01'
group by merchant_id
order by gross_fee_revenue desc
limit 20;

with merchant_revenue as (
    select merchant_id,
           count(*) as successful_transactions,
           sum(amount) as successful_tpv,
           sum(actual_fee) as gross_fee_revenue
    from transactions
    where transaction_status = 'Success'
      and transaction_at >= '2025-10-01'
      and transaction_at < '2026-10-01'
    group by merchant_id
)
select count(*) as revenue_generating_merchants,
       sum(successful_transactions) as successful_transactions,
       sum(successful_tpv) as total_successful_tpv,
       sum(gross_fee_revenue) as total_gross_fee_revenue,
       round(avg(gross_fee_revenue), 2) as revenue_per_merchant,
       round(avg(successful_tpv), 2) as tpv_per_merchant
from merchant_revenue;

-----EDA 5.1 Regional Performance-----
-----regional TPV, revenue, and terminal productivity-----

select 
      m.region,
    count(*) as transaction_vol,
	sum(amount) filter(where transaction_status='Success') as successful_tpv,
	count(*) filter(where transaction_status='Success') as successful_txns,
	sum(actual_fee) filter(where transaction_status= 'Success') as gross_fee_revenue,
	round(100.0 * count(*) filter(where transaction_status='Success')/nullif( count(*),0),2) as success_rate
from transactions t
left join merchants m
  on t.merchant_id=m.merchant_id
where transaction_at >='2025-10-01' and transaction_at<'2026-10-01'
group by m.region;

----EDA 5.1B Regional Terminal Productivity-----

select m.region,
       count(distinct t.terminal_id) as total_terminals
from terminals t
join terminal_assignments ta
  on t.terminal_id = ta.terminal_id
join merchants m
  on ta.merchant_id = m.merchant_id
where ta.assigned_at < '2026-10-01'
  and (ta.unassigned_at is null
       or ta.unassigned_at >= '2026-10-01')
group by m.region
order by total_terminals desc;

-----5.1C Regional Terminal Productivity----

with terminal_performance as (
  select t.terminal_id,
        m.region,
		count(*) as successful_txns,
		sum(t.amount) as successful_tpv,
		sum(t.actual_fee) as gross_fee_revenue
  from transactions t
  inner join merchants m
    on t.merchant_id=m.merchant_id
  where t.transaction_status='Success'
     and t.payment_channel in ('POS_CARD','POS_TRANSFER')
	 and t.transaction_at>='2025-10-01' and t.transaction_at<'2026-10-01'
	 and t.terminal_id is not null
  group by t.terminal_id,m.region
)
select region,
     count(distinct terminal_id) as active_terminals,
	 sum(successful_txns) as successful_txns,
	 sum(successful_tpv) as successful_pos_tpv,
	 sum(gross_fee_revenue) as gross_pos_revenue,
	 round(sum(successful_tpv)/nullif (count(distinct terminal_id),0),2) as tpv_per_active_terminal,
	  round(sum(gross_fee_revenue)/nullif (count(distinct terminal_id),0),2) as revenue_per_active_terminal
from terminal_performance
group by region
order by revenue_per_active_terminal desc;

----5.2 Relationship Manager Portfolio Performance----

select r.relationship_manager_id,
      r.manager_name,
	  r.region,
	  count(distinct c.merchant_id) as total_merchants
from relationship_managers r
left join crm_assignments c
  on r.relationship_manager_id=c.relationship_manager_id
  and assigned_at<'2026-10-01' and (unassigned_at is null or unassigned_at>='2026-10-01')
 group by manager_name,r.relationship_manager_id,r.region
 order by total_merchants desc;

 select merchant_id,
       count(distinct relationship_manager_id) as rm_count
from crm_assignments
where assigned_at < '2026-10-01'
  and (
      unassigned_at is null
      or unassigned_at >= '2026-10-01'
  )
group by merchant_id
having count(distinct relationship_manager_id) > 1;

with rm_portfolio as (
    select distinct r.relationship_manager_id,
           r.manager_name,
           r.region,
           c.merchant_id
    from relationship_managers r
    left join crm_assignments c
      on r.relationship_manager_id = c.relationship_manager_id
      and c.assigned_at < '2026-10-01'
      and (
          c.unassigned_at is null
          or c.unassigned_at >= '2026-10-01'
      )
),
merchant_performance as (
    select t.merchant_id,
           count(*) filter (
               where t.transaction_status = 'Success'
           ) as successful_txns,
           sum(t.amount) filter (
               where t.transaction_status = 'Success'
           ) as successful_tpv,
           sum(t.actual_fee) filter (
               where t.transaction_status = 'Success'
           ) as gross_fee_revenue
    from transactions t
    where t.transaction_at >= '2025-10-01'
      and t.transaction_at < '2026-10-01'
    group by t.merchant_id
)
select p.relationship_manager_id,
       p.manager_name,
       p.region,
       count(distinct p.merchant_id) as assigned_merchants,
       coalesce(sum(mp.successful_txns), 0) as successful_txns,
       coalesce(sum(mp.successful_tpv), 0) as successful_tpv,
       coalesce(sum(mp.gross_fee_revenue), 0) as gross_fee_revenue,
       round(
           coalesce(sum(mp.gross_fee_revenue), 0) /
           nullif(count(distinct p.merchant_id), 0), 2
       ) as revenue_per_merchant
from rm_portfolio p
left join merchant_performance mp
  on p.merchant_id = mp.merchant_id
group by p.relationship_manager_id,
         p.manager_name,
         p.region
order by gross_fee_revenue desc;

with current_assignments as (
    select distinct merchant_id
    from crm_assignments
    where assigned_at < '2026-10-01'
      and (
          unassigned_at is null
          or unassigned_at >= '2026-10-01'
      )
)
select count(*) as successful_txns,
       sum(t.amount) as successful_tpv,
       sum(t.actual_fee) as gross_fee_revenue
from transactions t
join current_assignments c
  on t.merchant_id = c.merchant_id
where t.transaction_status = 'Success'
  and t.transaction_at >= '2025-10-01'
  and t.transaction_at < '2026-10-01';

-----6.1 Operational Incident Frequency, Resolution Time & SLA Performance-----

select column_name,
       data_type
from information_schema.columns
where table_name = 'operational_incidents'
order by ordinal_position;

with incident_performance as (
    select incident_id,
           incident_status,
           severity,
           incident_type,
           sla_target_minutes,
           case when resolved_at >= started_at
                then extract(epoch from (resolved_at - started_at)) / 60.0
                else null end as resolution_minutes
    from operational_incidents
    where started_at >= '2025-10-01'
      and started_at < '2026-10-01'
)
select count(*) as total_incidents,
       count(*) filter (where incident_status = 'Resolved') as resolved_incidents,
       count(*) filter (where incident_status <> 'Resolved' or incident_status is null) as unresolved_incidents,
       round(avg(resolution_minutes) filter (where incident_status = 'Resolved'), 2) as avg_resolution_minutes,
       count(*) filter (where incident_status = 'Resolved' and resolution_minutes <= sla_target_minutes) as incidents_within_sla,
       count(*) filter (where incident_status = 'Resolved' and resolution_minutes > sla_target_minutes) as incidents_breaching_sla,
       round(100.0 * count(*) filter (where incident_status = 'Resolved' and resolution_minutes <= sla_target_minutes) /
             nullif(count(*) filter (where incident_status = 'Resolved'
                                    and resolution_minutes is not null
                                    and sla_target_minutes is not null), 0), 2) as sla_compliance_pct
from incident_performance;

-----6.1B: Incident Frequency by Type-----

select incident_type,
       count(*) as total_incidents,
       count(*) filter (where incident_status = 'Resolved') as resolved_incidents,
       round(avg(extract(epoch from (resolved_at - started_at)) / 60.0)
             filter (where incident_status = 'Resolved' and resolved_at >= started_at), 2) as avg_resolution_minutes
from operational_incidents
where started_at >= '2025-10-01'
  and started_at < '2026-10-01'
group by incident_type
order by total_incidents desc;

----6.1C SLA Performance by Severity----

with incident_resolution as (
    select severity,
           incident_status,
           sla_target_minutes,
           case when resolved_at >= started_at
                then extract(epoch from (resolved_at - started_at)) / 60.0
                else null end as resolution_minutes
    from operational_incidents
    where started_at >= '2025-10-01'
      and started_at < '2026-10-01'
)
select severity,
       count(*) as total_incidents,
       count(*) filter (where incident_status = 'Resolved') as resolved_incidents,
       round(avg(resolution_minutes) filter (where incident_status = 'Resolved'), 2) as avg_resolution_minutes,
       count(*) filter (where incident_status = 'Resolved' and resolution_minutes <= sla_target_minutes) as incidents_within_sla,
       count(*) filter (where incident_status = 'Resolved' and resolution_minutes > sla_target_minutes) as sla_breaches,
       round(100.0 * count(*) filter (where incident_status = 'Resolved' and resolution_minutes <= sla_target_minutes) /
             nullif(count(*) filter (where incident_status = 'Resolved'
                                    and resolution_minutes is not null
                                    and sla_target_minutes is not null), 0), 2) as sla_compliance_pct
from incident_resolution
group by severity
order by case severity
             when 'Critical' then 1
             when 'High' then 2
             when 'Medium' then 3
             when 'Low' then 4
             else 5 end;

-----6.2 Incident Impact on POS Terminals and Transactions-----

select column_name,
       data_type
from information_schema.columns
where table_name = 'incident_terminal_impacts'
order by ordinal_position;

with terminal_impact as (
    select i.incident_id,
           i.incident_type,
           i.severity,
           iti.terminal_id,
           iti.impact_id,
           iti.impact_type,
           case when iti.impact_ended_at >= iti.impact_started_at
                then extract(epoch from (iti.impact_ended_at - iti.impact_started_at)) / 60.0
                else null end as impact_minutes
    from operational_incidents i
    join incident_terminal_impacts iti
      on i.incident_id = iti.incident_id
    where i.started_at >= '2025-10-01'
      and i.started_at < '2026-10-01'
)
select count(distinct incident_id) as incidents_affecting_terminals,
       count(*) as total_terminal_impact_records,
       count(distinct terminal_id) as unique_terminals_affected,
       round(avg(impact_minutes), 2) as avg_impact_minutes,
       round(sum(impact_minutes) / 60.0, 2) as total_terminal_impact_hours
from terminal_impact;

----6.2B Terminal Impact by Incident Type----

with terminal_impact as (
    select i.incident_id,
           i.incident_type,
           iti.impact_id,
           iti.terminal_id,
           case when iti.impact_ended_at >= iti.impact_started_at
                then extract(epoch from (iti.impact_ended_at - iti.impact_started_at)) / 60.0
                else null end as impact_minutes
    from operational_incidents i
    join incident_terminal_impacts iti
      on i.incident_id = iti.incident_id
    where i.started_at >= '2025-10-01'
      and i.started_at < '2026-10-01'
)
select incident_type,
       count(distinct incident_id) as total_incidents,
       count(*) as terminal_impact_records,
       count(distinct terminal_id) as unique_terminals_affected,
       round(avg(impact_minutes), 2) as avg_impact_minutes,
       round(sum(impact_minutes) / 60.0, 2) as total_terminal_impact_hours
from terminal_impact
group by incident_type
order by total_terminal_impact_hours desc;

------6.2C Transaction Performance During Incident Windows-----

with transaction_exposure as (
    select t.transaction_id,
           t.transaction_status,
           t.amount,
           case when exists (
               select 1
               from incident_terminal_impacts iti
               join operational_incidents i
                 on iti.incident_id = i.incident_id
               where iti.terminal_id = t.terminal_id
                 and t.transaction_at >= iti.impact_started_at
                 and t.transaction_at < iti.impact_ended_at
                 and i.started_at >= '2025-10-01'
                 and i.started_at < '2026-10-01'
           ) then 'During incident'
             else 'Outside incident' end as incident_exposure
    from transactions t
    where t.transaction_at >= '2025-10-01'
      and t.transaction_at < '2026-10-01'
      and t.payment_channel in ('POS_CARD', 'POS_TRANSFER')
      and t.terminal_id is not null
)
select incident_exposure,
       count(*) as total_transactions,
       count(*) filter (where transaction_status = 'Success') as successful_txns,
       count(*) filter (where transaction_status = 'Failed') as failed_txns,
       round(100.0 * count(*) filter (where transaction_status = 'Success') /
             nullif(count(*), 0), 2) as success_rate_pct,
       round(100.0 * count(*) filter (where transaction_status = 'Failed') /
             nullif(count(*), 0), 2) as failure_rate_pct,
       coalesce(sum(amount) filter (where transaction_status = 'Failed'), 0) as failed_transaction_value
from transaction_exposure
group by incident_exposure
order by incident_exposure;

select count(*) as total_impact_records,
       count(*) filter (where impact_ended_at <= impact_started_at) as invalid_time_windows,
       count(*) filter (where impact_started_at is null or impact_ended_at is null) as missing_timestamps,
       min(impact_started_at) as earliest_impact,
       max(impact_ended_at) as latest_impact
from incident_terminal_impacts iti
join operational_incidents i
  on iti.incident_id = i.incident_id
where i.started_at >= '2025-10-01'
  and i.started_at < '2026-10-01';

----7.1 — Monthly MIS KPI Scorecard----

with monthly_performance as (
    select date_trunc('month', transaction_at)::date as report_month,
           count(*) as total_transactions,
           count(*) filter (where transaction_status = 'Success') as successful_txns,
           count(*) filter (where transaction_status = 'Failed') as failed_txns,
           coalesce(sum(amount) filter (where transaction_status = 'Success'), 0) as successful_tpv,
           coalesce(sum(actual_fee) filter (where transaction_status = 'Success'), 0) as gross_fee_revenue
    from transactions
    where transaction_at >= '2025-10-01'
      and transaction_at < '2026-10-01'
    group by date_trunc('month', transaction_at)::date
)
select report_month,
       total_transactions,
       successful_txns,
       failed_txns,
       round(100.0 * successful_txns / nullif(total_transactions, 0), 2) as success_rate_pct,
       successful_tpv,
       gross_fee_revenue,
       round(100.0 * (successful_tpv - lag(successful_tpv) over (order by report_month)) /
             nullif(lag(successful_tpv) over (order by report_month), 0), 2) as tpv_mom_growth_pct,
       round(100.0 * (gross_fee_revenue - lag(gross_fee_revenue) over (order by report_month)) /
             nullif(lag(gross_fee_revenue) over (order by report_month), 0), 2) as revenue_mom_growth_pct
from monthly_performance
order by report_month;

select count(*) filter (where transaction_status = 'Success') as successful_txns,
       sum(amount) filter (where transaction_status = 'Success') as successful_tpv,
       sum(actual_fee) filter (where transaction_status = 'Success') as gross_fee_revenue
from transactions
where transaction_at >= '2025-10-01'
  and transaction_at < '2026-10-01';

  with months as (
    select generate_series('2025-10-01'::date,
                           '2026-09-01'::date,
                           interval '1 month')::date as report_month
),
monthly_active_terminals as (
    select date_trunc('month', transaction_at)::date as report_month,
           count(distinct terminal_id) as active_terminals
    from transactions
    where transaction_at >= '2025-10-01'
      and transaction_at < '2026-10-01'
      and transaction_status = 'Success'
      and payment_channel in ('POS_CARD', 'POS_TRANSFER')
      and terminal_id is not null
    group by date_trunc('month', transaction_at)::date
)
select m.report_month,
       5000 as total_terminals,
       coalesce(a.active_terminals, 0) as active_terminals,
       5000 - coalesce(a.active_terminals, 0) as inactive_terminals,
       round(100.0 * coalesce(a.active_terminals, 0) / 5000, 2) as activation_rate_pct
from months m
left join monthly_active_terminals a
  on m.report_month = a.report_month
order by m.report_month;

----7.1C Monthly Incident & SLA Performance----

with monthly_incidents as (
    select date_trunc('month', started_at)::date as report_month,
           count(*) as total_incidents,
           count(*) filter (where incident_status = 'Resolved') as resolved_incidents,
           count(*) filter (where incident_status <> 'Resolved' or incident_status is null) as unresolved_incidents,
           round(avg(extract(epoch from (resolved_at - started_at)) / 60.0)
                 filter (where incident_status = 'Resolved' and resolved_at >= started_at), 2) as avg_resolution_minutes,
           count(*) filter (where incident_status = 'Resolved'
                            and resolved_at >= started_at
                            and extract(epoch from (resolved_at - started_at)) / 60.0 <= sla_target_minutes) as within_sla,
           count(*) filter (where incident_status = 'Resolved'
                            and resolved_at >= started_at
                            and extract(epoch from (resolved_at - started_at)) / 60.0 > sla_target_minutes) as sla_breaches
    from operational_incidents
    where started_at >= '2025-10-01'
      and started_at < '2026-10-01'
    group by date_trunc('month', started_at)::date
)
select report_month,
       total_incidents,
       resolved_incidents,
       unresolved_incidents,
       avg_resolution_minutes,
       within_sla,
       sla_breaches,
       round(100.0 * within_sla / nullif(within_sla + sla_breaches, 0), 2) as sla_compliance_pct
from monthly_incidents
order by report_month;

----7.2 Forecasting & Run-Rate Analysis----

with monthly_performance as (
    select date_trunc('month', transaction_at)::date as report_month,
           count(*) filter (where transaction_status = 'Success') as successful_txns,
           coalesce(sum(amount) filter (where transaction_status = 'Success'), 0) as successful_tpv,
           coalesce(sum(actual_fee) filter (where transaction_status = 'Success'), 0) as gross_fee_revenue
    from transactions
    where transaction_at >= '2025-10-01'
      and transaction_at < '2026-10-01'
    group by date_trunc('month', transaction_at)::date
)
select report_month,
       successful_txns,
       successful_tpv,
       gross_fee_revenue,
       round(avg(successful_tpv) over (order by report_month rows between 2 preceding and current row), 2) as rolling_3m_tpv,
       round(avg(gross_fee_revenue) over (order by report_month rows between 2 preceding and current row), 2) as rolling_3m_revenue
from monthly_performance
order by report_month;

with monthly_performance as (
    select date_trunc('month', transaction_at)::date as report_month,
           coalesce(sum(amount) filter (where transaction_status = 'Success'), 0) as successful_tpv,
           coalesce(sum(actual_fee) filter (where transaction_status = 'Success'), 0) as gross_fee_revenue
    from transactions
    where transaction_at >= '2025-10-01'
      and transaction_at < '2026-10-01'
    group by date_trunc('month', transaction_at)::date
),
monthly_forecast as (
    select report_month,
           successful_tpv,
           gross_fee_revenue,
           count(*) over (order by report_month rows between 3 preceding and 1 preceding) as prior_months,
           round(avg(successful_tpv) over (order by report_month rows between 3 preceding and 1 preceding), 2) as forecast_tpv,
           round(avg(gross_fee_revenue) over (order by report_month rows between 3 preceding and 1 preceding), 2) as forecast_revenue
    from monthly_performance
)
select report_month,
       successful_tpv,
       forecast_tpv,
       round(100.0 * (successful_tpv - forecast_tpv) / nullif(forecast_tpv, 0), 2) as tpv_variance_pct,
       gross_fee_revenue,
       forecast_revenue,
       round(100.0 * (gross_fee_revenue - forecast_revenue) / nullif(forecast_revenue, 0), 2) as revenue_variance_pct
from monthly_forecast
where prior_months = 3
order by report_month;

create or replace view vw_monthly_transaction_kpis as
select date_trunc('month', transaction_at)::date as report_month,
       count(*) as total_transactions,
       count(*) filter (where transaction_status = 'Success') as successful_txns,
       count(*) filter (where transaction_status = 'Failed') as failed_txns,
       count(*) filter (where transaction_status not in ('Success', 'Failed') or transaction_status is null) as other_txns,
       round(100.0 * count(*) filter (where transaction_status = 'Success') /
             nullif(count(*), 0), 2) as success_rate_pct,
       coalesce(sum(amount) filter (where transaction_status = 'Success'), 0) as successful_tpv,
       coalesce(sum(actual_fee) filter (where transaction_status = 'Success'), 0) as gross_fee_revenue
from transactions
group by date_trunc('month', transaction_at)::date;

create or replace view vw_terminal_performance as
with months as (
    select generate_series(
               date_trunc('month', min(transaction_at))::date,
               date_trunc('month', max(transaction_at))::date,
               interval '1 month'
           )::date as report_month
    from transactions
),
monthly_terminal_txns as (
    select date_trunc('month', transaction_at)::date as report_month,
           terminal_id,
           count(*) as total_txns,
           count(*) filter (where transaction_status = 'Success') as successful_txns,
           count(*) filter (where transaction_status = 'Failed') as failed_txns,
           coalesce(sum(amount) filter (where transaction_status = 'Success'), 0) as successful_tpv,
           coalesce(sum(actual_fee) filter (where transaction_status = 'Success'), 0) as gross_fee_revenue
    from transactions
    where payment_channel in ('POS_CARD', 'POS_TRANSFER')
      and terminal_id is not null
    group by date_trunc('month', transaction_at)::date, terminal_id
)
select m.report_month,
       t.terminal_id,
       coalesce(mt.total_txns, 0) as total_txns,
       coalesce(mt.successful_txns, 0) as successful_txns,
       coalesce(mt.failed_txns, 0) as failed_txns,
       round(100.0 * coalesce(mt.successful_txns, 0) /
             nullif(mt.total_txns, 0), 2) as success_rate_pct,
       coalesce(mt.successful_tpv, 0) as successful_tpv,
       coalesce(mt.gross_fee_revenue, 0) as gross_fee_revenue,
       case when coalesce(mt.successful_txns, 0) > 0 then 1 else 0 end as is_active
from months m
cross join terminals t
left join monthly_terminal_txns mt
  on m.report_month = mt.report_month
 and t.terminal_id = mt.terminal_id;

 create or replace view vw_merchant_performance as
with months as (
    select generate_series(
               date_trunc('month', min(transaction_at))::date,
               date_trunc('month', max(transaction_at))::date,
               interval '1 month'
           )::date as report_month
    from transactions
),
monthly_merchant_txns as (
    select date_trunc('month', transaction_at)::date as report_month,
           merchant_id,
           count(*) as total_txns,
           count(*) filter (where transaction_status = 'Success') as successful_txns,
           count(*) filter (where transaction_status = 'Failed') as failed_txns,
           coalesce(sum(amount) filter (where transaction_status = 'Success'), 0) as successful_tpv,
           coalesce(sum(actual_fee) filter (where transaction_status = 'Success'), 0) as gross_fee_revenue
    from transactions
    where merchant_id is not null
    group by date_trunc('month', transaction_at)::date, merchant_id
)
select m.report_month,
       mc.merchant_id,
       coalesce(mt.total_txns, 0) as total_txns,
       coalesce(mt.successful_txns, 0) as successful_txns,
       coalesce(mt.failed_txns, 0) as failed_txns,
       round(100.0 * coalesce(mt.successful_txns, 0) /
             nullif(mt.total_txns, 0), 2) as success_rate_pct,
       coalesce(mt.successful_tpv, 0) as successful_tpv,
       coalesce(mt.gross_fee_revenue, 0) as gross_fee_revenue,
       case when coalesce(mt.successful_txns, 0) > 0 then 1 else 0 end as is_active
from months m
cross join merchants mc
left join monthly_merchant_txns mt
  on m.report_month = mt.report_month
 and mc.merchant_id = mt.merchant_id;
 
 
select min(report_month) as first_month,
       max(report_month) as latest_month,
       count(distinct report_month) as total_months
from vw_merchant_performance;

 create or replace view vw_regional_performance as
select date_trunc('month', t.transaction_at)::date as report_month,
       m.region,
       count(*) as total_txns,
       count(*) filter (where t.transaction_status = 'Success') as successful_txns,
       count(*) filter (where t.transaction_status = 'Failed') as failed_txns,
       round(100.0 * count(*) filter (where t.transaction_status = 'Success') /
             nullif(count(*), 0), 2) as success_rate_pct,
       coalesce(sum(t.amount) filter (where t.transaction_status = 'Success'), 0) as successful_tpv,
       coalesce(sum(t.actual_fee) filter (where t.transaction_status = 'Success'), 0) as gross_fee_revenue,
       count(distinct t.merchant_id) filter (where t.transaction_status = 'Success') as active_merchants,
       count(distinct t.terminal_id) filter (where t.transaction_status = 'Success'
                                            and t.payment_channel in ('POS_CARD', 'POS_TRANSFER')) as active_pos_terminals
from transactions t
join merchants m
  on t.merchant_id = m.merchant_id
group by date_trunc('month', t.transaction_at)::date, m.region;

create or replace view vw_incident_performance as
select incident_id,
       incident_type,
       severity,
       started_at,
       resolved_at,
       date_trunc('month', started_at)::date as report_month,
       incident_status,
       assigned_team,
       sla_target_minutes,
       root_cause,
       case when resolved_at >= started_at
            then round(extract(epoch from (resolved_at - started_at)) / 60.0, 2)
            else null end as resolution_minutes,
       case when incident_status = 'Resolved'
                 and resolved_at >= started_at
                 and sla_target_minutes is not null
                 and extract(epoch from (resolved_at - started_at)) / 60.0 <= sla_target_minutes
            then 1 else 0 end as within_sla,
       case when incident_status = 'Resolved'
                 and resolved_at >= started_at
                 and sla_target_minutes is not null
                 and extract(epoch from (resolved_at - started_at)) / 60.0 > sla_target_minutes
            then 1 else 0 end as sla_breached
from operational_incidents;

create or replace view vw_rm_portfolio_performance as
with rm_portfolio as (
    select distinct r.relationship_manager_id,
           r.manager_name,
           r.region,
           r.team,
           c.merchant_id
    from relationship_managers r
    left join crm_assignments c
      on r.relationship_manager_id = c.relationship_manager_id
     and c.assigned_at < '2026-10-01'
     and (c.unassigned_at is null or c.unassigned_at >= '2026-10-01')
),
merchant_performance as (
    select t.merchant_id,
           count(*) filter (where t.transaction_status = 'Success') as successful_txns,
           coalesce(sum(t.amount) filter (where t.transaction_status = 'Success'), 0) as successful_tpv,
           coalesce(sum(t.actual_fee) filter (where t.transaction_status = 'Success'), 0) as gross_fee_revenue
    from transactions t
    where t.transaction_at >= '2025-10-01'
      and t.transaction_at < '2026-10-01'
    group by t.merchant_id
)
select p.relationship_manager_id,
       p.manager_name,
       p.region,
       p.team,
       count(distinct p.merchant_id) as assigned_merchants,
       count(distinct p.merchant_id) filter (where mp.successful_txns > 0) as revenue_generating_merchants,
       coalesce(sum(mp.successful_txns), 0) as successful_txns,
       coalesce(sum(mp.successful_tpv), 0) as successful_tpv,
       coalesce(sum(mp.gross_fee_revenue), 0) as gross_fee_revenue,
       round(coalesce(sum(mp.gross_fee_revenue), 0) /
             nullif(count(distinct p.merchant_id), 0), 2) as revenue_per_merchant,
       round(100.0 * count(distinct p.merchant_id) filter (where mp.successful_txns > 0) /
             nullif(count(distinct p.merchant_id), 0), 2) as merchant_activation_rate_pct
from rm_portfolio p
left join merchant_performance mp
  on p.merchant_id = mp.merchant_id
group by p.relationship_manager_id, p.manager_name, p.region, p.team;

create or replace view vw_terminal_performance as
with months as (
    select generate_series(
        date_trunc('month', min(transaction_at)),
        date_trunc('month', max(transaction_at)),
        interval '1 month'
    )::date as report_month
    from transactions
),
monthly_terminal_txns as (
    select date_trunc('month', transaction_at)::date as report_month,
           terminal_id,
           count(*) as total_txns,
           count(*) filter (where transaction_status = 'Success') as successful_txns,
           count(*) filter (where transaction_status = 'Failed') as failed_txns,
           coalesce(sum(amount) filter (where transaction_status = 'Success'), 0) as successful_tpv,
           coalesce(sum(actual_fee) filter (where transaction_status = 'Success'), 0) as gross_fee_revenue
    from transactions
    where payment_channel in ('POS_CARD', 'POS_TRANSFER')
      and terminal_id is not null
    group by date_trunc('month', transaction_at)::date, terminal_id
)
select m.report_month,
       t.terminal_id,
       coalesce(mt.total_txns, 0) as total_txns,
       coalesce(mt.successful_txns, 0) as successful_txns,
       coalesce(mt.failed_txns, 0) as failed_txns,
       round(100.0 * coalesce(mt.successful_txns, 0) /
             nullif(mt.total_txns, 0), 2) as success_rate_pct,
       coalesce(mt.successful_tpv, 0) as successful_tpv,
       coalesce(mt.gross_fee_revenue, 0) as gross_fee_revenue,
       case when coalesce(mt.successful_txns, 0) > 0 then 1 else 0 end as is_active
from months m
cross join terminals t
left join monthly_terminal_txns mt
  on m.report_month = mt.report_month
 and t.terminal_id = mt.terminal_id;

 create or replace view vw_monthly_mis_scorecard as
with monthly_terminals as (
    select report_month,
           count(*) as total_terminals,
           sum(is_active) as active_terminals,
           count(*) - sum(is_active) as inactive_terminals,
           round(100.0 * sum(is_active) / nullif(count(*), 0), 2) as activation_rate_pct
    from vw_terminal_performance
    group by report_month
),
monthly_incidents as (
    select report_month,
           count(*) as total_incidents,
           round(avg(resolution_minutes) filter (where incident_status = 'Resolved'), 2) as avg_resolution_minutes,
           sum(within_sla) as incidents_within_sla,
           sum(sla_breached) as sla_breaches,
           round(100.0 * sum(within_sla) /
                 nullif(sum(within_sla) + sum(sla_breached), 0), 2) as sla_compliance_pct
    from vw_incident_performance
    group by report_month
),
monthly_scorecard as (
    select t.report_month,
           t.total_transactions,
           t.successful_txns,
           t.failed_txns,
           t.success_rate_pct,
           t.successful_tpv,
           t.gross_fee_revenue,
           mt.total_terminals,
           mt.active_terminals,
           mt.inactive_terminals,
           mt.activation_rate_pct,
           coalesce(mi.total_incidents, 0) as total_incidents,
           mi.avg_resolution_minutes,
           coalesce(mi.incidents_within_sla, 0) as incidents_within_sla,
           coalesce(mi.sla_breaches, 0) as sla_breaches,
           mi.sla_compliance_pct
    from vw_monthly_transaction_kpis t
    left join monthly_terminals mt
      on t.report_month = mt.report_month
    left join monthly_incidents mi
      on t.report_month = mi.report_month
)
select *,
       round(100.0 * (successful_tpv - lag(successful_tpv) over (order by report_month)) /
             nullif(lag(successful_tpv) over (order by report_month), 0), 2) as tpv_mom_growth_pct,
       round(100.0 * (gross_fee_revenue - lag(gross_fee_revenue) over (order by report_month)) /
             nullif(lag(gross_fee_revenue) over (order by report_month), 0), 2) as revenue_mom_growth_pct
from monthly_scorecard;

select *
from vw_monthly_mis_scorecard;