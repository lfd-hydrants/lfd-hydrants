-- ============================================================
-- SAMPLE DATA — for testing only. Delete/replace once real CSVs are loaded.
-- Run this AFTER 001_schema.sql
-- ============================================================

insert into companies (name) values ('Engine 1'), ('Engine 4'), ('Ladder 2');

insert into divisions (name) values ('Group 1'), ('Group 2'), ('Group 3'), ('Group 4');

insert into members (name, company_id, is_admin)
select 'Chief Test', id, true from companies where name = 'Engine 1'
union all
select 'FF Sample A', id, false from companies where name = 'Engine 1'
union all
select 'FF Sample B', id, false from companies where name = 'Engine 4'
union all
select 'FF Sample C', id, false from companies where name = 'Ladder 2';

insert into hydrants (hydrant_number, address, company_id, retest_interval_months)
select 'H-101', '10 Main St', id, 12 from companies where name = 'Engine 1'
union all
select 'H-102', '25 Main St', id, 12 from companies where name = 'Engine 1'
union all
select 'H-203', '4 Broad St', id, 12 from companies where name = 'Engine 4'
union all
select 'H-310', '88 Western Ave', id, 12 from companies where name = 'Ladder 2';
