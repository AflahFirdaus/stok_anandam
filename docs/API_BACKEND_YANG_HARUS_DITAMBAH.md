# Prompt: API Backend yang Seharusnya Ada (Saat Ini Logic di Frontend)

Gunakan dokumen ini sebagai **brief untuk tim backend** atau **spesifikasi** untuk menambah/mengubah API agar logic yang saat ini dijalankan di frontend bisa dipindah ke backend. Dengan begitu performa, konsistensi, dan keamanan data lebih baik.

---

## Konteks

Aplikasi Flutter (Stok Anandam) saat ini melakukan beberapa **filtering, pengambilan data massal, dan pengumpulan opsi dropdown** di sisi **frontend** karena API yang ada belum mendukung parameter atau endpoint yang dibutuhkan. Akibatnya:

- Banyak request (loop pagination) hanya untuk mengisi satu dropdown atau satu filter.
- Data besar (ribuan record) di-load lalu di-filter di client → lambat dan boros bandwidth.
- Logic bisnis (filter spesifikasi, agregasi) ada di frontend → seharusnya di backend.

Diharapkan backend menambah atau mengubah API berikut.

---

## 1. TKDN – Filter berdasarkan spesifikasi (Processor, RAM, SSD, HDD, VGA, Layar, OS)

**Situasi saat ini (frontend):**
- Endpoint `GET /api/v1/tkdn` hanya punya parameter: `page`, `size`, `sortBy`, `direction`, `isTkdn`, `kategori`, `search`.
- Tidak ada parameter filter per kolom spesifikasi (processor, ram, ssd, hdd, vga, layar, os).
- Frontend terpaksa memuat banyak halaman (sampai 50 halaman × 200 item) lalu memfilter di client dengan logic: tiap kolom spesifikasi AND (contains, case-insensitive).

**Yang diminta ke backend:**
- Tambahkan query parameter (opsional) pada `GET /api/v1/tkdn` untuk filter spesifikasi, misalnya:
  - `processor` (string, filter: kolom processor contains value)
  - `ram` (string)
  - `ssd` (string)
  - `hdd` (string)
  - `vga` (string)
  - `layar` (string)
  - `os` (string)
- Filter bersifat AND: jika beberapa param diisi, hanya baris yang memenuhi **semua** kriteria yang dikembalikan.
- Pencocokan: contains (substring), case-insensitive.
- Response tetap paginated (`page`, `size`) dengan `totalElements` dan `totalPages` yang sudah dihitung setelah filter.

**Contoh request yang diinginkan:**
```
GET /api/v1/tkdn?page=0&size=20&sortBy=nama&direction=asc&processor=i5&ram=16&ssd=256
```

---

## 2. TKDN – Daftar nilai unik untuk filter “Kategori”

**Situasi saat ini (frontend):**
- Untuk mengisi dropdown “Kategori” di halaman TKDN, frontend memanggil `GET /api/v1/tkdn` berulang untuk **semua halaman** (loop sampai `page < totalPages`) hanya untuk mengumpulkan nilai unik dari field `kategori`.

**Yang diminta ke backend:**
- Endpoint baru (atau alternatif) yang mengembalikan **daftar nilai unik** untuk filter, tanpa mengirim semua data TKDN. Contoh:
  - `GET /api/v1/tkdn/filter-options`  
    Response: `{ "kategori": ["Kategori A", "Kategori B", ...] }`
  - Atau: `GET /api/v1/tkdn/categories`  
    Response: list string kategori yang unik, terurut.

- Frontend cukup satu request untuk isi dropdown kategori, tanpa pagination loop.

---

## 3. Penjualan (Sales) – Daftar kode karyawan untuk dropdown filter

**Situasi saat ini (frontend):**
- Untuk dropdown filter “Kode Karyawan” di halaman Penjualan, frontend memanggil `GET /api/v1/sales` dengan `page=0`, `size=1000` hanya untuk mengekstrak nilai unik dari field `empCode` di setiap item.

**Yang diminta ke backend:**
- Endpoint baru yang mengembalikan daftar kode karyawan (emp code) yang bisa dipakai di filter. Contoh:
  - `GET /api/v1/sales/employee-codes`  
    Response: `["EMP001", "EMP002", ...]` atau `{ "codes": ["EMP001", ...] }`
- Boleh dari tabel sales (distinct emp_code) atau dari master karyawan, sesuai arsitektur backend.

---

## 4. Canvas – Daftar instansi untuk dropdown “Tambah Data Canvas”

**Situasi saat ini (frontend):**
- Endpoint `GET /api/v1/canvasing` sudah punya parameter `search` dan dipakai saat user mengetik (pencarian server-side sudah dipakai).
- Di sisi buka form: frontend memuat 5 halaman pertama (1.000 item) untuk isi dropdown awal, lalu filter teks (contains) di client.

**Yang diminta ke backend (opsional, untuk optimasi):**
- Tetap pertahankan parameter `search` pada `GET /api/v1/canvasing` (sudah sesuai).
- Opsional: endpoint ringan khusus autocomplete, misalnya:
  - `GET /api/v1/canvasing/options?search=...&limit=50`  
    Response hanya id + nama instansi (minimal payload) untuk dropdown/autocomplete.
- Dengan ini frontend tidak perlu load 5 halaman penuh hanya untuk inisialisasi dropdown.

---

## Ringkasan tabel

| No | Fitur / Halaman | Yang dilakukan frontend saat ini | Yang diharapkan dari API |
|----|----------------------------------|-----------------------------------|---------------------------|
| 1  | TKDN – filter spesifikasi        | Load banyak halaman, filter 7 kolom di client | Param query processor, ram, ssd, hdd, vga, layar, os di GET /tkdn; filter + pagination di backend |
| 2  | TKDN – opsi kategori             | Load semua halaman hanya untuk ambil distinct kategori | GET /tkdn/categories atau /tkdn/filter-options (daftar kategori) |
| 3  | Penjualan – opsi kode karyawan   | Load 1000 sales hanya untuk ambil distinct empCode | GET /sales/employee-codes (daftar kode karyawan) |
| 4  | Canvas – dropdown instansi       | Load 5 halaman + filter di client; search sudah ke API | Pertahankan search; opsional: endpoint options ringan (id + nama) |

---

## Catatan

- Semua endpoint di atas sebaiknya mengikuti pola auth yang sama dengan API yang ada (mis. bearer token).
- Untuk filter TKDN spesifikasi: jika backend sudah support, frontend akan diubah untuk memakai parameter tersebut dan menghapus logic load massal + filter di client.
- Dokumen ini bisa diberikan ke developer backend sebagai **spesifikasi** atau **prompt** untuk implementasi.
