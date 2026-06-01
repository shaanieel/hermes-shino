# Taste-Skill Folder → Canonical Name Mapping

When installing from `https://github.com/Leonxlnx/taste-skill`, the repo folder names under `skills/` do NOT match the `name:` frontmatter field in each SKILL.md. Hermes skill discovery uses `name:` — so you must rename directories.

| Repo Folder | Canonical Name (`name:` field) | Type |
|---|---|---|
| `taste-skill/` | `design-taste-frontend` | Code (default) |
| `taste-skill-v1/` | `design-taste-frontend-v1` | Code (legacy) |
| `gpt-tasteskill/` | `gpt-taste` | Code (strict) |
| `soft-skill/` | `high-end-visual-design` | Code (agency) |
| `minimalist-skill/` | `minimalist-ui` | Code (editorial) |
| `brutalist-skill/` | `industrial-brutalist-ui` | Code (brutalist) |
| `redesign-skill/` | `redesign-existing-projects` | Code (redesign) |
| `image-to-code-skill/` | `image-to-code` | Code (img→code) |
| `output-skill/` | `full-output-enforcement` | Code (anti-trunc) |
| `stitch-skill/` | `stitch-design-taste` | Code (Stitch) |
| `brandkit/` | `brandkit` | Image gen |
| `imagegen-frontend-web/` | `imagegen-frontend-web` | Image gen |
| `imagegen-frontend-mobile/` | `imagegen-frontend-mobile` | Image gen |

13 total: 10 code + 3 image-gen skills.
