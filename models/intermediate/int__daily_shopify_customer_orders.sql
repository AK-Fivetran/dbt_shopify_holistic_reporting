with orders as (

    select *
    from {{ ref('orders_attribution') }}

), order_lines as (

    select *
    from {{ ref('shopify__order_lines') }}

), order_line_metrics as (

    select 
        order_id,
        count(distinct product_id) as count_products,
        count(distinct product_id || '-' || variant_id) as count_product_variants,
        sum(quantity) as sum_quantity
        
    from order_lines
    group by 1

), join_orders as (

    select 
        orders.*,
        order_line_metrics.count_products,
        order_line_metrics.count_product_variants,
        order_line_metrics.sum_quantity

    from orders 
    left join order_line_metrics
        on orders.order_id = order_line_metrics.order_id

), daily_order_metrics as (

    select
        cast( {{ dbt_utils.date_trunc('day', 'created_timestamp') }} as date) as date_day,
        email,
        last_touch_campaign_id,
        last_touch_flow_id,
        campaign_name,
        flow_name,
        variation_id,
        campaign_subject_line,
        campaign_type,

        count(distinct order_id) as total_orders,
        sum(order_adjusted_total) as total_price,

        sum(line_item_count) as count_line_items,
        sum(total_line_items_price) as total_line_items_price,
        

        sum(total_discounts) as total_discounts,
        sum(total_tax) as total_tax,
        sum(shipping_cost) as total_shipping_cost,
        sum(refund_subtotal) as total_refund_subtotal,
        sum(refund_total_tax) as total_refund_tax,

        sum(case when cancelled_timestamp is not null then 1 else 0 end) as count_cancelled_orders,

        sum(count_products) as count_products,
        sum(count_product_variants) as count_product_variants,
        sum(sum_quantity) as sum_quantity

        -- add refunds/returns, adjustments, fulfilled orders %, discounts

    from join_orders
    {{ dbt_utils.group_by(n=9)}}
)

select *
from daily_order_metrics