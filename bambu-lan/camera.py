#!/usr/bin/env python3
"""Grab JPEG frames from the A1/P1 camera stream (TLS, port 6000).
  python3 camera.py [n_frames] [out_dir]
"""
import os, socket, ssl, struct, sys

HOST = os.environ["BAMBU_HOST"]
CODE = os.environ["BAMBU_ACCESS_CODE"]
n = int(sys.argv[1]) if len(sys.argv) > 1 else 3
out = sys.argv[2] if len(sys.argv) > 2 else "frames"
os.makedirs(out, exist_ok=True)

auth = struct.pack("<IIII", 0x40, 0x3000, 0, 0) + b"bblp".ljust(32, b"\0") + CODE.encode().ljust(32, b"\0")
ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE
s = ctx.wrap_socket(socket.create_connection((HOST, 6000), timeout=15), server_hostname=HOST)
s.sendall(auth)

def recv_exact(k):
    b = b""
    while len(b) < k:
        chunk = s.recv(k - len(b))
        if not chunk: raise ConnectionError("stream closed")
        b += chunk
    return b

for i in range(n):
    size = struct.unpack("<I", recv_exact(16)[:4])[0]
    jpg = recv_exact(size)
    assert jpg[:2] == b"\xff\xd8", "not a JPEG"
    path = f"{out}/frame_{i}.jpg"
    open(path, "wb").write(jpg); print(f"{path} ({size} bytes)")
s.close()
