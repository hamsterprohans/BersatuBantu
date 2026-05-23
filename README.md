<p align="center">
  <img src="https://github.com/user-attachments/assets/07fd0d52-22dc-45cd-8850-12833cf8e514" alt="github" width="600"/>
</p>

<h1 align="center">
  <img src="assets/bersatubantu.png" alt="BersatuBantu Logo" width="120" />
</h1>
<h2 align="center">
 🤝 Unified Platform for Social Giving & Community Action 🤝
</h2>

<div align="center">
 
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Connected-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev/)
[![License](https://img.shields.io/badge/License-Academic-red)](LICENSE)

## 🌐 Akses Aplikasi BersatuBantu
🔗 **File APK untuk install**:  
(comming soon)

 **UI Design**:  
**[![Figma](https://img.shields.io/badge/Figma-F24E1E?logo=figma&logoColor=white)](https://www.figma.com/design/qzsXWisZWtbFQU7uANxgIP/UI-App-Bersatu-Bantu--Copy-?node-id=0-1&t=ot94GksXAfgGTvTm-1)**


</div>



**BersatuBantu** adalah aplikasi donasi terpadu berbasis **Flutter** yang menghubungkan **donatur**, **organisasi sosial**, dan **relawan** dalam satu platform untuk mendukung **donasi uang**, **donasi barang**, serta **kegiatan sosial dan volunteer**, dilengkapi dengan **fitur chat**, **notifikasi**, dan **verifikasi organisasi oleh admin** guna meningkatkan transparansi dan kepercayaan publik.

---

## 📱 Screenshots
| Splash Screen | Dashboard | Volunteer| Donasi | Chat |
|--------------|-----------|-----------------|-----------|------|
| ![logo](assets/splash.png) | ![logo](assets/dashboard.png) | ![logo](assets/volunteer.png) | ![logo](assets/donasi.png) | ![logo](assets/chat.png) |

---

## ✨ Fitur Utama

### 👥 Untuk Pengguna (User)
- 🏠 **Dashboard Pengguna** — Melihat ringkasan donasi dan aktivitas
- 💰 **Donasi Uang** — Berdonasi melalui campaign aktif
- 📦 **Donasi Barang** — Input data barang dan upload foto
- 📅 **Kegiatan & Volunteer** — Daftar dan mengikuti kegiatan sosial
- 📜 **Riwayat Aktivitas** — Riwayat donasi dan kegiatan yang diikuti
- 💬 **Chat** — Berkomunikasi langsung dengan organisasi
- 🔔 **Notifikasi** — Update status donasi, kegiatan, dan pesan

---

### 🏢 Untuk Organisasi
- 📝 **Registrasi Organisasi Multi-Step**
  - Data Pemilik
  - Data Organisasi
  - Upload Berkas Legal
- ⏳ **Status Verifikasi** — Pending, Approved, Rejected
- 📊 **Dashboard Organisasi** — Kelola donasi dan kegiatan
- 📢 **Posting Kegiatan & Donasi**
- 💬 **Chat dengan User**
- 📰 **Berita Sosial**

---

### 🛠️ Untuk Admin
- 📋 **Dashboard Verifikasi Organisasi**
- ✅ **Manajemen Berita**
- 🗂️ **Manajemen Data Organisasi**
- 🔍 **Monitoring Aktivitas Sistem**

---

## 🏗️ Arsitektur & Teknologi
### Tech Stack
- 💙 **Flutter** — Cross-platform UI framework
- 🟢 **Supabase** — Backend as a Service
  - Supabase Auth — Autentikasi user
  - PostgreSQL — Database relasional
  - Supabase Storage — Penyimpanan file & berkas
  - Supabase Realtime — Chat & data sinkron
- 🎯 **Dart** — Bahasa pemrograman utama

---

### Arsitektur Aplikasi
```
lib/
├── 🎯 main.dart                     # Entry point aplikasi
├── 🔐 auth/                         # Login & register (user, organisasi, admin)
├── 👤 aturprofile/                  # Manajemen profil pengguna
├── 🤝 aksi/                         # Aksi sosial & aktivitas umum
├── 💰 donasi/                       # Donasi uang (campaign & transaksi)
├── 📦 berikandonasi/                # Donasi barang
├── 📰 berita_sosial/                # Berita & posting sosial
├── 💬 chat/                         # Fitur chat
│   └── 📱 screens/                  # UI chat & message
├── 🏢 organisasi/                   # Modul organisasi
│   ├── 📝 pendaftaran/              # Pendaftaran organisasi (multi-step)
│   └── ✅ verifikasi_organisasi/    # Verifikasi organisasi oleh admin
├── 📊 dashboard/                    # Dashboard (user, organisasi, admin)
├── 📅 kegiatan/                     # Kegiatan & volunteer
│   ├── 📌 sedang_diikuti/           # Kegiatan yang sedang diikuti
│   └── 📜 pernah_diikuti/           # Riwayat kegiatan
├── 🔄 loading/                      # Loading & splash state
├── 🧭 pilihrole/                    # Pilih role pengguna
├── ✍️ posting/                      # Posting donasi & kegiatan
│   ├── 💰 posting_donasi/
│   └── 📅 posting_kegiatan/
├── 🎉 welcome/                      # Welcome & onboarding
├── 🧩 widgets/                      # Reusable UI components
│   ├── 🔘 button.dart
│   ├── 📋 form_field.dart
│   ├── 📅 date_picker.dart
│   ├── 🪟 modal.dart
│   └── 📊 dashboard_card.dart
├── 🧠 models/                       # Data models & entities
├── 🔌 services/                     # Supabase service & API handler
├── 🔧 utils/                        # Helper & utility functions
└── 🎨 theme/                        # Theme, color, dan typography

```
---

## 🚀 Panduan Instalasi & Setup

### 📋 Prerequisites

Pastikan Anda telah menginstall:

- **[Flutter SDK](https://flutter.dev/docs/get-started/install)** (≥3.x)
- **[Dart SDK](https://dart.dev/get-dart)** (≥3.x)
- **[Android Studio](https://developer.android.com/studio)** atau **[VS Code](https://code.visualstudio.com/)**
- **[Git](https://git-scm.com/)** untuk version control
- **Akun [Supabase](https://supabase.com/)** (project aktif)

### 🔧 Langkah Instalasi

#### 1. Clone Repository

```bash
git clone https://github.com/your-username/BersatuBantu.git
cd BersatuBantu
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Setup Supabase

Project ini menggunakan file `.env` untuk menyimpan konfigurasi environment (Supabase).
<img width="1615" height="884" alt="supabase-schema-kkacuemmgvgtyhgmxidy (1)" src="https://github.com/user-attachments/assets/07f3e886-13f2-4974-87b3-90e6f50c0202" />

```bash
Copy dari file `envcopy` ke `.env`
```
Pastikan file `envcopy` sudah tersedia di root project.

#### 4. Jalankan Aplikasi

```bash
# Debug mode
flutter run

# Untuk device spesifik
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d ios             # iOS
```
---

## 👥 Team & Credits

### 🎓 Kelompok 2 - Final Project Teknologi Berkembang

<div align="start">

| Nama                             | NRP          | GitHub      |
| -------------------------------- | ------------ | ----------- |
| **Daniel Setiawan**         | `5026231010` | `eLlawliet` |
| **Izzuddin Hammadi Faiz** | `5026231018` | `freudian178` |
| **Kevin Nathanael**    | `5026231079` | `kevin-079` |
| **Hans Christian Cakrawangsa**     | `502623130` | `hanscakrawangsa15` |
| **Dzaky Ahmad**     | `502623184` | `Jek786` |
| **Heber Bryan Hutajulu**     | `502623204` | `heberbryan` |

</div>

### 🏫 Institution

**Institut Teknologi Sepuluh Nopember (ITS)**  
Mata Kuliah: Teknologi Berkembang  (B)

Semester: Ganjil 2025/2026

---

### 🌍 Social Impact Inspiration

Project ini terinspirasi dari:

- **UN Sustainable Development Goals (SDGs)**  
  Khususnya Goal 1 (No Poverty), Goal 10 (Reduced Inequalities), dan Goal 17 (Partnerships for the Goals)
- **Social Giving & Community Challenges in Indonesia**  
  Mendorong transparansi, kepercayaan, dan kolaborasi dalam kegiatan donasi dan sosial
- **Digital Collaboration for Social Impact**  
  Pemanfaatan teknologi digital untuk memperkuat peran individu, organisasi, dan relawan

<div align="center">

---

### Made with Love for a Better Indonesia

**"Bersatu untuk Membantu, Bergerak untuk Berdampak"**

[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-02569B?logo=flutter&logoColor=white)](https://flutter.dev/)
[![Powered by Supabase](https://img.shields.io/badge/Powered%20by-Supabase-3ECF8E?logo=supabase&logoColor=white)](https://supabase.com/)
[![Built by Students](https://img.shields.io/badge/Built%20by-ITS%20Students-green)](https://its.ac.id/)

**© 2025 BersatuBantu — Final Project Teknologi Berkembang**  
_Institut Teknologi Sepuluh Nopember (ITS)_

---

 🫱🏻‍🫲🏼 **"Setiap aksi kebaikan, sekecil apa pun, adalah langkah menuju Indonesia yang lebih peduli dan berdaya"** 🫱🏻‍🫲🏼

</div>






