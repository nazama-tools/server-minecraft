<div align="center">

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/bash/bash-original.svg" width="80" alt="Bash" />

# Minecraft Server NZCloud

**Self-hosted Minecraft server manager — jalankan di Termux, Linux, macOS, dan lainnya.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![Bash](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Platform](https://img.shields.io/badge/Platform-Termux%20%7C%20Linux%20%7C%20macOS-blue?style=flat-square&logo=linux&logoColor=white)](https://github.com)
[![Minecraft](https://img.shields.io/badge/Minecraft-Java%20%26%20Bedrock-62B47A?style=flat-square&logo=minecraft&logoColor=white)](https://minecraft.net)
[![Version](https://img.shields.io/badge/Version-1.0-purple?style=flat-square)](https://github.com)
[![Tunnel](https://img.shields.io/badge/Tunnel-ngrok-blue?style=flat-square&logo=ngrok&logoColor=white)](https://ngrok.com)

<br/>

> Satu script. Perangkat apapun. Server Minecraft kamu online dan bisa Mabar dalam hitungan menit.

</div>

---

## 📋 Table of Contents

- [Overview](#-overview)
- [Features](#-features)
- [Requirements per Platform](#-requirements-per-platform)
- [Installation](#-installation)
  - [Termux (Android)](#-termux-android)
  - [Ubuntu / Debian](#-ubuntu--debian)
  - [Arch Linux / Manjaro](#-arch-linux--manjaro)
  - [macOS](#-macos)
  - [CentOS / RHEL / Fedora](#-centos--rhel--fedora)
- [Usage](#-usage)
- [File Structure](#-file-structure)
- [Security](#-security)
- [Supported Software](#-supported-software)
- [FAQ](#-faq)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🌐 Overview

**NZCloud Minecraft Server** adalah manajer server Minecraft berbasis Bash yang sepenuhnya otomatis dan interaktif. Dirancang untuk berjalan di hampir semua sistem Unix — termasuk **Termux (Android)**, **Ubuntu/Debian**, **Arch Linux**, **macOS**, dan lainnya.

Clone repo, jalankan satu script, jawab beberapa pertanyaan, dan server Minecraft kamu sudah **online publik** via tunnel **ngrok** — langsung bisa Mabar jarak jauh tanpa port forwarding, tanpa domain, tanpa konfigurasi manual apapun.

---

## ✨ Features

<table>
<tr>
<td>

### 🎮 Server Management
- Java & Bedrock Edition support
- Paper, Purpur, Vanilla server software
- Auto-download server JAR yang sesuai
- Start / Stop / Restart controls
- Server berjalan di background
- Live log streaming

</td>
<td>

### 🌍 Tunnel Publik (ngrok)
- Otomatis install & jalankan ngrok
- Langsung dapat alamat publik
- Tidak perlu port forwarding
- Tidak peduli CGNAT / IP dinamis
- Jalan di HP, laptop, VPS semua sama

</td>
</tr>
<tr>
<td>

### 🔐 Security
- Setup username + password admin
- Hashing password SHA-256
- Kredensial disimpan lokal (tidak pernah ke GitHub)
- Repo auto-terkunci setelah setup pertama
- Autentikasi wajib untuk masuk kembali

</td>
<td>

### ⚡ Performance
- RAM otomatis terdeteksi dari perangkat
- 70% dari RAM tersedia dialokasikan
- G1GC JVM flags untuk performa optimal
- Jalan native — tanpa Docker, tanpa container

</td>
</tr>
</table>

---

## 📦 Requirements per Platform

### 📱 Termux (Android)

```bash
pkg update && pkg upgrade -y
pkg install git curl wget openjdk-17 python3 jq unzip -y
```

> Install Termux dari **[F-Droid](https://f-droid.org/packages/com.termux/)**, bukan Play Store.

### 🐧 Ubuntu / Debian / Raspberry Pi OS

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget default-jdk python3 jq unzip
```

### 🎩 Arch Linux / Manjaro

```bash
sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm git curl wget jdk-openjdk python jq unzip
```

### 🍎 macOS

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git curl wget openjdk python3 jq
```

### 🎩 CentOS / RHEL / Fedora

```bash
# Fedora
sudo dnf install -y git curl wget java-17-openjdk python3 jq unzip

# CentOS / RHEL
sudo yum install -y git curl wget java-17-openjdk python3 jq unzip
```

> Script akan mencoba auto-install dependensi yang kurang saat pertama kali dijalankan.

---

## 🛠️ Installation

### 📱 Termux (Android)

```bash
# 1. Install dependensi
pkg update && pkg upgrade -y
pkg install git curl wget openjdk-17 python3 jq unzip -y

# 2. Clone repo
git clone https://github.com/nazama-tools/server-minecraft.git

# 3. Masuk folder
cd server-minecraft/Minecraft_server-nzcloud-v1.0

# 4. Beri izin eksekusi
chmod +x setup.sh

# 5. Jalankan!
./setup.sh
```

---

### 🐧 Ubuntu / Debian

```bash
# 1. Install dependensi
sudo apt update
sudo apt install -y git curl wget default-jdk python3 jq unzip

# 2. Clone repo
git clone https://github.com/nazama-tools/server-minecraft.git

# 3. Masuk folder
cd server-minecraft/Minecraft_server-nzcloud-v1.0

# 4. Beri izin eksekusi
chmod +x setup.sh

# 5. Jalankan!
./setup.sh
```

---

### 🎩 Arch Linux / Manjaro

```bash
# 1. Install dependensi
sudo pacman -S --noconfirm git curl wget jdk-openjdk python jq unzip

# 2. Clone repo
git clone https://github.com/nazama-tools/server-minecraft.git

# 3. Masuk folder
cd server-minecraft/Minecraft_server-nzcloud-v1.0

# 4. Beri izin eksekusi
chmod +x setup.sh

# 5. Jalankan!
./setup.sh
```

---

### 🍎 macOS

```bash
# 1. Install Homebrew (jika belum)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install dependensi
brew install git curl wget openjdk python3 jq

# 3. Clone repo
git clone https://github.com/nazama-tools/server-minecraft.git

# 4. Masuk folder
cd server-minecraft/Minecraft_server-nzcloud-v1.0

# 5. Beri izin eksekusi
chmod +x setup.sh

# 6. Jalankan!
./setup.sh
```

---

### 🎩 CentOS / RHEL / Fedora

```bash
# 1. Install dependensi
sudo dnf install -y git curl wget java-17-openjdk python3 jq unzip

# 2. Clone repo
git clone https://github.com/nazama-tools/server-minecraft.git

# 3. Masuk folder
cd server-minecraft/Minecraft_server-nzcloud-v1.0

# 4. Beri izin eksekusi
chmod +x setup.sh

# 5. Jalankan!
./setup.sh
```

---

## 🚀 Quick Start

```bash
git clone https://github.com/nazama-tools/server-minecraft.git
cd server-minecraft/Minecraft_server-nzcloud-v1.0
chmod +x setup.sh
./setup.sh
```

Ikuti panduan interaktif:

```
[1/6] Pilih tipe Minecraft     →  Java / Bedrock
[2/6] Pilih software server    →  Paper / Purpur / Vanilla
[3/6] Masukkan versi Minecraft →  contoh: 1.21.4
[4/6] Masukkan nama server     →  contoh: MyServer
[5/6] Buat akun admin          →  username + password (disimpan lokal)
[6/6] Port server              →  Enter untuk pakai default 25565
```

Di tengah setup, kamu akan diminta setup **ngrok token** (sekali saja):

```
  ➜  https://ngrok.com/signup        ← Daftar gratis
  ➜  https://dashboard.ngrok.com     ← Login jika sudah punya akun
  ➜  https://dashboard.ngrok.com/get-started/your-authtoken  ← Ambil token

  Authtoken ngrok: ___
```

Setelah itu server langsung online dengan alamat publik otomatis!

---

## 📖 Usage

### Menu Utama

Jalankan kembali `./setup.sh` untuk membuka menu (wajib login admin):

```
┌─────────────────────────────────────────────────┐
│        Minecraft Server Manager - NZCloud        │
│           Tunnel: ngrok  |  Version 1.0          │
└─────────────────────────────────────────────────┘

  Status Server:
  Minecraft  : ● RUNNING (PID: 12345)
  Tunnel     : ● RUNNING (PID: 12346)
  Alamat     : 0.tcp.ngrok.io:12345  ← share ke teman

  1) Start Server + Tunnel
  2) Stop Server + Tunnel
  3) Restart Server + Tunnel
  4) Lihat Log Minecraft
  5) Lihat Log Tunnel (ngrok)
  6) Ganti Port Server
  7) Refresh Status
  0) Keluar (server tetap berjalan)
```

### Alamat Publik

Setelah server di-start, alamat publik langsung muncul di status dengan format:

```
0.tcp.ngrok.io:XXXXX
```

Share alamat itu ke teman — langsung bisa connect dari mana saja.

### Server Tetap Berjalan

Server berjalan dengan `nohup`. Menutup terminal **tidak mematikan** server. Untuk menghentikan gunakan menu **Stop Server + Tunnel**.

---

## 📁 File Structure

```
server-minecraft/                     ← repo
│
├── Minecraft_server-nzcloud-v1.0/
│   ├── setup.sh              ← Script utama
│   ├── admin.json            ← Kredensial admin (LOKAL, tidak di-commit)
│   ├── server.conf           ← Konfigurasi server (LOKAL, tidak di-commit)
│   ├── server.log            ← Log Minecraft (LOKAL)
│   ├── ngrok.log             ← Log tunnel (LOKAL)
│   ├── server.pid            ← PID Minecraft (LOKAL)
│   ├── ngrok.pid             ← PID tunnel (LOKAL)
│   ├── ngrok                 ← Binary ngrok (LOKAL, tidak di-commit)
│   └── server_data/          ← Data server Minecraft (LOKAL, tidak di-commit)
│       ├── server.jar
│       ├── eula.txt
│       ├── server.properties
│       └── world/
│
├── .gitignore
├── LICENSE
└── README.md
```

> ⚠️ **Semua file runtime disimpan lokal** — tidak pernah masuk ke GitHub.

---

## 🔐 Security

| Komponen | Penjelasan |
|---|---|
| **Password hashing** | SHA-256 — password tidak pernah disimpan plaintext |
| **admin.json** | Disimpan lokal, tidak pernah di-push ke GitHub |
| **File Manager Lock** | Repo terkunci setelah setup, wajib login admin |
| **chmod 600** | `admin.json` hanya bisa dibaca oleh user pemilik |
| **ngrok token** | Disimpan di config ngrok lokal, tidak masuk repo |

---

## 🎮 Supported Software

| Software | Tipe | Keterangan |
|---|---|---|
| **Paper** | Java | ⭐ Direkomendasikan — performa terbaik, banyak plugin |
| **Purpur** | Java | Fork Paper dengan fitur tambahan |
| **Vanilla** | Java | Server resmi dari Mojang |
| **Bedrock DS** | Bedrock | Server resmi untuk Bedrock Edition |

---

## ❓ FAQ

**Q: Apakah server bisa langsung diakses dari internet / Mabar jarak jauh?**
A: Ya, langsung bisa! Script otomatis install dan jalankan **ngrok** sebagai tunnel publik. Tidak perlu port forwarding, tidak perlu domain, jalan di HP, laptop rumah, maupun VPS.

**Q: Berapa RAM yang digunakan?**
A: Script otomatis pakai 70% dari RAM tersedia di perangkat kamu (minimum 512 MB).

**Q: ngrok token itu apa dan bayar tidak?**
A: Token ngrok gratis. Daftar di [ngrok.com](https://ngrok.com), ambil token di dashboard, paste sekali saja. Setelah itu tidak perlu diulangi.

**Q: Saya lupa password admin, bagaimana reset?**
A: Hapus `admin.json` dan `.nzcloud_fm_lock`, lalu jalankan ulang `./setup.sh`.

```bash
cd server-minecraft/Minecraft_server-nzcloud-v1.0
rm -f admin.json ../.nzcloud_fm_lock
./setup.sh
```

**Q: Apakah bisa dijalankan di HP Android?**
A: Ya! Gunakan [Termux](https://f-droid.org/packages/com.termux/) dari F-Droid. Diuji dan berfungsi di Android 10+.

**Q: Server mati ketika terminal ditutup?**
A: Tidak — server berjalan dengan `nohup`. Untuk menghentikan gunakan menu **Stop Server + Tunnel**.

**Q: Apakah bisa dipakai di VPS?**
A: Ya, berjalan sempurna di Ubuntu, Debian, CentOS, dan distro Linux lainnya.

**Q: Cara hapus data server lama untuk setup ulang?**

```bash
cd server-minecraft/Minecraft_server-nzcloud-v1.0
pkill -f "server.jar" 2>/dev/null; pkill -f "ngrok" 2>/dev/null
rm -rf server_data/ server.conf admin.json server.log ngrok.log server.pid ngrok.pid ngrok ../.nzcloud_fm_lock
./setup.sh
```

---

## 🤝 Contributing

Kontribusi sangat disambut!

1. Fork repositori ini
2. Buat branch fitur (`git checkout -b feature/nama-fitur`)
3. Commit (`git commit -m 'feat: tambahkan fitur X'`)
4. Push (`git push origin feature/nama-fitur`)
5. Buka Pull Request

---

## 📄 License

Distributed under the **MIT License**. See [`LICENSE`](LICENSE) for more information.

---

<div align="center">

Made with ❤️ by **NZCloud**

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/linux/linux-original.svg" width="24" alt="Linux" />
&nbsp;
<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/bash/bash-original.svg" width="24" alt="Bash" />
&nbsp;
<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/java/java-original.svg" width="24" alt="Java" />

*Kalau project ini membantu, kasih ⭐ di GitHub ya!*

</div>
