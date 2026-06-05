# AnnexPool

Ride-sharing platform for BUP students (`@student.bup.edu.bd`).

## Stack

- **Frontend:** Flutter, Riverpod, GoRouter, Dio, Socket.IO
- **Backend:** Node.js, Express, MongoDB, JWT, Socket.IO

## Quick start

### 1. Backend

```bash
cd backend
cp .env.example .env   # edit MONGO_URI if needed
npm install
npm run dev
```

Create an admin account (once):

```bash
npm run seed:admin
# Default: admin@student.bup.edu.bd / Admin@123456
```

### 2. Frontend

```bash
cd frontend
flutter pub get
flutter run -d chrome   # or android / ios
```

- **Web / iOS simulator:** API `http://localhost:8000`
- **Android emulator:** API `http://10.0.2.2:8000` (configured in `lib/core/config/app_config.dart`)

### 3. Health check

```bash
curl http://localhost:8000/api/health
```

## User roles

| Role | Capabilities |
|------|----------------|
| Rider | Request rides, join offers, chat, SOS |
| Driver+Rider | All rider features + offer rides, driver dashboard |
| Admin | Admin panel — users, reports, rides, analytics |

## Project phases (completed)

1. Architecture & setup  
2. Authentication  
3. User profiles  
4. Ride requests  
5. Ride offers  
6. Smart route matching  
7. Real-time chat  
8. Women safety & SOS  
9. Notifications (in-app + socket)  
10. Ratings & trust score  
11. Admin panel  
12. Rate limiting, docs, production notes  

## Firebase push (optional)

Register FCM token via `POST /api/notifications/fcm-token`. Add `google-services.json` / Firebase Admin credentials for device push delivery.

## Environment variables

See `backend/.env.example`.
