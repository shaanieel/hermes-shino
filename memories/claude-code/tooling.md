---
name: tooling
description: "Tooling status di mesin user — git ada, gh CLI belum terpasang"
metadata: 
  node_type: memory
  type: project
  originSessionId: bf9c4a5d-d75f-4cba-ae8e-70236cf7bb24
---

- `git` tersedia di `/mingw64/bin/git` (versi 2.51.0.windows.2)
- `gh` GitHub CLI v2.92.0 terpasang di `C:\Program Files\GitHub CLI\gh.exe`
- PATH bash mungkin belum auto-load `gh.exe` — selalu prepend di awal command:
  `export PATH="/c/Program Files/GitHub CLI:$PATH"`
- Sudah login sebagai **shaanieel** dengan scope `gist, read:org, repo, workflow`
- Shell: bash (Git Bash) di Windows 11

**How to apply:** Untuk setiap command yang pakai gh, prefix dengan `export PATH="/c/Program Files/GitHub CLI:$PATH" && gh ...`. Jangan jalankan `gh auth login` (interaktif, tidak akan jalan di non-interactive shell).

Lihat juga [[pr-workflow]] untuk alur otomatis bikin PR.
