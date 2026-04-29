-- Normalize reports.status and maintain lifecycle timestamps at the database layer.
-- Safe to run multiple times.

alter table public.reports
  add column if not exists ai_triaged_at timestamptz,
  add column if not exists review_started_at timestamptz,
  add column if not exists resolved_at timestamptz,
  add column if not exists closed_at timestamptz;

create or replace function public.normalize_report_status_and_timestamps()
returns trigger
language plpgsql
as $$
declare
  compact_status text;
begin
  compact_status := regexp_replace(upper(trim(coalesce(new.status, ''))), '[\s_-]+', '', 'g');

  if compact_status in ('PENDING', 'SUBMITTED', 'NEW', 'OPEN', 'QUEUED') then
    new.status := 'PENDING';
  elsif compact_status in ('INREVIEW', 'REVIEWING', 'UNDERREVIEW', 'TRIAGED') then
    new.status := 'IN REVIEW';
  elsif compact_status in ('RESOLVED', 'DONE', 'SUCCESS', 'COMPLETED') then
    new.status := 'RESOLVED';
  elsif compact_status in ('CLOSED', 'CLOSE', 'REJECTED', 'SPAM') then
    new.status := 'CLOSED';
  else
    new.status := 'PENDING';
  end if;

  if new.ai_triaged_at is null then
    new.ai_triaged_at := now();
  end if;

  if new.status in ('IN REVIEW', 'RESOLVED', 'CLOSED') and new.review_started_at is null then
    new.review_started_at := now();
  end if;

  if new.status = 'RESOLVED' and new.resolved_at is null then
    new.resolved_at := now();
  end if;

  if new.status = 'CLOSED' and new.closed_at is null then
    new.closed_at := now();
  end if;

  return new;
end;
$$;

drop trigger if exists reports_normalize_status_and_timestamps on public.reports;

create trigger reports_normalize_status_and_timestamps
before insert or update of status on public.reports
for each row
execute function public.normalize_report_status_and_timestamps();
