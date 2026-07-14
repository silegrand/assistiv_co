#!/usr/bin/env python3
"""
Builds 02_seed_resources.sql from a hand-curated, ASCOT-tagged dataset
derived from the KCC BetterCare Support signposting list.

Row format:
(title, url, category, scope, provider_type, [(domain, confidence), ...])

scope:         'national' | 'kent'
provider_type: statutory | health | voluntary | community | commercial | other
domains:       control, personal_care, food, safety, social, occupation,
               accommodation, dignity
"""

C_AIDS   = 'Aids and equipment'
C_GUIDE  = 'Guides'
C_SHOP   = 'Shopping service'
C_ASSIST = 'Assistance schemes'
C_HELP   = 'Help, advice and guidance'
C_SUPP   = 'Support services and organisations'
C_GOV    = 'Government support'
C_MEAL   = 'Meal support'
C_TELE   = 'Telecare'

R = [
# ---- Aids and equipment ----
("Technology Enhanced Lives House", "https://kent.connecttosupport.org/technology-enhanced-lives-house/", C_AIDS, "kent", "statutory",
 [("safety",0.8),("control",0.7),("accommodation",0.5)]),
("Equipment House", "https://kent.connecttosupport.org/equipment-house/", C_AIDS, "kent", "statutory",
 [("personal_care",0.7),("safety",0.7),("accommodation",0.6),("control",0.5)]),
("Medequip Community Equipment Service", "https://www.medequip-uk.com", C_AIDS, "kent", "commercial",
 [("personal_care",0.7),("safety",0.7),("accommodation",0.6)]),
("Dressing aids", "https://www.manageathome.co.uk/collections/dressing-aids", C_AIDS, "national", "commercial",
 [("personal_care",0.9),("dignity",0.6),("control",0.5)]),
("Mobility aids", "https://www.manageathome.co.uk/collections/mobility", C_AIDS, "national", "commercial",
 [("safety",0.6),("control",0.6),("social",0.4),("occupation",0.4)]),
("Equipment and adaptations in Kent", "https://kent.connecttosupport.org/information-and-advice/home-and-community/equipment-and-adaptations/help-and-advice/", C_AIDS, "kent", "statutory",
 [("accommodation",0.8),("safety",0.7),("personal_care",0.6)]),
("Eating and drinking aids", "https://www.manageathome.co.uk/collections/eating-and-drinking", C_AIDS, "national", "commercial",
 [("food",0.9),("dignity",0.6),("control",0.5)]),
("Household aids", "https://www.manageathome.co.uk/collections/living-aids", C_AIDS, "national", "commercial",
 [("accommodation",0.7),("control",0.6),("safety",0.5)]),
("Personal care and grooming aids", "https://www.manageathome.co.uk/collections/washing-and-personal-care", C_AIDS, "national", "commercial",
 [("personal_care",0.9),("dignity",0.7)]),
("Home adaptations", "https://www.kent.gov.uk/social-care-and-health/adult-social-care/care-and-support/live-safe-and-well-at-home/equipment-and-changes-to-your-home/home-adaptations", C_AIDS, "kent", "statutory",
 [("accommodation",0.9),("safety",0.7)]),
("Bathroom aids", "https://www.manageathome.co.uk/collections/bathroom", C_AIDS, "national", "commercial",
 [("personal_care",0.9),("safety",0.7),("dignity",0.6)]),
("Accessible toilets and changing places in Kent", "https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/accessible-toilets-and-changing-places/accessible-toilets-and-changing-places/", C_AIDS, "kent", "statutory",
 [("dignity",0.8),("social",0.6),("personal_care",0.5)]),

# ---- Guides ----
("Community Micro-Enterprise", "https://kent.connecttosupport.org/information-and-advice/home-and-community/community-micro-enterprises/community-micro-enterprises/", C_GUIDE, "kent", "statutory",
 [("control",0.6),("personal_care",0.4),("social",0.4)]),
("Personal Assistants", "https://kent.connecttosupport.org/information-and-advice/home-and-community/personal-assistants/what-is-a-personal-assistant/", C_GUIDE, "kent", "statutory",
 [("control",0.9),("personal_care",0.7),("occupation",0.5),("social",0.5)]),
("Hoarding information, advice and resources (Hoarding Support)", "https://hoarding.support/", C_GUIDE, "national", "voluntary",
 [("accommodation",0.8),("safety",0.7),("dignity",0.5)]),
("Hoarding information, advice and resources (Hoarding Disorders UK)", "https://hoardingdisordersuk.org/", C_GUIDE, "national", "voluntary",
 [("accommodation",0.8),("safety",0.7),("dignity",0.5)]),
("Falls prevention in the home", "https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/falls-prevention/", C_GUIDE, "kent", "statutory",
 [("safety",0.9)]),
("Fire safety in the home", "https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/fire-safety/", C_GUIDE, "kent", "statutory",
 [("safety",0.9)]),
("Bathroom safety in the home", "https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/bathroom-safety/", C_GUIDE, "kent", "statutory",
 [("safety",0.9),("personal_care",0.5)]),
("Kitchen safety in the home", "https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/kitchen-safety/", C_GUIDE, "kent", "statutory",
 [("safety",0.9),("food",0.5)]),
("Staircase safety in the home", "https://kent.connecttosupport.org/information-and-advice/health-and-wellbeing/preventing-accidents-at-home/staircase-safety/", C_GUIDE, "kent", "statutory",
 [("safety",0.9),("accommodation",0.5)]),

# ---- Shopping service ----
("Shopping services in Kent", "https://kent.connecttosupport.org/information-and-advice/home-and-community/homecare-and-help-around-your-home/shopping-services/", C_SHOP, "kent", "statutory",
 [("food",0.8),("control",0.6)]),

# ---- Assistance schemes ----
("Motability", "https://www.motability.co.uk/", C_ASSIST, "national", "voluntary",
 [("social",0.7),("occupation",0.6),("control",0.6)]),
("The Trussell Trust - Food Bank", "https://www.trussell.org.uk/", C_ASSIST, "national", "voluntary",
 [("food",0.9)]),
("NHS - Support with hoarding", "https://www.nhs.uk/mental-health/conditions/hoarding-disorder/", C_ASSIST, "national", "health",
 [("accommodation",0.7),("safety",0.6)]),
("Buy With Confidence - Find a business you can trust", "https://www.buywithconfidence.gov.uk/", C_ASSIST, "national", "statutory",
 [("safety",0.8),("accommodation",0.4)]),
("LEAP - Local Energy Advice Partnership", "https://applyforleap.org.uk/apply/", C_ASSIST, "national", "voluntary",
 [("accommodation",0.8)]),
("Housing Advice Options for Older People (HOOP)", "https://hoop.eac.org.uk/hooptool/", C_ASSIST, "national", "voluntary",
 [("accommodation",0.9),("control",0.6)]),
("Wheels for Wellbeing", "https://wheelsforwellbeing.org.uk", C_ASSIST, "national", "voluntary",
 [("occupation",0.7),("social",0.7)]),
("Disability Driving Instructors", "https://www.disabilitydrivinginstructors.com/", C_ASSIST, "national", "other",
 [("control",0.7),("social",0.6),("occupation",0.5)]),
("Stagecoach Journey Assistance Cards", "https://www.stagecoachbus.com/promos-and-offers/national/journey-assistance-cards", C_ASSIST, "national", "commercial",
 [("social",0.6),("occupation",0.5),("control",0.5)]),
("Travelling by train (Railcard)", "https://www.railcard.co.uk", C_ASSIST, "national", "commercial",
 [("social",0.6),("occupation",0.5)]),
("Accessible train travel", "https://www.nationalrail.co.uk/on-the-train/accessible-train-travel-and-facilities/", C_ASSIST, "national", "commercial",
 [("social",0.6),("occupation",0.5),("control",0.5)]),
("Trainline accessible travel", "https://support.thetrainline.com/hc/en-gb/articles/5186625841183-How-to-book-assistance-or-check-accessibility-for-disabled-passengers", C_ASSIST, "national", "commercial",
 [("social",0.5),("occupation",0.4)]),
("NHS Health Checks", "https://www.nhs.uk/tests-and-treatments/nhs-health-check/", C_ASSIST, "national", "health",
 [("safety",0.6)]),
("NHS Vaccinations", "https://www.nhs.uk/vaccinations/", C_ASSIST, "national", "health",
 [("safety",0.7)]),

# ---- Help, advice and guidance ----
("One You Kent", "https://www.kent.gov.uk/social-care-and-health/health/one-you-kent", C_HELP, "kent", "statutory",
 [("occupation",0.6),("safety",0.5),("food",0.5),("social",0.4)]),
("Kent Connect to Support - Community Directory", "https://kent.connecttosupport.org", C_HELP, "kent", "statutory",
 [("social",0.6),("control",0.6),("occupation",0.5)]),
("Kent Care Directory - Care Choices", "https://www.carechoices.co.uk/publication/kent-care-services-directory", C_HELP, "kent", "other",
 [("personal_care",0.6),("accommodation",0.6),("control",0.5)]),

# ---- Support services and organisations ----
("Age UK - Help at home", "https://www.ageuk.org.uk/services/in-your-area/home-help/", C_SUPP, "national", "voluntary",
 [("personal_care",0.7),("accommodation",0.5),("food",0.5)]),
("Carers UK Digital Resource for Carers", "https://www.carersuk.org/for-professionals/digital-products-and-services/digital-resource-for-carers/", C_SUPP, "national", "voluntary",
 [("control",0.6),("occupation",0.4)]),
("Jointly App - Carers Support", "https://jointlyapp.com/", C_SUPP, "national", "voluntary",
 [("control",0.6)]),
("Independent financial advice for older people", "https://www.kent.gov.uk/social-care-and-health/adult-social-care/paying-for-care/independent-financial-advice-for-older-people", C_SUPP, "kent", "statutory",
 [("control",0.8)]),
("Benefits and financial support", "https://www.kent.gov.uk/social-care-and-health/adult-social-care/paying-for-care/benefits-and-financial-support", C_SUPP, "kent", "statutory",
 [("control",0.8),("food",0.4),("accommodation",0.4)]),
("Financial calculator - estimate what you may pay for care", "https://www.kent.gov.uk/social-care-and-health/adult-social-care/paying-for-care/how-much-you-will-pay-for-care-and-support/estimate-how-much-you-may-need-to-pay-towards-your-care", C_SUPP, "kent", "statutory",
 [("control",0.7)]),
("Hoarding UK", "https://www.hoardinguk.org", C_SUPP, "national", "voluntary",
 [("accommodation",0.8),("safety",0.6),("dignity",0.5)]),
("Independent Age", "https://www.independentage.org/", C_SUPP, "national", "voluntary",
 [("control",0.7),("social",0.7),("dignity",0.5)]),
("Shelter Housing Advice", "https://england.shelter.org.uk/", C_SUPP, "national", "voluntary",
 [("accommodation",0.9)]),
("Citizens Advice Housing Advice", "https://www.citizensadvice.org.uk/housing/", C_SUPP, "national", "voluntary",
 [("accommodation",0.9),("control",0.6)]),
("Care Service Directory in Kent", "https://kent.connecttosupport.org/s4s/CustomPage/Index/176?q=", C_SUPP, "kent", "statutory",
 [("personal_care",0.6),("accommodation",0.5)]),
("Hidden Disabilities Sunflower", "https://hdsunflower.com/uk/", C_SUPP, "national", "commercial",
 [("dignity",0.8),("social",0.6)]),
("NHS Live Well", "https://www.nhs.uk/live-well/", C_SUPP, "national", "health",
 [("occupation",0.5),("food",0.5),("safety",0.4)]),
("AbilityNet - Accessibility", "https://abilitynet.org.uk/", C_SUPP, "national", "voluntary",
 [("occupation",0.7),("social",0.6),("control",0.6)]),
("Money Helper", "https://www.moneyhelper.org.uk/en", C_SUPP, "national", "statutory",
 [("control",0.8)]),
("SOLLA - Society of Later Life Advisers", "https://societyoflaterlifeadvisers.co.uk/", C_SUPP, "national", "other",
 [("control",0.8),("accommodation",0.4)]),
("Compassion in Dying", "https://compassionindying.org.uk/", C_SUPP, "national", "voluntary",
 [("control",0.9),("dignity",0.8)]),
("Find my Home Improvement Agency", "https://www.findmyhia.org.uk/", C_SUPP, "national", "voluntary",
 [("accommodation",0.9),("safety",0.6)]),
("Report Fraud", "https://www.reportfraud.police.uk/", C_SUPP, "national", "statutory",
 [("safety",0.9),("control",0.5)]),
("Dementia Friendly Communities Kent", "https://kent.connecttosupport.org/community-directory-services/dementia-friendly-communities/", C_SUPP, "kent", "voluntary",
 [("social",0.9),("dignity",0.7),("occupation",0.6)]),
("Age UK - Keeping fit", "https://www.ageuk.org.uk/services/in-your-area/exercise/", C_SUPP, "national", "voluntary",
 [("occupation",0.8),("social",0.7),("safety",0.5)]),
("Road safety (THINK)", "https://www.think.gov.uk/", C_SUPP, "national", "statutory",
 [("safety",0.7)]),
("The Silver Line Helpline", "https://www.thesilverline.org.uk/", C_SUPP, "national", "voluntary",
 [("social",0.9),("dignity",0.5)]),
("Carers Digital", "https://carersdigital.org/", C_SUPP, "national", "voluntary",
 [("control",0.6)]),
("Cruse Bereavement Support", "https://www.cruse.org.uk/", C_SUPP, "national", "voluntary",
 [("social",0.7),("dignity",0.6)]),
("MindEd for Families - older people", "https://www.mindedforfamilies.org.uk/older-people", C_SUPP, "national", "voluntary",
 [("social",0.5),("dignity",0.4)]),
("NHS - Support for veterans", "https://www.nhs.uk/nhs-services/armed-forces-community/veterans-service-leavers-non-mobilised-reservists/", C_SUPP, "national", "health",
 [("social",0.6),("control",0.5)]),
("Citizens Advice", "https://www.citizensadvice.org.uk/", C_SUPP, "national", "voluntary",
 [("control",0.8),("accommodation",0.6),("food",0.4)]),
("Deafblind UK", "https://deafblind.org.uk/", C_SUPP, "national", "voluntary",
 [("social",0.8),("dignity",0.6),("control",0.6)]),
("Alzheimer's Society - Dementia support", "https://www.alzheimers.org.uk/", C_SUPP, "national", "voluntary",
 [("social",0.7),("dignity",0.7),("control",0.6),("occupation",0.5)]),

# ---- Government support ----
("Find a job", "https://www.gov.uk/find-a-job", C_GOV, "national", "statutory",
 [("occupation",0.4)]),
("Volunteering", "https://www.gov.uk/volunteering", C_GOV, "national", "statutory",
 [("occupation",0.8),("social",0.8)]),
("Jobcentre Plus", "https://www.gov.uk/contact-jobcentre-plus", C_GOV, "national", "statutory",
 [("occupation",0.4),("control",0.4)]),
("Access to Work", "https://www.gov.uk/access-to-work", C_GOV, "national", "statutory",
 [("occupation",0.5)]),
("Benefits and financial support for carers", "https://www.gov.uk/browse/benefits/help-for-carers", C_GOV, "national", "statutory",
 [("control",0.7)]),
("Disabled facilities grants", "https://www.gov.uk/disabled-facilities-grants", C_GOV, "national", "statutory",
 [("accommodation",0.9),("safety",0.6)]),
("Warm Home Discount Scheme", "https://www.gov.uk/the-warm-home-discount-scheme", C_GOV, "national", "statutory",
 [("accommodation",0.7)]),
("Cold Weather Payment", "https://www.gov.uk/cold-weather-payment", C_GOV, "national", "statutory",
 [("accommodation",0.7)]),
("Winter Fuel Payment", "https://www.gov.uk/winter-fuel-payment/how-much-youll-get", C_GOV, "national", "statutory",
 [("accommodation",0.7)]),
("Make, register or end a lasting power of attorney", "https://www.gov.uk/power-of-attorney", C_GOV, "national", "statutory",
 [("control",0.9),("dignity",0.6)]),
("Become an appointee for someone claiming benefits", "https://www.gov.uk/become-appointee-for-someone-claiming-benefits", C_GOV, "national", "statutory",
 [("control",0.7)]),
("Deputies: make decisions for someone who lacks capacity", "https://www.gov.uk/become-deputy", C_GOV, "national", "statutory",
 [("control",0.7),("dignity",0.5)]),
("Blue Badge Scheme in Kent", "https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/blue-badge-scheme/", C_GOV, "kent", "statutory",
 [("social",0.7),("occupation",0.6),("control",0.6)]),
("Wheelchair service transport in Kent", "https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/wheelchair-service/", C_GOV, "kent", "statutory",
 [("social",0.6),("control",0.6),("occupation",0.5)]),
("Bus passes in Kent", "https://kent.connecttosupport.org/information-and-advice/getting-out-and-about/transport/travelling-by-bus/", C_GOV, "kent", "statutory",
 [("social",0.8),("occupation",0.7),("control",0.6)]),
("Disability Service Centre", "https://www.gov.uk/disability-service-centre", C_GOV, "national", "statutory",
 [("control",0.6)]),
("NHS continuing healthcare", "https://www.nhs.uk/social-care-and-support/money-work-and-benefits/nhs-continuing-healthcare/", C_GOV, "national", "health",
 [("personal_care",0.7),("control",0.6)]),

# ---- Meal support ----
("Meal delivery services in Kent", "https://kent.connecttosupport.org/information-and-advice/home-and-community/homecare-and-help-around-your-home/meal-delivery-services/", C_MEAL, "kent", "statutory",
 [("food",0.9)]),
("Meals on wheels", "https://www.gov.uk/meals-home", C_MEAL, "national", "statutory",
 [("food",0.9),("social",0.4)]),
("Oakhouse Foods", "https://www.oakhousefoods.co.uk/", C_MEAL, "national", "commercial",
 [("food",0.8)]),
("Wiltshire Farm Foods", "https://www.wiltshirefarmfoods.com/", C_MEAL, "national", "commercial",
 [("food",0.8)]),

# ---- Telecare ----
("The Technology Enhanced Lives Service", "https://kent.connecttosupport.org/information-and-advice/home-and-community/assistive-technology/the-technology-enhanced-lives-service/", C_TELE, "kent", "statutory",
 [("safety",0.9),("control",0.6)]),
("Private Pay Service (Argenti)", "https://argenti.co.uk/", C_TELE, "kent", "commercial",
 [("safety",0.8),("control",0.5)]),
("Technology enabled care in Kent", "https://kent.connecttosupport.org/information-and-advice/home-and-community/assistive-technology/sensors-alarms-and-monitors/", C_TELE, "kent", "statutory",
 [("safety",0.9),("control",0.6)]),
("Careline 365", "https://careline.co.uk/", C_TELE, "national", "commercial",
 [("safety",0.8),("control",0.5)]),
]


