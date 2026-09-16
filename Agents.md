# 🤖 AGENTS.MD — Standar Operasional Teknis & Pedoman AI Agent: Mountify

> **Status Dokumen**: Mandatory (Wajib Dipatuhi Tanpa Pengecualian)  
> **Target Proyek**: Mountify (Android Native Companion App & Magisk/KernelSU/APatch Module)  
> **Package ID**: `app.mihon`  
> **Author & Maintainer**: Noir ([@Zy0x](https://github.com/Zy0x))  
> **Repositori**: [https://github.com/Zy0x/Mountify](https://github.com/Zy0x/Mountify)  

Dokumen ini berfungsi sebagai **standar teknis, arsitektur sistem, pedoman keselamatan root, aturan desain UI/UX, serta Product Requirements Document (PRD)** yang mengikat seluruh AI Coding Assistant (Antigravity, Cursor, Copilot, dsb.) dan kontributor dalam mengembangkan, memodifikasi, atau memelihara repositori **Mountify**.

---

## DAFTAR ISI
1. [Identitas & Filosofi Proyek](#1-identitas--filosofi-proyek)
2. [Product Requirements Document (PRD)](#2-product-requirements-document-prd)
3. [Standar Responsivitas Tampilan & Mobile-First (Ekstrem)](#3-standar-responsivitas-tampilan--mobile-first-ekstrem)
4. [Protokol Keamanan Tingkat Tinggi & Operasi Root (Non-Negotiable)](#4-protokol-keamanan-tingkat-tinggi--operasi-root-non-negotiable)
5. [Standar Arsitektur Kode & Disiplin Tech Stack](#5-standar-arsitektur-kode--disiplin-tech-stack)
6. [Standar Modul Magisk / KernelSU / APatch](#6-standar-modul-magisk--kernelsu--apatch)
7. [Standar Lokalisasi (i18n) & Aksesibilitas](#7-standar-lokalisasi-i18n--aksesibilitas)
8. [Protokol Git, Commit, Push, dan Kebijakan Perilisan](#8-protokol-git-commit-push-dan-kebijakan-perilisan)
9. [Standar CI/CD & Keamanan Kredensial](#9-standar-cicd--keamanan-kredensial)
10. [Checklist Larangan Keras (Golden Rules for AI Agents)](#10-checklist-larangan-keras-golden-rules-for-ai-agents)

---

## 1. IDENTITAS & FILOSOFI PROYEK

### 1.1 Identitas Resmi
- **Nama Aplikasi di Launcher**: `Mountify`
- **Application ID / Package**: `app.mihon`
- **Nama Modul Root**: `Mountify`
- **Target OS**: Android 10 (API 29) hingga Android 15+ (API 35+)
- **Root Solutions Didukung**: Magisk, KernelSU, APatch

### 1.2 Masalah Pokok yang Dipecahkan
Mulai Android 10 ke atas, Google memperketat *Scoped Storage*. Pengguna tidak dapat lagi memindahkan data aplikasi/game ke penyimpanan eksternal (MicroSD) secara normal. Game modern seperti *Wuthering Waves*, *Genshin Impact*, *Honkai: Star Rail*, *Zenless Zone Zero*, dan *PUBG Mobile* menghabiskan 20 GB – 40 GB+ per judul. 

Mountify memecahkan masalah ini dengan menghubungkan direktori data game di partisi kedua MicroSD yang diformat Linux (F2FS/Ext4) ke penyimpanan internal melalui teknik **bind-mount pada seluruh namespace runtime Android** tanpa memicu error FUSE cross-device.

---

## 2. PRODUCT REQUIREMENTS DOCUMENT (PRD)

### 2.1 Persona Pengguna
- **Mobile Gamers**: Memiliki HP penyimpanan internal terbatas (64GB/128GB) dan ingin menginstal banyak game berukuran besar tanpa performa stuttering.
- **Android Power Users & Modders**: Menggunakan custom ROM atau perangkat yang di-root dengan Magisk, KernelSU, atau APatch yang membutuhkan kontrol penuh terhadap partisi penyimpanan dan mount point.

### 2.2 Kebutuhan Fungsional (Functional Requirements)

| Modul Fitur | Spesifikasi Kebutuhan |
|---|---|
| **FR-01: Root & Module Detector** | Mendeteksi ketersediaan root dan jenis root engine (Magisk/KernelSU/APatch). Memverifikasi apakah modul Magisk Mountify aktif di `/data/adb/modules/Mountify`. |
| **FR-02: Game Registry (CRUD)** | Menambah, mengubah mode (`PKG` atau `FILES`), menghapus, serta mencari game. Mendukung auto-discovery game terpasang via Android `PackageManager`. |
| **FR-03: Two Mount Strategies** | 1. **Mode PKG**: Bind-mount seluruh folder `Android/data/<package>` (cocok untuk WuWa, PUBG, COD).<br>2. **Mode FILES**: Bind-mount hanya subfolder `/files` (database tetap di internal, cocok untuk Genshin, HSR, ZZZ). |
| **FR-04: Dynamic Bind Mount Engine** | Mengeksekusi bind-mount ke seluruh 7 namespace runtime Android, menetapkan hak akses Linux UID sandbox, dan menyetel context SELinux `u:object_r:media_rw_data_file:s0`. |
| **FR-05: Physical Data Migration** | Menyalin data fisik game antara Internal Storage (`/data/media/0/Android/data/...`) dan MicroSD (`/data/sdext2/Android/data/...`) langsung dari UI dengan verifikasi integritas sebelum penghapusan data lama. |
| **FR-06: Partition & Formatter** | Memindai blok partisi (`mmcblk*`, `sd*`). Menyediakan opsi pemformatan cepat ke **F2FS** (Direkomendasikan) atau **Ext4** dengan konfirmasi pencegahan insiden format yang tidak disengaja. |
| **FR-07: Real-time Log Viewer** | Menampilkan log aktivitas mount secara langsung (*live tail*) dari `/storage/emulated/0/mountify.log` dan `/data/adb/modules/Mountify/mountify.log` dengan filter warna level log (Info, Success, Error, Debug). |
| **FR-08: Backup & Restore JSON** | Mengekspor dan mengimpor konfigurasi daftar game dalam format JSON via Android Storage Access Framework (SAF). |
| **FR-09: Update Checker** | Memeriksa ketersediaan versi rilis baru dari endpoint GitHub Releases API dan menyediakan tautan unduh langsung. |
| **FR-10: Boot Automation** | Layanan `BootReceiver` + `MountService` Foreground Service untuk melakukan auto-mount otomatis saat booting perangkat selesai. |

### 2.3 Kebutuhan Non-Fungsional (Non-Functional Requirements)
- **Kinerja**: Waktu eksekusi mount satu game tidak boleh melebihi 1.5 detik.
- **Keandalan**: Kegagalan mount satu game tidak boleh menghentikan proses mount game lainnya.
- **Stabilitas UI**: Tidak ada stutter (jank) atau frame drop pada Compose list saat memuat puluhan data aplikasi.
- **Integritas Data**: Nol toleransi terhadap kehilangan data game (*zero data-loss tolerance*).

---

## 3. STANDAR RESPONSIVITAS TAMPILAN & MOBILE-FIRST (EKSTREM)

Setiap elemen antarmuka Jetpack Compose wajib mematuhi ketentuan berikut:

### 3.1 Mobile-First & Touch Targets
- **Target Sentuh Minimum**: Semua elemen interaktif (tombol, ikon, chip, switch) wajib memiliki ukuran target sentuh minimal **48×48 dp** (`Modifier.sizeIn(minWidth = 48.dp, minHeight = 48.dp)`).
- **No Hover-Only**: Tidak boleh bergantung pada status hover; seluruh aksi harus jelas melalui sentuhan, long-press, atau gesture yang intuitif.

### 3.2 Resolusi & Rasio Layar Non-Reguler (720p hingga 4K)
- Layout **tidak boleh rusak** pada rasio layar panjang modern (20:9, 20.5:9, 21:9 seperti 1080×2460, 1080×2380) maupun layar tablet/foldable (4:3, 16:10).
- Dilarang keras meng-hardcode tinggi/lebar container utama dengan nilai tetap yang dapat memicu clipping pada teks saat resolusi atau font-scale sistem berubah.
- Wajib menggunakan `LazyColumn`, `rememberScrollState()`, atau layout berbasis bobot (`Modifier.weight()`) agar tampilan tetap dapat digulir ketika viewport terbatas.
- Mode **Portrait** dan **Landscape** wajib diantisipasi; dialog dan bottom-sheet harus memiliki batasan tinggi (`heightIn(max = ...)`) dan mendukung scroll internal.

### 3.3 Keterbacaan (Readability First) & Kontras Warna
- **Standar Kontras**: Teks dan elemen penting wajib memenuhi standar kontras WCAG AAA.
- **Tema Gelap (AMOLED/Midnight)**: Latar belakang gelap pekat `#0F1117` dengan surface `#181B26` yang tidak melelahkan mata dan hemat daya pada layar OLED.
- **Warna Teks & Hirarki**:
  - Judul/Konten Primer: Kontras tinggi (`#F1F3F5` di tema gelap / `#212529` di tema terang).
  - Deskripsi/Subtitle: Kontras medium dengan opacity minimal 70% (`alpha = 0.7f`).
  - Dilarang menggunakan kombinasi warna yang bertabrakan (misal: teks biru tua di atas latar gelap).

### 3.4 Animasi Modern, Ringan, dan Fungsional
- Seluruh animasi transisi antar halaman, dialog, dan status chips berada dalam rentang durasi **150–350 ms**.
- Dilarang membuat animasi berlebih yang membebani GPU/CPU pada perangkat spesifikasi rendah (*low-end devices*).
- Gunakan `AnimatedVisibility`, `fadeIn()`, `fadeOut()`, dan `slideIntoContainer()` secara terukur untuk memberikan umpan balik visual yang jelas.

---

## 4. PROTOKOL KEAMANAN TINGKAT TINGGI & OPERASI ROOT (NON-NEGOTIABLE)

Karena aplikasi ini beroperasi pada tingkat **Superuser (Root)** dan berinteraksi langsung dengan blok penyimpanan partisi, kegagalan penanganan logika dapat mengakibatkan kehilangan data atau kerusakan partisi. AI Agent wajib mematuhi protokol berikut:

### 4.1 Proteksi Migrasi Data Game (Anti Data Loss)
- **Larangan Penghapusan Prematur**: Sebelum folder data asal (`/data/media/0/Android/data/...`) dihapus atau dibersihkan saat proses *Move to SD*, sistem **wajib** melakukan verifikasi bahwa folder target di MicroSD (`/data/sdext2/Android/data/...`) telah ada, tidak kosong, dan proses penyalinan mengembalikan exit code 0 (`isSuccess`).
- Jika proses salin gagal di tengah jalan, proses pemindahan harus dibatalkan seketika dan berkas asal tidak boleh disentuh.

### 4.2 Sanitasi Perintah Shell (`libsu`)
- Seluruh variabel path atau nama package yang disuntikkan ke perintah shell wajib dibungkus dengan tanda kutip ganda (`"..."`) untuk mencegah *shell command injection* atau kesalahan parsing akibat spasi.
- Contoh yang benar:
  ```kotlin
  RootShell.exec("mount -o bind \"$srcPath\" \"$targetPath\" 2>/dev/null")
  ```
- Dilarang menjalankan perintah berbahaya seperti `rm -rf /` atau operasi rekursif pada direktori di luar sandbox aplikasi dan target MicroSD.

### 4.3 Format Partisi dengan Konfirmasi Bertingkat
- Pemformatan partisi adalah operasi destruktif. Kode UI **wajib** menampilkan dialog konfirmasi dengan detail nama perangkat blok (misalnya `/dev/block/mmcblk0p3`) dan peringatan tegas bahwa seluruh data akan terhapus permanen.
- Sebelum memformat, sistem wajib memastikan partisi tersebut telah di-unmount terlebih dahulu (`umount -f`).

### 4.4 Penanganan Izin & Konteks SELinux
- Data game di MicroSD yang di-bind-mount wajib disetel dengan hak akses yang tepat agar aplikasi game tidak *force-close* saat boot:
  - Linux permissions: `chmod -R 777`
  - Linux ownership: `chown -R <APP_UID>:1023` (GID 1023 adalah `media_rw`)
  - SELinux context: `chcon -R u:object_r:media_rw_data_file:s0`

---

## 5. STANDAR ARSITEKTUR KODE & DISIPLIN TECH STACK

Repositori Mountify mengadopsi **Clean Architecture** dan **MVVM** yang ketat. Seluruh penambahan kode baru wajib mematuhi pembagian modul berikut:

```
app/src/main/java/app/mihon/
├── data/
│   ├── db/          # Room AppDatabase & GameDao (Single source of truth)
│   ├── model/       # Data classes, Room Entities, Enums (GameEntry, StorageInfo, dsb.)
│   └── repository/  # GameRepository & StorageRepository
├── di/              # Hilt Modules (AppModule, DatabaseModule)
├── root/            # Libsu Shell API wrappers (RootShell, RootDetector, MountManager, StorageManager)
├── service/         # Android Services (MountService, BootReceiver)
├── ui/              # Jetpack Compose UI
│   ├── about/       # AboutScreen & AboutViewModel
│   ├── components/  # Komponen UI reusable (StatusChip, SectionHeader, ConfirmDialog, ErrorCard)
│   ├── dashboard/   # DashboardScreen & DashboardViewModel
│   ├── games/       # GamesScreen, GamesViewModel, AddGameSheet, MoveDataSheet
│   ├── logs/        # LogsScreen & LogsViewModel
│   ├── navigation/  # Screen sealed class & NavGraph
│   ├── settings/    # SettingsScreen & SettingsViewModel
│   ├── storage/     # StorageScreen, StorageViewModel, BackupRestoreScreen
│   └── theme/       # Color, Type, Shape, Theme (Material You Dynamic Color)
└── util/            # AppPreferences (DataStore), UpdateChecker, FormatUtils
```

### 5.1 Aturan Penulisan Kotlin & Coroutines
1. **Thread Disiplin**: Semua operasi yang melibatkan `RootShell`, pembacaan file sistem, atau jaringan **wajib** dieksekusi di dalam `withContext(Dispatchers.IO)`. Dilarang keras memblokir `Dispatchers.Main`.
2. **State Management**: Gunakan `StateFlow` dan `asStateFlow()` pada ViewModel. Konsumsi di Compose menggunakan `collectAsState()` atau `collectAsStateWithLifecycle()`.
3. **Database**: Room database adalah *single source of truth* untuk status game lokal. Pembaruan status mount harus merefleksikan perubahan ke Room DAO.
4. **Dependency Injection**: Selalu gunakan Hilt (`@Inject`, `@Singleton`, `@HiltViewModel`). Jangan membuat *service locator* atau instansiasi manual kelas repository di luar DI.
5. **Package Consistency**: Root package adalah `app.mihon`. Jangan membuat subpackage di luar namespace ini.

---

## 6. STANDAR MODUL MAGISK / KERNELSU / APATCH

Modul root berada pada direktori `/module` di root repositori:
```
module/
├── module.prop       # Metadata Magisk (id=Mountify, author=Noir)
├── service.sh        # Skrip otomatis saat boot
├── config.conf       # Konfigurasi: SD_BASE, SD_BLOCK, FS_TYPE
└── gamelist.conf     # Daftar game: pkg_name:mode
```

### 6.1 Ketentuan service.sh
1. **Dinamis**: `service.sh` wajib membaca konfigurasi dari `config.conf` dan `gamelist.conf`. Dilarang meng-hardcode nama package game di dalam skrip shell.
2. **7 Runtime Namespaces**: Setiap proses bind-mount game wajib diaplikasikan ke seluruh namespace berikut:
   - `/mnt/runtime/default/emulated/0`
   - `/mnt/runtime/read/emulated/0`
   - `/mnt/runtime/write/emulated/0`
   - `/mnt/runtime/full/emulated/0`
   - `/mnt/user/0/primary`
   - `/storage/emulated/0`
   - `/data/media/0`
3. **Mirror Logging**: Setiap log event di `service.sh` wajib ditulis ke dua tempat:
   - `/data/adb/modules/Mountify/mountify.log`
   - `/storage/emulated/0/mountify.log` (agar aplikasi dapat membacanya langsung).

---

## 7. STANDAR LOKALISASI (I18N) & AKSESIBILITAS

1. **Multi-bahasa Terstruktur**:
   - Berkas `app/src/main/res/values/strings.xml` adalah bahasa default (**English**).
   - Berkas `app/src/main/res/values-id/strings.xml` adalah bahasa terjemahan (**Bahasa Indonesia**).
   - Setiap string UI baru wajib ditambahkan ke kedua berkas tersebut dengan key resource yang identik. Dilarang melakukan hardcode string teks langsung di file Compose `.kt`.
2. **Aksesibilitas (A11y)**:
   - Seluruh icon interaktif wajib memiliki parameter `contentDescription` yang jelas dan bermakna.
   - Gunakan heading semantik pada `SectionHeader` dan `TopAppBar`.

---

## 8. PROTOKOL GIT, COMMIT, PUSH, DAN KEBIJAKAN PERILISAN

### 8.1 Aturan Commit & Push Otomatis
- Setelah menyelesaikan suatu perubahan fitur, perbaikan bug, atau pembaruan dokumentasi, AI Agent **WAJIB langsung melakukan commit dan push ke remote GitHub tanpa menunggu perintah tambahan**.
- Format commit message wajib mengikuti standar **Conventional Commits**:
  - `feat(scope): ...` untuk fitur baru.
  - `fix(scope): ...` untuk perbaikan bug.
  - `refactor(scope): ...` untuk refactoring kode.
  - `docs(scope): ...` untuk dokumentasi.
  - `chore(scope): ...` untuk pemeliharaan dependensi atau konfigurasi.

### 8.2 Aturan Penomoran Versi & Changelog
- Format versi aplikasi mengikuti format semantik: `x.x.x` (misalnya `1.0.0`, `1.0.1`, ... hingga `1.0.99`, kemudian meningkat ke `1.1.0`).
- Setiap perubahan fungsional wajib dicatat di berkas [`CHANGELOG.md`](CHANGELOG.md) dan nilai `versionName` di [`app/build.gradle.kts`](app/build.gradle.kts) diperbarui secara konsisten.
- Dilarang menulis log changelog yang mengekspos celah keamanan atau rahasia backend.

### 8.3 KEBIJAKAN PERILISAN (RELEASE POLICY) — PENTING
> [!IMPORTANT]
> **PERILISAN APLIKASI DITAHAN**: Meskipun setiap commit wajib langsung di-push ke branch `main`, **AI AGENT DILARANG MEMBUAT GIT TAG (`v*`) SECARA OTOMATIS DI SETIAP COMMIT**.
> Pembuatan tag `git tag vX.X.X` akan memicu GitHub Actions mem-build signed release APK dan membuat GitHub Release publik. Hal ini ditahan agar tidak menghabiskan kuota runner CI/CD dan tidak membanjiri riwayat rilis dengan patch minor. Tag rilis hanya dibuat saat ada instruksi eksplisit dari pemilik repositori (*Noir / Zy0x*).

---

## 9. STANDAR CI/CD & KEAMANAN KREDENSIAL

1. **Perlindungan Keystore Signing**:
   - File biner `.jks`, `.keystore`, file teks `.b64`, serta `keystore.properties` **DILARANG KERAS** di-commit ke Git. File-file ini telah dilindungi di `.gitignore`.
   - Proses signing APK rilis pada GitHub Actions dieksekusi secara terisolasi via GitHub Repository Secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`).
2. **Workflow GitHub Actions (`.github/workflows/build.yml`)**:
   - Push ke branch `main` akan memvalidasi proses build (`assembleDebug` & `assembleRelease`).
   - Push ke git tag `v*` akan memicu penandatanganan APK, pembuatan zip modul Magisk, dan publikasi GitHub Release otomatis.

---

## 10. CHECKLIST LARANGAN KERAS (GOLDEN RULES FOR AI AGENTS)

Saat mengedit repositori Mountify, AI Agent **DILARANG KERAS**:
- ❌ **Menggunakan nama lama "ExtGameStorage" di mana pun** (kode program, komentar, path file, log, commit message, maupun dokumentasi). Nama resmi satu-satunya adalah **Mountify**.
- ❌ Mengubah nama package `app.mihon` atau nama aplikasi `Mountify` tanpa persetujuan tertulis.
- ❌ Menghapus data game pada internal storage sebelum memverifikasi keberhasilan penyalinan di target MicroSD.
- ❌ Menjalankan operasi format tanpa konfirmasi dialog berlapis di UI.
- ❌ Melakukan blocking call shell di Main/UI Thread (`Dispatchers.Main`).
- ❌ Meng-hardcode string antarmuka langsung di Compose tanpa mendaftarkannya di `strings.xml` (EN) dan `strings.xml` (ID).
- ❌ Meng-commit file keystore signing (`.jks`), file `.b64`, atau token akses ke repositori git.
- ❌ Membuat git tag rilis (`v*`) secara sepihak di setiap commit rutin.
- ❌ Menggunakan dependensi pihak ketiga yang tidak terdaftar di `gradle/libs.versions.toml` tanpa justifikasi arsitektural.

---

*Dokumen ini merupakan referensi tunggal kebenaran teknis (Single Source of Technical Truth) untuk pengembangan Mountify.*
