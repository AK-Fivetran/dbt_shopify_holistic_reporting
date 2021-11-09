with shopify_daily as (

    select *
    from {{ ref('int__daily_shopify_customer_orders') }}

), klaviyo_daily as (

    select *
    from {{ ref('int__daily_klaviyo_user_campaign_flow') }}

), combine_histories as (

    select 
        coalesce(shopify_daily.date_day, klaviyo_daily.date_day) as date_day,
        coalesce(shopify_daily.email, klaviyo_daily.email) as email,

        -- when the below is null, these are unattributed actions
        coalesce(shopify_daily.last_touch_campaign_id, klaviyo_daily.last_touch_campaign_id) as campaign_id,
        coalesce(shopify_daily.last_touch_flow_id, klaviyo_daily.last_touch_flow_id) as flow_id,
        coalesce(shopify_daily.campaign_name, klaviyo_daily.campaign_name) as campaign_name,
        coalesce(shopify_daily.flow_name, klaviyo_daily.flow_name) as flow_name,
        coalesce(shopify_daily.variation_id, klaviyo_daily.variation_id) as variation_id,
        coalesce(shopify_daily.campaign_subject_line, klaviyo_daily.campaign_subject_line) as campaign_subject_line,
        coalesce(shopify_daily.campaign_type, klaviyo_daily.campaign_type) as campaign_type,

        shopify_daily.source_relation as shopify_source_relation,
        klaviyo_daily.source_relation as klaviyo_source_relation,
        
        {{ dbt_utils.star(from=ref('int__daily_shopify_customer_orders'), relation_alias='shopify_daily', prefix='shopify_',
                                except=['date_day', 'email', 'variation_id', 'flow_name', 'campaign_name', 'last_touch_flow_id', 'last_touch_campaign_id']) }},

        {{ dbt_utils.star(from=ref('int__daily_klaviyo_user_campaign_flow'), relation_alias='klaviyo_daily', prefix='klaviyo_',
                                except=['date_day', 'email', 'variation_id', 'flow_name', 'campaign_name', 'last_touch_flow_id', 'last_touch_campaign_id']) }}

    from shopify_daily
    full outer join klaviyo_daily
        on lower(shopify_daily.email) = lower(klaviyo_daily.email)
        and shopify_daily.date_day = klaviyo_daily.date_day
)

select *
from combine_histories