-- STEP A. Run this first in the SQL editor. It is small.
-- Creates the staging table that you will then fill by CSV import.

drop table if exists charity_stage;

create table charity_stage (
  charity_number bigint,
  name text,
  activities text,
  address text,
  postcode text,
  phone text,
  email text,
  website text,
  income bigint
);

-- Columns the spine needs on org.
alter table org add column if not exists charity_number bigint;
alter table org add column if not exists income bigint;

create unique index if not exists org_charity_number_uidx
  on org (charity_number) where charity_number is not null;
