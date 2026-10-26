# 🎯 Google Login Callback URL Mismatch - Complete Fix Guide

## Problem Analysis

The callback URL mismatch is caused by **inconsistent callback URL configurations** between:
1. The mobile app (Android/iOS)
2. The Auth0 dashboard
3. Different build flavors (dev/staging/prod)

## Current Configuration

> Updated Oct 2026 — the flavor scheme split described in Step 3 below is now
> in place; this file is kept as the callback-URL reference.

### Android (`android/app/build.gradle.kts`)
- Flavor-specific `auth0Scheme` manifest placeholders:
  - Dev: `org.pecha.app.dev` (application ID `org.pecha.app.dev`, `auth0Domain` = `dev-vz6o17motc18g45h.us.auth0.com`)
  - Staging: `org.pecha.app.staging` (application ID `org.pecha.app.staging`, `auth0Domain` = `we-buddhist-prod.us.auth0.com`)
  - Prod: `org.pecha.app` (application ID `org.pecha.app`, `auth0Domain` = `we-buddhist-prod.us.auth0.com`)

### iOS (`ios/Flutter/<flavor>-<mode>.xcconfig`)
- `AUTH0_SCHEME` per flavor (`org.pecha.app.dev`, `org.pecha.app.staging`, `org.pecha.app`), referenced from `CFBundleURLSchemes` in `ios/Runner/Info.plist`.

### Dart
- `AuthService` passes `ConfigService.auth0Scheme` (from `AUTH0_SCHEME` in the
  flavor's `.env.<flavor>`, fallback `org.pecha.app`) to
  `webAuthentication(scheme:)`; it must match the native scheme above.
- Domain / client ID / audience are fetched at runtime from the backend
  `GET {BASE_API_URL}/props` (cached for offline), so the dev callback URLs must
  be registered on whichever tenant the dev backend's `/props` returns.

### The Issue
The app is using these callback URLs:
```
org.pecha.app://we-buddhist-prod.us.auth0.com/android/org.pecha.app/callback
https://we-buddhist-prod.us.auth0.com/android/org.pecha.app/callback
```

But the Auth0 dashboard likely has:
1. Old callback URLs with the old scheme (`com.pecha.app`)
2. Missing custom scheme callbacks
3. Inconsistent callbacks for dev/staging environments

## ✅ Solution

### Step 1: Update Auth0 Dashboard Configuration

Log into [Auth0 Dashboard](https://manage.auth0.com/) and configure the following callback URLs for **ALL environments**:

#### Production Environment
**Allowed Callback URLs & Allowed Logout URLs:**
```
org.pecha.app://we-buddhist-prod.us.auth0.com/android/org.pecha.app/callback
https://we-buddhist-prod.us.auth0.com/android/org.pecha.app/callback
org.pecha.app://we-buddhist-prod.us.auth0.com/ios/org.pecha.app/callback
https://we-buddhist-prod.us.auth0.com/ios/org.pecha.app/callback
```

#### Development Environment
**Allowed Callback URLs & Allowed Logout URLs:**
```
org.pecha.app.dev://we-buddhist-prod.us.auth0.com/android/org.pecha.app.dev/callback
https://we-buddhist-prod.us.auth0.com/android/org.pecha.app.dev/callback
org.pecha.app.dev://we-buddhist-prod.us.auth0.com/ios/org.pecha.app.dev/callback
https://we-buddhist-prod.us.auth0.com/ios/org.pecha.app.dev/callback
```

#### Staging Environment
**Allowed Callback URLs & Allowed Logout URLs:**
```
org.pecha.app.staging://we-buddhist-prod.us.auth0.com/android/org.pecha.app.staging/callback
https://we-buddhist-prod.us.auth0.com/android/org.pecha.app.staging/callback
org.pecha.app.staging://we-buddhist-prod.us.auth0.com/ios/org.pecha.app.staging/callback
https://we-buddhist-prod.us.auth0.com/ios/org.pecha.app.staging/callback
```

### Step 2: ~~Remove Old iOS Scheme~~ (do NOT do this)

The `webuddhist` URL scheme in iOS `Info.plist` is **required**: it is the Airbridge deep-link scheme (`webuddhist://…`, see `docs/implementation/AIRBRIDGE_SETUP.md`). It does not conflict with Auth0, which uses the flavor's `AUTH0_SCHEME`.

### Step 3: Ensure Consistent Scheme Configuration

Both Android and iOS should use flavor-specific schemes for consistency.

## 🚀 Quick Fix (If Auth0 Dashboard Changes Are Not Possible)

If you cannot modify the Auth0 dashboard immediately, ensure your app uses the **same callback URLs** that are already configured in Auth0:

1. Check what callback URLs are currently in Auth0 dashboard
2. Update the app configuration to match those URLs exactly
3. Remove any conflicting old schemes

## 📱 Testing After Fix

After updating the Auth0 dashboard:
1. Clean and rebuild the app
2. Clear app data (uninstall/reinstall)
3. Test Google login flow
4. Verify the callback is handled correctly

## ⚠️ Important Notes

- **Do not change the Auth0 domain** (`we-buddhist-prod.us.auth0.com`)
- **Do not change the client ID** unless you update all configurations
- **Ensure callback URLs match exactly** between app and Auth0 dashboard
- **Test all build flavors** (dev, staging, prod) after configuration

## 🔍 Verification Checklist

After implementing the fix:
- [ ] Callback URLs added to Auth0 dashboard for all environments
- [ ] `webuddhist` scheme still present in Info.plist (Airbridge)
- [ ] Android and iOS use consistent schemes per flavor
- [ ] Google login tested successfully
- [ ] Callback redirect works properly
- [ ] No callback URL mismatch errors in logs
