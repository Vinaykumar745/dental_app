# DentalScan AI — Backend Setup Guide

## Prerequisites
- Node.js (v18+): https://nodejs.org
- MongoDB (local): https://www.mongodb.com/try/download/community
  OR use MongoDB Atlas (free cloud): https://cloud.mongodb.com

---

## Step 1: Install & Start MongoDB

### Option A — Local MongoDB
1. Download & install MongoDB Community Server
2. Start MongoDB service:
   - Windows: `net start MongoDB`  OR open "MongoDB" from Services
   - It runs on: mongodb://localhost:27017

### Option B — MongoDB Atlas (Cloud, free)
1. Create free account at https://cloud.mongodb.com
2. Create a cluster → Get connection string
3. Update `backend/.env`:
   MONGODB_URI=mongodb+srv://username:password@cluster.mongodb.net/dental_app

---

## Step 2: Install Backend Dependencies

Open a terminal in C:\dental_app\backend and run:

```bash
npm install
```

---

## Step 3: Start the Backend

```bash
npm run dev
```

You should see:
  ✅ MongoDB connected successfully
  🚀 DentalScan AI Backend running on http://localhost:5000

---

## Step 4: Update Flutter IP Address

In `lib/services/api_service.dart`, set the correct base URL:

- Android Emulator:  http://10.0.2.2:5000/api   ← already set
- Real Android device: http://YOUR_PC_IP:5000/api  (e.g. http://192.168.1.5:5000/api)
- Web/Desktop:  http://localhost:5000/api

To find your PC IP:
  Windows: ipconfig → look for IPv4 Address

---

## Step 5: Run Flutter App

```bash
cd C:\dental_app\dental_app
flutter pub get
flutter run
```

---

## API Endpoints

| Method | Endpoint           | Description         | Auth Required |
|--------|--------------------|---------------------|---------------|
| POST   | /api/auth/signup   | Register new user   | No            |
| POST   | /api/auth/login    | Login               | No            |
| GET    | /api/auth/me       | Get current user    | Yes           |
| POST   | /api/patients      | Create patient      | Yes           |
| GET    | /api/patients      | List patients       | Yes           |
| GET    | /api/patients/:id  | Get patient by ID   | Yes           |
| POST   | /api/scans         | Save scan result    | Yes           |
| GET    | /api/scans         | List all scans      | Yes           |
| GET    | /api/scans/:id     | Get scan by ID      | Yes           |

---

## MongoDB Collections

- `users`    — Doctor accounts (hashed passwords, JWT auth)
- `patients` — Patient records (name, age, mobile, appointment date)
- `scans`    — Scan results (cancer probability, lesion type, risk level)

---

## Troubleshooting

❌ "Cannot connect to server"
   → Make sure backend is running: cd backend && npm run dev
   → Check the IP address in api_service.dart

❌ "MongoDB connection failed"
   → Make sure MongoDB service is running
   → Check MONGODB_URI in backend/.env

❌ "flutter pub get" fails
   → Firebase packages removed. Run: flutter clean && flutter pub get
