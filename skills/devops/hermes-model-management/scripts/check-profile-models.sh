#!/usr/bin/env bash
# Cross-check all Hermes profile config model settings against router /v1/models.
# Usage: bash scripts/check-profile-models.sh [router_url]

set -euo pipefail

ROUTER_URL="${1:-http://127.0.0.1:20128/v1}"

echo "==> Fetching model list from router: ${ROUTER_URL}/models"
MODELS_JSON=$(curl -sS "${ROUTER_URL}/models")
VALID_IDS=$(echo "$MODELS_JSON" | python3 -c "
import json,sys
for m in json.load(sys.stdin)['data']:
    print(m['id'])
")

echo ""
echo "==> Checking profile configs..."
echo ""

EXIT_CODE=0

check_profile() {
    local profile="$1"
    local cfg
    if [ "$profile" = "default" ]; then
        cfg="$HOME/.hermes/config.yaml"
    else
        cfg="$HOME/.hermes/profiles/$profile/config.yaml"
    fi

    if [ ! -f "$cfg" ]; then
        echo "  [SKIP] $cfg not found"
        return
    fi

    # Extract model.default value
    local model
    model=$(python3 -c "
import yaml
with open('$cfg') as f:
    doc = yaml.safe_load(f)
print(doc.get('model', {}).get('default', 'N/A'))
" 2>/dev/null || echo "PARSE_ERROR")

    echo "  [$profile] default: $model"

    if [ "$model" = "N/A" ] || [ "$model" = "PARSE_ERROR" ]; then
        echo "    ⚠️  Could not parse model default"
        EXIT_CODE=1
        return
    fi

    if echo "$VALID_IDS" | grep -qxF "$model"; then
        echo "    ✅ Model exists in router"
    else
        echo "    ❌ Model NOT found in router /v1/models"
        echo "       Available alternatives:"
        echo "$VALID_IDS" | grep -i "$(echo "$model" | cut -d/ -f2- | cut -d/ -f1)" | head -5 | sed 's/^/         /'
        EXIT_CODE=1
    fi

    # Check fallback model if present
    local fallback
    fallback=$(python3 -c "
import yaml
with open('$cfg') as f:
    doc = yaml.safe_load(f)
fb = doc.get('fallback_model', {})
if fb:
    print(fb.get('model', 'N/A'))
" 2>/dev/null || echo "")
    if [ -n "$fallback" ] && [ "$fallback" != "N/A" ]; then
        echo "    fallback: $fallback"
        if echo "$VALID_IDS" | grep -qxF "$fallback"; then
            echo "    ✅ Fallback exists in router"
        else
            echo "    ❌ Fallback NOT found"
        fi
    fi
}

# Check all profiles
for profile in default designer reviewer; do
    dir="$HOME/.hermes/profiles/$profile"
    if [ "$profile" != "default" ] && [ ! -d "$dir" ]; then
        continue
    fi
    check_profile "$profile"
    echo ""
done

exit $EXIT_CODE
