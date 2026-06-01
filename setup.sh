#!/usr/bin/env bash
# ============================================================
#  NZCloud Minecraft Server Setup & Manager
#  Version : 1.0
#  Author  : NZCloud
#  GitHub  : https://github.com/bacotbanget1/Minecraft-server
#  Tunnel  : ngrok (publik tanpa port forwarding)
# ============================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

# ── Paths ────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ADMIN_FILE="$SCRIPT_DIR/admin.json"
SERVER_DIR="$SCRIPT_DIR/server_data"
CONFIG_FILE="$SCRIPT_DIR/server.conf"
LOG_FILE="$SCRIPT_DIR/server.log"
NGROK_LOG="$SCRIPT_DIR/ngrok.log"
PID_FILE="$SCRIPT_DIR/server.pid"
NGROK_PID="$SCRIPT_DIR/ngrok.pid"
NGROK_BIN="$SCRIPT_DIR/ngrok"
FILEMANAGER_LOCK="$REPO_ROOT/.nzcloud_fm_lock"

# ── Banner ───────────────────────────────────────────────────
print_banner() {
  clear
  echo -e "${CYAN}"
  cat << 'EOF'
  ███╗   ██╗███████╗ ██████╗██╗      ██████╗ ██╗   ██╗██████╗ 
  ████╗  ██║╚══███╔╝██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
  ██╔██╗ ██║  ███╔╝ ██║     ██║     ██║   ██║██║   ██║██║  ██║
  ██║╚██╗██║ ███╔╝  ██║     ██║     ██║   ██║██║   ██║██║  ██║
  ██║ ╚████║███████╗╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
  ╚═╝  ╚═══╝╚══════╝ ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ 
EOF
  echo -e "${RESET}"
  echo -e "${MAGENTA}${BOLD}  ┌─────────────────────────────────────────────────┐${RESET}"
  echo -e "${MAGENTA}${BOLD}  │        Minecraft Server Manager - NZCloud        │${RESET}"
  echo -e "${MAGENTA}${BOLD}  │           Tunnel: ngrok  |  Version 1.0          │${RESET}"
  echo -e "${MAGENTA}${BOLD}  └─────────────────────────────────────────────────┘${RESET}"
  echo ""
}

# ── Helpers ──────────────────────────────────────────────────
info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }
success() { echo -e "${GREEN}[OK]${RESET}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }
error()   { echo -e "${RED}[ERROR]${RESET} $*"; }
step()    { echo -e "${BLUE}${BOLD}[STEP]${RESET}  $*"; }
divider() { echo -e "${DIM}──────────────────────────────────────────────────${RESET}"; }

confirm_prompt() {
  read -rp "$(echo -e "${YELLOW}$1 [y/N]: ${RESET}")" ans
  [[ "${ans,,}" == "y" ]]
}

# ── Detect Platform ───────────────────────────────────────────
detect_platform() {
  ARCH=$(uname -m)
  OS=$(uname -s)

  if [[ -n "${PREFIX:-}" && "$PREFIX" == *com.termux* ]]; then
    PLATFORM="termux"
  elif [[ "$OS" == "Linux" ]]; then
    PLATFORM="linux"
  elif [[ "$OS" == "Darwin" ]]; then
    PLATFORM="macos"
  else
    PLATFORM="linux"
  fi

  case "$ARCH" in
    x86_64)        NGROK_ARCH="amd64" ;;
    aarch64|arm64) NGROK_ARCH="arm64" ;;
    armv7l|armv7)  NGROK_ARCH="arm"   ;;
    i686|i386)     NGROK_ARCH="386"   ;;
    *)             NGROK_ARCH="amd64" ;;
  esac
}

# ── Install Dependencies ──────────────────────────────────────
check_deps() {
  local missing=()
  for cmd in curl wget java python3 jq unzip; do
    command -v "$cmd" &>/dev/null || missing+=("$cmd")
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    success "Semua dependensi tersedia."
    return
  fi

  warn "Dependensi tidak ditemukan: ${missing[*]}"

  case "$PLATFORM" in
    termux)
      pkg update -y 2>/dev/null || true
      pkg install -y curl wget openjdk-17 python3 jq unzip 2>/dev/null || true
      ;;
    linux)
      if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq
        sudo apt-get install -y curl wget default-jdk python3 jq unzip
      elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm curl wget jdk-openjdk python jq unzip
      elif command -v dnf &>/dev/null; then
        sudo dnf install -y curl wget java-17-openjdk python3 jq unzip
      elif command -v yum &>/dev/null; then
        sudo yum install -y curl wget java-17-openjdk python3 jq unzip
      fi
      ;;
    macos)
      command -v brew &>/dev/null && brew install curl wget openjdk python3 jq
      ;;
  esac
  success "Dependensi selesai diinstall."
}