def q(s):
    return "'" + s.replace("'", "''") + "'"


def main():
    lines = []
    lines.append("-- Kent + Medway directory: non-geocoded advice layer.")
    lines.append("-- Source: KCC BetterCare Support signposting list, ASCOT-tagged by hand.")
    lines.append("-- Run AFTER 01_schema_resources.sql. Idempotent: safe to re-run.")
    lines.append("")
    lines.append("begin;")
    lines.append("")

    for title, url, cat, scope, ptype, domains in R:
        lines.append(
            "insert into resource (title, url, category, scope, provider_type, primary_source) values\n"
            f"  ({q(title)}, {q(url)}, {q(cat)}, {q(scope)}, {q(ptype)}, 'KCC BetterCare Support')\n"
            "on conflict (url) do update set\n"
            "  title = excluded.title, category = excluded.category,\n"
            "  scope = excluded.scope, provider_type = excluded.provider_type;"
        )
        for d, c in domains:
            lines.append(
                "insert into resource_domain (resource_id, domain, confidence, method)\n"
                f"  select id, {q(d)}, {c}, 'manual' from resource where url = {q(url)}\n"
                "on conflict (resource_id, domain) do update set confidence = excluded.confidence;"
            )
        lines.append("")

    lines.append("commit;")
    lines.append("")

    with open("02_seed_resources.sql", "w") as f:
        f.write("\n".join(lines))

    # stats
    from collections import Counter
    dc = Counter()
    for *_, domains in R:
        for d, _ in domains:
            dc[d] += 1
    sc = Counter(r[3] for r in R)
    pc = Counter(r[4] for r in R)
    print(f"resources: {len(R)}")
    print(f"scope:     {dict(sc)}")
    print(f"provider:  {dict(pc)}")
    print("domain coverage (resources tagged to each):")
    for d in ['safety','accommodation','control','food','personal_care','social','occupation','dignity']:
        print(f"  {d:<15} {dc[d]}")


if __name__ == "__main__":
    main()
