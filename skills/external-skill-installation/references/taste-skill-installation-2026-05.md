# Taste-Skill Installation — Concrete Transcript

Session: 2026-05-29 — Installing 13 Leonxlnx/taste-skill into designer + reviewer profiles.

## Repo Structure

```
taste-skill/
├── skills/
│   ├── taste-skill/        → name: design-taste-frontend (DEFAULT)
│   ├── taste-skill-v1/      → name: design-taste-frontend-v1
│   ├── gpt-tasteskill/      → name: gpt-taste
│   ├── soft-skill/          → name: high-end-visual-design
│   ├── minimalist-skill/    → name: minimalist-ui
│   ├── brutalist-skill/     → name: industrial-brutalist-ui
│   ├── redesign-skill/      → name: redesign-existing-projects
│   ├── image-to-code-skill/ → name: image-to-code
│   ├── output-skill/        → name: full-output-enforcement
│   ├── stitch-skill/        → name: stitch-design-taste
│   ├── brandkit/            → name: brandkit (image skill)
│   ├── imagegen-frontend-web/   → name: imagegen-frontend-web (image skill)
│   └── imagegen-frontend-mobile/ → name: imagegen-frontend-mobile (image skill)
```

## Key Lesson: Folder Name ≠ Skill Name

The frontmatter `name:` field is authoritative. Example:

```yaml
# skills/taste-skill/SKILL.md
---
name: design-taste-frontend    ← This is the Hermes skill name
description: ...
---
# skills/gpt-tasteskill/SKILL.md
---
name: gpt-taste                ← NOT "gpt-tasteskill"
---
# skills/soft-skill/SKILL.md
---
name: high-end-visual-design   ← NOT "soft-skill"
---
```

## Failed Attempt (Nested Dirs)

First attempt put skills under `~/.hermes/skills/taste/<name>/` — invisible to loader. Hermes auto-discovers only flat `~/.hermes/skills/<name>/SKILL.md`.

## Working Mapping

```bash
cd /tmp && git clone --depth 1 https://github.com/Leonxlnx/taste-skill.git

# Map folder → frontmatter name
declare -A MAP=(
  [taste-skill]=design-taste-frontend
  [taste-skill-v1]=design-taste-frontend-v1
  [gpt-tasteskill]=gpt-taste
  [soft-skill]=high-end-visual-design
  [minimalist-skill]=minimalist-ui
  [brutalist-skill]=industrial-brutalist-ui
  [redesign-skill]=redesign-existing-projects
  [image-to-code-skill]=image-to-code
  [output-skill]=full-output-enforcement
  [stitch-skill]=stitch-design-taste
  [brandkit]=brandkit
  [imagegen-frontend-web]=imagegen-frontend-web
  [imagegen-frontend-mobile]=imagegen-frontend-mobile
)

for old in "${!MAP[@]}"; do
  cp -r /tmp/taste-skill/skills/$old ~/.hermes/skills/${MAP[$old]}
done
```

## SOUL.md Injection Pattern

Designer SOUL.md (skills they should load before building):

```markdown
## TASTE SKILLS (13 anti-slop design skills from @Leonxlnx/taste-skill)
Load the appropriate taste skill BEFORE building (use skill_view):
- `design-taste-frontend`: **DEFAULT** — v2 experimental, 3-dial tuning (VARIANCE/MOTION/DENSITY), brief inference, design-system map, strict em-dash ban, canonical GSAP, pre-flight check
- `gpt-taste`: Stricter GPT/Codex variant — higher layout variance, stronger GSAP, aggressive anti-slop
...

TASTE-SKILL HARD RULES (inherited from all 13 skills):
- NO em dashes (—) in code — use CSS borders, SVG, or Unicode alternatives
- NO placeholder comments like "// more sections here" — ship complete
- NO centered-column default — use asymmetric, diagonal, overlapping layouts
- NO Inter/Roboto/Arial — pick distinctive characterful fonts
- ALWAYS do pre-flight check: viewport clip test, font load check, GSAP kill check
```

Reviewer SOUL.md (audit checks derived from taste rules):

```markdown
TASTE-SKILL AUDIT CHECKS (add to your scoring):
- Em dash (—) in source code → instant FAIL on code quality
- Placeholder comments → instant FAIL on code quality
- Inter/Roboto/Arial as primary font → -3 on Anti AI-Slop
- Only centered-column layout → -3 on Layout & Spacing
- Body text below 16px anywhere → -2 on Typography
- Missing pre-flight check → -2 on Code Quality
```

## Gateway Restart Problem

`terminal(background=true)` is required because `terminal()` in foreground blocks shell wrappers (`nohup`, trailing `&`). The pattern:

```python
# WRONG — rejected
terminal("nohup hermes -p designer gateway run &")

# RIGHT
terminal("hermes -p designer gateway run", background=True, notify_on_complete=True)
```

## Multi-Bot "Chat Not Found" Pitfall

When running 3 bots (default, designer, reviewer) targeting the same Telegram group:
- Each bot token must be separately invited to the group
- Bot A in the group ≠ Bot B in the group
- `BadRequest: Chat not found` = this specific bot hasn't joined that chat
- Fix: invite the missing bot via Telegram UI → Add Member → search bot username
