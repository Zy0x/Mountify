# AGENTS.md — Standar Operasional Teknis & Pedoman Sistem: MountX

> **Status Dokumen**: Mandatory (Wajib Dipatuhi Tanpa Pengecualian)  
> **Target Proyek**: MountX (Android Native App & Modul Root Magisk/KernelSU/APatch)  
> **Package ID**: `app.mountx`  
> **Author & Maintainer**: Noir ([@Zy0x](https://github.com/Zy0x))  
> **Repositori**: [https://github.com/Zy0x/MountX](https://github.com/Zy0x/MountX)  
> **Identitas Folder / Direktori Proyek**: `MountX`

Dokumen ini berfungsi sebagai spesifikasi teknis tunggal, standar arsitektur sistem, pedoman keselamatan operasi root, aturan antarmuka grafis, serta Product Requirements Document (PRD) yang mengikat seluruh agen pengembangan dan kontributor repositori MountX.

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
11. [Protokol Screenshot & Pelaporan Hasil Testing](#11-protokol-screenshot--pelaporan-hasil-testing)

---

## 1. IDENTITAS & FILOSOFI PROYEK

### 1.1 Identitas Resmi
- **Nama Aplikasi**: `MountX` (resmi direbrand dari nama lama `Mountify` sejak v2.2.0+)
- **Application ID / Package**: `app.mountx`
- **Nama Modul Root**: `MountX` (dengan dukungan backward compatibility modul lama `Mountify`)
- **Target OS**: Android 10 (API 29) hingga Android 15+ (API 35+)
- **Dukungan Root**: Magisk, KernelSU, APatch
- **Nama Proyek & Direktori**: Nama resmi tunggal adalah **MountX** (lokasi folder proyek: `MountX`). Seluruh file konfigurasi, `settings.gradle.kts` (`rootProject.name = "MountX"`), strings, package (`app.mountx`), dan antarmuka pengguna Wajib menggunakan **MountX**. Repositori GitHub resmi adalah `Zy0x/MountX`.

### 1.2 Masalah Pokok yang Dipecahkan
Sejak Android 10, pembatasan penyimpanan sistem (Scoped Storage) mencegah pemindahan data game ke kartu MicroSD. Game berkapasitas besar (20 GB hingga 40 GB+) membebani penyimpanan internal. 

MountX mengalihkan data game dari partisi sekunder MicroSD berformat Linux (F2FS atau Ext4) ke penyimpanan internal melalui bind-mount pada seluruh namespace runtime Android secara transparan tanpa memicu galat FUSE cross-device.

---

## 2. PRODUCT REQUIREMENTS DOCUMENT (PRD)

### 2.1 Persona Pengguna
- **Mobile Gamers**: Memiliki keterbatasan kapasitas penyimpanan internal dan menjalankan beberapa game berukuran besar.
- **Android Power Users**: Pengguna perangkat berbasis root (Magisk, KernelSU, atau APatch) yang memerlukan kontrol tingkat rendah terhadap bind-mount partisi.

### 2.2 Kebutuhan Fungsional (Functional Requirements)

| Kode | Modul Fitur | Spesifikasi Kebutuhan |
|---|---|---|
| **FR-01** | Root & Module Detector | Mendeteksi ketersediaan root dan jenis engine aktif (Magisk, KernelSU, APatch). Memverifikasi integritas direktori modul di `/data/adb/modules/MountX` (dengan fallback `/data/adb/modules/Mountify`). |
| **FR-02** | Game Registry | Operasi CRUD daftar game dengan opsi mode mount (`PKG` atau `FILES`). Pencarian dan deteksi otomatis aplikasi terpasang via Android `PackageManager`. |
| **FR-03** | Dual Mount Mode | 1. **Mode PKG**: Bind-mount seluruh direktori `Android/data/<package>` (contoh: Wuthering Waves, PUBG Mobile).<br>2. **Mode FILES**: Bind-mount hanya subdirektori `/files`, menjaga basis data lokal tetap pada penyimpanan internal (contoh: Honkai: Star Rail, Genshin Impact). |
| **FR-04** | Dynamic Bind Mount Engine | Mengeksekusi bind-mount ke 7 namespace runtime Android, menetapkan hak akses Linux UID sandbox, dan menyetel context SELinux `u:object_r:media_rw_data_file:s0`. |
| **FR-05** | Physical Data Migration | Menyalin data fisik game antara penyimpanan internal (`/data/media/0/Android/data/...`) dan MicroSD (`/data/sdext2/Android/data/...`) dengan verifikasi integritas berkas sebelum pembersihan direktori asal. |
| **FR-06** | Partition & Formatter | Memindai blok partisi (`mmcblk*`, `sd*`). Menyediakan opsi pemformatan ke F2FS atau Ext4 dengan dialog konfirmasi pengamanan. |
| **FR-07** | Real-time Log Viewer | Menampilkan log aktivitas secara langsung (*live tail*) dari `/storage/emulated/0/mountx.log` dan `/data/adb/modules/MountX/mountx.log` (dengan fallback log `mountify.log`) dengan penanda level (Info, Success, Error, Debug, Warn). |
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

### 3.5 Standar Proporsi & Dimensi Kompak UI (Anti UI-Bloat)
Dilarang menggunakan komponen default Material Design yang berukuran besar/membengkak (*bloated*) tanpa penyesuaian proporsi. Seluruh komponen wajib mengikuti standar dimensi kompak MountX:
1. **Screen Header**: Wajib menggunakan `CompactScreenHeader` (~46 dp tinggi visual + `statusBarsPadding()`), ukuran judul 16–17sp tebal, icon navigasi 18–20 dp. Dilarang menggunakan default `TopAppBar` (64 dp) yang membuang ruang vertikal layar.
2. **Search Bar Kompak**: Tinggi visual wajib **36–40 dp** (standar resmi: **38 dp**) menggunakan `Surface(RoundedCornerShape(10.dp))` + `BasicTextField` horizontal padding 10 dp, icon search 16 dp, placeholder 12sp. Dilarang menggunakan default `OutlinedTextField` (56 dp) yang terlalu tinggi dan memakan ruang.
3. **Filter Chips & Kategori**: Tinggi visual **28–32 dp** (standar resmi: **30 dp**), sudut membulat 8 dp, label teks 11–12sp, ikon chip 13–15 dp, padding horizontal 8–10 dp. Hindari default `FilterChip` bawaan Material yang tingginya mencapai 48 dp.
4. **Tombol Aksi & CTA**: Tinggi visual **40–44 dp** untuk CTA utama (dengan `AuroraGradientBrush` atau warna tema), dan **32–36 dp** untuk tombol sekunder/utilitas. Teks tombol 13–14sp tebal.
5. **Proporsi Ikon**:
   - Ikon navigasi / top action: **18–20 dp**
   - Ikon search bar / chip / inline: **14–16 dp**
   - Ikon aplikasi dalam daftar: **36–40 dp**
   - Dilarang keras menampilkan ikon berukuran raksasa yang mendominasi tata letak.
6. **Arsitektur Layar Penuh (Sub-screens & Pickers)**:
   - Sub-screen (seperti App Picker) wajib dibangun sebagai composable layar penuh native langsung di dalam pohon navigasi/Scaffold, **BUKAN** sebagai popup `Dialog` jendela Android.
   - Hal ini untuk mencegah munculnya margin jendela floating, celah kosong di bagian atas status bar, atau latar belakang yang bocor di sisi kiri/kanan.
7. **Dropdown Menus & Popup**:
   - Tinggi item menu wajib **30–34 dp** (standar resmi: **32 dp**), padding horizontal 10–12 dp, sudut membulat 8 dp, label teks 11.5–12sp, ikon indikator 14 dp.
   - Dilarang menggunakan default `DropdownMenuItem` (48 dp) atau menu yang memicu whitespace raksasa dan tidak proporsional.
   - Menggunakan `containerColor = MaterialTheme.colorScheme.surface`, border halus, dan shadow kompak (3–4 dp).
8. **Dialog & Pop-up Overlays**:
   - **Margin Sisi**: Kartu dialog wajib memiliki margin horizontal **24–28 dp** dari tepi layar. Dilarang keras menempel atau mepet ke tepi kiri/kanan layar.
   - **Modern Backdrop Blur**: Wajib menyertakan efek blur latar belakang (`Modifier.blur(16.dp)`) dengan transisi animasi halus dan scrim semi-transparan (`Color.Black.copy(alpha = 0.45f)`).
   - **Bentuk Kartu**: Sudut membulat 14–16 dp, border halus `outlineVariant`, dan shadow elevasi modern (6–8 dp).

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

MountX menerapkan arsitektur modular **Clean Architecture** dan **MVVM**:

```
app/src/main/java/app/mountx/
├── data/
│   ├── db/          # Room AppDatabase & GameDao (Single source of truth)
│   ├── model/       # Data classes, Room Entities, Enums
│   └── repository/  # GameRepository & StorageRepository
├── di/              # Hilt Modules (AppModule, DatabaseModule)
├── root/            # Engine Shell libsu (RootShell, RootDetector, MountManager, StorageManager)
├── service/         # Android Services (MountService, BootReceiver)
├── ui/              # Jetpack Compose UI Screens, ViewModels, Theme, Components
└── util/            # AppPreferences, AppLogger, UpdateChecker, FormatUtils
```

### 5.1 Aturan Penulisan Kotlin & Coroutines
1. **Thread Disiplin**: Seluruh eksekusi shell, I/O berkas, dan operasi basis data wajib dijalankan di dalam `withContext(Dispatchers.IO)`. Dilarang memblokir `Dispatchers.Main`.
2. **State Management**: Gunakan `StateFlow` pada ViewModel dan konsumsi di Compose menggunakan `collectAsState()`.
3. **Basis Data**: Room database adalah sumber kebenaran tunggal (*single source of truth*) status lokal.
4. **Dependency Injection**: Seluruh komponen dikelola melalui Hilt (`@Inject`, `@Singleton`, `@HiltViewModel`).
5. **Konsistensi Paket**: Package root adalah `app.mountx`.

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
3. Log sistem dicatat secara simultan ke `/data/adb/modules/MountX/mountx.log` dan `/storage/emulated/0/mountx.log` (dengan kompatibilitas modul legacy di `/data/adb/modules/Mountify/mountify.log`).

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
4. **Larangan Referensi Lama & Penegakan Rebrand MountX**:
   - Dilarang keras membatalkan (revert) atau mengubah nama proyek dari **MountX** kembali ke nama lama (**Mountify**).
   - Nama resmi satu-satunya sekarang adalah **MountX**.
   - Seluruh teks antarmuka, strings (`app_name`, `dashboard_title`, dsb.), konfigurasi, notifikasi, dan dokumentasi wajib menggunakan **MountX** tanpa pengecualian.
   - Repositori GitHub resmi adalah `https://github.com/Zy0x/MountX`, direktori proyek lokal adalah `MountX`, dan seluruh nama produk, modul, serta aplikasi adalah murni **MountX**.
5. **Larangan Penghapusan Data Tanpa Verifikasi**: Dilarang menghapus berkas penyimpanan internal sebelum verifikasi salinan pada MicroSD selesai dengan valid.
6. **Larangan Blocking Thread**: Dilarang memanggil perintah shell atau I/O pada `Dispatchers.Main`.

---

## 11. PROTOKOL SCREENSHOT & PELAPORAN HASIL TESTING

Seluruh sesi pengujian (testing) wajib menyertakan tangkapan layar (screenshot) sebagai bukti visual dan bahan review oleh maintainer.

### 11.1 Kewajiban Screenshot
- Setiap kali menjalankan pengujian — baik pengujian UI, build verification, emulator run, maupun pengujian fitur apa pun — agen **wajib** mengambil screenshot layar pada titik-titik kritis berikut:
  1. **Sebelum pengujian**: kondisi awal (initial state).
  2. **Selama pengujian**: tangkap setiap layar atau state yang diuji (misalnya: tampilan screen utama, dialog, hasil operasi mount, log viewer, dsb.).
  3. **Setelah pengujian**: kondisi akhir (final state / hasil), termasuk layar sukses atau pesan error.

### 11.2 Kewajiban Pelaporan Visual
- Seluruh screenshot yang diambil **wajib ditampilkan di akhir respons** sebagai bagian dari laporan testing.
- Format penyajian screenshot dalam laporan:
  ```
  ### Hasil Testing — [Nama Fitur / Skenario]
  
  **[1] Initial State**
  ![Initial State](<path-atau-embed-screenshot>)
  
  **[2] During Test — [Nama State/Layar]**
  ![During Test](<path-atau-embed-screenshot>)
  
  **[3] Final Result**
  ![Final Result](<path-atau-embed-screenshot>)
  ```
- Jika lebih dari satu skenario diuji dalam satu sesi, setiap skenario memiliki blok laporan tersendiri.

### 11.3 Metode Pengambilan Screenshot
- Untuk pengujian via **emulator Android** (Android Studio / AVD): gunakan perintah ADB berikut untuk mengambil screenshot:
  ```bash
  adb exec-out screencap -p > test_<nama_skenario>_<timestamp>.png
  ```
- Untuk pengujian via **Chrome DevTools / browser preview**: gunakan MCP tool `take_screenshot` dari server `chrome-devtools-mcp`.
- Untuk pengujian via **Playwright / browser automation**: gunakan MCP tool `browser_take_screenshot` dari server `playwright`.
- Untuk pengujian **desktop / sistem lokal**: gunakan MCP tool `computer` dari server `computer-use`.
- Screenshot disimpan sementara di direktori `<appDataDir>/brain/<conversation-id>/screenshots/` sebelum disajikan dalam laporan.

### 11.4 Standar Kualitas Screenshot
- Screenshot wajib menampilkan area yang relevan dengan skenario pengujian secara penuh tanpa terpotong.
- Nama file screenshot menggunakan format: `test_<fitur>_<state>_<timestamp>.png` (huruf kecil, underscore).
- **Wajib menunggu hingga seluruh notifikasi sistem (toast, snackbar, status bar notification, popup overlay) benar-benar hilang dari layar sebelum mengambil screenshot.** Tidak ada toleransi terhadap notifikasi yang menghalangi atau menutupi sebagian tampilan aplikasi.
- Prosedur sebelum shutter:
  1. Amati layar selama minimal **2–3 detik** setelah aksi terakhir untuk memastikan semua animasi dan notifikasi transien selesai.
  2. Jika notifikasi masih terlihat, tunggu hingga hilang secara alami atau dismiss secara eksplisit (swipe/dismiss via ADB: `adb shell input swipe 900 100 900 600`).
  3. Baru ambil screenshot setelah layar dalam kondisi bersih penuh.
- Jika setelah menunggu notifikasi tetap tidak hilang, ambil screenshot ulang hingga kondisi layar benar-benar bersih, maksimal **3 kali percobaan** sebelum melaporkan kendala kepada maintainer.

### 11.5 Larangan
- **Dilarang** menyimpulkan hasil pengujian hanya berdasarkan teks log tanpa screenshot sebagai bukti visual, kecuali pengujian bersifat murni unit test tanpa antarmuka grafis.
- **Dilarang** menyelesaikan sesi testing tanpa menampilkan screenshot hasil akhir kepada maintainer untuk review.