# ── Install ngrok ─────────────────────────────────────────────
install_ngrok() {
  if [[ -f "$NGROK_BIN" ]]; then
    success "ngrok sudah terinstall."
    return
  fi

  step "Menginstall ngrok..."

  local url="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-${NGROK_ARCH}.tgz"

  info "Download dari: ${DIM}$url${RESET}"
  if wget -q --show-progress -O "$SCRIPT_DIR/ngrok.tgz" "$url" 2>/dev/null || \
     curl -L --progress-bar -o "$SCRIPT_DIR/ngrok.tgz" "$url" 2>/dev/null; then
    tar -xzf "$SCRIPT_DIR/ngrok.tgz" -C "$SCRIPT_DIR/"
    rm -f "$SCRIPT_DIR/ngrok.tgz"
    chmod +x "$NGROK_BIN"
    success "ngrok berhasil diinstall."
  else
    error "Gagal download ngrok. Cek koneksi internet."
    exit 1
  fi
}

# ── Setup ngrok token ─────────────────────────────────────────
setup_ngrok_token() {
  # Cek apakah token sudah tersimpan
  if "$NGROK_BIN" config check &>/dev/null 2>&1; then
    local existing
    existing=$(grep "authtoken" ~/.config/ngrok/ngrok.yml 2>/dev/null || \
               grep "authtoken" ~/.ngrok2/ngrok.yml 2>/dev/null || echo "")
    if [[ -n "$existing" ]]; then
      success "ngrok token sudah terkonfigurasi."
      return
    fi
  fi

  clear
  echo -e "${CYAN}"
  cat << 'EOF'
  ███╗   ██╗███████╗ ██████╗██╗      ██████╗ ██╗   ██╗██████╗ 
  ████╗  ██║╚══███╔╝██╔════╝██║     ██╔═══██╗██║   ██║██╔══██╗
  ██╔██╗ ██║  ███╔╝ ██║     ██║     ██║   ██║██║   ██║██║  ██║
  ██║╚██╗██║ ███╔╝  ██║     ██║     ██║   ██║██║   ██║██║  ██║
  ██║ ╚████║███████╗╚██████╗███████╗╚██████╔╝╚██████╔╝██████╔╝
  ╚═╝  ╚═══╝╚══════╝ ╚═════╝╚══════╝ ╚═════╝  ╚═════╝ ╚═════╝ 
EOF
  echo -e "${RESET}"
  echo -e "${MAGENTA}${BOLD}  ┌─────────────────────────────────────────────────────────┐${RESET}"
  echo -e "${MAGENTA}${BOLD}  │           Setup Tunnel ngrok — NZCloud                  │${RESET}"
  echo -e "${MAGENTA}${BOLD}  └─────────────────────────────────────────────────────────┘${RESET}"
  echo ""
  echo -e "${WHITE}${BOLD}  ngrok digunakan agar server kamu bisa diakses publik${RESET}"
  echo -e "${WHITE}${BOLD}  dari mana saja tanpa port forwarding. Gratis!${RESET}"
  echo ""
  divider
  echo -e "${BOLD}  Langkah 1 — Daftar / Login ke ngrok${RESET}"
  divider
  echo ""
  echo -e "  Buka link berikut di browser kamu untuk daftar atau login:"
  echo ""
  echo -e "  ${CYAN}${BOLD}  ➜  https://ngrok.com/signup${RESET}   ${DIM}← Daftar (gratis)${RESET}"
  echo -e "  ${CYAN}${BOLD}  ➜  https://dashboard.ngrok.com${RESET}  ${DIM}← Langsung login jika sudah punya akun${RESET}"
  echo ""
  divider
  echo -e "${BOLD}  Langkah 2 — Ambil Authtoken kamu${RESET}"
  divider
  echo ""
  echo -e "  Setelah login, buka link ini untuk dapat token:"
  echo ""
  echo -e "  ${CYAN}${BOLD}  ➜  https://dashboard.ngrok.com/get-started/your-authtoken${RESET}"
  echo ""
  echo -e "  ${DIM}  Klik tombol 'Copy' di sebelah token, lalu kembali ke sini.${RESET}"
  echo ""
  divider
  echo ""

  read -rp "$(echo -e "${YELLOW}Sudah login dan punya token? Tekan Enter untuk lanjut...${RESET}")" _

  echo ""
  echo -e "${BOLD}  Langkah 3 — Paste token kamu di bawah${RESET}"
  echo ""

  local NGROK_TOKEN=""
  while true; do
    read -rp "$(echo -e "${WHITE}  Authtoken ngrok: ${RESET}")" NGROK_TOKEN
    [[ -n "$NGROK_TOKEN" ]] && break
    warn "Token tidak boleh kosong. Coba lagi."
  done

  echo ""
  step "Menyimpan token ke konfigurasi ngrok..."
  "$NGROK_BIN" config add-authtoken "$NGROK_TOKEN"
  echo ""
  success "Token berhasil disimpan! Tunnel ngrok siap digunakan."
  echo ""
  sleep 1
}

