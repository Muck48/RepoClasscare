-- Apply in Supabase SQL Editor (project of classcare_user).
-- Goal: allow app users (anon/authenticated) to upload report images to bucket: report-images.

insert into storage.buckets (id, name, public)
values ('report-images', 'report-images', true)
on conflict (id) do update set public = true;

drop policy if exists "report_images_insert_anon" on storage.objects;
drop policy if exists "report_images_insert_authenticated" on storage.objects;
drop policy if exists "report_images_read_anon" on storage.objects;
drop policy if exists "report_images_read_authenticated" on storage.objects;

create policy "report_images_insert_anon"
on storage.objects
for insert
to anon
with check (
  bucket_id = 'report-images'
);

create policy "report_images_insert_authenticated"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'report-images'
);

create policy "report_images_read_anon"
on storage.objects
for select
to anon
using (
  bucket_id = 'report-images'
);

create policy "report_images_read_authenticated"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'report-images'
);
