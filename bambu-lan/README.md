# Bambu Lab LAN API experiments

Small Python scripts for talking to a Bambu Lab printer directly over the local network, without
Bambu Studio or the cloud. Tested on an **A1 (+ AMS Lite) in LAN Only Mode with Developer Mode on**,
firmware 01.08.01.00, from an M1 Mac mini running Bambu Connect.

## Setup

```bash
pip install paho-mqtt
python3 discover.py                     # find the printer's IP + serial
export BAMBU_HOST=192.168.x.x
export BAMBU_SERIAL=XXXXXXXXXXXXXXX
export BAMBU_ACCESS_CODE=xxxxxxxx       # printer screen: Settings > LAN Only Mode
```

Never commit the access code: anyone on the network who has it gets full control of the printer.

## What the printer exposes

| Port | Protocol | Used for | Auth |
|------|----------|----------|------|
| UDP 2021 | SSDP NOTIFY broadcasts | Discovery (IP, serial, model, mode, firmware) | none |
| 8883 | MQTT over TLS (self-signed cert) | Status reports + commands | user `bblp`, password = access code |
| 990 | Implicit FTPS | SD card file access | user `bblp`, password = access code |
| 6000 | TLS, custom JPEG framing | Camera (A1 / P1 series) | 80-byte auth packet with `bblp` + access code |
| 322 | RTSPS | Camera (X1 series only, needs "LAN liveview" enabled) | `bblp` + access code |

MQTT topics: subscribe to `device/<serial>/report`, publish to `device/<serial>/request`.
Reports are incremental: send a `pushall` first to get the full state, then merge deltas.

## Scripts

| Script | What it does |
|--------|--------------|
| `discover.py` | Lists printers on the LAN from their SSDP broadcasts |
| `bambu.py status` | Full status: state, progress, layers, temps, AMS slots; raw JSON to `status.json` |
| `bambu.py watch` | Streams live changes (state, %, layer, temps, time left) |
| `bambu.py pause\|resume\|stop` | Print control |
| `bambu.py gcode "G28 Y"` | Sends raw G-code (needs developer mode) |
| `ftp.py list` / `ftp.py upload <file> [name]` | Lists or uploads files on the SD card |
| `camera.py [n] [dir]` | Saves `n` JPEG frames (1536×1080, ~170–200 KB each) |
| `move_test.py` | Homes Y, moves the bed to Y=180 → 50 → 128, then turns motors off, grabbing a camera frame at each step |

## Results (2026-09-27)

- **Discovery**: works; the printers answer within a few seconds on UDP 2021.
- **MQTT status**: works. `pushall` returns everything: temps, `gcode_state`, `mc_percent`,
  layers, AMS tray types/colours, external spool, Wi-Fi signal, HMS errors.
- **FTPS upload**: works, with two quirks Python's `ftplib` needs patching for (see `ftp.py`):
  1. The data connection must **reuse the control connection's TLS session**, or the transfer is refused.
  2. The printer never answers the TLS `close_notify` after a `STOR`, so stock `storbinary()`
     hangs in `conn.unwrap()`. Skip the unwrap.
- **Camera**: works. Send the auth packet, then read `[16-byte header, first 4 bytes = LE payload size][JPEG]`
  forever. The A1 camera looks across the bed from the side, which is handy for checking that the bed moved.
- **Motion via G-code**: works in developer mode. `G28 Y`, `G1 Y… F3000`, `M400`, `M18` all return
  `result: success`, and the frames show the bed moving. Multiple lines can go in one `gcode_line`
  command, separated by `\n`. Home before absolute moves so the bed can't hit its end stop.

## Printers in cloud mode (X1C, P1S)

With firmware that has Authorization Control (roughly 2025+), in cloud mode without developer mode:

- MQTT login with the access code and **reading status still work** (Home Assistant relies on this).
- **Control commands** (print start/stop, G-code, motion) are **rejected** unless signed by Bambu
  Studio or Bambu Connect.
- FTPS and the port-6000 camera are expected to still work. X1-series cameras use RTSPS on port 322 instead.

This is based on known firmware behaviour; we haven't tested it on those printers. All three ports
(8883/990/6000) were open on both. For full control a printer has to go LAN Only + Developer Mode,
which disconnects it from the cloud and the Handy app.

## Remote access / Bambu Connect

- Bambu Connect has **no network API**. The only entry point is its `bambu-connect://` URL handler,
  which works on the machine it's installed on.
- Other machines on the same LAN can use these scripts directly against the printer.
- Away from home over Tailscale, you can either:
  - make the Mac hosting Bambu Connect a subnet router (`--advertise-routes=<printer-ip>/32`,
    IP forwarding on, route approved, clients use `--accept-routes`). SSDP discovery won't cross it; or
  - run a small HTTP service on that Mac bound to its Tailscale IP that wraps these scripts. This keeps
    the access code on one machine and uses a single MQTT connection (the printer allows only a few).
