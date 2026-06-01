---
name: project-research
description: "Research what the community is saying about an open-source project — discussions, sentiment, recent activity. Use when the user asks 'what are people saying about X', 'check X for Y discussions', or 'is anyone talking about Z'."
version: 1.0.0
platforms: [linux, macos]
---

# Project Research — Community Intel

Find what people are saying about an open-source project: discussions, issues,
PRs, sentiment, and recent activity. Designed for VPS-hosted agents where many
standard paths are blocked (Google CAPTCHA, Reddit bot detection, X login wall,
Nitter instability).

## Trigger Conditions

Load this skill when the user asks any of:
- "What are people saying about [project]?"
- "Check X/Twitter for [topic]"
- "Is [project] trending?"
- "Any news about [project] today?"
- "How's the community reacting to [project]?"

## Workflow (ordered by reliability from VPS)

### 1. HN Algolia (best first stop)

```
https://hn.algolia.com/?query=<project+name>&sort=byDate&type=all
```

- No auth, no CAPTCHA, fast JSON-backed search
- Switch `type=comment` for discussion-only view
- Use `dateRange=last24h` for today's activity
- Covers Hacker News discussions + linked URLs (often includes X/Twitter posts)

### 2. GitHub Issues (sorted by newest)

```
https://github.com/<org>/<repo>/issues?q=sort:created-desc
```

- Shows what's actively being worked on RIGHT NOW
- Read issue titles + labels to gauge community activity
- Use `sort:updated-desc` for recently active discussions
- PR list at `?q=sort:created-desc` on the Pull Requests tab

### 3. GitHub Pulse (if available)

```
https://github.com/<org>/<repo>/pulse
```

- Shows merge activity, active PRs, and contributor stats
- May be empty for repos that don't use it — skip if blank

### 4. X/Twitter (only if xurl is configured)

See `xurl` skill for setup. Requires OAuth 2.0 PKCE — one-time manual setup.
Once configured:
```
xurl search "project name" -n 10
```

### 5. Reddit (unreliable from VPS)

`old.reddit.com` often triggers "whoa there, pardner!" bot detection.
If needed, try `old.reddit.com/r/LocalLLaMA/search?q=...` but expect blocks.

## Pitfalls

| What | Why | Fix |
|------|-----|-----|
| Google search from VPS | IP flagged, CAPTCHA wall | Skip — use HN Algolia |
| Nitter instances | Most are dead/blocked (403/connection refused) | Don't waste time trying multiple |
| X.com without login | Forces login wall for search | Use HN Algolia as proxy (X posts often linked from HN) |
| DuckDuckGo lite scraping | Returns empty from VPS IPs | Not reliable, skip |
| Reddit | Aggressive bot detection | Only as last resort |

## Output Format

When presenting findings to the user:
- Group by **freshness**: today → this week → older
- Use bullet lists with **timestamps** so the user knows what's current
- Separate **news/discussions** from **development activity** (issues/PRs)
- Include **stats** when visible (stars, forks, open/closed issues)
