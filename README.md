# Shino Hermes Agent — Portable Configuration

Repository ini berisi semua yang dibutuhkan untuk menjalankan Shino (Hermes Agent) di VPS atau laptop lain.

## Struktur
```
hermes-shino/
├── skills/          # 151 skills yang sudah dilatih
├── memory/          # MEMORY.md + USER.md (profil boss)
├── config/          # config.yaml + env.example
├── scripts/         # Script install + cron helpers
├── persona.md       # Kepribadian Shino
├── install.sh       # Auto-install script
└── README.md
```

## Cara Install di VPS Baru / Laptop

### 1. Clone repo
```bash
git clone https://github.com/shaanieel/hermes-shino.git ~/hermes-shino
cd ~/hermes-shino
```

### 2. Install Hermes Agent
```bash
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

### 3. Install Shino config
```bash
bash install.sh
```

Script `install.sh` akan:
- Copy semua skills ke `~/.hermes/skills/`
- Copy memory/user profile
- Copy config.yaml
- Setup persona
- Remind kamu untuk isi API keys di `.env`

### 4. Setup API keys
```bash
# Edit .env, isi OPENAI_API_KEY dan GOOGLE_API_KEY minimal
cp config/env.example ~/.hermes/.env
nano ~/.hermes/.env
```

### 5. Jalankan
```bash
hermes                     # CLI interaktif
hermes gateway run         # Telegram gateway
```

## Struktur Router9 (Custom Provider)
Config ini pakai **router9** sebagai provider (custom proxy di `localhost:20128`).
Kalau VPS/laptop baru gak ada router9, ubah provider di config.yaml:
```bash
hermes model    # pilih OpenRouter atau Gemini langsung
```

## IDE / Editor Rekomendasi

### Terminal-based (paling recommended):
- **VS Code + Terminal** — edit repo di VS Code, jalanin `hermes` di integrated terminal. Best combo.
- **Warp** — terminal modern dengan AI built-in, GPU-accelerated, split panes
- **Tmux + neovim** — buat yang suka keyboard-only

### GUI IDE:
- **VS Code** — gratis, extension lengkap, terminal terintegrasi
- **Cursor** — VS Code fork dengan AI coding built-in (berbayar)
- **Windsurf** — AI-native IDE, lebih ringan dari Cursor

### Cara pakai di laptop (Windows/Mac/Linux):
1. Install Hermes Agent
2. Clone repo ini
3. Jalankan `install.sh`
4. Buka terminal / VS Code integrated terminal
5. Ketik `hermes` → Shino siap dipakai

## Cara Deploy Telegram Gateway
```bash
# Install sebagai systemd service (auto-start)
hermes gateway install

# Start
systemctl --user start hermes-gateway

# Status
hermes gateway status

# Logs
tail -f ~/.hermes/logs/gateway.log
```

## Update Skills dari VPS Utama
Kalau ada skill baru di VPS utama, jalankan:
```bash
cd ~/hermes-shino
git pull
bash install.sh
```
