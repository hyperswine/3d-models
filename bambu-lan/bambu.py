#!/usr/bin/env python3
"""Minimal Bambu Lab A1 LAN-mode MQTT client.

Usage:
  export BAMBU_HOST=192.168.x.x          # printer IP (see README: discovery)
  export BAMBU_SERIAL=XXXXXXXXXXXXXXX    # printer serial
  export BAMBU_ACCESS_CODE=xxxxxxxx      # from the printer screen: Settings > LAN Only Mode
  python3 bambu.py status                # one-shot full status dump (summary + raw JSON to status.json)
  python3 bambu.py watch                 # stream live updates
  python3 bambu.py pause|resume|stop
  python3 bambu.py gcode "M104 S0"       # send a raw G-code line (developer mode)
"""
import json, os, ssl, sys, time
import paho.mqtt.client as mqtt

HOST = os.environ.get("BAMBU_HOST")
SERIAL = os.environ.get("BAMBU_SERIAL")
CODE = os.environ.get("BAMBU_ACCESS_CODE")

REPORT = f"device/{SERIAL}/report"
REQUEST = f"device/{SERIAL}/request"

_seq = 0
def cmd(section, payload):
    global _seq
    _seq += 1
    return json.dumps({section: {"sequence_id": str(_seq), **payload}})

COMMANDS = {
    "pushall": lambda: cmd("pushing", {"command": "pushall", "version": 1, "push_target": 1}),
    "pause":   lambda: cmd("print", {"command": "pause"}),
    "resume":  lambda: cmd("print", {"command": "resume"}),
    "stop":    lambda: cmd("print", {"command": "stop"}),
    "gcode":   lambda line: cmd("print", {"command": "gcode_line", "param": line + "\n"}),
}

state = {}

def merge(dst, src):
    for k, v in src.items():
        if isinstance(v, dict) and isinstance(dst.get(k), dict):
            merge(dst[k], v)
        else:
            dst[k] = v

def summary(p):
    fields = [
        ("state", "gcode_state"), ("progress %", "mc_percent"), ("mins left", "mc_remaining_time"),
        ("layer", "layer_num"), ("total layers", "total_layer_num"), ("file", "gcode_file"),
        ("nozzle °C", "nozzle_temper"), ("nozzle target", "nozzle_target_temper"),
        ("bed °C", "bed_temper"), ("bed target", "bed_target_temper"),
        ("wifi", "wifi_signal"), ("print error", "print_error"),
    ]
    for label, key in fields:
        if key in p:
            print(f"  {label:14} {p[key]}")
    for tray in p.get("ams", {}).get("ams", [{}])[0].get("tray", []) if p.get("ams") else []:
        print(f"  AMS slot {tray.get('id')}: {tray.get('tray_type','—')} #{tray.get('tray_color','')}")
    ext = p.get("vt_tray")
    if ext:
        print(f"  external spool {ext.get('tray_type','—')} #{ext.get('tray_color','')}")

def main():
    if not (HOST and SERIAL and CODE):
        sys.exit("Set BAMBU_HOST, BAMBU_SERIAL and BAMBU_ACCESS_CODE (see README).")
    action = sys.argv[1] if len(sys.argv) > 1 else "status"

    c = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id=f"cli-{os.getpid()}")
    c.username_pw_set("bblp", CODE)
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE  # printer uses a self-signed cert
    c.tls_set_context(ctx)

    done = {"flag": False}

    def on_connect(cl, ud, flags, rc, props):
        if rc != 0:
            sys.exit(f"MQTT connect failed: {rc} (wrong access code?)")
        cl.subscribe(REPORT)
        cl.publish(REQUEST, COMMANDS["pushall"]())
        if action in ("pause", "resume", "stop"):
            cl.publish(REQUEST, COMMANDS[action]()); print(f"sent {action}")
        elif action == "gcode":
            cl.publish(REQUEST, COMMANDS["gcode"](sys.argv[2])); print(f"sent gcode: {sys.argv[2]}")

    def on_message(cl, ud, msg):
        data = json.loads(msg.payload)
        merge(state, data)
        p = data.get("print", {})
        if action == "watch":
            changed = {k: v for k, v in p.items() if k in (
                "gcode_state", "mc_percent", "layer_num", "nozzle_temper", "bed_temper", "mc_remaining_time")}
            if changed:
                print(time.strftime("%H:%M:%S"), changed)
        elif p.get("command") == "push_status" and "gcode_state" in p:
            done["flag"] = True
        elif action == "gcode" and p.get("command") == "gcode_line":
            print("printer reply:", p.get("result"), p.get("reason", ""))

    c.on_connect, c.on_message = on_connect, on_message
    c.connect(HOST, 8883, keepalive=60)

    if action == "watch":
        c.loop_forever()
    c.loop_start()
    t0 = time.time()
    while not done["flag"] and time.time() - t0 < 10:
        time.sleep(0.2)
    time.sleep(0.5)
    c.loop_stop(); c.disconnect()

    if not state:
        sys.exit("No data received.")
    json.dump(state, open("status.json", "w"), indent=2)
    print(f"printer @ {HOST}")
    summary(state.get("print", {}))
    print("(full report saved to status.json)")

if __name__ == "__main__":
    main()
