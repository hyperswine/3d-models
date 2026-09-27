#!/usr/bin/env python3
"""Find Bambu printers on the LAN by listening for their SSDP NOTIFY broadcasts (UDP 2021).
  python3 discover.py [seconds]
"""
import socket, sys, time

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
if hasattr(socket, "SO_REUSEPORT"):
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEPORT, 1)
s.bind(("", 2021)); s.settimeout(1)

seen, end = set(), time.time() + (int(sys.argv[1]) if len(sys.argv) > 1 else 15)
while time.time() < end:
    try: data, (ip, _) = s.recvfrom(4096)
    except socket.timeout: continue
    text = data.decode(errors="replace")
    if "bambulab" not in text or ip in seen: continue
    seen.add(ip)
    h = dict(l.split(": ", 1) for l in text.splitlines() if ": " in l)
    print(f"{ip:15} {h.get('DevName.bambu.com','?'):12} model={h.get('DevModel.bambu.com')} "
          f"serial={h.get('USN')} mode={h.get('DevConnect.bambu.com')} fw={h.get('DevVersion.bambu.com')}")
if not seen: print("no printers heard")
