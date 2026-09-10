# Google Drive Backup/Restore Setup Guide
## Hifaz Tracker App

---

## 📋 Overview

Ye guide aapko batayegi ke Hifaz Tracker app mein Google Drive backup/restore feature ko kaise connect aur configure karein.

---

## 🔧 Step 1: Google Cloud Console Project Banayein

1. **Google Cloud Console** par jayein:
   - 🔗 https://console.cloud.google.com

2. **Sign in** karein apne Google account se

3. **Naya project create** karein:
   - Top menu mein **"Select a project"** par click karein
   - **"New Project"** par click karein
   - Project name: `Hifaz Tracker` (ya koi bhi naam dein)
   - **"Create"** par click karein

---

## 🔧 Step 2: Google Drive API Enable Karein

1. Left menu mein **"APIs & Services"** → **"Library"** par jayein

2. Search bar mein type karein: **"Google Drive API"**

3. **"Google Drive API"** par click karein

4. **"Enable"** button par click karein

---

## 🔧 Step 3: OAuth Consent Screen Configure Karein

1. Left menu mein **"APIs & Services"** → **"OAuth consent screen"** par jayein

2. **User Type** select karein:
   - ✅ **External** select karein (recommended)
   - **"Create"** par click karein

3. **App Registration** form fill karein:
   - **App name**: `Hifaz Tracker`
   - **User support email**: Apna email dalen
   - **Developer contact information**: Apna email dalen
   - **"Save and Continue"** par click karein

4. **Scopes** section:
   - **"Add or Remove Scopes"** par click karein
   - Search karein: `drive.file`
   - ✅ `drive.file` select karein (ye sirf backup files access karega)
   - **"Update"** par click karein
   - **"Save and Continue"** par click karein

5. **Test Users** section:
   - **"Add Users"** par click karein
   - Apna Google email address dalen jo backup use karega
   - **"Add"** par click karein
   - **"Save and Continue"** par click karein

6. **Summary** page par **"Back to Dashboard"** par click karein

---

## 🔧 Step 4: OAuth 2.0 Credentials Banayein

1. Left menu mein **"APIs & Services"** → **"Credentials"** par jayein

2. **"+ Create Credentials"** par click karein

3. **"OAuth client ID"** select karein

4. **Application type**: **"Android"** select karein

5. **Name**: `Hifaz Tracker Android` (ya koi bhi naam dein)

6. **Package name**: 
   ```
   com.example.huffa_tracker_5
   ```
   *(Ye aapke `android/app/src/main/AndroidManifest.xml` mein hona chahiye)*

7. **SHA-1 certificate fingerprint** dalen (Step 5 mein dekhein)

8. **"Create"** par click karein

9. **OAuth client ID** aur **Client Secret** copy karein ( zaruri hai!)

---

## 🔧 Step 5: SHA-1 Certificate Fingerprint Kaise Mile

### Debug Ke Liye (Development):

```bash
# Windows (Git Bash ya CMD mein):
keytool -list -v -alias androiddebugkey -keystore "%USERPROFILE%\.android\debug.keystore" -storepass android

# macOS / Linux:
keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android
```

### Release Ke Liye (Production):

```bash
keytool -list -v -alias <your-key-alias> -keystore <path-to-your-keystore>
```

### Output Mein Dekhein:
```
SHA1: XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX:XX
```
Ye wala SHA-1 fingerprint copy karein aur Google Cloud Console mein paste karein.

---

## 🔧 Step 6: Android Configuration

### 6.1 `android/app/build.gradle.kts` mein:

```kotlin
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.huffa_tracker_5"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.example.huffa_tracker_5"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
}
```

### 6.2 `android/settings.gradle.kts` mein:

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
}
```

### 7.3 `android/app/src/main/AndroidManifest.xml` mein:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- Internet permission (already hona chahiye) -->
    <uses-permission android:name="android.permission.INTERNET"/>
    
    <application
        android:label="Hifaz Tracker"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:usesCleartextTraffic="true"> <!-- Ye add karein -->
        
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:taskAffinity=""
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme"
                />
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
```

---

## 🔧 Step 8: Dependencies Check Karein

`pubspec.yaml` mein ye packages hona chahiye:

```yaml
dependencies:
  google_sign_in: ^6.2.2
  googleapis: ^13.2.0
  googleapis_auth: ^2.3.3
  http: ^1.2.2
```

Run karein:
```bash
flutter pub get
```

---

## 🔧 Step 9: App Build aur Test

1. **Clean build** karein:
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Android build** karein:
   ```bash
   flutter build apk --debug
   ```

3. **App install karein** aur test karein:
   - Settings mein jayein
   - "Google Drive Backup" section mein jayein
   - "Sign in with Google" par click karein
   - Google account select karein
   - "Backup" par click karein

---

## ⚠️ Common Issues aur Solutions

### Issue 1: "Sign-in failed" error
**Solution:**
- SHA-1 fingerprint sahi hai ya nahi check karein
- Package name match karta hai ya nahi

### Issue 2: "API not enabled" error
**Solution:**
- Google Drive API enable hai ya nahi check karein
- APIs & Services → Enabled APIs mein dekhein

### Issue 3: "OAuth consent screen not configured"
**Solution:**
- OAuth consent screen properly configured hai ya nahi
- Scopes sahi hain ya nahi (`drive.file`)
- Test users add kiye hain ya nahi

### Issue 4: "Quota exceeded" error
**Solution:**
- Google Drive API ki quota check karein
- Free tier mein 100 queries per day hain

---

## 📱 Testing Checklist

- [ ] Google Cloud Console project created
- [ ] Google Drive API enabled
- [ ] OAuth consent screen configured
- [ ] OAuth credentials created (Android type)
- [ ] SHA-1 fingerprint added
- [ ] Build config files updated (without `google-services` plugin)
- [ ] AndroidManifest.xml updated
- [ ] `flutter pub get` run kiya
- [ ] App build successful
- [ ] Google Sign-In working
- [ ] Backup to Google Drive working
- [ ] Restore from Google Drive working

---

## 📞 Support

Agar koi issue aaye to:
1. Ye guide dobara parhein
2. Google Cloud Console mein error messages check karein
3. Flutter documentation dekhein: https://docs.flutter.dev

---

**Last Updated**: August 30, 2026
**App Version**: 1.0.0
