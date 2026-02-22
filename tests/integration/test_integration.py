import os
import requests
import sys

url = os.environ.get("FORMATTER_URL", "http://localhost:8081")
response = requests.post(url)

if response.status_code != 200:
    print(f"FAILED: {response.status_code}")
    sys.exit(1)

print("OK")
