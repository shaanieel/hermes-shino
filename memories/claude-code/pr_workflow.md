---
name: pr-workflow
description: "Auto-create PR pada setiap commit baru, biar user tinggal klik \"ready to merge\""
metadata: 
  node_type: memory
  type: feedback
  originSessionId: bf9c4a5d-d75f-4cba-ae8e-70236cf7bb24
---

User mau alur kerja: setiap kali ada perubahan code yang siap dikerjakan & commit, langsung buat Pull Request di GitHub juga. User tinggal klik "Ready to merge" / "Merge pull request" di GitHub UI. Tidak perlu nunggu user minta PR dulu.

**Why:** User sudah login `gh` CLI sebagai shaanieel dengan scope `repo`+`workflow`. Workflow ini efisien — kerja langsung jadi PR, user fokus review & merge tanpa setup ulang. Disampaikan eksplisit pada 2026-05-19 setelah test alur PR pertama kali.

**How to apply:**
1. Selesai bikin perubahan, jangan langsung commit ke branch default.
2. Buat branch baru dengan nama deskriptif (pola: `codex/<topic>-<YYYY-MM-DD>` atau `feature/<topic>`).
3. **Selalu base branch baru dari `origin/<default-branch>`** (bukan branch lokal sebelumnya). User selalu sudah merge PR sebelumnya saat kasih task baru, jadi `origin/<default>` sudah berisi semua perubahan PR yang baru-baru di-merge. Branch lokal lama mungkin sudah obsolete.
4. Commit dengan pesan jelas (subject pendek + body kalau perlu).
5. Push branch: `git push -u origin <branch>`.
6. Langsung buat PR via gh CLI:
   ```
   gh pr create --base <default-branch> --head <branch> --title "..." --body "..."
   ```
   Pakai HEREDOC untuk body. Default branch tiap repo:
   - drive → `main`
   - bottelegram → `main`
   - webstream → `main`
   - adminweb1 → `devin/1777177599-initial-admin`
7. Kasih user URL PR-nya supaya bisa langsung di-merge.

**Asumsi auto-merge:** Saat user kasih task baru, anggap PR-PR sebelumnya sudah di-merge. Jangan tanya konfirmasi merge atau tunggu — langsung kerja dari `origin/<default>` yang fresh. Disampaikan eksplisit user 2026-05-19: "kalau aku udah nyuruh kamu, berarti pr sebelumnya udah aku merge".

**Catatan:** Hanya berlaku untuk repo di [[github-repos]]. Tetap konfirmasi user untuk action high-risk (force push, merge ke production, dll).

Lihat juga [[tooling]] untuk path gh CLI di Windows.
