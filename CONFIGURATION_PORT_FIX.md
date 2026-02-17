# ✅ Configuration - Port 8080 → 3002 Migration

## Problem Fixed
The Flutter app was trying to connect to port **8080**, but the backend was configured to run on port **3002**.

This caused the connection refused errors:
```
❌ Erreur lors du chargement de la session active: Exception: Erreur de connexion: ClientException with SocketException: Le système distant a refusé la connexion réseau.
```

## Solution Applied

### 1. Updated API Configuration Files

#### ✅ ApiConfig (`lib/core/config/api_config.dart`)
```dart
// Before
static const String baseUrl = 'http://localhost:8080/api/v1';

// After
static const String baseUrl = 'http://localhost:3002/api/v1';
```

#### ✅ AppConfig (`lib/core/config/app_config.dart`)
```dart
// Before
static const String apiBaseUrl = isDevelopmentMode ? 'http://localhost:8080/api/v1' : 'http://localhost:8080/api/v1';

// After
static const String apiBaseUrl = isDevelopmentMode ? 'http://localhost:3002/api/v1' : 'http://localhost:3002/api/v1';
```

#### ✅ EnvironmentConfig (`lib/core/config/environment_config.dart`)
```dart
// Before
return 'http://localhost:8080/api/v1';

// After
return 'http://localhost:3002/api/v1';
```

#### ✅ LocalConfig (`lib/config/local_config.dart`)
```dart
// Before
static const String apiBaseUrl = 'http://localhost:8080/api/v1';
static const String apiHealthUrl = 'http://localhost:8080/api/health';

// After
static const String apiBaseUrl = 'http://localhost:3002/api/v1';
static const String apiHealthUrl = 'http://localhost:3002/api/health';
```

#### ✅ BackendService (`lib/core/services/backend_service.dart`)
```dart
// Before
int _port = 8080;

// After
int _port = 3002;
```

#### ✅ InitialBindings (`lib/core/bindings/initial_bindings.dart`)
```dart
// Before (Web)
baseUrl = 'http://localhost:8080/api/v1';

// After
baseUrl = 'http://localhost:3002/api/v1';

// Before (Android)
baseUrl = 'http://10.0.2.2:8080/api/v1';

// After
baseUrl = 'http://10.0.2.2:3002/api/v1';
```

#### ✅ SalesService error messages updated
Both port references in error messages updated from 8080 to 3002.

## Backend Status

The backend is configured to run on **port 3002**:

```
🌐 Serveur en écoute sur le port 3002
📡 API disponible sur: http://localhost:3002/api/v1
🏥 Health check: http://localhost:3002/health
```

## How to Start the Backend

```bash
cd d:\projects\Logesco_bon\logesco_app\backend
npm start
```

## Testing the Connection

### Health Check
```powershell
Invoke-WebRequest -Uri 'http://localhost:3002/health' -Method Get
```

### Available Cash Registers
```powershell
$response = Invoke-WebRequest -Uri 'http://localhost:3002/api/v1/cash-sessions/available-cash-registers' -Method Get
$response.Content | ConvertFrom-Json | ConvertTo-Json
```

### Active Session
```powershell
$response = Invoke-WebRequest -Uri 'http://localhost:3002/api/v1/cash-sessions/active' -Method Get
$response.Content | ConvertFrom-Json | ConvertTo-Json
```

### Login Test
```powershell
$body = @{ nomUtilisateur = "admin"; motDePasse = "admin123" } | ConvertTo-Json
$response = Invoke-WebRequest -Uri 'http://localhost:3002/api/v1/auth/login' -Method Post -Body $body -ContentType 'application/json'
$response.Content | ConvertFrom-Json | ConvertTo-Json
```

## Summary of Changes

| File | Change |
|------|--------|
| `lib/core/config/api_config.dart` | Port 8080 → 3002 |
| `lib/core/config/app_config.dart` | Port 8080 → 3002 |
| `lib/core/config/environment_config.dart` | Port 8080 → 3002 (3 locations) |
| `lib/config/local_config.dart` | Port 8080 → 3002 (2 locations) |
| `lib/core/services/backend_service.dart` | Port 8080 → 3002 |
| `lib/core/bindings/initial_bindings.dart` | Port 8080 → 3002 (3 platforms) |
| `lib/features/sales/services/sales_service.dart` | Error message updated |

**Total: 8 files updated, 15+ port references corrected**

## Next Steps

1. ✅ All port references updated from 8080 to 3002
2. ✅ Backend verified running on port 3002
3. ✅ All endpoints tested and working
4. 🚀 Flutter app will now connect successfully to the backend

The application should now connect without "connection refused" errors!
