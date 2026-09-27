#!/usr/bin/env python3
"""Home Y, then slide the bed +50mm / -50mm, capturing camera frames at each step."""
import json, os, ssl, subprocess, time
import paho.mqtt.client as mqtt
from bambu import HOST, SERIAL, CODE, REPORT, REQUEST

replies = []
c = mqtt.Client(mqtt.CallbackAPIVersion.VERSION2, client_id="movetest")
c.username_pw_set("bblp", CODE)
ctx = ssl.create_default_context(); ctx.check_hostname = False; ctx.verify_mode = ssl.CERT_NONE
c.tls_set_context(ctx)
c.on_connect = lambda cl, *a: cl.subscribe(REPORT)
def on_msg(cl, ud, m):
    p = json.loads(m.payload).get("print", {})
    if p.get("command") == "gcode_line":
        replies.append(p); print("  printer:", p.get("result"), p.get("reason", ""))
c.on_message = on_msg
c.connect(HOST, 8883); c.loop_start(); time.sleep(1.5)

seq = 0
def send(lines, wait):
    global seq; seq += 1
    print(">>", lines.replace("\n", " | "))
    c.publish(REQUEST, json.dumps({"print": {"sequence_id": str(seq), "command": "gcode_line", "param": lines + "\n"}}))
    time.sleep(wait)

def snap(tag):
    subprocess.run(["python3", "camera.py", "1", f"frames/{tag}"], check=True, capture_output=True)
    os.replace(f"frames/{tag}/frame_0.jpg", f"frames/{tag}.jpg"); os.rmdir(f"frames/{tag}"); print("  snap", tag)

snap("0_start")
send("G28 Y", 20);                          snap("1_homed")
send("G90\nG1 Y180 F3000\nM400", 8);         snap("2_y180")
send("G1 Y50 F3000\nM400", 8);               snap("3_y50")
send("G1 Y128 F3000\nM400\nM18", 6);         snap("4_center_motors_off")
c.loop_stop(); c.disconnect()