# ── Hash Password ─────────────────────────────────────────────
hash_password() {
  echo -n "$1" | sha256sum | awk '{print $1}'
}

# ── Admin Auth ────────────────────────────────────────────────
require_admin_auth() {
  if [[ ! -f "$ADMIN_FILE" ]]; then
    error "File admin.json tidak ditemukan. Jalankan setup terlebih dahulu."
    exit 1
  fi

  local stored_user stored_hash
  stored_user=$(jq -r '.username' "$ADMIN_FILE")
  stored_hash=$(jq -r '.password_hash' "$ADMIN_FILE")

  echo -e "${YELLOW}${BOLD}Autentikasi Admin Diperlukan${RESET}"
  divider
  read -rp "$(echo -e "${WHITE}Username: ${RESET}")" input_user
  read -rsp "$(echo -e "${WHITE}Password: ${RESET}")" input_pass
  echo ""

  local input_hash
  input_hash=$(hash_password "$input_pass")

  if [[ "$input_user" != "$stored_user" || "$input_hash" != "$stored_hash" ]]; then
    error "Username atau password salah!"
    exit 1
  fi
  success "Autentikasi berhasil — Selamat datang, ${stored_user}!"
  divider
}

# ── Download Server JAR ───────────────────────────────────────
download_server_jar() {
  local mc_type="$1" software="$2" version="$3" dest="$4"

  step "Mengunduh server $software $version ($mc_type)..."

  case "${software,,}" in
    paper)
      local build
      build=$(curl -s "https://api.papermc.io/v2/projects/paper/versions/$version" \
        | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['builds'][-1])")
      wget -q --show-progress -O "$dest/server.jar" \
        "https://api.papermc.io/v2/projects/paper/versions/$version/builds/$build/downloads/paper-$version-$build.jar"
      ;;
    purpur)
      wget -q --show-progress -O "$dest/server.jar" \
        "https://api.purpurmc.org/v2/purpur/$version/latest/download"
      ;;
    vanilla)
      local manifest ver_url dl_url
      manifest=$(curl -s "https://launchermeta.mojang.com/mc/game/version_manifest.json")
      ver_url=$(echo "$manifest" | python3 -c "
import sys,json
m=json.load(sys.stdin)
for v in m['versions']:
    if v['id']=='$version':
        print(v['url']); break
")
      [[ -z "$ver_url" ]] && { error "Versi '$version' tidak ditemukan."; exit 1; }
      dl_url=$(curl -s "$ver_url" | python3 -c "import sys,json; print(json.load(sys.stdin)['downloads']['server']['url'])")
      wget -q --show-progress -O "$dest/server.jar" "$dl_url"
      ;;
    bedrock)
      wget -q --show-progress -O "$dest/bedrock-server.zip" \
        "https://www.minecraft.net/bedrockdedicatedserver/bin-linux/bedrock-server-latest.zip"
      cd "$dest" && unzip -q bedrock-server.zip && rm bedrock-server.zip
      chmod +x bedrock_server
      cd - > /dev/null
      ;;
    *)
      error "Software '$software' tidak dikenali."
      exit 1
      ;;
  esac

  success "Download selesai!"
}

