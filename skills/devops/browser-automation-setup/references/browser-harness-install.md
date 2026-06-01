# Browser Harness Install Notes

Browser Harness connects agents to Chrome/Chromium through CDP with an editable helper workspace.

## What it is for

- Control a real browser from an agent.
- Work through complex web tasks such as uploads, forms, admin panels, testing, and screenshots.
- Let the agent add helper code in `agent-workspace/agent_helpers.py` and reusable per-site playbooks in `agent-workspace/domain-skills/`.

## Install pattern

```bash
mkdir -p ~/Developer
if [ -d ~/Developer/browser-harness/.git ]; then
  cd ~/Developer/browser-harness && git pull --ff-only
else
  git clone https://github.com/browser-use/browser-harness ~/Developer/browser-harness
  cd ~/Developer/browser-harness
fi
uv tool install -e .
mkdir -p "${CODEX_HOME:-$HOME/.codex}/skills/browser-harness"
ln -sf "$PWD/SKILL.md" "${CODEX_HOME:-$HOME/.codex}/skills/browser-harness/SKILL.md"
mkdir -p "$HOME/.hermes/skills/browser-harness"
ln -sf "$PWD/SKILL.md" "$HOME/.hermes/skills/browser-harness/SKILL.md"
browser-harness --doctor
```

## Interpreting doctor output

- Installed: `command -v browser-harness` returns a path and `browser-harness --doctor` runs.
- Connected: doctor reports daemon/active browser connections OK.
- Not connected yet: doctor may say Chrome is running but daemon/active browser connections fail. Fix by enabling remote debugging or using `BU_CDP_URL`/`BU_CDP_WS`/cloud browser.

## Quick connection test

```bash
browser-harness <<'PY'
print(page_info())
PY
```

If it asks for `chrome://inspect/#remote-debugging`, the install is present but browser attach permission/CDP discovery is missing.
