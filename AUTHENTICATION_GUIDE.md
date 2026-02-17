# 🔐 Authentication & Login Guide

## ✅ Admin User Configured

The admin user has been successfully created and verified in the database.

### Default Credentials

```
Username: admin
Password: admin123
```

### Admin Privileges

- **Role**: Administrateur (Full Admin)
- **Permissions**: Complete access to all modules
  - Users: CREATE, READ, UPDATE, DELETE
  - Products: CREATE, READ, UPDATE, DELETE
  - Sales: CREATE, READ, UPDATE, DELETE
  - Inventory: CREATE, READ, UPDATE, DELETE, ADJUST
  - Reports: READ, EXPORT
  - Company Settings: UPDATE
  - Cash Registers: CREATE, READ, UPDATE, DELETE
  - Dashboard: STATS
  - Stock Inventory: COUNT
  - Financial Movements: CREATE, READ, UPDATE, DELETE

---

## 🔑 How to Reset Password

If you forget the admin password, run this script:

```bash
cd backend
node scripts/reset-admin-password.js
```

This will reset the password back to `admin123`.

---

## 🧪 Testing Login via API

### Using PowerShell:

```powershell
$body = @{
    nomUtilisateur = "admin"
    motDePasse = "admin123"
} | ConvertTo-Json

$response = Invoke-WebRequest `
  -Uri "http://localhost:3002/api/v1/auth/login" `
  -Method Post `
  -Body $body `
  -ContentType "application/json"

$result = $response.Content | ConvertFrom-Json
Write-Host "Token: $($result.data.accessToken)"
```

### Using cURL:

```bash
curl -X POST http://localhost:3002/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"nomUtilisateur":"admin","motDePasse":"admin123"}'
```

### Response (200 OK):

```json
{
  "utilisateur": {
    "id": 1,
    "nomUtilisateur": "admin",
    "email": "admin@logesco.com",
    "role": {
      "nom": "admin",
      "displayName": "Administrateur",
      "isAdmin": true
    }
  },
  "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expiresIn": "24h",
  "tokenType": "Bearer"
}
```

---

## 📱 Flutter App Login

The Flutter app automatically logs in with these credentials in development mode.

### Manual Login Flow:

1. Start the app: `flutter run -d windows`
2. On the login screen, enter:
   - **Username**: admin
   - **Password**: admin123
3. Click **Login**
4. You should see the dashboard with all modules

### Development Mode:

In development mode, the app attempts automatic login:
- If no token is found, it tries to authenticate with admin/admin123
- If authentication fails, you can enter credentials manually
- Check the logs for authentication details

---

## 🛡️ Token Management

### Access Token

- **Duration**: 24 hours
- **Type**: Bearer Token (JWT)
- **Usage**: Include in all authenticated requests:

```
Authorization: Bearer <accessToken>
```

### Refresh Token

- **Duration**: 7 days
- **Purpose**: Obtain a new access token when the current one expires
- **Endpoint**: `POST /api/v1/auth/refresh`

---

## 🔒 Security Best Practices

1. **Change default password in production**
   - The admin123 password is only for development
   - Change it before deploying to production

2. **Use environment variables**
   - Store sensitive credentials in `.env` files
   - Never commit credentials to version control

3. **Enable HTTPS**
   - Use HTTPS instead of HTTP in production
   - Configure SSL certificates

4. **Rate Limiting**
   - Login endpoints have rate limiting enabled
   - Prevents brute force attacks

---

## 🔄 Creating Additional Users

To create new users with specific roles, use the admin interface in the app or the API:

```bash
POST /api/v1/users
Headers: Authorization: Bearer <adminToken>
Body: {
  "nomUtilisateur": "newuser",
  "email": "newuser@logesco.com",
  "motDePasse": "secure_password",
  "roleId": 2
}
```

---

## ❌ Troubleshooting Login Issues

### "Nom d'utilisateur ou mot de passe incorrect" (401)

**Causes:**
- Wrong username or password
- Admin user not created yet
- Password not synced with hash

**Solution:**
```bash
cd backend
node scripts/reset-admin-password.js
```

### Backend Not Responding

**Check:**
1. Backend is running: `Get-Process node`
2. Port 3002 is listening: `netstat -ano | findstr :3002`
3. Start backend: `node src/server.js`

### Token Expired (401 after 24 hours)

**Solution:**
1. Use the refresh token to get a new access token
2. Or log in again with credentials

---

## 📊 Admin Dashboard

After successful login, the admin can:

- ✅ Manage Users & Roles
- ✅ Configure Products & Inventory
- ✅ Track Sales & Revenues
- ✅ Manage Cash Registers
- ✅ View Financial Reports
- ✅ Configure Company Settings
- ✅ Access All Modules

---

**Status**: ✅ Authentication System Ready

**Last Updated**: 23 December 2025

**API Base URL**: http://localhost:3002/api/v1