# ── Get Available RAM ─────────────────────────────────────────
get_available_ram() {
  local total_mb=1024
  if command -v free &>/dev/null; then
    total_mb=$(free -m | awk '/^Mem:/{print $2}')
  elif [[ "$PLATFORM" == "macos" ]]; then
    total_mb=$(( $(sysctl -n hw.memsize) / 1024 / 1024 ))
  fi
  local ram=$(( total_mb * 70 / 100 ))
  [[ $ram -lt 512 ]] && ram=512
  echo "$ram"
}

# ── Start ngrok tunnel ────────────────────────────────────────
start_ngrok() {
  source "$CONFIG_FILE"

  # Cek sudah jalan
  if [[ -f "$NGROK_PID" ]] && kill -0 "$(cat "$NGROK_PID")" 2>/dev/null; then
    info "ngrok sudah berjalan (PID: $(cat "$NGROK_PID"))"
    return
  fi

  step "Menjalankan ngrok tunnel di port ${SERVER_PORT:-25565}..."

  nohup "$NGROK_BIN" tcp "${SERVER_PORT:-25565}" \
    --log=stdout > "$NGROK_LOG" 2>&1 &
  echo $! > "$NGROK_PID"

  # Tunggu ngrok siap
  local i=0
  while [[ $i -lt 15 ]]; do
    sleep 1
    local addr
    addr=$(get_ngrok_address)
    if [[ "$addr" != "Sedang menghubungkan..." ]]; then
      break
    fi
    i=$((i+1))
  done

  if kill -0 "$(cat "$NGROK_PID")" 2>/dev/null; then
    success "ngrok tunnel aktif!"
  else
    error "ngrok gagal dijalankan. Cek log: $NGROK_LOG"
  fi
}

# ── Stop ngrok ────────────────────────────────────────────────
stop_ngrok() {
  if [[ -f "$NGROK_PID" ]]; then
    local pid
    pid=$(cat "$NGROK_PID")
    kill -SIGTERM "$pid" 2>/dev/null || true
    sleep 1
    kill -SIGKILL "$pid" 2>/dev/null || true
    rm -f "$NGROK_PID"
  fi
}

