# Rekomendasi Frontend Level Enterprise — Stok Anandam

Dokumen ini berisi rekomendasi khusus **frontend (Flutter)** agar aplikasi siap skala enterprise. Backend dan DevOps tidak dibahas di sini.

---

## 1. Design System & Theming

**Kondisi saat ini:** Satu `ThemeData` di `main.dart`, warna/hardcoded di banyak widget (`Colors.grey.shade200`, `Colors.blueAccent`, dll).

**Rekomendasi:**

- **Pusatkan tema** di satu tempat, mis. `lib/core/theme/app_theme.dart`:
  - `AppTheme.light` dan `AppTheme.dark`
  - Semantic tokens: `colorScheme.primary`, `colorScheme.error`, `colorScheme.surface`, dll.
  - Typography: `textTheme.titleLarge`, `bodyMedium`, dll. — pakai di seluruh app, jangan `fontSize: 13` langsung.
- **Design tokens:** spacing (8, 12, 16, 24), radius (8, 12, 16), elevation — pakai konstanta (mis. `AppSpacing.md`, `AppRadius.card`).
- **Dark mode:** dukung `ThemeMode.system` / `ThemeMode.dark` dan simpan preferensi user (SharedPreferences).
- **Consistency:** Hindari `Colors.xxx` di widget; pakai `Theme.of(context).colorScheme` dan `textTheme`.

Ini mengurangi duplikasi dan memudahkan rebranding / white-label.

---

## 2. Error Handling & User Feedback

**Kondisi saat ini:** Error ditampilkan inline (teks di halaman), SnackBar/ShowDialog dipakai ad-hoc, pesan kadang teknis (exception string).

**Rekomendasi:**

- **Pusatkan pesan error:** mapping kode/status (401, 403, 409, 500, timeout) ke pesan user-friendly di satu tempat (mis. `lib/core/errors/app_errors.dart`). Jangan tampilkan stack trace ke user.
- **Feedback konsisten:**
  - **SnackBar** untuk feedback singkat (sukses simpan, “Data disimpan”).
  - **Banner / inline error** di atas konten untuk error yang butuh perhatian (mis. “Sesi habis, silakan login lagi”).
  - **Dialog** hanya untuk konfirmasi atau error yang memblokir (session expired, conflict).
- **Global error handler:** Zone / `FlutterError.onError` + (opsional) kirim ke layanan monitoring; di UI tampilkan pesan umum (“Terjadi kesalahan. Coba lagi.”) + tombol retry jika relevan.
- **Loading & empty state:** pastikan tiap list punya state: loading, error (dengan retry), empty (ilustrasi + CTA), dan success. Hindari hanya “Gagal: $e”.

Ini membuat perilaku error dan feedback seragam di seluruh fitur.

---

## 3. Internationalization (i18n)

**Kondisi saat ini:** Teks dalam bahasa Indonesia hardcoded di widget.

**Rekomendasi:**

- Pakai **flutter_localizations** + **intl** (atau **easy_localization** / **flutter_gen**).
- Ekstrak semua string ke file ARB (mis. `lib/l10n/app_id.arb`, `app_en.arb`).
- Akses teks lewat `AppLocalizations.of(context)!.someKey`, jangan string literal di UI.
- Siapkan sejak awal meski awalnya hanya satu bahasa; menambah bahasa nanti jadi lebih murah.

Ini memudahkan ekspansi ke bahasa lain dan audit konten.

---

## 4. Accessibility (A11y)

**Kondisi saat ini:** Belum terlihat fokus ke semantic labels dan kontras.

**Rekomendasi:**

- **Semantic labels:** `Semantics(label: '...', button: true)` untuk tombol/icon penting (refresh, logout, menu).
- **TalkBack / VoiceOver:** pastikan urutan fokus logis (sidebar → konten → pagination).
- **Kontras:** pastikan teks memenuhi rasio kontras (WCAG AA) terhadap background; pakai `colorScheme.onSurface`, `onPrimary`, dll.
- **Touch target:** minimal ~48dp untuk tombol/icon; pakai `Material` / `InkWell` dengan padding cukup.
- **Font scaling:** hindari ukuran font absolut; pakai `textTheme` yang mengikuti `MediaQuery.textScalerOf(context)`.

Ini penting untuk compliance dan pengguna dengan kebutuhan aksesibilitas.

---

## 5. State Management & Data Layer

**Kondisi saat ini:** Bloc untuk auth; list pages pakai setState + pemanggilan API langsung di widget.

**Rekomendasi:**

- **Konsisten pakai Bloc/Cubit (atau Provider/Riverpod)** untuk fitur yang punya state kompleks (list + filter + pagination, form multi-step). Hindari setState + API call besar di satu widget.
- **Pisah lapisan:**
  - **Repository:** satu entry point per domain (mis. `StockRepository` yang pakai `StockControllerApi` + cache/retry).
  - **Bloc/Cubit:** hanya orchestration + mapping ke UI state; tidak import Dio/API detail.
- **Satu arah data:** Event → Bloc → State → UI. Error dan loading jadi bagian state, bukan side effect ad-hoc.
- **Refresh token:** tangani di satu tempat (interceptor Dio); Bloc hanya terima “session expired” dan emit state redirect ke login.

Ini membuat fitur baru lebih mudah ditambah dan di-test.

---

## 6. Routing & Deep Linking

**Kondisi saat ini:** `onGenerateRoute` manual dengan switch-case; route name string tersebar.

**Rekomendasi:**

- **Route sentral:** definisi route (path, name, guard) di satu modul (mis. `lib/core/routing/app_router.dart`). Pakai named route atau package seperti **go_router**.
- **Deep link:** dukung scheme (mis. `stokanandam://stok/123`) dan web path (`/stok`, `/penjualan`) lewat konfigurasi router; berguna untuk notifikasi, email, dan bookmark.
- **Auth guard:** redirect ke login untuk route yang butuh auth, dan redirect ke dashboard setelah login sukses — di router, bukan di tiap page.

