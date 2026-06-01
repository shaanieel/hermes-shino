---
name: external-skill-installation
description: Install external GitHub skills (like taste-skill, superpowers, UI/UX Pro Max) into Hermes profiles. Use when importing agent skills from third-party repos.
version: 1.0.0
author: Hermes Agent
license: MIT
metadata:
  hermes:
    tags: [skills, installation, github, third-party, profiles]
    related_skills: [messaging-gateway-setup, hermes-agent-skill-authoring]
---

# External Skill Installation

## Overview

Hermes skills live under `~/.hermes/skills/<name>/SKILL.md`. External repos (taste-skill, UI/UX Pro Max, superpowers) package skills differently — some use skill installers (`npx skills add`), others just have `skills/` folders with SKILL.md files. This skill covers the common patterns for importing these into Hermes profiles.

## When to Use

- User shares a GitHub link to an agent skill repo (e.g. `https://github.com/Leonxlnx/taste-skill`)
- User asks to "install" or "add" a skill from a URL
- You need to bulk-install multiple skills from a repo into designer/reviewer/default profiles
- A profile needs awareness of newly installed skills (SOUL.md update)

Don't use for:
- Creating new skills from scratch → `skill_manage(action='create')`
- Editing existing skills → `skill_manage(action='patch')`
- In-repo skill authoring → `hermes-agent-skill-authoring`

## Workflow

### Phase 1: Discover

1. **Clone the repo shallow:**
   ```bash
   cd /tmp && git clone --depth 1 <repo-url> <name>
   ```

2. **Explore structure.** Common patterns:
   - `skills/<name>/SKILL.md` — multiple skills in a `skills/` folder
   - `SKILL.md` at repo root — single-skill repo
   - `skills/<name>/` with sub-structure (`references/`, `templates/`, `scripts/`)

3. **Read the README** first — it usually lists all skill names and install commands.

4. **Read frontmatter** of each SKILL.md to extract the `name:` field. This is the Hermes skill name, NOT the folder name.

```bash
head -5 /tmp/taste-skill/skills/taste-skill/SKILL.md
# ---
# name: design-taste-frontend     ← USE THIS, not "taste-skill"
# description: ...
# ---
```

### Phase 2: Install to Default Profile

Skills must live at `~/.hermes/skills/<name>/`, NOT nested like `~/.hermes/skills/<category>/<name>/`. Hermes auto-discovers flat directories; nested categories are invisible.

```bash
cp -r /tmp/<repo>/skills/<folder>/ ~/.hermes/skills/<frontmatter-name>/
```

For repos with a `skills/` folder containing multiple skills, map each folder to its frontmatter `name:`:

```bash
# Example: taste-skill repo
cp -r /tmp/taste-skill/skills/taste-skill/   ~/.hermes/skills/design-taste-frontend/
cp -r /tmp/taste-skill/skills/gpt-tasteskill/ ~/.hermes/skills/gpt-taste/
# ... repeat for all 13 skills
```

### Phase 3: Sync to Target Profiles

If skills are for specific profiles (designer, reviewer), copy them there too:

```bash
for name in <skill1> <skill2> ...; do
  cp -r ~/.hermes/skills/$name ~/.hermes/profiles/designer/skills/$name
  cp -r ~/.hermes/skills/$name ~/.hermes/profiles/reviewer/skills/$name
done
```

### Phase 4: Inject Awareness into SOUL.md

Profiles need to know the skills exist. Patch each profile's `SOUL.md` with a skills section:

```markdown
## TASTE SKILLS (13 anti-slop design skills from @Leonxlnx/taste-skill)
Load the appropriate taste skill BEFORE building (use skill_view):
- `design-taste-frontend`: **DEFAULT** — v2 experimental, 3-dial tuning
- `gpt-taste`: Stricter GPT/Codex variant
...
```

Include hard rules derived from the skills so the agent follows them even without explicitly loading each skill.

### Phase 5: Restart Gateway

```bash
# Kill existing
pkill -f "hermes.*-p designer"
pkill -f "hermes.*-p reviewer"

# Restart
hermes -p designer gateway run &
hermes -p reviewer gateway run &
```

**Critical:** Do NOT use shell-level background wrappers (`nohup`, `disown`, trailing `&`) in foreground `terminal()` calls — Hermes blocks them. Use `terminal(background=true)` instead.

### Phase 6: Verify

```bash
ls ~/.hermes/skills/ | grep <skill-prefix>
# Should list all expected skill directories
```

Then in a Hermes session: `skill_view(name='<skill-name>')` to confirm it loads.

## Common Pitfalls

1. **Nested directories.** Installing to `~/.hermes/skills/taste/<name>/` makes skills invisible to the loader. Always flat: `~/.hermes/skills/<name>/`.

2. **Using folder name instead of frontmatter name.** The `name:` field in YAML frontmatter is the canonical skill name. The folder is just a container. Always extract `name:` from SKILL.md.

3. **Skipping SOUL.md update.** The agent persona won't discover new skills from filesystem alone — SOUL.md must enumerate them with load triggers.

4. **Forgetting profile-specific copies.** Skills in `~/.hermes/skills/` (default profile) don't automatically appear in `~/.hermes/profiles/<name>/skills/`. Copy explicitly when skills are for named profiles.

5. **Restarting gateway wrong.** Shell wrappers (`nohup`, `&` in foreground) are blocked. Use `terminal(background=true)` or manual start in a separate shell.

6. **Skill loader caching.** The current session won't see newly installed skills until a fresh session starts. This is expected — verify in a new session.

7. **Repo has no SKILL.md at root.** Many repos (like taste-skill) keep skills in a `skills/` subfolder. Explore the repo structure before assuming it's broken.

8. **Category subdirectory trap.** `skill_manage(action='create', category='x')` creates `~/.hermes/skills/x/<name>/` — nested and INVISIBLE to the loader. After creating with category, manually move it to `~/.hermes/skills/<name>/` with `cp -r && rm -rf`.

## References

- `references/taste-skill-installation-2026-05.md` — Concrete transcript of installing all 13 taste-skill skills with frontmatter name mapping.

## Verification Checklist

- [ ] Repo cloned and explored
- [ ] All skill names extracted from YAML frontmatter `name:` fields
- [ ] Skills copied to `~/.hermes/skills/<name>/` (flat, no nesting)
- [ ] Skills synced to all target profile directories
- [ ] SOUL.md updated with skill names, descriptions, and hard rules
- [ ] Gateway restarted for each affected profile
- [ ] `skill_view(name='<skill-name>')` succeeds in a fresh session
