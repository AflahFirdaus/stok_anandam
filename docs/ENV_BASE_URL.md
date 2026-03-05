# Konfigurasi Base URL (Lokal & Server)

Aplikasi memakai **BASE_URL** untuk mengarahkan request API ke backend. Bisa diatur lewat file `.env` atau `--dart-define`.

## 1. Menggunakan file `.env` (disarankan untuk development)

Di root project sudah ada file **`.env`** dengan nilai default. Edit saja isinya:

| Lingkungan | Nilai BASE_URL |
|------------|----------------|
| **Lokal (desktop / web)** | `http://localhost:8080` |
| **Android Emulator** (backend jalan di PC host) | `http://10.0.2.2:8080` |
| **Server production** | `https://api.anandamcomputer.com` atau domain Anda |

Contoh isi `.env` untuk emulator Android:

```env
BASE_URL=http://10.0.2.2:8080
```

Simpan tanpa spasi di kiri/kanan, dan **tanpa** trailing slash. Setelah diubah, jalankan ulang aplikasi (hot restart).

## 2. Menggunakan `--dart-define` (build / production)

Untuk build tertentu tanpa mengubah `.env`:

```bash
# Emulator Android
flutter run --dart-define=BASE_URL=http://10.0.2.2:8080

# Server production
flutter run --dart-define=BASE_URL=https://api.anandamcomputer.com

# Atau saat build release
flutter build apk --dart-define=BASE_URL=https://api.anandamcomputer.com
```

**Prioritas:** `--dart-define=BASE_URL` mengalahkan nilai di `.env`. Nilai di `.env` mengalahkan default (`http://localhost:8080`).

## 3. File template

- **`.env`** – file yang dipakai aplikasi (bisa di-commit dengan default localhost, atau di-gitignore jika tiap developer punya nilai sendiri).
- **`.env.example`** – template dan contoh nilai; bisa di-copy jadi `.env` kalau `.env` tidak ada.

Setelah menambah atau mengubah `.env`, jalankan:

```bash
flutter pub get
flutter run
```
