-- منصة الخوارزمي محمد جمال
-- شغّل الملف بالكامل من Supabase SQL Editor بعد إنشاء مشروعك.

create extension if not exists "pgcrypto";

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text not null,
  email text,
  grade text default 'الثانية الثانوية باكالوريا',
  role text not null default 'student' check (role in ('student','admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.lessons (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  unit text,
  grade text,
  duration text,
  video_url text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.exams (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  unit text,
  grade text,
  questions int default 0,
  duration int default 0,
  published boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table if not exists public.pdfs (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  type text not null default 'واجب',
  grade text,
  unit text,
  description text,
  url text not null,
  storage_path text,
  published boolean not null default false,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

-- إنشاء profile تلقائيًا عند تسجيل طالب جديد.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id,name,email,grade)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email,'@',1)),
    new.email,
    coalesce(new.raw_user_meta_data->>'grade','الثانية الثانوية باكالوريا')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

alter table public.profiles enable row level security;
alter table public.lessons enable row level security;
alter table public.exams enable row level security;
alter table public.pdfs enable row level security;

-- Helper: هل المستخدم الحالي أدمن؟
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists(select 1 from public.profiles where id = auth.uid() and role='admin');
$$;

-- Profiles
create policy "profiles_select_own" on public.profiles for select to authenticated using (id=auth.uid() or public.is_admin());
create policy "profiles_update_own" on public.profiles for update to authenticated using (id=auth.uid()) with check (id=auth.uid());

-- Lessons
create policy "lessons_select_auth" on public.lessons for select to authenticated using (true);
create policy "lessons_admin_insert" on public.lessons for insert to authenticated with check (public.is_admin());
create policy "lessons_admin_update" on public.lessons for update to authenticated using (public.is_admin()) with check (public.is_admin());
create policy "lessons_admin_delete" on public.lessons for delete to authenticated using (public.is_admin());

-- Exams
create policy "exams_select_auth" on public.exams for select to authenticated using (published=true or public.is_admin());
create policy "exams_admin_all" on public.exams for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- PDFs
create policy "pdfs_select_auth" on public.pdfs for select to authenticated using (published=true or public.is_admin());
create policy "pdfs_admin_all" on public.pdfs for all to authenticated using (public.is_admin()) with check (public.is_admin());

-- Storage bucket: ملفات PDF عامة للعرض، لكن الرفع والحذف للأدمن فقط.
insert into storage.buckets (id,name,public)
values ('pdfs','pdfs',true)
on conflict (id) do update set public=true;

create policy "pdfs_storage_public_read" on storage.objects for select using (bucket_id='pdfs');
create policy "pdfs_storage_admin_insert" on storage.objects for insert to authenticated with check (bucket_id='pdfs' and public.is_admin());
create policy "pdfs_storage_admin_update" on storage.objects for update to authenticated using (bucket_id='pdfs' and public.is_admin()) with check (bucket_id='pdfs' and public.is_admin());
create policy "pdfs_storage_admin_delete" on storage.objects for delete to authenticated using (bucket_id='pdfs' and public.is_admin());

-- بعد إنشاء حساب محمد جمال البدري من واجهة التسجيل، نفّذ هذا السطر بعد وضع بريده الحقيقي:
-- update public.profiles set role='admin', name='محمد جمال البدري' where email='EMAIL_HERE';
