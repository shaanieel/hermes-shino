#!/usr/bin/env bash
# Shino Hermes Agent — Install Script
# Copies all skills, memory, and config to ~/.hermes/

set -e

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================"
echo "  Shino Hermes Agent — Installer"
echo "========================================"
echo ""
echo "Hermes home: $HERMES_HOME"

# 1. Copy skills
echo ""
echo "[1/5] Installing skills..."
rsync -av --delete "$SCRIPT_DIR/skills/" "$HERMES_HOME/skills/"
echo "  ✓ Skills installed"

# 2. Copy memory
echo ""
echo "[2/5] Installing memory..."
mkdir -p "$HERMES_HOME/memories"
cp "$SCRIPT_DIR/memory/MEMORY.md" "$HERMES_HOME/memories/MEMORY.md" 2>/dev/null && echo "  ✓ MEMORY.md"
cp "$SCRIPT_DIR/memory/USER.md" "$HERMES_HOME/memories/USER.md" 2>/dev/null && echo "  ✓ USER.md"

# 3. Copy config (non-destructive — user decides)
echo ""
echo "[3/5] Config..."
if [ -f "$HERMES_HOME/config.yaml" ]; then
    echo "  ⚠ config.yaml already exists, backing up..."
    cp "$HERMES_HOME/config.yaml" "$HERMES_HOME/config.yaml.bak.$(date +%s)"
fi
cp "$SCRIPT_DIR/config/config.yaml" "$HERMES_HOME/config.yaml"
echo "  ✓ config.yaml installed"

# 4. Persona
echo ""
echo "[4/5] Persona..."
mkdir -p "$HERMES_HOME/personas"
if [ -f "$SCRIPT_DIR/persona.md" ]; then
    cp "$SCRIPT_DIR/persona.md" "$HERMES_HOME/personas/default.md"
    echo "  ✓ persona installed"
else
    echo "  ⚠ No persona.md found, skipping"
fi

# 5. Env reminder
echo ""
echo "[5/5] Environment..."
if [ -f "$HERMES_HOME/.env" ]; then
    echo "  ⚠ .env already exists — not overwriting"
else
    cp "$SCRIPT_DIR/config/env.example" "$HERMES_HOME/.env"
    echo "  ✓ env.example copied to .env"
fi

echo ""
echo "========================================"
echo "  INSTALL COMPLETE! 🎉"
echo "========================================"
echo ""
echo "Next steps:"
echo "  1. Edit ~/.hermes/.env — isi API keys"
echo "     > API keys yang WAJIB: OPENAI_API_KEY, GOOGLE_API_KEY"
echo ""
echo "  2. Jalankan Shino:"
echo "     hermes              # CLI mode"
echo "     hermes gateway run  # Telegram bot"
echo ""
echo "  3. Ganti model/provider (kalau gak pakai router9):"
echo "     hermes model"
echo ""
echo "  Enjoy! 🔥"
