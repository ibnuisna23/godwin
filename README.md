# Godwin Store — paket awal website aggregator

## Isi paket
- `index.html`: website publik, katalog, pencarian, filter, login admin, CRUD produk/penawaran.
- `config.js`: konfigurasi URL dan public/anon key Supabase.
- `supabase/schema.sql`: database, Row Level Security (RLS), kolom harga pemilik, dan bucket Storage untuk foto/PDF.
- `supabase/functions/sync-marketplace/index.ts`: kerangka backend sinkronisasi (belum terhubung ke API marketplace).

## Status yang jujur
Paket ini adalah fondasi aplikasi yang dapat dipasang. Ini **belum** berarti domain `www.godwinstore.id` sudah dibeli/aktif, dan bukan integrasi harga live. Produk contoh adalah data demo. Harga live dan foto listing memerlukan akses API/feed resmi, izin, dan kredensial masing-masing marketplace/affiliate. Link contoh akan membuka hasil pencarian marketplace; admin dapat menggantinya dengan URL listing dan affiliate yang sah.

## A. Siapkan database Supabase
1. Buat project di https://supabase.com/dashboard
2. Buka SQL Editor, jalankan isi `supabase/schema.sql`.
3. Buka Project Settings > API, salin Project URL dan anon/publishable key.
4. Isi `config.js`. Jangan pernah masukkan `service_role` key ke browser.
5. Di Authentication > Users, buat user admin dengan email dan password kuat.
6. Salin UUID user tersebut, lalu jalankan SQL:
   `insert into public.profiles (id, role) values ('UUID_ADMIN', 'admin') on conflict (id) do update set role='admin';`
7. Atur Authentication URL Configuration: Site URL ke domain produksi, dan Redirect URLs sesuai domain hosting.

## B. Uji lokal
Buka folder ini melalui local web server (contoh `python -m http.server 8080`), lalu kunjungi `http://localhost:8080`. Jangan membuka index.html langsung dari `file://` jika browser memblokir module/network. Login admin hanya aktif setelah Supabase dikonfigurasi dan role admin dibuat.

## C. Publikasikan
Cara sederhana: deploy folder ini ke Netlify atau Cloudflare Pages. Hubungkan domain custom `www.godwinstore.id` dari dashboard hosting dan ikuti instruksi DNS yang ditampilkan provider. Domain harus didaftarkan terpisah melalui registrar .ID terakreditasi PANDI. Periksa ketersediaan domain sebelum membayar.

## D. Sinkronisasi harga dan affiliate
- Shopee memiliki Affiliate Open API Explorer: https://open-api.affiliate.shopee.co.id/explorer/v2
- Gunakan API/feed resmi sesuai akun/approval dan ketentuan program.
- Jangan melakukan scraping halaman marketplace atau mengambil foto/harga tanpa izin.
- Kredensial API hanya disimpan di server/secret manager, bukan `config.js`.
- Buat adapter per marketplace di Edge Function/worker, normalisasi produk, update `offers.price`, `offers.product_url`, `offers.affiliate_url`, dan `offers.last_checked_at`.
- Implementasikan rate limit, retry/backoff, pencatatan kegagalan, dan aturan marketplace.
- Tokopedia dan Bukalapak: integrasi hanya jika program/API/feed yang sesuai tersedia untuk akun Anda. Jangan mengasumsikan akses publik.

## F. Harga manual, upload foto, dan PDF
- Pemilik dapat mengisi `Harga Godwin Store (Rp)` untuk menetapkan harga jual/tampilan sendiri. Harga penawaran marketplace tetap dapat diatur per baris pada bagian penawaran.
- Admin dapat mengunggah foto JPG/PNG/WebP langsung dari dashboard.
- Admin juga dapat mengunggah PDF. File PDF disimpan di Supabase Storage; sistem membuat pratinjau JPG dari halaman pertama PDF untuk gambar produk, dan menampilkan tautan untuk membuka PDF penuh.
- Setelah perubahan ini, jalankan ulang seluruh `supabase/schema.sql` di SQL Editor. Script memakai `IF NOT EXISTS` dan kebijakan yang dapat dibuat ulang.
- Pastikan bucket `product-media` tersedia dan kebijakan Storage dari SQL aktif. Batas unggah default 15 MB per file.
- Setiap penawaran marketplace menerima URL produk dan URL affiliate opsional dengan format: `Shopee | 2500000 | https://... | https://...`. Pemilik bisa mengganti harga dan URL tersebut kapan saja dari dashboard.

## E. Sebelum go-live
- Ganti semua foto contoh dengan foto yang Anda miliki atau yang boleh digunakan dari feed resmi.
- Ganti penawaran demo dengan listing nyata dan URL affiliate yang sah.
- Tambahkan halaman Kebijakan Privasi, Syarat & Ketentuan, kontak, disclaimer affiliate, dan prosedur pelaporan listing.
- Aktifkan HTTPS, backup database, email auth, proteksi spam, dan monitoring.
- Uji RLS dengan akun publik, customer, dan admin.
