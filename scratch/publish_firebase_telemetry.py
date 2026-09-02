"""
SIH Smart Water Monitor - Firebase Real-Time Telemetry Publisher Script
Use this script to push live sensor telemetry into your Firebase project `bitronix-sih`
"""

import time
import random
import urllib.request
import json
from datetime import datetime

PROJECT_ID = "bitronix-sih"
DEVICE_ID = "SWU-001"
API_KEY = "AIzaSyDMmkKz3RIbikcofyeRNwIDlPT0KGd_Cu0"

URL = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/devices/{DEVICE_ID}/readings?key={API_KEY}"

print("=========================================================")
print(f"  SIH SMART WATER MONITOR - FIREBASE TELEMETRY PUBLISHER ")
print("=========================================================")
print(f"Target Firebase Project: {PROJECT_ID}")
print(f"Device ID: {DEVICE_ID}\n")

try:
    while True:
        # Generate realistic sensor values
        ph = round(random.uniform(6.4, 8.2), 1)
        tds = round(random.uniform(120, 480), 0)
        turbidity = round(random.uniform(0.4, 6.5), 1)
        salinity = round(random.uniform(0.15, 1.2), 2)
        temperature = round(random.uniform(22.0, 29.0), 1)

        payload = {
            "fields": {
                "deviceId": {"stringValue": DEVICE_ID},
                "ph": {"doubleValue": ph},
                "tds": {"doubleValue": tds},
                "turbidity": {"doubleValue": turbidity},
                "salinity": {"doubleValue": salinity},
                "temperature": {"doubleValue": temperature},
                "timestamp": {"timestampValue": datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')}
            }
        }

        req = urllib.request.Request(
            URL,
            data=json.dumps(payload).encode('utf-8'),
            headers={'Content-Type': 'application/json'}
        )

        try:
            with urllib.request.urlopen(req) as response:
                if response.status in [200, 201]:
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] Telemetry Published -> "
                          f"pH: {ph} | TDS: {tds} ppm | Turbidity: {turbidity} NTU | "
                          f"Salinity: {salinity} ppt | Temp: {temperature} °C")
                else:
                    print(f"Failed with status: {response.status}")
        except Exception as e:
            print(f"HTTP Request Notice: {e}")

        time.sleep(3)

except KeyboardInterrupt:
    print("\nPublisher stopped.")
