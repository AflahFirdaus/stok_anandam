# Pengecekan Implementasi API di Frontend

Daftar semua API yang ada di `api_client` dan status implementasinya di frontend (lib/features).

---

## 1. AuthControllerApi

| Endpoint | Method | Implementasi | Lokasi |
|----------|--------|--------------|--------|
| `/api/v1/auth/login` | POST | ✅ Ya | `lib/features/auth/bloc/auth_bloc.dart` — `authApi.login()` |
| `/api/v1/auth/refresh` | POST | ❌ Tidak | **refreshToken** belum dipakai (bisa dipakai untuk perpanjang sesi) |

---

## 2. CanvasingControllerApi

| Endpoint | Method | Implementasi | Lokasi |
|----------|--------|--------------|--------|
| `/api/v1/canvasing` (getAllCanvasing) | GET | ✅ Ya | `lib/features/canvas/data/canvas_repository.dart` — list Canvas; `lib/features/data_canvas/data_canvas_page.dart` — dropdown instansi (getAllCanvasing) |

---

## 3. DashboardControllerApi

| Endpoint | Method | Implementasi | Lokasi |
|----------|--------|--------------|--------|
| `/api/v1/dashboard/summary` (getSummary) | GET | ✅ Ya | `lib/features/dashboard/dashboard_page.dart` — ringkasan penjualan, pembelian, canvasing, stok rendah, TKDN |

---

## 4. DataCanvasingControllerApi

| Endpoint | Method | Implementasi | Lokasi |
|----------|--------|--------------|--------|
| `/api/v1/data-canvasing` (getAll) | GET | ✅ Ya | `lib/features/data_canvas/data_canvas_page.dart` — list Data Canvas + filter |
| `/api/v1/data-canvasing` (create) | POST | ✅ Ya | `lib/features/data_canvas/data_canvas_page.dart` — form "Tambah Data Canvas" |

---

## 5. MigrationControllerApi

| Endpoint | Method | Implementasi | Lokasi |
|----------|--------|--------------|--------|
| `/api/v1/migration/canvasing` | POST | ✅ Ya | `lib/features/dashboard/dashboard_page.dart` — dialog Sync Migrasi |
| `/api/v1/migration/purchase` | POST | ✅ Ya | Idem |
| `/api/v1/migration/sales` | POST | ✅ Ya | Idem |
| `/api/v1/migration/stock` | POST | ✅ Ya | Idem |
| `/api/v1/migration/tkdn` | POST | ✅ Ya | Idem |

---

## 6. PurchaseControllerApi

| Endpoint | Method | Implementasi | Lokasi |
|----------|--------|--------------|--------|
| `/api/v1/purchases` (getPurchases) | GET | ✅ Ya | `lib/features/purchase/purchase_page.dart` — list pembelian + filter |

---

## 7. SalesControllerApi

| Endpoint | Method | Implementasi | Lokasi |
|----------|--------|--------------|--------|
| `/api/v1/sales` (getAllSales) | GET | ✅ Ya | `lib/features/sales/sales_page.dart` — list penjualan + filter |

---

## 8. StockControllerApi

| Endpoint | Method | Implementasi | Lokasi |
|----------|--------|--------------|--------|
| `/api/v1/stock` (getAllStocks) | GET | ⚠️ Sebagian | List stok di `lib/features/stock/stock_page.dart` memakai **dio.get('/api/v1/stock', ...)** langsung (bukan `StockControllerApi.getAllStocks()`), dengan query tambahan `kategoriItemcode`. Perilaku sama endpoint, hanya belum lewat API class. |
| `/api/v1/stock/{id}` (getStockDetail) | GET | ✅ Ya | `lib/features/stock/stock_page.dart` — _openDetail() → `api.getStockDetail(id: id)` |
| `/api/v1/stocks` (getAllStocks1) | GET | ❌ Tidak | Endpoint alternatif, tidak dipakai di frontend. |
| `/api/v1/stocks/{id}` (getStockDetail1) | GET | ❌ Tidak | Endpoint alternatif, tidak dipakai. |

---

## 9. TkdnControllerApi

| Endpoint | Method | Implementasi | Lokasi |
|----------|--------|--------------|--------|
| `/api/v1/tkdn` (getAllTkdn) | GET | ✅ Ya | `lib/features/tkdn/tkdn_page.dart` — list TKDN + filter |
| `/api/v1/tkdn/{id}` (getTkdnDetail) | GET | ✅ Ya | `lib/features/tkdn/tkdn_page.dart` — detail item (dialog/sheet) |

---

## 10. UserControllerApi

| Endpoint | Method | Implementasi | Lokasi |
|----------|--------|--------------|--------|
| `/api/v1/users` (getAllUsers) | GET | ❌ Tidak | Tidak ada halaman manajemen user. |
| `/api/v1/users` (createUser) | POST | ❌ Tidak | Idem. |
| `/api/v1/users/{id}` (updateUser) | PUT | ❌ Tidak | Idem. |
| `/api/v1/users/{id}` (deleteUser) | DELETE | ❌ Tidak | Idem. |

**Catatan:** `UserControllerApi` terdaftar di `injection.dart` tapi tidak dipanggil di fitur manajemen user karena fitur tersebut belum ada.

---

## Ringkasan

| Kategori | Jumlah |
|----------|--------|
| ✅ Sudah diimplementasikan | Mayoritas endpoint (login, dashboard, canvas, data canvas, migration, purchase, sales, stock detail, tkdn list & detail) |
| ⚠️ Sebagian / tidak lewat API class | 1 — list stok pakai Dio langsung |
| ❌ Belum diimplementasikan | Auth: **refreshToken**; Stock: **getAllStocks1**, **getStockDetail1** (alternatif); **UserControllerApi** seluruhnya (getAllUsers, createUser, updateUser, deleteUser) — karena belum ada fitur manajemen user. |

---

## Rekomendasi

1. **Auth – refreshToken**  
   Tambah pemanggilan `refreshToken` (mis. di interceptor Dio) saat token kedaluwarsa (401) agar sesi bisa diperpanjang tanpa login ulang.

2. **Stock – list**  
   Agar konsisten dan mudah dirawat, ganti `dio.get('/api/v1/stock', ...)` di `stock_page.dart` dengan `StockControllerApi.getAllStocks(...)`. Jika butuh filter `kategoriItemcode`, cek dulu apakah API client sudah mendukung parameter tersebut; bila belum, tambahkan ke definisi API/OpenAPI lalu generate ulang client.

3. **UserControllerApi**  
   Jika produk membutuhkan manajemen user (list, tambah, edit, hapus), buat halaman/fitur baru dan panggil `getAllUsers`, `createUser`, `updateUser`, `deleteUser` dari `UserControllerApi` yang sudah di-inject.

4. **getAllStocks1 / getStockDetail1**  
   Jika backend hanya menyediakan satu set endpoint (mis. hanya `/api/v1/stock` dan `/api/v1/stock/{id}`), endpoint alternatif ini bisa diabaikan di frontend.
