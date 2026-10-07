# منصة الخوارزمي محمد جمال - Vercel + Supabase

نسخة جاهزة للنشر على Vercel مع قاعدة بيانات Supabase.

## 1) Supabase
1. أنشئ مشروعًا في https://supabase.com
2. افتح SQL Editor.
3. الصق كل محتوى `supabase-schema.sql` وشغّله.
4. من Project Settings > API انسخ:
   - Project URL
   - anon public key
5. ضع القيم في `public/config.js`.

## 2) حساب الأدمن
أنشئ حسابًا من شاشة التسجيل باستخدام بريد محمد جمال البدري.
بعدها في Supabase SQL Editor نفّذ:

update public.profiles
set role='admin', name='محمد جمال البدري'
where email='EMAIL_HERE';

استبدل EMAIL_HERE بالبريد الحقيقي.

## 3) GitHub
ارفع الملفات الموجودة داخل هذا المجلد إلى جذر Repository، وليس ملف ZIP.
يجب أن ترى `package.json` أو `public` أو `supabase-schema.sql` مباشرة في جذر المستودع.

## 4) Vercel
Import Project > اختر Repository > Root Directory `./` > Deploy.
هذا المشروع واجهة ثابتة، فلا يحتاج Express أو أمر تشغيل.

## 5) ملاحظات
- تسجيل الطلاب يتم عبر Supabase Auth.
- الملفات PDF تُخزن في Supabase Storage.
- رفع وحذف PDF مقصور على الأدمن.
- الطلاب يرون الملفات المنشورة فقط.
