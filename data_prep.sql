# clean mistyped emails

update `dev-msa-browstage.zb_reg.zb_reg_fv_hash` a
set a.email = b.string_field_4 
--from `dev-msa-browstage.zb_reg.zb_reg_fv_hash` a
from 
(select distinct email, string_field_4 
from `dev-msa-browstage.zb_reg.zb_reg_fv_hash` a
inner join `dev-msa-browstage.zb_reg.updated_email` b on lower(a.email) = lower(b.string_field_3)
where email <> string_field_4 ) b
where lower(a.email) = lower(b.email)


# join email and page views

SELECT case when email is not null then email else a.fullvisitorId end as User,
visit_date, publication_country, a.platform, a.fullVisitorId, visitId, hitNumber, hit_datetime, hitType, deviceCategory, page_type, b.email, 
case when email is not null then 1 else 0 end as reg_flag,
b.verify
FROM `prd-msa-ga360bq.all_flat.combined_flat` a 
left join `dev-msa-browstage.zb_reg.zb_fv_email_final` b on a.fullVisitorId = b.fullVisitorId and a.platform = b.platform 
WHERE visit_date >= "2019-10-01" and visit_date < "2020-09-01" 
and email is not null
and publication_country = 'SG'
and product_family = 'ZB' and (hitType = 'PAGE' or hitType = 'APPVIEW')


# summary data by year, month, platform

select Year, Mon, platform, count(distinct user) as NofUser, sum(PV) as NofPV, sum(PV)/count(distinct user) as PVperUser
from (
select user, Year, Mon, platform, count(*) as PV
from (
SELECT case when email is not null then lower(email) else a.fullvisitorId end as User,
visit_date, extract(MONTH from visit_date) as Mon,  extract(YEAR from visit_date) as Year, 
publication_country, a.platform, a.fullVisitorId, visitId, hitNumber, hit_datetime, hitType, deviceCategory, page_type, b.email, 
case when email is not null then 1 else 0 end as reg_flag,
b.verify
FROM `prd-msa-ga360bq.all_flat.combined_flat` a 
left join `dev-msa-browstage.zb_reg.zb_fv_email_final` b on a.fullVisitorId = b.fullVisitorId and a.platform = b.platform 
WHERE visit_date >= "2019-10-01" and visit_date < "2020-09-01" 
and email is null
and publication_country = 'SG'
and product_family = 'ZB' and (hitType = 'PAGE' or hitType = 'APPVIEW')
)
group by user, Year, Mon, platform
)
where platform <> 'ePaper'
group by Year, Mon, platform


# Separated by verified/unverified accounts

select user, Year, Mon, platform, verify, count(*) as PV
from (
SELECT case when email is not null then lower(email) else a.fullvisitorId end as User,
visit_date, extract(MONTH from visit_date) as Mon,  extract(YEAR from visit_date) as Year, 
publication_country, a.platform, a.fullVisitorId, visitId, hitNumber, hit_datetime, hitType, deviceCategory, page_type, b.email, 
case when email is not null then 1 else 0 end as reg_flag,
b.verify
FROM `prd-msa-ga360bq.all_flat.combined_flat` a 
left join `dev-msa-browstage.zb_reg.zb_fv_email_final` b on a.fullVisitorId = b.fullVisitorId and a.platform = b.platform 
WHERE visit_date >= "2019-10-01" and visit_date < "2020-09-01" 
and email is not null
and publication_country = 'SG'
and product_family = 'ZB' and (hitType = 'PAGE' or hitType = 'APPVIEW')
)
group by user, Year, Mon, platform, verify
order by Year, Mon, platform


# Visitor Status

