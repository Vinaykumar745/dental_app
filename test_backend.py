import requests
import json
import time

base_url = "https://dentalscan-backend.onrender.com"

# 1. Signup
signup_data = {
    "name": "Test User",
    "email": f"test{int(time.time())}@example.com",
    "password": "password123",
    "age": 30,
    "mobile": "1234567890",
    "dob": "",
    "gender": "male"
}
r1 = requests.post(f"{base_url}/auth/signup", json=signup_data)
print("Signup:", r1.status_code, r1.text)

if r1.status_code == 200:
    token = r1.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    
    # 2. Save Scan
    scan_data = {
        "cancerProbability": 80.5,
        "lesionType": "Oral Leukoplakia",
        "lesionLocations": ["Tongue"],
        "riskLevel": "high",
        "recommendation": "Consult doctor immediately.",
        "imageAnalysis": [
            {"type": "Tongue", "finding": "Leukoplakia", "confidence": 92}
        ],
        "scanDate": "2026-08-18T12:00:00Z"
    }
    r2 = requests.post(f"{base_url}/scans", headers=headers, json=scan_data)
    print("Save Scan:", r2.status_code, r2.text)
    
    # 3. Get Scans
    r3 = requests.get(f"{base_url}/scans", headers=headers)
    print("Get Scans:", r3.status_code, r3.text)
