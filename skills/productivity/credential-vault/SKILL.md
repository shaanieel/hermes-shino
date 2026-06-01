---
name: credential-vault
description: Store credentials (email, password, API key, token) in Hermes memory with multi-layer obfuscation so MEMORY.md looks like garbage to casual readers but can be decoded by the agent.
version: 1.0.0
triggers:
  - "simpan email/password/akun/kredensial/sandi/API key/token ku"
  - "ingetin akun/password/email untuk *"
  - "password/email * apa?"
  - user asks to store sensitive data in memory
---

# Credential Vault

Multi-layer obfuscation for storing credentials in Hermes memory.

**Language:** Indonesian (casual). **Entity reference:** user = "boss sholeh", agent = "Shino".

## Encoding (store)

Apply **three layers** of encoding in this exact order:

1. **ROT13** — shift each letter by 13 (A→N, B→O, ..., M→Z, N→A, ...)
2. **Base64** — encode the ROT13 result
3. **Base64 again** — wrap layer 2 inside a sentence: `I STORE: email = <base64>, password = <base64>` and base64-encode that whole string

Use Python's `codecs.encode(val, 'rot_13')` and `base64.b64encode()`.

Store the final single base64 string in memory using the `memory` tool with `target='memory'`.

## Decoding (retrieve)

Reverse the order:

1. **Base64 decode** outer layer → reveals sentence with inner base64 values
2. **Extract** the inner base64 strings (email, password, etc.)
3. **Base64 decode** each inner value
4. **ROT13 decode** (`codecs.decode(..., 'rot_13')`) → original plaintext

## Response style

When user asks to store: confirm with "Oke, udah disimpen bos! 🔐" and optionally show the final obfuscated string in memory.

When user asks to retrieve: decode and reply plainly with the credential values, no ceremony.

When user asks "dimana file memory-nya?": answer `~/.hermes/memories/MEMORY.md`.

## Pitfalls

- **NOT for banking/crypto keys.** This is obfuscation, not encryption. Anyone who knows the 3-layer method can reverse it. Only casual snoop protection.
- ROT13 is self-inverse in Alpha, not general case — don't try to use ROT13 as `codecs.decode(val, 'rot_13')` directly as encoding; always `codecs.encode(val, 'rot_13')` for encoding step.
- The outer wrapper must contain `I STORE:` prefix so decoding logic can identify it among other memory entries.
- Memory has a 2,200 char limit — keep combined entries compact.

## References

- `references/encoding-script.py` — reusable Python script for encode/decode
