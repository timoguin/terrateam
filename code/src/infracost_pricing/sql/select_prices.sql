with matched as (
  select "productHash", "vendorName", region, prices
  from products
  where ($vendor_name is null or "vendorName" = $vendor_name)
    and ($service is null or service = $service)
    and ($product_family is null or "productFamily" = $product_family)
    and ($sku is null or sku = $sku)
    -- region is the only nullable column of the product filter, so an empty
    -- filter must also match the rows that carry no region.
    and ($region is null
         or region = $region
         or ($region = '' and region is null))
    -- These four repeat equality filters of $attribute_filters on the keys of
    -- products_ec2_instances_index, which can only read them in this form.
    and ($instance_type is null or attributes ->> 'instanceType' = $instance_type)
    and ($operating_system is null or attributes ->> 'operatingSystem' = $operating_system)
    and ($capacity_status is null or attributes ->> 'capacitystatus' = $capacity_status)
    and ($pre_installed_sw is null or attributes ->> 'preInstalledSw' = $pre_installed_sw)
    and not exists (
      select 1
      from jsonb_array_elements($attribute_filters::jsonb) f
      where not coalesce(
        case f ->> 'kind'
          when 'eq' then attributes ->> (f ->> 'key') = f ->> 'value'
          when 'empty' then coalesce(attributes ->> (f ->> 'key'), '') = ''
          when 're' then attributes ->> (f ->> 'key') ~ (f ->> 'value')
          when 're_ci' then attributes ->> (f ->> 'key') ~* (f ->> 'value')
          when 'never' then false
        end,
        false))
  limit 1000)
select m."productHash",
       p.value ->> 'priceHash',
       round(nullif(p.value ->> 'USD', '')::numeric * $rate::numeric, 10)::text,
       round(round(nullif(p.value ->> 'CNY', '')::numeric * $cny_rate::numeric, 10)
               * $rate::numeric, 10)::text,
       p.value ->> 'startUsageAmount',
       p.value ->> 'endUsageAmount',
       m."vendorName" = 'aws' and m.region is null
from matched m, jsonb_each(m.prices) h, jsonb_array_elements(h.value) p
where ($purchase_option is null
       or coalesce(p.value ->> 'purchaseOption', '') = $purchase_option)
  and ($unit is null or coalesce(p.value ->> 'unit', '') = $unit)
  and ($description is null or coalesce(p.value ->> 'description', '') = $description)
  and ($description_regex is null
       or case
            when $description_regex_ci
              then p.value ->> 'description' ~* $description_regex
            else p.value ->> 'description' ~ $description_regex
          end)
  and ($start_usage_amount is null
       or coalesce(p.value ->> 'startUsageAmount', '') = $start_usage_amount)
  and ($end_usage_amount is null
       or coalesce(p.value ->> 'endUsageAmount', '') = $end_usage_amount)
  and ($term_length is null or coalesce(p.value ->> 'termLength', '') = $term_length)
  and ($term_purchase_option is null
       or coalesce(p.value ->> 'termPurchaseOption', '') = $term_purchase_option)
  and ($term_offering_class is null
       or coalesce(p.value ->> 'termOfferingClass', '') = $term_offering_class)
