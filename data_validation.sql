select *
from terminal_config_history;

select
    count(*) as total_transactions,
    count(distinct transaction_id) as unique_transactions,
    count(distinct merchant_id) as merchants_with_transactions,
    count(distinct terminal_id) as terminals_with_transactions,
    min(transaction_at) as first_transaction,
    max(transaction_at) as last_transaction
from transactions;

select
    date_trunc('month', transaction_at)::date as transaction_month,
    count(*) as total_transactions,
    count(distinct merchant_id) as active_merchants,
    count(distinct terminal_id) as transacting_terminals
from transactions
group by 1
order by 1;

select
    count(*) filter (
        where merchant_id is null
    ) as missing_merchant_id,
    count(*) filter (
        where transaction_at is null
    ) as missing_transaction_date,
    count(*) filter (
        where amount is null
    ) as missing_amount,
    count(*) filter (
        where transaction_status is null
    ) as missing_status,
    count(*) filter (
        where payment_channel is null
    ) as missing_channel,
    count(*) filter (
        where payment_channel in ('POS_CARD', 'POS_TRANSFER')
            and terminal_id is null
    ) as missing_pos_terminal
from transaction;
select
    count (*) filter (where amount<=0) as invalid_amounts,
    count(*) filter (where transaction_status not in ('Success', 'Failed', 'Abandoned', 'Pending')
    ) as invalid_statuses,
    count(*) filter (
        where payment_channel not in ('POS_CARD', 'POS_TRANSFER', 'PWBT')
    ) as invalid_channels,
    count(*) filter (
        where transaction_status = 'Success' and actual_fee is null
    ) as successful_transactions_missing_fees,
    count(*) filter (
        where transaction_status <> 'Success' and actual_fee is not null
    ) as unsuccessful_transactions_with_fees
from transactions;
select
    column_name,
    data_type
from information_schema.columns
where table_schema = 'public'
    and table_name = 'terminal_assignments'
order by ordinal_position;
select
    count(*) as total_assignments,
    count(*) filter (
        where assigned_at is null
    ) as missing_start_dates,
    count(*) filter (
        where unassigned_at is not null
          and unassigned_at <= assigned_at
    ) as invalid_date_ranges
from terminal_assignments;
select count(*) as invalid_date_ranges
from terminal_assignments
where unassigned_at<=assigned_at;
select count(*)filter (where assigned_at is null) as missing_start_dates
from terminal_assignments;
select count(*) as total_assignments,
       count(*) filter(where unassigned_at<=assigned_at)as invalid_date_range,
	   count(*) filter(where assigned_at is null)as missing_start_date
from terminal_assignments;
select
    count(*) as total_assignments,
    count(unassigned_at) as completed_assignments,
    count(*) filter (
        where unassigned_at is null
    ) as ongoing_assignments
from terminal_assignments;
select
    terminal_id,
    count(*) as assignment_count
from terminal_assignments
group by terminal_id
having count(*)>1;
select
    tr.merchant_id as transaction_merchant,
    tr.terminal_id,
    ta.merchant_id as assigned_merchant
from transactions tr
left join terminal_assignments ta
    on tr.terminal_id = ta.terminal_id;
	select
    payment_channel,
    count(*) as total_transactions,
    count(*) filter (
        where terminal_id is null
    ) as missing_terminal_ids
from transactions
group by payment_channel;
select
    tr.merchant_id as transaction_merchant,
    tr.terminal_id,
    ta.merchant_id as assigned_merchant
from transactions tr
left join terminal_assignments ta
    on tr.terminal_id = ta.terminal_id
where tr.payment_channel in ('POS_CARD', 'POS_TRANSFER');
select count(*) as total_records,
            count(distinct transaction_id) as distinct_transaction_id
from transactions;
select count(*) as missing_transaction_ids
from transactions
where transaction_id is null;
select tr.transaction_id,tr.terminal_id,tr.merchant_id,tr.payment_channel
from transactions tr
left join terminal_assignments ta
on tr.terminal_id=ta.terminal_id
where tr.payment_channel in ('POS_CARD','POS_TRANSFER') and ta. terminal_id is null;
select
    tr.transaction_id,
    tr.terminal_id,
    tr.merchant_id as transaction_merchant,
    ta.merchant_id as assigned_merchant
from transactions tr
left join terminal_assignments ta
    on tr.terminal_id = ta.terminal_id
where tr.payment_channel in ('POS_CARD', 'POS_TRANSFER')
    and tr.merchant_id <> ta.merchant_id;
	select
    column_name,
    data_type
from information_schema.columns
where table_schema = 'public'
    and table_name = 'transactions'
    and data_type like 'timestamp%'
order by ordinal_position;
select tr.transaction_id,
     tr.terminal_id,
	 tr. merchant_id,
	 tr.transaction_at,
	 ta.assigned_at,
	 ta.unassigned_at
from transactions tr
left join terminal_assignments ta
on tr.terminal_id=ta.terminal_id
where tr.payment_channel in ('POS_CARD', 'POS_TRANSFER')
   and (tr.transaction_at<ta.assigned_at or tr.transaction_at>=ta.assigned_at);
   select
    count(*) filter (
        where tr.transaction_at < ta.assigned_at
    ) as before_assignment,
    count(*) filter (
        where tr.transaction_at >= ta.unassigned_at
    ) as after_unassignment
from transactions tr
left join terminal_assignments ta
    on tr.terminal_id = ta.terminal_id
where tr.payment_channel in ('POS_CARD', 'POS_TRANSFER');
select
    count(*) as invalid_assignment_dates
from transactions tr
join terminal_assignments ta
    on tr.terminal_id = ta.terminal_id
where tr.payment_channel in ('POS_CARD', 'POS_TRANSFER')
    and (
        tr.transaction_at < ta.assigned_at
        or (
            ta.unassigned_at is not null
            and tr.transaction_at >= ta.unassigned_at
        )
    );
	select
    min(transaction_at) as first_transaction,
    max(transaction_at) as last_transaction,
    count(*) as total_transactions
from transactions;
select count(*) as reporting_transactions,
      count(distinct merchant_id) as merchants_with_transactions,
	  count(distinct terminal_id) as terminals_with_transactions
from transactions
where transaction_at>='2025-10-01'
 and transaction_at<'2026-10-01';
 select
    merchant_id,
    count(distinct terminal_id) as terminal_count
from transactions
where transaction_at >= '2025-10-01'
    and transaction_at < '2026-10-01'
    and payment_channel in ('POS_CARD', 'POS_TRANSFER')
group by merchant_id
order by terminal_count desc
limit 10;
Merchant-Terminal Mismatch Validation
select
    tr.transaction_id,
    tr.terminal_id,
    tr.merchant_id as transaction_merchant,
    ta.merchant_id as assigned_merchant
from transactions tr
left join terminal_assignments ta
    on tr.terminal_id = ta.terminal_id
where tr.payment_channel in ('POS_CARD', 'POS_TRANSFER')
    and tr.merchant_id <> ta.merchant_id;
	select
    merchant_id,
    count(*) as total_transactions
	from transactions
	group by merchant_id
	order by count(*);


	

	