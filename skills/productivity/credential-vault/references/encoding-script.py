"""
Credential Vault — encode/decode utilities.
Used by Hermes agent to obfuscate credentials in MEMORY.md.
"""
import base64
import codecs
import re


def encode(email: str, password: str) -> str:
    """
    Encode email + password with 3-layer obfuscation:
    ROT13 → base64 → wrapper base64.
    Returns the final string to store in memory.
    """
    e_rot = codecs.encode(email, "rot_13")
    p_rot = codecs.encode(password, "rot_13")
    e_b64 = base64.b64encode(e_rot.encode()).decode()
    p_b64 = base64.b64encode(p_rot.encode()).decode()
    payload = f"I STORE: email = {e_b64}, password = {p_b64}"
    return base64.b64encode(payload.encode()).decode()


def decode(vault_entry: str) -> tuple[str, str]:
    """
    Decode a vault entry string from memory back to (email, password).
    """
    # Layer 1: outer base64
    inner = base64.b64decode(vault_entry.encode()).decode()
    # Extract inner base64 values
    m = re.search(r"email = (\S+), password = (\S+)", inner)
    if not m:
        raise ValueError(f"Cannot parse vault entry: {inner}")
    e_b64, p_b64 = m.group(1), m.group(2)
    # Layer 2: inner base64 → ROT13
    e_rot = base64.b64decode(e_b64.encode()).decode()
    p_rot = base64.b64decode(p_b64.encode()).decode()
    # Layer 3: ROT13 → plaintext
    email = codecs.decode(e_rot, "rot_13")
    password = codecs.decode(p_rot, "rot_13")
    return email, password


if __name__ == "__main__":
    import sys

    if len(sys.argv) < 3:
        print("Usage: python encoding-script.py encode <email> <password>")
        print("       python encoding-script.py decode <vault_string>")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "encode":
        result = encode(sys.argv[2], sys.argv[3])
        print(result)
    elif cmd == "decode":
        email, password = decode(sys.argv[2])
        print(f"Email: {email}\nPassword: {password}")