Ini memudahkan maintenance dan integrasi dengan sistem enterprise (SSO, link dari email).

---

## 7. Performance

**Rekomendasi:**

- **List besar:** pakai `ListView.builder` / `ListView.separated` (sudah dipakai); hindari `ListView(children: list.map(...).toList())` untuk data besar.
- **Tabel besar:** pertimbangkan virtualisasi (scroll view dengan hanya baris terlihat di-render) atau pagination server-side (sudah ada) — jangan load ribuan baris sekaligus.
- **Gambar:** jika nanti ada gambar, pakai caching (cached_network_image) dan placeholder; lazy load di list.
- **Build cost:** pecah widget besar jadi widget kecil dengan `const` di mana mungkin; hindari rebuild seluruh tree saat hanya satu field berubah.
- **Analisis:** pakai DevTools (Performance, CPU) dan `flutter build web --profile` untuk cek jank dan ukuran bundle.

Ini menjaga UX tetap baik saat data dan pengguna bertambah.

---

## 8. Testing (Frontend)

**Kondisi saat ini:** Ada test di `api_client`; widget/app test masih minimal.

**Rekomendasi:**

- **Unit test:** untuk Bloc/Cubit (event → state), repository (mock API), dan helper/validator.
- **Widget test:** untuk komponen kunci: form login, filter bar, card summary, tabel (satu baris + header).
- **Integration test:** untuk flow kritis: login → dashboard, buka list → filter → pagination. Gunakan mock server atau stub API.
- **Golden test (opsional):** untuk komponen design system (button, card, input) agar perubahan layout terdeteksi.

Prioritas: unit test Bloc + repository, lalu widget test untuk form dan list.

---

## 9. Keamanan (Frontend)

**Rekomendasi:**

- **Token:** simpan di tempat aman (flutter_secure_storage untuk mobile; untuk web pertimbangkan httpOnly cookie dari backend).
- **Sensitive input:** pastikan layar login tidak tercatat di screenshot/recording jika kebijakan enterprise ketat (mis. `android:windowSecureFlags`).
- **Certificate pinning (opsional):** untuk lingkungan enterprise yang wajib pinning; konfigurasi di Dio.
- **Log:** jangan log token atau data sensitif; di production matikan `LogInterceptor` atau set level ke warning/error saja.

Ini memenuhi ekspektasi keamanan standar enterprise.

---

## 10. Code Quality & Konsistensi

**Rekomendasi:**

- **Struktur folder:** pertahankan feature-first (`features/canvas`, `features/stock`); dalam tiap feature: `bloc/`, `widgets/`, `screens/`, `models/` (jika domain-specific).
- **Shared UI:** komponen yang dipakai banyak fitur (tombol, card, input, tabel wrapper, empty state) pindah ke `lib/core/widgets/` atau `lib/shared/`; gunakan design tokens dari tema.
- **Konstanta:** breakpoint (720, 640), string magic number, dan default pagination size — taruh di satu file (mis. `lib/core/constants/app_constants.dart`).
- **Lint:** aktifkan aturan ketat (avoid_dynamic, prefer_const, strict types); sesekali jalankan `dart fix --apply` dan perbaiki warning.

Ini memudahkan onboarding dan refactor jangka panjang.

---

## 11. Offline & Resiliency

**Rekomendasi:**

- **Cache response (opsional):** untuk data yang boleh “agak basi” (mis. list referensi), cache di local (SQLite / Hive) dan tampilkan saat offline, dengan indikator “Data terakhir: …”.
- **Retry:** untuk request gagal (timeout, 5xx), tampilkan “Coba lagi” dan retry otomatis 1–2x dengan backoff; setelah itu tampilkan pesan error yang jelas.
- **Queue (advanced):** untuk aksi yang harus terkirim (mis. create data canvas), bisa antre di local dan sync saat online.

Ini meningkatkan keandalan di jaringan tidak stabil.

---

## 12. Analytics & Monitoring (Frontend)

**Rekomendasi:**

- **Event penting:** login (sukses/gagal), buka halaman (screen view), aksi kunci (filter, export, create). Kirim ke backend atau tool analytics (Firebase, Mixpanel, atau backend sendiri).
- **Error reporting:** kirim error yang sudah “dibersihkan” (tanpa token/sensitive data) ke layanan (Sentry, Crashlytics, atau endpoint backend).
- **Performance:** laporkan metrik seperti “time to first screen”, “time to list loaded” (opsional) untuk prioritas perbaikan.

Ini mendukung keputusan produk dan support level enterprise.

---

## Prioritas Implementasi (Saran)

| Prioritas | Area              | Usaha | Dampak |
|----------|-------------------|--------|--------|
| 1        | Design system     | Medium | Tinggi (konsistensi, maintainability) |
| 2        | Error handling    | Kecil–sedang | Tinggi (UX, kepercayaan) |
| 3        | State management  | Sedang | Tinggi (skalabilitas fitur) |
| 4        | Routing (go_router) | Kecil | Sedang (deep link, guard) |
| 5        | i18n              | Sedang | Sedang (ekspansi pasar) |
| 6        | Testing           | Tinggi | Tinggi (refactor aman) |
| 7        | Accessibility     | Sedang | Sedang (compliance) |
| 8        | Token storage     | Kecil  | Tinggi (keamanan) |

Fokus awal yang paling berdampak: **design system + error handling + konsistensi state management**; lalu routing dan testing; kemudian i18n dan a11y.

---

*Dokumen ini bisa diperbarui seiring perubahan arsitektur dan kebijakan perusahaan.*