select Year, Mon, platform, visitor_cat, count(distinct fullvisitorId) as NofUser
from (
SELECT -- visit_date, extract(MONTH from visit_date) as Mon,  extract(YEAR from visit_date) as Year, 
-- a.platform, a.fullVisitorId, visitId, visitor_category_session
distinct a.visit_date, extract(MONTH from visit_date) as Mon,  extract(YEAR from visit_date) as Year, a.fullVisitorId, platform,
case when visitor_category_session in ('Anonymous', 'non-login', 'anonymous', 'not login', '(not set)', '') or visitor_category_session is null then 'Anonymous'
when visitor_category_session in ('Registered', 'NonverifiedReg', 'VerifiedReg', 'login') then 'Registered'
when visitor_category_session in ('Subscriber', 'subscriber') then 'Subscriber'
else 'Anonymous' end as visitor_cat

FROM `prd-msa-ga360bq.all_flat.combined_flat` a 
WHERE visit_date >= "2019-10-01" and visit_date < "2020-09-01" 
-- a.visit_date = '2020-05-01'
and product_family = 'ZB' and (hitType = 'PAGE' or hitType = 'APPVIEW')
and a.publication_country = 'SG'
)
group by Year, Mon, platform, visitor_cat
order by Year, Mon, platform, visitor_cat


# registered user session time

select Year, Mon, platform, count(distinct user) as NofUser, sum(PV) as NofPV, sum(PV)/count(distinct user) as PVperUser, 
round(sum(page_time)/60/60,1)  as page_hour, sum(n_session) as total_session, round(sum(page_time)/sum(n_session)/60, 1) as average_min
from (
select user, Year, Mon, platform, count(*) as PV, count(distinct visitid) as n_session, sum(page_time_spent) as page_time
from (
SELECT case when email is not null then lower(email) else a.fullvisitorId end as User,
visit_date, extract(MONTH from visit_date) as Mon,  extract(YEAR from visit_date) as Year, 
publication_country, a.platform, a.fullVisitorId, visitId, hitNumber, hit_datetime, hitType, deviceCategory, page_time_spent, page_type, b.email, 
case when email is not null then 1 else 0 end as reg_flag,
b.verify
FROM `prd-msa-ga360bq.all_flat.combined_flat` a 
left join `dev-msa-browstage.zb_reg.zb_fv_email_final` b on a.fullVisitorId = b.fullVisitorId and a.platform = b.platform 
WHERE visit_date >= "2019-10-01" and visit_date < "2020-09-01" 
and email is null
and publication_country = 'SG'
and product_family = 'ZB' and (hitType = 'PAGE' or hitType = 'APPVIEW')
)
group by user, Year, Mon, platform
)


#PV Band

select Year, Mon, pv_band, count(distinct user) as N from (
select user, Year, Mon,
case when PV <= 10 then '1-10' when PV > 10 and PV <= 30 then '11-30' when PV > 30 and PV <= 150 then '31-150' when PV > 150 and PV <= 300 then '151-300' when PV > 300 then '>300' end as pv_band
from (
select user, Year, Mon, platform, count(*) as PV, count(distinct visitid) as n_session, sum(page_time_spent) as page_time
from (
SELECT case when email is not null then lower(email) else a.fullvisitorId end as User,
visit_date, extract(MONTH from visit_date) as Mon,  extract(YEAR from visit_date) as Year, 
publication_country, a.platform, a.fullVisitorId, visitId, hitNumber, hit_datetime, hitType, deviceCategory, page_time_spent, page_type, b.email, 
case when email is not null then 1 else 0 end as reg_flag,
b.verify
FROM `prd-msa-ga360bq.all_flat.combined_flat` a 
left join `dev-msa-browstage.zb_reg.zb_fv_email_final` b on a.fullVisitorId = b.fullVisitorId and a.platform = b.platform 
WHERE visit_date >= "2019-10-01" and visit_date < "2020-09-01" 
and email is null
and publication_country = 'SG'
and product_family = 'ZB' and hitType = 'PAGE' )
group by user, Year, Mon, platform ) )
group by Year, Mon, pv_band
order by Year, Mon, pv_band