# ── Get ngrok address ─────────────────────────────────────────
get_ngrok_address() {
  # Ambil dari ngrok API lokal
  local addr=""
  addr=$(curl -s --max-time 3 http://127.0.0.1:4040/api/tunnels 2>/dev/null \
    | python3 -c "
import sys,json
try:
    d=json.load(sys.stdin)
    t=d.get('tunnels',[])
    if t:
        pub=t[0].get('public_url','')
        # Format: tcp://0.tcp.ngrok.io:PORT
        print(pub.replace('tcp://',''))
    else:
        print('Sedang menghubungkan...')
except:
    print('Sedang menghubungkan...')
" 2>/dev/null)
  echo "${addr:-Sedang menghubungkan...}"
}

# ── Start Server ──────────────────────────────────────────────
start_server() {
  source "$CONFIG_FILE"

  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    warn "Server sudah berjalan (PID: $(cat "$PID_FILE"))"
    return
  fi

  local ram
  ram=$(get_available_ram)

  step "Memulai server Minecraft: $SERVER_NAME..."
  info "RAM dialokasikan: ${ram}MB"

  if [[ "${MC_TYPE:-java}" == "java" ]]; then
    cd "$SERVER_DIR"
    nohup java \
      -Xms512M -Xmx${ram}M \
      -XX:+UseG1GC \
      -XX:+ParallelRefProcEnabled \
      -XX:MaxGCPauseMillis=200 \
      -XX:+UnlockExperimentalVMOptions \
      -XX:+DisableExplicitGC \
      -XX:G1NewSizePercent=30 \
      -XX:G1MaxNewSizePercent=40 \
      -XX:G1HeapRegionSize=8M \
      -jar server.jar nogui >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    cd - > /dev/null
  else
    cd "$SERVER_DIR"
    nohup ./bedrock_server >> "$LOG_FILE" 2>&1 &
    echo $! > "$PID_FILE"
    cd - > /dev/null
  fi

  sleep 2

  if kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    success "Server Minecraft berjalan! (PID: $(cat "$PID_FILE"))"
  else
    error "Server gagal dimulai. Cek log: $LOG_FILE"
    return 1
  fi

  # Start ngrok
  echo ""
  start_ngrok

  sleep 2

  echo ""
  divider
  local addr
  addr=$(get_ngrok_address)
  echo -e "  ${WHITE}Nama Server  :${RESET} $SERVER_NAME"
  echo -e "  ${WHITE}Port Lokal   :${RESET} ${SERVER_PORT:-25565}"
  echo -e "  ${WHITE}Alamat Publik:${RESET} ${CYAN}${BOLD}${addr}${RESET}"
  echo -e "  ${DIM}Share alamat di atas ke teman untuk connect${RESET}"
  divider
}

# ── Stop Server ───────────────────────────────────────────────
stop_server() {
  local stopped=0

  if [[ -f "$PID_FILE" ]]; then
    local pid
    pid=$(cat "$PID_FILE")
    if kill -0 "$pid" 2>/dev/null; then
      step "Menghentikan server Minecraft..."
      kill -SIGTERM "$pid" 2>/dev/null || true
      sleep 3
      kill -SIGKILL "$pid" 2>/dev/null || true
      stopped=1
    fi
    rm -f "$PID_FILE"
  fi

  if [[ -f "$NGROK_PID" ]]; then
    step "Menghentikan ngrok tunnel..."
    stop_ngrok
    stopped=1
  fi

  [[ $stopped -eq 1 ]] && success "Server dan tunnel dihentikan." || warn "Tidak ada proses yang berjalan."
}

# ── Restart ───────────────────────────────────────────────────
restart_server() {
  step "Me-restart server dan tunnel..."
  stop_server
  sleep 2
  start_server
}

# ── Server Status ─────────────────────────────────────────────
server_status() {
  source "$CONFIG_FILE" 2>/dev/null || true

  echo -e "\n${BOLD}${WHITE}Status Server:${RESET}"
  divider
  echo -e "  ${WHITE}Nama    :${RESET} ${SERVER_NAME:-N/A}"
  echo -e "  ${WHITE}Tipe    :${RESET} ${MC_TYPE:-N/A}"
  echo -e "  ${WHITE}Software:${RESET} ${SOFTWARE:-N/A} ${MC_VERSION:-}"

  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    echo -e "  ${WHITE}Minecraft:${RESET} ${GREEN}● RUNNING${RESET} (PID: $(cat "$PID_FILE"))"
  else
    echo -e "  ${WHITE}Minecraft:${RESET} ${RED}● STOPPED${RESET}"
  fi

  if [[ -f "$NGROK_PID" ]] && kill -0 "$(cat "$NGROK_PID")" 2>/dev/null; then
    local addr
    addr=$(get_ngrok_address)
    echo -e "  ${WHITE}Tunnel   :${RESET} ${GREEN}● RUNNING${RESET} (PID: $(cat "$NGROK_PID"))"
    echo -e "  ${WHITE}Alamat   :${RESET} ${CYAN}${BOLD}${addr}${RESET}"
  else
    echo -e "  ${WHITE}Tunnel   :${RESET} ${RED}● STOPPED${RESET}"
    echo -e "  ${WHITE}Alamat   :${RESET} ${DIM}Tidak tersedia${RESET}"
  fi

  divider
  echo -e "  ${DIM}RAM tersedia: $(get_available_ram) MB${RESET}"
  echo ""
}

# ── Show Logs ─────────────────────────────────────────────────
show_mc_log() {
  [[ -f "$LOG_FILE" ]] && tail -f "$LOG_FILE" || warn "Belum ada log Minecraft."
}

show_ngrok_log() {
  [[ -f "$NGROK_LOG" ]] && tail -f "$NGROK_LOG" || warn "Belum ada log ngrok."
}

# ── Update Port ───────────────────────────────────────────────
update_network() {
  source "$CONFIG_FILE"
  echo -e "\n${BOLD}${WHITE}Ganti Port Server:${RESET}"
  divider
  echo -e "  ${WHITE}Port saat ini:${RESET} ${SERVER_PORT:-25565}"
  echo ""
  read -rp "$(echo -e "${YELLOW}Port baru (kosongkan untuk skip): ${RESET}")" new_port
  if [[ -n "$new_port" ]]; then
    sed -i "s/^SERVER_PORT=.*/SERVER_PORT=$new_port/" "$CONFIG_FILE"
    [[ -f "$SERVER_DIR/server.properties" ]] && \
      sed -i "s/^server-port=.*/server-port=$new_port/" "$SERVER_DIR/server.properties"
    success "Port diperbarui ke $new_port"
    confirm_prompt "Restart server sekarang?" && restart_server
  fi
}

# ── First Setup ───────────────────────────────────────────────
run_setup() {
  print_banner
  info "Memulai setup server Minecraft pertama kali..."
  divider

  detect_platform
  info "Platform: ${BOLD}${PLATFORM}${RESET} | Arsitektur: ${BOLD}${ARCH}${RESET}"
  check_deps
  install_ngrok
  setup_ngrok_token

  mkdir -p "$SERVER_DIR"

  # [1/6] Tipe
  echo -e "\n${BOLD}${WHITE}[1/6] Pilih Tipe Minecraft:${RESET}"
  echo -e "  ${GREEN}1)${RESET} Java Edition"
  echo -e "  ${GREEN}2)${RESET} Bedrock Edition"
  read -rp "$(echo -e "${YELLOW}Pilih [1/2]: ${RESET}")" mc_choice
  case "$mc_choice" in
    1) MC_TYPE="java" ;;
    2) MC_TYPE="bedrock" ;;
    *) error "Pilihan tidak valid."; exit 1 ;;
  esac
  success "Tipe: $MC_TYPE"

  # [2/6] Software
  echo -e "\n${BOLD}${WHITE}[2/6] Pilih Software Server:${RESET}"
  if [[ "$MC_TYPE" == "java" ]]; then
    echo -e "  ${GREEN}1)${RESET} Paper   ${DIM}(Direkomendasikan)${RESET}"
    echo -e "  ${GREEN}2)${RESET} Purpur  ${DIM}(Fitur ekstra)${RESET}"
    echo -e "  ${GREEN}3)${RESET} Vanilla ${DIM}(Resmi Mojang)${RESET}"
    read -rp "$(echo -e "${YELLOW}Pilih [1/2/3]: ${RESET}")" sw_choice
    case "$sw_choice" in
      1) SOFTWARE="paper" ;;
      2) SOFTWARE="purpur" ;;
      3) SOFTWARE="vanilla" ;;
      *) error "Pilihan tidak valid."; exit 1 ;;
    esac
  else
    SOFTWARE="bedrock"
    echo -e "  ${GREEN}→${RESET} Bedrock Dedicated Server (otomatis)"
  fi
  success "Software: $SOFTWARE"

  # [3/6] Versi
  echo -e "\n${BOLD}${WHITE}[3/6] Masukkan Versi Minecraft:${RESET}"
  echo -e "  ${DIM}Contoh: 1.21.4, 1.20.4, 1.19.4${RESET}"
  read -rp "$(echo -e "${YELLOW}Versi: ${RESET}")" MC_VERSION
  [[ -z "$MC_VERSION" ]] && { error "Versi tidak boleh kosong."; exit 1; }
  success "Versi: $MC_VERSION"

  # [4/6] Nama
  echo -e "\n${BOLD}${WHITE}[4/6] Masukkan Nama Server:${RESET}"
  read -rp "$(echo -e "${YELLOW}Nama Server: ${RESET}")" SERVER_NAME
  [[ -z "$SERVER_NAME" ]] && { error "Nama tidak boleh kosong."; exit 1; }
  success "Nama: $SERVER_NAME"

  # [5/6] Admin
  echo -e "\n${BOLD}${WHITE}[5/6] Buat Akun Admin:${RESET}"
  read -rp "$(echo -e "${YELLOW}Username Admin: ${RESET}")" ADMIN_USER
  [[ -z "$ADMIN_USER" ]] && { error "Username tidak boleh kosong."; exit 1; }

  while true; do
    read -rsp "$(echo -e "${YELLOW}Password Admin: ${RESET}")" ADMIN_PASS; echo ""
    [[ -z "$ADMIN_PASS" ]] && { warn "Password tidak boleh kosong."; continue; }
    read -rsp "$(echo -e "${YELLOW}Konfirmasi Password: ${RESET}")" ADMIN_PASS2; echo ""
    [[ "$ADMIN_PASS" == "$ADMIN_PASS2" ]] && break
    warn "Password tidak cocok, coba lagi."
  done

  local pass_hash
  pass_hash=$(hash_password "$ADMIN_PASS")
  cat > "$ADMIN_FILE" << EOF
{
  "username": "$ADMIN_USER",
  "password_hash": "$pass_hash",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
  chmod 600 "$ADMIN_FILE"
  success "Akun admin '$ADMIN_USER' tersimpan."

  # [6/6] Port
  echo -e "\n${BOLD}${WHITE}[6/6] Port Server:${RESET}"
  local default_port=25565
  [[ "$MC_TYPE" == "bedrock" ]] && default_port=19132
  echo -e "  ${DIM}Default: $default_port | Alamat publik otomatis via ngrok${RESET}"
  read -rp "$(echo -e "${YELLOW}Port [$default_port]: ${RESET}")" SERVER_PORT
  SERVER_PORT="${SERVER_PORT:-$default_port}"
  success "Port: $SERVER_PORT"

  # Simpan config
  cat > "$CONFIG_FILE" << EOF
MC_TYPE=$MC_TYPE
SOFTWARE=$SOFTWARE
MC_VERSION=$MC_VERSION
SERVER_NAME=$SERVER_NAME
SERVER_PORT=$SERVER_PORT
SETUP_DATE=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
PLATFORM=$PLATFORM
EOF

  # Download server
  divider
  download_server_jar "$MC_TYPE" "$SOFTWARE" "$MC_VERSION" "$SERVER_DIR"

  # EULA & properties
  if [[ "$MC_TYPE" == "java" ]]; then
    echo "eula=true" > "$SERVER_DIR/eula.txt"
    cat > "$SERVER_DIR/server.properties" << EOF
server-name=$SERVER_NAME
server-port=$SERVER_PORT
motd=$SERVER_NAME — Powered by NZCloud
max-players=20
online-mode=true
difficulty=normal
gamemode=survival
allow-nether=true
enable-command-block=false
EOF
    success "EULA disetujui & server.properties dibuat."
  fi

  touch "$FILEMANAGER_LOCK"

  divider
  echo -e "\n${GREEN}${BOLD}Setup selesai!${RESET}\n"
  echo -e "  ${WHITE}Server  :${RESET} $SERVER_NAME"
  echo -e "  ${WHITE}Tipe    :${RESET} $MC_TYPE | $SOFTWARE $MC_VERSION"
  echo -e "  ${WHITE}Port    :${RESET} $SERVER_PORT"
  echo -e "  ${CYAN}Alamat publik otomatis via ngrok setelah server distart${RESET}"
  echo ""
}

