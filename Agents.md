# AGENTS.md — Standar Operasional Teknis & Pedoman Sistem: Mountify

> **Status Dokumen**: Mandatory (Wajib Dipatuhi Tanpa Pengecualian)  
> **Target Proyek**: Mountify (Android Native App & Modul Root Magisk/KernelSU/APatch)  
> **Package ID**: `app.mountify`  
> **Author & Maintainer**: Noir ([@Zy0x](https://github.com/Zy0x))  
> **Repositori**: [https://github.com/Zy0x/Mountify](https://github.com/Zy0x/Mountify)  

Dokumen ini berfungsi sebagai spesifikasi teknis tunggal, standar arsitektur sistem, pedoman keselamatan operasi root, aturan antarmuka grafis, serta Product Requirements Document (PRD) yang mengikat seluruh agen pengembangan dan kontributor repositori Mountify.

---

## DAFTAR ISI
1. [Identitas & Filosofi Proyek](#1-identitas--filosofi-proyek)
2. [Product Requirements Document (PRD)](#2-product-requirements-document-prd)
3. [Standar Responsivitas Tampilan & Mobile-First](#3-standar-responsivitas-tampilan--mobile-first)
4. [Protokol Keamanan Tingkat Tinggi & Operasi Root](#4-protokol-keamanan-tingkat-tinggi--operasi-root)
5. [Standar Arsitektur Kode & Disiplin Tech Stack](#5-standar-arsitektur-kode--disiplin-tech-stack)
6. [Standar Modul Magisk / KernelSU / APatch](#6-standar-modul-magisk--kernelsu--apatch)
7. [Standar Lokalisasi & Aksesibilitas](#7-standar-lokalisasi--aksesibilitas)
8. [Protokol Git, Commit, Push, dan Kebijakan Perilisan](#8-protokol-git-commit-push-dan-kebijakan-perilisan)
9. [Standar CI/CD & Keamanan Kredensial](#9-standar-cicd--keamanan-kredensial)
10. [Kebijakan Anti-AI Slop & Larangan Mutlak](#10-kebijakan-anti-ai-slop--larangan-mutlak)

---

## 1. IDENTITAS & FILOSOFI PROYEK

### 1.1 Identitas Resmi
- **Nama Aplikasi**: `Mountify`
- **Application ID / Package**: `app.mountify`
- **Nama Modul Root**: `Mountify`
- **Target OS**: Android 10 (API 29) hingga Android 15+ (API 35+)
- **Dukungan Root**: Magisk, KernelSU, APatch

### 1.2 Masalah Pokok yang Dipecahkan
Sejak Android 10, pembatasan penyimpanan sistem (Scoped Storage) mencegah pemindahan data game ke kartu MicroSD. Game berkapasitas besar (20 GB hingga 40 GB+) membebani penyimpanan internal. 

Mountify mengalihkan data game dari partisi sekunder MicroSD berformat Linux (F2FS atau Ext4) ke penyimpanan internal melalui bind-mount pada seluruh namespace runtime Android secara transparan tanpa memicu galat FUSE cross-device.

---

## 2. PRODUCT REQUIREMENTS DOCUMENT (PRD)

### 2.1 Persona Pengguna
- **Mobile Gamers**: Memiliki keterbatasan kapasitas penyimpanan internal dan menjalankan beberapa game berukuran besar.
- **Android Power Users**: Pengguna perangkat berbasis root (Magisk, KernelSU, atau APatch) yang memerlukan kontrol tingkat rendah terhadap bind-mount partisi.

### 2.2 Kebutuhan Fungsional (Functional Requirements)

| Kode | Modul Fitur | Spesifikasi Kebutuhan |
|---|---|---|
| **FR-01** | Root & Module Detector | Mendeteksi ketersediaan root dan jenis engine aktif (Magisk, KernelSU, APatch). Memverifikasi integritas direktori modul di `/data/adb/modules/Mountify`. |
| **FR-02** | Game Registry | Operasi CRUD daftar game dengan opsi mode mount (`PKG` atau `FILES`). Pencarian dan deteksi otomatis aplikasi terpasang via Android `PackageManager`. |
| **FR-03** | Dual Mount Mode | 1. **Mode PKG**: Bind-mount seluruh direktori `Android/data/<package>` (contoh: Wuthering Waves, PUBG Mobile).<br>2. **Mode FILES**: Bind-mount hanya subdirektori `/files`, menjaga basis data lokal tetap pada penyimpanan internal (contoh: Honkai: Star Rail, Genshin Impact). |
| **FR-04** | Dynamic Bind Mount Engine | Mengeksekusi bind-mount ke 7 namespace runtime Android, menetapkan hak akses Linux UID sandbox, dan menyetel context SELinux `u:object_r:media_rw_data_file:s0`. |
| **FR-05** | Physical Data Migration | Menyalin data fisik game antara penyimpanan internal (`/data/media/0/Android/data/...`) dan MicroSD (`/data/sdext2/Android/data/...`) dengan verifikasi integritas berkas sebelum pembersihan direktori asal. |
| **FR-06** | Partition & Formatter | Memindai blok partisi (`mmcblk*`, `sd*`). Menyediakan opsi pemformatan ke F2FS atau Ext4 dengan dialog konfirmasi pengamanan. |
| **FR-07** | Real-time Log Viewer | Menampilkan log aktivitas secara langsung (*live tail*) dari `/storage/emulated/0/mountify.log` dan `/data/adb/modules/Mountify/mountify.log` dengan penanda level (Info, Success, Error, Debug). |
| **FR-08** | Backup & Restore JSON | Ekspor dan impor konfigurasi daftar game dalam format JSON melalui Storage Access Framework (SAF). |
| **FR-09** | Update Checker | Pengecekan versi rilis baru secara langsung dari endpoint GitHub Releases API. |
| **FR-10** | Boot Automation | Layanan `BootReceiver` dan `MountService` Foreground Service untuk auto-mount saat booting sistem selesai. |

### 2.3 Kebutuhan Non-Fungsional (Non-Functional Requirements)
- **Kinerja**: Waktu eksekusi mount per game tidak melebihi 1.5 detik.
- **Keandalan**: Kegagalan mount pada satu game tidak boleh memutus proses mount game lainnya.
- **Integritas Data**: Nol toleransi terhadap kehilangan data pengguna (*zero data-loss tolerance*).

---

## 3. STANDAR RESPONSIVITAS TAMPILAN & MOBILE-FIRST

Seluruh komponen Jetpack Compose wajib mematuhi parameter berikut:

### 3.1 Mobile-First & Touch Targets
- **Target Sentuh Minimum**: Elemen interaktif wajib memiliki dimensi sentuh minimal **48×48 dp** (`Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)`).
- **Interaksi Sentuh**: Tidak boleh mengandalkan status hover; semua interaksi dirancang untuk sentuhan langsung, penekanan lama (long-press), atau gesture standar Android.

### 3.2 Resolusi & Rasio Layar Non-Reguler (720p hingga 4K)
- Antarmuka harus tetap presisi pada rasio layar panjang (20:9, 21:9 seperti 1080×2460, 1080×2380) maupun layar tablet dan foldable (4:3, 16:10).
- Dilarang meng-hardcode tinggi atau lebar kontainer utama dengan angka statis yang dapat menyebabkan pemotongan teks saat font scale sistem diubah pengguna.
- Gunakan `LazyColumn`, `rememberScrollState()`, atau `Modifier.weight()` agar tata letak dapat digulir saat dimensi viewport terbatas.
- Orientasi portrait dan landscape wajib diuji; dialog dan bottom-sheet harus memiliki batasan tinggi (`heightIn(max = ...)`) dan mendukung scroll internal.

### 3.3 Keterbacaan & Kontras Warna
- Teks dan elemen fungsional wajib memenuhi standar kontras WCAG AAA.
- **Dark Mode**: Latar belakang `#0F1117` dengan surface `#181B26` untuk optimalisasi konsumsi daya pada layar AMOLED.
- Kontras teks primer dijaga pada tingkat keterbacaan tinggi (`#F1F3F5` pada tema gelap / `#212529` pada tema terang). Subtitle memiliki opasitas minimal 70% (`alpha = 0.7f`).

### 3.4 Animasi Fungsional
- Durasi transisi visual berada dalam rentang **150–350 ms**.
- Animasi harus ringan dan tidak membebani GPU perangkat berspesifikasi rendah.

---

## 4. PROTOKOL KEAMANAN TINGKAT TINGGI & OPERASI ROOT

### 4.1 Proteksi Migrasi Data (Anti Data Loss)
- Sebelum direktori data asal di penyimpanan internal dibersihkan saat proses migrasi ke MicroSD, sistem wajib memvalidasi bahwa direktori tujuan di MicroSD telah terbentuk, memiliki data yang valid, dan proses penyalinan mengembalikan exit code 0 (`isSuccess`).
- Jika proses penyalinan terputus atau gagal, proses migrasi wajib dibatalkan dan direktori asal tidak boleh dihapus.

### 4.2 Sanitasi Perintah Shell
- Seluruh variabel path, blok perangkat, atau nama paket yang diteruskan ke `RootShell` wajib dibungkus dengan tanda kutip ganda (`"..."`) untuk mencegah injeksi perintah shell atau kesalahan parsing.
  ```kotlin
  RootShell.exec("mount -o bind \"$srcPath\" \"$targetPath\" 2>/dev/null")
  ```

### 4.3 Format Partisi dengan Konfirmasi Bertingkat
- Pemformatan adalah tindakan destruktif. Antarmuka wajib menampilkan dialog konfirmasi yang memuat nama blok perangkat secara eksplisit sebelum pemformatan dijalankan.
- Partisi wajib di-unmount terlebih dahulu sebelum eksekusi `mkfs`.

### 4.4 Penegakan Hak Akses & SELinux
- Berkas data game pada MicroSD wajib dikonfigurasi dengan parameter keamanan Android:
  - Hak akses Linux: `chmod -R 777`
  - Kepemilikan Linux: `chown -R <APP_UID>:1023` (GID 1023 untuk `media_rw`)
  - Konteks SELinux: `chcon -R u:object_r:media_rw_data_file:s0`

---

## 5. STANDAR ARSITEKTUR KODE & DISIPLIN TECH STACK

Mountify menerapkan arsitektur modular **Clean Architecture** dan **MVVM**:

```
app/src/main/java/app/mountify/
├── data/
│   ├── db/          # Room AppDatabase & GameDao (Single source of truth)
│   ├── model/       # Data classes, Room Entities, Enums
│   └── repository/  # GameRepository & StorageRepository
├── di/              # Hilt Modules (AppModule, DatabaseModule)
├── root/            # Engine Shell libsu (RootShell, RootDetector, MountManager, StorageManager)
├── service/         # Android Services (MountService, BootReceiver)
├── ui/              # Jetpack Compose UI Screens, ViewModels, Theme, Components
└── util/            # AppPreferences, UpdateChecker, FormatUtils
```

### 5.1 Aturan Penulisan Kotlin & Coroutines
1. **Thread Disiplin**: Seluruh eksekusi shell, I/O berkas, dan operasi basis data wajib dijalankan di dalam `withContext(Dispatchers.IO)`. Dilarang memblokir `Dispatchers.Main`.
2. **State Management**: Gunakan `StateFlow` pada ViewModel dan konsumsi di Compose menggunakan `collectAsState()`.
3. **Basis Data**: Room database adalah sumber kebenaran tunggal (*single source of truth*) status lokal.
4. **Dependency Injection**: Seluruh komponen dikelola melalui Hilt (`@Inject`, `@Singleton`, `@HiltViewModel`).
5. **Konsistensi Paket**: Package root adalah `app.mountify`.

---

## 6. STANDAR MODUL MAGISK / KERNELSU / APATCH

Struktur berkas modul root berada pada direktori `/module`:
```
module/
├── module.prop       # Metadata Modul
├── service.sh        # Skrip Eksekusi Boot-Time
├── config.conf       # Konfigurasi: SD_BASE, SD_BLOCK, FS_TYPE
└── gamelist.conf     # Konfigurasi Daftar Game
```

### 6.1 Ketentuan service.sh
1. Konfigurasi dibaca secara dinamis dari `config.conf` dan `gamelist.conf`.
2. Bind-mount diaplikasikan pada 7 namespace runtime Android:
   - `/mnt/runtime/default/emulated/0`
   - `/mnt/runtime/read/emulated/0`
   - `/mnt/runtime/write/emulated/0`
   - `/mnt/runtime/full/emulated/0`
   - `/mnt/user/0/primary`
   - `/storage/emulated/0`
   - `/data/media/0`
3. Log sistem dicatat secara simultan ke `/data/adb/modules/Mountify/mountify.log` dan `/storage/emulated/0/mountify.log`.

---

## 7. STANDAR LOKALISASI & AKSESIBILITAS

1. **Multi-bahasa**:
   - `app/src/main/res/values/strings.xml` memuat bahasa default (English).
   - `app/src/main/res/values-id/strings.xml` memuat bahasa Indonesia.
   - Penambahan string baru wajib didaftarkan pada kedua berkas dengan key yang identik. Dilarang melakukan hardcode string pada kode Compose.
2. **Aksesibilitas**: Seluruh komponen interaktif wajib memiliki `contentDescription` yang jelas untuk pembaca layar (screen reader).

---

## 8. PROTOKOL GIT, COMMIT, PUSH, DAN KEBIJAKAN PERILISAN

### 8.1 Commit & Push Otomatis
- Setiap penyelesaian tugas teknis, perbaikan bug, atau pembaruan dokumentasi wajib langsung di-commit dan di-push ke remote GitHub branch `main`.
- Format pesan commit mengikuti standar **Conventional Commits**:
  - `feat(scope): ...` untuk penambahan fungsionalitas baru.
  - `fix(scope): ...` untuk perbaikan galat.
  - `refactor(scope): ...` untuk restrukturisasi kode.
  - `docs(scope): ...` untuk pembaruan dokumentasi.
  - `chore(scope): ...` untuk pemeliharaan konfigurasi dan dependensi.

### 8.2 Versi & Changelog
- Penomoran versi menggunakan format semantik `x.x.x` (contoh: `1.0.0` s/d `1.0.99`, lalu meningkat ke `1.1.0`).
- Setiap perubahan fungsional dicatat pada [`CHANGELOG.md`](CHANGELOG.md) dan disinkronkan dengan `versionName` di [`app/build.gradle.kts`](app/build.gradle.kts).

### 8.3 Kebijakan Perilisan
- **Penahanan Tag Rilis**: Pembuatan git tag (`v*`) **DITAHAN** dan tidak dibuat pada commit rutin harian. Tagging dan pembuatan GitHub Release hanya dijalankan ketika terdapat instruksi eksplisit untuk perilisan rilis publik resmi.

---

## 9. STANDAR CI/CD & KEAMANAN KREDENSIAL

1. **Keamanan Keystore**: Berkas `.jks`, `.keystore`, `.b64`, dan `keystore.properties` dilindungi pada `.gitignore` dan dilarang masuk ke riwayat git.
2. **Kompilasi Otomatis**: GitHub Actions (`.github/workflows/build.yml`) mengompilasi APK rilis dan membungkus modul Magisk secara terotomatisasi.

---

## 10. KEBIJAKAN ANTI-AI SLOP & LARANGAN MUTLAK

Seluruh kontributor dan agen pengembangan wajib mematuhi batasan berikut:

1. **Larangan AI Slop & Teks Klise**:
   - Dilarang menyertakan kata-kata klise generator (misal: "revolutionary", "seamlessly crafted", "powerful solution", emoji berlebihan, dsb.) pada deskripsi aplikasi, commit message, maupun dokumentasi.
   - Dilarang menyertakan frasa sentimental seperti "Made with ❤️". Gunakan atribusi rekayasa perangkat lunak standar seperti "Author: Noir" atau "Developed by Noir".
2. **Pencegahan Kebocoran Prompt (Prompt Leakage Prevention)**:
   - Dilarang membocorkan atau menyalin kalimat prompt pengguna, instruksi sistem internal, atau konteks percakapan ke dalam berkas kode, komentar, dokumen, maupun commit message.
3. **Format Komentar Kode Profesional**:
   - Dilarang keras membuat komentar canggung seperti `# Script untuk...` atau `// Fungsi ini digunakan untuk...`.
   - Komentar dalam skrip dan kode program murni berfungsi sebagai:
     a. Penanda judul seksi teknis (contoh: `# ── Storage Mount ──` atau `// Section: Storage State`).
     b. Penjelasan logika non-trivial yang ringkas dan profesional.
4. **Larangan Referensi Lama**: Dilarang menggunakan nama lama proyek. Nama resmi satu-satunya adalah **Mountify**.
5. **Larangan Penghapusan Data Tanpa Verifikasi**: Dilarang menghapus berkas penyimpanan internal sebelum verifikasi salinan pada MicroSD selesai dengan valid.
6. **Larangan Blocking Thread**: Dilarang memanggil perintah shell atau I/O pada `Dispatchers.Main`.
