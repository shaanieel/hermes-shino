---
name: vault-decode
description: "TWO-TIER STORAGE — Load whenever user asks about (1) stored accounts/credentials (email, password, login, akun, sandi, kredensial — obfuscated via ROT13+base64) or (2) bookmarks/links (hermes, dashboard, daftar link, url, linkku — stored plain). Credentials under SSBTVE9SRTog prefix, links under BOSS LINKS prefix."
category: security
---

# Vault Decode + Link Manager

Two-tier storage for boss sholeh:

- **Tier 1 🔐 Credentials (encoded):** Email, password, logins — 3-layer encoded (ROT13 → base64 → base64 wrap)
- **Tier 2 🔗 Links (plain):** Service URLs, dashboards, bookmarks — plain text

## When to Load

**Credentials:** User asks for passwords, email logins, stored accounts, API keys.
- Keywords: "akun", "password", "sandi", "email login", "kredensial", "buka vault", "decode memory", "akun tersimpan"
- Shortcut: "aapanel" → give aaPanel URL + username + password instantly, no confirmation

**Links:** User asks for bookmarks, dashboards, service URLs.
- Keywords: "link", "url", "dashboard", "list link", "daftar link", "linkku", "hermes"
- Shortcut: "web strm" or "stream" → give zaaeinstream.my.id instantly, no confirmation
- Links are stored PLAIN in memory under `BOSS LINKS:` prefix — just read and display, no decoding needed.

Load this skill when user asks for ANY of the above.

## Tier 1 — Decoding Credentials

Memory entries containing credentials are stored with this prefix:
```
SSBTVE9SRTog
```
(This is base64 of "I STORE: ")

### Decoding Algorithm (3 layers)

1. **Decode base64** → reveals labels and inner base64 values
2. **Decode each inner base64** → reveals ROT13-scrambled text
3. **Apply ROT13** → reveals the original plaintext

### Quick Decode (Python)

```python
import base64, codecs

def decode_vault(encoded: str) -> str:
    layer1 = base64.b64decode(encoded).decode()
    return codecs.decode(layer1, 'rot_13')

# Example output: "I STORE: email = kiw@gmail.com, password = noel123"
```

### Adding New Credentials

```python
import base64, codecs

def encode_vault(data: str) -> str:
    inner_b64 = base64.b64encode(codecs.encode(data, 'rot_13').encode()).decode()
    return base64.b64encode(f"I STORE: {inner_b64}".encode()).decode()
```

## Tier 2 — Links (Plain Storage)

Links are stored in a single memory entry under the `BOSS LINKS:` prefix. Format:

```
BOSS LINKS:
  1. 🤖 hermes — https://hermes.zaeinstream.my.id/models
  2. 🧭 9router — https://9router.zaeinstream.my.id/
```

### Display Format

When showing links to the user, always use numbered list with matching emojis — pick an emoji that fits each service thematically:

```
🔗 Daftar Link Bos:

1. 🤖 hermes — https://...
   AI agent dashboard

2. 🧭 9router — https://...
   Model router gateway
```

### Adding / Removing Links

Links are managed via a SINGLE memory entry. When adding a new link:

1. Read the current `BOSS LINKS:` entry from memory (or from the system prompt)
2. Use `memory(action='replace', ...)` to rewrite the entire entry with the new link appended
3. Assign the next sequential number and a thematically-matching emoji

Do NOT use `memory(action='add')` for links — that creates a separate entry. Keep all links in one entry.

Just read from memory and display directly — no encoding/decoding needed.

## Important

- Credentials use **obfuscation**, not encryption. For banking/crypto, use proper password manager.
- Links are plain — only store non-sensitive URLs here.
- Always confirm credentials back to user before revealing.