# ── Main Menu ─────────────────────────────────────────────────
main_menu() {
  while true; do
    print_banner
    server_status

    echo -e "${BOLD}${WHITE}Menu Utama:${RESET}"
    echo -e "  ${GREEN}1)${RESET} Start Server + Tunnel"
    echo -e "  ${GREEN}2)${RESET} Stop Server + Tunnel"
    echo -e "  ${GREEN}3)${RESET} Restart Server + Tunnel"
    echo -e "  ${GREEN}4)${RESET} Lihat Log Minecraft"
    echo -e "  ${GREEN}5)${RESET} Lihat Log Tunnel (ngrok)"
    echo -e "  ${GREEN}6)${RESET} Ganti Port Server"
    echo -e "  ${GREEN}7)${RESET} Refresh Status"
    echo -e "  ${RED}0)${RESET} Keluar ${DIM}(server tetap berjalan)${RESET}"
    divider
    read -rp "$(echo -e "${YELLOW}Pilih menu: ${RESET}")" choice

    case "$choice" in
      1) start_server ;;
      2) stop_server ;;
      3) restart_server ;;
      4) show_mc_log ;;
      5) show_ngrok_log ;;
      6) update_network ;;
      7) server_status ;;
      0) info "Keluar. Server & tunnel tetap berjalan."; exit 0 ;;
      *) warn "Pilihan tidak valid." ;;
    esac

    echo ""
    read -rp "$(echo -e "${DIM}Tekan Enter untuk kembali ke menu...${RESET}")" _
  done
}

# ── Entry Point ───────────────────────────────────────────────
main() {
  detect_platform

  if [[ -f "$FILEMANAGER_LOCK" ]]; then
    print_banner
    echo -e "${MAGENTA}${BOLD}Server sudah dikonfigurasi. Login admin diperlukan.${RESET}\n"
    require_admin_auth
    main_menu
  elif [[ -f "$CONFIG_FILE" && -f "$ADMIN_FILE" ]]; then
    touch "$FILEMANAGER_LOCK"
    print_banner
    require_admin_auth
    main_menu
  else
    run_setup
    echo ""
    confirm_prompt "Start server sekarang?" && start_server
    echo ""
    confirm_prompt "Buka menu manajemen?" && main_menu
  fi
}

main "$@"
