-- Kent + Medway directory: non-geocoded advice layer.
-- Source: KCC BetterCare Support signposting list, ASCOT-tagged by hand.
-- Run AFTER 01_schema_resources.sql. Idempotent: safe to re-run.

begin;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Technology Enhanced Lives House', 'https://kent.connecttosupport.org/technology-enhanced-lives-house/', 'Aids and equipment', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.8, 'manual' from resource where url = 'https://kent.connecttosupport.org/technology-enhanced-lives-house/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.7, 'manual' from resource where url = 'https://kent.connecttosupport.org/technology-enhanced-lives-house/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.5, 'manual' from resource where url = 'https://kent.connecttosupport.org/technology-enhanced-lives-house/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Equipment House', 'https://kent.connecttosupport.org/equipment-house/', 'Aids and equipment', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.7, 'manual' from resource where url = 'https://kent.connecttosupport.org/equipment-house/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.7, 'manual' from resource where url = 'https://kent.connecttosupport.org/equipment-house/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/equipment-house/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.5, 'manual' from resource where url = 'https://kent.connecttosupport.org/equipment-house/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Medequip Community Equipment Service', 'https://www.medequip-uk.com', 'Aids and equipment', 'kent', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.7, 'manual' from resource where url = 'https://www.medequip-uk.com'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.7, 'manual' from resource where url = 'https://www.medequip-uk.com'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.6, 'manual' from resource where url = 'https://www.medequip-uk.com'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Dressing aids', 'https://www.manageathome.co.uk/collections/dressing-aids', 'Aids and equipment', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.9, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/dressing-aids'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.6, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/dressing-aids'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.5, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/dressing-aids'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Mobility aids', 'https://www.manageathome.co.uk/collections/mobility', 'Aids and equipment', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.6, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/mobility'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/mobility'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.4, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/mobility'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.4, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/mobility'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Equipment and adaptations in Kent', 'https://kent.connecttosupport.org/information-and-advice/home-and-community/equipment-and-adaptations/help-and-advice/', 'Aids and equipment', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.8, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/equipment-and-adaptations/help-and-advice/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.7, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/equipment-and-adaptations/help-and-advice/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/equipment-and-adaptations/help-and-advice/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Eating and drinking aids', 'https://www.manageathome.co.uk/collections/eating-and-drinking', 'Aids and equipment', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.9, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/eating-and-drinking'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.6, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/eating-and-drinking'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.5, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/eating-and-drinking'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Household aids', 'https://www.manageathome.co.uk/collections/living-aids', 'Aids and equipment', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.7, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/living-aids'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/living-aids'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.5, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/living-aids'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Personal care and grooming aids', 'https://www.manageathome.co.uk/collections/washing-and-personal-care', 'Aids and equipment', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.9, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/washing-and-personal-care'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.7, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/washing-and-personal-care'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Home adaptations', 'https://www.kent.gov.uk/social-care-and-health/adult-social-care/care-and-support/live-safe-and-well-at-home/equipment-and-changes-to-your-home/home-adaptations', 'Aids and equipment', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.9, 'manual' from resource where url = 'https://www.kent.gov.uk/social-care-and-health/adult-social-care/care-and-support/live-safe-and-well-at-home/equipment-and-changes-to-your-home/home-adaptations'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.7, 'manual' from resource where url = 'https://www.kent.gov.uk/social-care-and-health/adult-social-care/care-and-support/live-safe-and-well-at-home/equipment-and-changes-to-your-home/home-adaptations'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Bathroom aids', 'https://www.manageathome.co.uk/collections/bathroom', 'Aids and equipment', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.9, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/bathroom'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.7, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/bathroom'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.6, 'manual' from resource where url = 'https://www.manageathome.co.uk/collections/bathroom'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Accessible toilets and changing places in Kent', 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/accessible-toilets-and-changing-places/accessible-toilets-and-changing-places/', 'Aids and equipment', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.8, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/accessible-toilets-and-changing-places/accessible-toilets-and-changing-places/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/accessible-toilets-and-changing-places/accessible-toilets-and-changing-places/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.5, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/accessible-toilets-and-changing-places/accessible-toilets-and-changing-places/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Community Micro-Enterprise', 'https://kent.connecttosupport.org/information-and-advice/home-and-community/community-micro-enterprises/community-micro-enterprises/', 'Guides', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/community-micro-enterprises/community-micro-enterprises/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.4, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/community-micro-enterprises/community-micro-enterprises/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.4, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/community-micro-enterprises/community-micro-enterprises/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Personal Assistants', 'https://kent.connecttosupport.org/information-and-advice/home-and-community/personal-assistants/what-is-a-personal-assistant/', 'Guides', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.9, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/personal-assistants/what-is-a-personal-assistant/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.7, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/personal-assistants/what-is-a-personal-assistant/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.5, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/personal-assistants/what-is-a-personal-assistant/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.5, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/personal-assistants/what-is-a-personal-assistant/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Hoarding information, advice and resources (Hoarding Support)', 'https://hoarding.support/', 'Guides', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.8, 'manual' from resource where url = 'https://hoarding.support/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.7, 'manual' from resource where url = 'https://hoarding.support/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.5, 'manual' from resource where url = 'https://hoarding.support/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Hoarding information, advice and resources (Hoarding Disorders UK)', 'https://hoardingdisordersuk.org/', 'Guides', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.8, 'manual' from resource where url = 'https://hoardingdisordersuk.org/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.7, 'manual' from resource where url = 'https://hoardingdisordersuk.org/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.5, 'manual' from resource where url = 'https://hoardingdisordersuk.org/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Falls prevention in the home', 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/falls-prevention/', 'Guides', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.9, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/falls-prevention/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Fire safety in the home', 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/fire-safety/', 'Guides', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.9, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/fire-safety/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Bathroom safety in the home', 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/bathroom-safety/', 'Guides', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.9, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/bathroom-safety/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.5, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/bathroom-safety/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Kitchen safety in the home', 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/kitchen-safety/', 'Guides', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.9, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/kitchen-safety/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.5, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/kitchen-safety/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Staircase safety in the home', 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/staircase-safety/', 'Guides', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.9, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/staircase-safety/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.5, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/staircase-safety/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Shopping services in Kent', 'https://kent.connecttosupport.org/information-and-advice/home-and-community/homecare-and-help-around-your-home/shopping-services/', 'Shopping service', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.8, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/homecare-and-help-around-your-home/shopping-services/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/homecare-and-help-around-your-home/shopping-services/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Motability', 'https://www.motability.co.uk/', 'Assistance schemes', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.7, 'manual' from resource where url = 'https://www.motability.co.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.6, 'manual' from resource where url = 'https://www.motability.co.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://www.motability.co.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('The Trussell Trust - Food Bank', 'https://www.trussell.org.uk/', 'Assistance schemes', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.9, 'manual' from resource where url = 'https://www.trussell.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('NHS - Support with hoarding', 'https://www.nhs.uk/mental-health/conditions/hoarding-disorder/', 'Assistance schemes', 'national', 'health', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.7, 'manual' from resource where url = 'https://www.nhs.uk/mental-health/conditions/hoarding-disorder/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.6, 'manual' from resource where url = 'https://www.nhs.uk/mental-health/conditions/hoarding-disorder/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Buy With Confidence - Find a business you can trust', 'https://www.buywithconfidence.gov.uk/', 'Assistance schemes', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.8, 'manual' from resource where url = 'https://www.buywithconfidence.gov.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.4, 'manual' from resource where url = 'https://www.buywithconfidence.gov.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('LEAP - Local Energy Advice Partnership', 'https://applyforleap.org.uk/apply/', 'Assistance schemes', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.8, 'manual' from resource where url = 'https://applyforleap.org.uk/apply/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Housing Advice Options for Older People (HOOP)', 'https://hoop.eac.org.uk/hooptool/', 'Assistance schemes', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.9, 'manual' from resource where url = 'https://hoop.eac.org.uk/hooptool/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://hoop.eac.org.uk/hooptool/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Wheels for Wellbeing', 'https://wheelsforwellbeing.org.uk', 'Assistance schemes', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.7, 'manual' from resource where url = 'https://wheelsforwellbeing.org.uk'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.7, 'manual' from resource where url = 'https://wheelsforwellbeing.org.uk'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Disability Driving Instructors', 'https://www.disabilitydrivinginstructors.com/', 'Assistance schemes', 'national', 'other', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.7, 'manual' from resource where url = 'https://www.disabilitydrivinginstructors.com/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.6, 'manual' from resource where url = 'https://www.disabilitydrivinginstructors.com/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.5, 'manual' from resource where url = 'https://www.disabilitydrivinginstructors.com/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Stagecoach Journey Assistance Cards', 'https://www.stagecoachbus.com/promos-and-offers/national/journey-assistance-cards', 'Assistance schemes', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.6, 'manual' from resource where url = 'https://www.stagecoachbus.com/promos-and-offers/national/journey-assistance-cards'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.5, 'manual' from resource where url = 'https://www.stagecoachbus.com/promos-and-offers/national/journey-assistance-cards'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.5, 'manual' from resource where url = 'https://www.stagecoachbus.com/promos-and-offers/national/journey-assistance-cards'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Travelling by train (Railcard)', 'https://www.railcard.co.uk', 'Assistance schemes', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.6, 'manual' from resource where url = 'https://www.railcard.co.uk'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.5, 'manual' from resource where url = 'https://www.railcard.co.uk'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Accessible train travel', 'https://www.nationalrail.co.uk/on-the-train/accessible-train-travel-and-facilities/', 'Assistance schemes', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.6, 'manual' from resource where url = 'https://www.nationalrail.co.uk/on-the-train/accessible-train-travel-and-facilities/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.5, 'manual' from resource where url = 'https://www.nationalrail.co.uk/on-the-train/accessible-train-travel-and-facilities/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.5, 'manual' from resource where url = 'https://www.nationalrail.co.uk/on-the-train/accessible-train-travel-and-facilities/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Trainline accessible travel', 'https://support.thetrainline.com/hc/en-gb/articles/5186625841183-How-to-book-assistance-or-check-accessibility-for-disabled-passengers', 'Assistance schemes', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.5, 'manual' from resource where url = 'https://support.thetrainline.com/hc/en-gb/articles/5186625841183-How-to-book-assistance-or-check-accessibility-for-disabled-passengers'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.4, 'manual' from resource where url = 'https://support.thetrainline.com/hc/en-gb/articles/5186625841183-How-to-book-assistance-or-check-accessibility-for-disabled-passengers'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('NHS Health Checks', 'https://www.nhs.uk/tests-and-treatments/nhs-health-check/', 'Assistance schemes', 'national', 'health', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.6, 'manual' from resource where url = 'https://www.nhs.uk/tests-and-treatments/nhs-health-check/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('NHS Vaccinations', 'https://www.nhs.uk/vaccinations/', 'Assistance schemes', 'national', 'health', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.7, 'manual' from resource where url = 'https://www.nhs.uk/vaccinations/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('One You Kent', 'https://www.kent.gov.uk/social-care-and-health/health/one-you-kent', 'Help, advice and guidance', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.6, 'manual' from resource where url = 'https://www.kent.gov.uk/social-care-and-health/health/one-you-kent'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.5, 'manual' from resource where url = 'https://www.kent.gov.uk/social-care-and-health/health/one-you-kent'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.5, 'manual' from resource where url = 'https://www.kent.gov.uk/social-care-and-health/health/one-you-kent'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.4, 'manual' from resource where url = 'https://www.kent.gov.uk/social-care-and-health/health/one-you-kent'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Kent Connect to Support - Community Directory', 'https://kent.connecttosupport.org', 'Help, advice and guidance', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.5, 'manual' from resource where url = 'https://kent.connecttosupport.org'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Kent Care Directory - Care Choices', 'https://www.carechoices.co.uk/publication/kent-care-services-directory', 'Help, advice and guidance', 'kent', 'other', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.6, 'manual' from resource where url = 'https://www.carechoices.co.uk/publication/kent-care-services-directory'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.6, 'manual' from resource where url = 'https://www.carechoices.co.uk/publication/kent-care-services-directory'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.5, 'manual' from resource where url = 'https://www.carechoices.co.uk/publication/kent-care-services-directory'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Age UK - Help at home', 'https://www.ageuk.org.uk/services/in-your-area/home-help/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.7, 'manual' from resource where url = 'https://www.ageuk.org.uk/services/in-your-area/home-help/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.5, 'manual' from resource where url = 'https://www.ageuk.org.uk/services/in-your-area/home-help/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.5, 'manual' from resource where url = 'https://www.ageuk.org.uk/services/in-your-area/home-help/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Carers UK Digital Resource for Carers', 'https://www.carersuk.org/for-professionals/digital-products-and-services/digital-resource-for-carers/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://www.carersuk.org/for-professionals/digital-products-and-services/digital-resource-for-carers/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.4, 'manual' from resource where url = 'https://www.carersuk.org/for-professionals/digital-products-and-services/digital-resource-for-carers/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Jointly App - Carers Support', 'https://jointlyapp.com/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://jointlyapp.com/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Independent financial advice for older people', 'https://www.kent.gov.uk/social-care-and-health/adult-social-care/paying-for-care/independent-financial-advice-for-older-people', 'Support services and organisations', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.8, 'manual' from resource where url = 'https://www.kent.gov.uk/social-care-and-health/adult-social-care/paying-for-care/independent-financial-advice-for-older-people'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Benefits and financial support', 'https://www.kent.gov.uk/social-care-and-health/adult-social-care/paying-for-care/benefits-and-financial-support', 'Support services and organisations', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.8, 'manual' from resource where url = 'https://www.kent.gov.uk/social-care-and-health/adult-social-care/paying-for-care/benefits-and-financial-support'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.4, 'manual' from resource where url = 'https://www.kent.gov.uk/social-care-and-health/adult-social-care/paying-for-care/benefits-and-financial-support'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.4, 'manual' from resource where url = 'https://www.kent.gov.uk/social-care-and-health/adult-social-care/paying-for-care/benefits-and-financial-support'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Financial calculator - estimate what you may pay for care', 'https://www.kent.gov.uk/social-care-and-health/adult-social-care/paying-for-care/how-much-you-will-pay-for-care-and-support/estimate-how-much-you-may-need-to-pay-towards-your-care', 'Support services and organisations', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.7, 'manual' from resource where url = 'https://www.kent.gov.uk/social-care-and-health/adult-social-care/paying-for-care/how-much-you-will-pay-for-care-and-support/estimate-how-much-you-may-need-to-pay-towards-your-care'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Hoarding UK', 'https://www.hoardinguk.org', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.8, 'manual' from resource where url = 'https://www.hoardinguk.org'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.6, 'manual' from resource where url = 'https://www.hoardinguk.org'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.5, 'manual' from resource where url = 'https://www.hoardinguk.org'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Independent Age', 'https://www.independentage.org/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.7, 'manual' from resource where url = 'https://www.independentage.org/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.7, 'manual' from resource where url = 'https://www.independentage.org/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.5, 'manual' from resource where url = 'https://www.independentage.org/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Shelter Housing Advice', 'https://england.shelter.org.uk/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.9, 'manual' from resource where url = 'https://england.shelter.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Citizens Advice Housing Advice', 'https://www.citizensadvice.org.uk/housing/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.9, 'manual' from resource where url = 'https://www.citizensadvice.org.uk/housing/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://www.citizensadvice.org.uk/housing/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Care Service Directory in Kent', 'https://kent.connecttosupport.org/s4s/CustomPage/Index/176?q=', 'Support services and organisations', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/s4s/CustomPage/Index/176?q='
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.5, 'manual' from resource where url = 'https://kent.connecttosupport.org/s4s/CustomPage/Index/176?q='
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Hidden Disabilities Sunflower', 'https://hdsunflower.com/uk/', 'Support services and organisations', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.8, 'manual' from resource where url = 'https://hdsunflower.com/uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.6, 'manual' from resource where url = 'https://hdsunflower.com/uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('NHS Live Well', 'https://www.nhs.uk/live-well/', 'Support services and organisations', 'national', 'health', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.5, 'manual' from resource where url = 'https://www.nhs.uk/live-well/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.5, 'manual' from resource where url = 'https://www.nhs.uk/live-well/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.4, 'manual' from resource where url = 'https://www.nhs.uk/live-well/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('AbilityNet - Accessibility', 'https://abilitynet.org.uk/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.7, 'manual' from resource where url = 'https://abilitynet.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.6, 'manual' from resource where url = 'https://abilitynet.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://abilitynet.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Money Helper', 'https://www.moneyhelper.org.uk/en', 'Support services and organisations', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.8, 'manual' from resource where url = 'https://www.moneyhelper.org.uk/en'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('SOLLA - Society of Later Life Advisers', 'https://societyoflaterlifeadvisers.co.uk/', 'Support services and organisations', 'national', 'other', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.8, 'manual' from resource where url = 'https://societyoflaterlifeadvisers.co.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.4, 'manual' from resource where url = 'https://societyoflaterlifeadvisers.co.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Compassion in Dying', 'https://compassionindying.org.uk/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.9, 'manual' from resource where url = 'https://compassionindying.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.8, 'manual' from resource where url = 'https://compassionindying.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Find my Home Improvement Agency', 'https://www.findmyhia.org.uk/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.9, 'manual' from resource where url = 'https://www.findmyhia.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.6, 'manual' from resource where url = 'https://www.findmyhia.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Report Fraud', 'https://www.reportfraud.police.uk/', 'Support services and organisations', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.9, 'manual' from resource where url = 'https://www.reportfraud.police.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.5, 'manual' from resource where url = 'https://www.reportfraud.police.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Dementia Friendly Communities Kent', 'https://kent.connecttosupport.org/community-directory-services/dementia-friendly-communities/', 'Support services and organisations', 'kent', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.9, 'manual' from resource where url = 'https://kent.connecttosupport.org/community-directory-services/dementia-friendly-communities/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.7, 'manual' from resource where url = 'https://kent.connecttosupport.org/community-directory-services/dementia-friendly-communities/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/community-directory-services/dementia-friendly-communities/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Age UK - Keeping fit', 'https://www.ageuk.org.uk/services/in-your-area/exercise/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.8, 'manual' from resource where url = 'https://www.ageuk.org.uk/services/in-your-area/exercise/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.7, 'manual' from resource where url = 'https://www.ageuk.org.uk/services/in-your-area/exercise/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.5, 'manual' from resource where url = 'https://www.ageuk.org.uk/services/in-your-area/exercise/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Road safety (THINK)', 'https://www.think.gov.uk/', 'Support services and organisations', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.7, 'manual' from resource where url = 'https://www.think.gov.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('The Silver Line Helpline', 'https://www.thesilverline.org.uk/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.9, 'manual' from resource where url = 'https://www.thesilverline.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.5, 'manual' from resource where url = 'https://www.thesilverline.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Carers Digital', 'https://carersdigital.org/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://carersdigital.org/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Cruse Bereavement Support', 'https://www.cruse.org.uk/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.7, 'manual' from resource where url = 'https://www.cruse.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.6, 'manual' from resource where url = 'https://www.cruse.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('MindEd for Families - older people', 'https://www.mindedforfamilies.org.uk/older-people', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.5, 'manual' from resource where url = 'https://www.mindedforfamilies.org.uk/older-people'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.4, 'manual' from resource where url = 'https://www.mindedforfamilies.org.uk/older-people'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('NHS - Support for veterans', 'https://www.nhs.uk/nhs-services/armed-forces-community/veterans-service-leavers-non-mobilised-reservists/', 'Support services and organisations', 'national', 'health', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.6, 'manual' from resource where url = 'https://www.nhs.uk/nhs-services/armed-forces-community/veterans-service-leavers-non-mobilised-reservists/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.5, 'manual' from resource where url = 'https://www.nhs.uk/nhs-services/armed-forces-community/veterans-service-leavers-non-mobilised-reservists/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Citizens Advice', 'https://www.citizensadvice.org.uk/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.8, 'manual' from resource where url = 'https://www.citizensadvice.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.6, 'manual' from resource where url = 'https://www.citizensadvice.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.4, 'manual' from resource where url = 'https://www.citizensadvice.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Deafblind UK', 'https://deafblind.org.uk/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.8, 'manual' from resource where url = 'https://deafblind.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.6, 'manual' from resource where url = 'https://deafblind.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://deafblind.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Alzheimer''s Society - Dementia support', 'https://www.alzheimers.org.uk/', 'Support services and organisations', 'national', 'voluntary', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.7, 'manual' from resource where url = 'https://www.alzheimers.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.7, 'manual' from resource where url = 'https://www.alzheimers.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://www.alzheimers.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.5, 'manual' from resource where url = 'https://www.alzheimers.org.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Find a job', 'https://www.gov.uk/find-a-job', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.4, 'manual' from resource where url = 'https://www.gov.uk/find-a-job'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Volunteering', 'https://www.gov.uk/volunteering', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.8, 'manual' from resource where url = 'https://www.gov.uk/volunteering'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.8, 'manual' from resource where url = 'https://www.gov.uk/volunteering'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Jobcentre Plus', 'https://www.gov.uk/contact-jobcentre-plus', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.4, 'manual' from resource where url = 'https://www.gov.uk/contact-jobcentre-plus'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.4, 'manual' from resource where url = 'https://www.gov.uk/contact-jobcentre-plus'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Access to Work', 'https://www.gov.uk/access-to-work', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.5, 'manual' from resource where url = 'https://www.gov.uk/access-to-work'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Benefits and financial support for carers', 'https://www.gov.uk/browse/benefits/help-for-carers', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.7, 'manual' from resource where url = 'https://www.gov.uk/browse/benefits/help-for-carers'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Disabled facilities grants', 'https://www.gov.uk/disabled-facilities-grants', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.9, 'manual' from resource where url = 'https://www.gov.uk/disabled-facilities-grants'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.6, 'manual' from resource where url = 'https://www.gov.uk/disabled-facilities-grants'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Warm Home Discount Scheme', 'https://www.gov.uk/the-warm-home-discount-scheme', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.7, 'manual' from resource where url = 'https://www.gov.uk/the-warm-home-discount-scheme'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Cold Weather Payment', 'https://www.gov.uk/cold-weather-payment', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.7, 'manual' from resource where url = 'https://www.gov.uk/cold-weather-payment'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Winter Fuel Payment', 'https://www.gov.uk/winter-fuel-payment/how-much-youll-get', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'accommodation', 0.7, 'manual' from resource where url = 'https://www.gov.uk/winter-fuel-payment/how-much-youll-get'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Make, register or end a lasting power of attorney', 'https://www.gov.uk/power-of-attorney', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.9, 'manual' from resource where url = 'https://www.gov.uk/power-of-attorney'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.6, 'manual' from resource where url = 'https://www.gov.uk/power-of-attorney'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Become an appointee for someone claiming benefits', 'https://www.gov.uk/become-appointee-for-someone-claiming-benefits', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.7, 'manual' from resource where url = 'https://www.gov.uk/become-appointee-for-someone-claiming-benefits'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Deputies: make decisions for someone who lacks capacity', 'https://www.gov.uk/become-deputy', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.7, 'manual' from resource where url = 'https://www.gov.uk/become-deputy'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'dignity', 0.5, 'manual' from resource where url = 'https://www.gov.uk/become-deputy'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Blue Badge Scheme in Kent', 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/blue-badge-scheme/', 'Government support', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.7, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/blue-badge-scheme/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/blue-badge-scheme/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/blue-badge-scheme/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Wheelchair service transport in Kent', 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/wheelchair-service/', 'Government support', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/wheelchair-service/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/wheelchair-service/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.5, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/wheelchair-service/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Bus passes in Kent', 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/travelling-by-bus/', 'Government support', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.8, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/travelling-by-bus/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'occupation', 0.7, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/travelling-by-bus/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/travelling-by-bus/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Disability Service Centre', 'https://www.gov.uk/disability-service-centre', 'Government support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://www.gov.uk/disability-service-centre'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('NHS continuing healthcare', 'https://www.nhs.uk/social-care-and-support/money-work-and-benefits/nhs-continuing-healthcare/', 'Government support', 'national', 'health', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'personal_care', 0.7, 'manual' from resource where url = 'https://www.nhs.uk/social-care-and-support/money-work-and-benefits/nhs-continuing-healthcare/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://www.nhs.uk/social-care-and-support/money-work-and-benefits/nhs-continuing-healthcare/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Meal delivery services in Kent', 'https://kent.connecttosupport.org/information-and-advice/home-and-community/homecare-and-help-around-your-home/meal-delivery-services/', 'Meal support', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.9, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/homecare-and-help-around-your-home/meal-delivery-services/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Meals on wheels', 'https://www.gov.uk/meals-home', 'Meal support', 'national', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.9, 'manual' from resource where url = 'https://www.gov.uk/meals-home'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'social', 0.4, 'manual' from resource where url = 'https://www.gov.uk/meals-home'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Oakhouse Foods', 'https://www.oakhousefoods.co.uk/', 'Meal support', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.8, 'manual' from resource where url = 'https://www.oakhousefoods.co.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Wiltshire Farm Foods', 'https://www.wiltshirefarmfoods.com/', 'Meal support', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'food', 0.8, 'manual' from resource where url = 'https://www.wiltshirefarmfoods.com/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('The Technology Enhanced Lives Service', 'https://kent.connecttosupport.org/information-and-advice/home-and-community/assistive-technology/the-technology-enhanced-lives-service/', 'Telecare', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.9, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/assistive-technology/the-technology-enhanced-lives-service/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/assistive-technology/the-technology-enhanced-lives-service/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Private Pay Service (Argenti)', 'https://argenti.co.uk/', 'Telecare', 'kent', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.8, 'manual' from resource where url = 'https://argenti.co.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.5, 'manual' from resource where url = 'https://argenti.co.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Technology enabled care in Kent', 'https://kent.connecttosupport.org/information-and-advice/home-and-community/assistive-technology/sensors-alarms-and-monitors/', 'Telecare', 'kent', 'statutory', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.9, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/assistive-technology/sensors-alarms-and-monitors/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.6, 'manual' from resource where url = 'https://kent.connecttosupport.org/information-and-advice/home-and-community/assistive-technology/sensors-alarms-and-monitors/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

insert into resource (title, url, category, scope, provider_type, primary_source) values
  ('Careline 365', 'https://careline.co.uk/', 'Telecare', 'national', 'commercial', 'KCC BetterCare Support')
on conflict (url) do update set
  title = excluded.title, category = excluded.category,
  scope = excluded.scope, provider_type = excluded.provider_type;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'safety', 0.8, 'manual' from resource where url = 'https://careline.co.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;
insert into resource_domain (resource_id, domain, confidence, method)
  select id, 'control', 0.5, 'manual' from resource where url = 'https://careline.co.uk/'
on conflict (resource_id, domain) do update set confidence = excluded.confidence;

commit;
