# 🎓 WowCare - Staff Management & Student Care SaaS Platform

<div align="center">

**Modern Staff Management & Student Care Platform for Educational Institutions**

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-blue.svg)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.9.2-blue.svg)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Proprietary-red.svg)](#license)

**[Features](#-key-features) • [Tech Stack](#-tech-stack) • [Quick Start](#-quick-start) • [Docs](#-documentation)**

</div>

---

## 📱 Product Overview

WowCare is a comprehensive SaaS platform designed for schools and educational institutions to manage staff scheduling, student care, real-time attendance, and operational analytics.

### Core Solutions
- **👥 Staff Management** - Schedules, shifts, attendance, performance tracking
- **🎯 Student Care** - Activity tracking, care schedules, health monitoring
- **📍 QR Attendance** - Real-time check-in/check-out with location tracking
- **📲 Notifications** - Push notifications, alerts, real-time updates
- **📊 Analytics** - Comprehensive dashboards, reports, data visualization

---

## 🎬 Product Demo

### Watch WowCare in Action
> 📹 **[CLICK HERE TO WATCH PRODUCT DEMO](https://www.youtube.com/watch?v=DEMO_VIDEO_ID)**
>
> **What you'll see:**
> - ✅ Login & authentication flow
> - ✅ Dashboard overview & real-time data
> - ✅ Staff scheduling interface
> - ✅ QR code scanning in action
> - ✅ Real-time notifications
> - ✅ Analytics & reporting
> - ✅ Mobile app features
>
> **Video Details:**
> - Duration: 3-5 minutes
> - Resolution: 1080p
> - Languages: English (with subtitles available)
> - Platform: YouTube / Loom
>
> **For Custom Video Hosting:**
> - MP4 Format: `assets/videos/wowcare-demo.mp4`
> - WebM Format: `assets/videos/wowcare-demo.webm`
> - YouTube Link: `https://youtu.be/DEMO_VIDEO_ID`
> - Loom Embed: `https://www.loom.com/embed/DEMO_ID`

---

## ✨ Key Features

### 📊 Staff Management
✅ Staff directory with detailed profiles  
✅ Real-time shift scheduling & swaps  
✅ Automated attendance tracking  
✅ Performance analytics & metrics  
✅ Leave & PTO management  
✅ Payroll integration (coming soon)  

### 👥 Student Care
✅ Comprehensive student profiles  
✅ Care schedules & rotations  
✅ Activity tracking & logs  
✅ Parent notifications & updates  
✅ Health & wellness monitoring  
✅ Incident reporting system  

### 📍 Location & Attendance
✅ QR code scanning  
✅ Real-time check-in/check-out  
✅ Geolocation tracking  
✅ Attendance reports & analytics  
✅ Historical data tracking  
✅ Batch operations support  

### 📲 Smart Notifications
✅ Push notifications  
✅ Custom alert rules  
✅ In-app messaging  
✅ Email notifications  
✅ SMS alerts (optional)  
✅ Notification history  

### 📈 Analytics & Reports
✅ Real-time dashboards  
✅ Custom report builder  
✅ Data visualization  
✅ PDF/Excel export  
✅ Performance metrics  
✅ Compliance reporting  

---

## 🏗️ Tech Stack

**Frontend (Mobile)**
- Flutter 3.9.2 | Dart 3.9.2 | BLoC State Management | Material Design 3

**Backend & Services**
- Firebase (Firestore, Storage, Messaging) | Firebase Auth | Cloud Functions

**Development**
- Gradle (Android) | Xcode (iOS) | Makefile automation | Pub package manager

**Security**
- SSL Pinning | Device Integrity Checks | Code Obfuscation | Release Signing

---

## 🚀 Quick Start

### Prerequisites
```bash
✓ Flutter 3.9.2+
✓ Dart 3.9.2+
✓ Android SDK 36+ / Xcode 15+
✓ CocoaPods (iOS)
```

### Setup
```bash
# Clone & setup
git clone https://github.com/yourorg/wowcare.git
cd wowcare2-mobile

# Install dependencies
flutter pub get
flutter pub run build_runner build

# Run (local environment)
flutter run --dart-define=ENVIRONMENT=LOCAL
```

### Build Optimized Release
```bash
# One-command production builds with size optimization
make prod-apk-optimized         # Android APK (~158 MB)
make prod-appbundle-optimized   # Google Play Bundle (~40-50 MB)
make prod-ios-optimized         # iOS release
make prod-build-optimized       # Both platforms

# Verify sizes
make check-apk-size
make analyze-apk
```

---

## 📋 Available Commands

### Build Commands
```bash
make prod-apk-optimized         ✅ Optimized APK (158 MB vs 223 MB)
make prod-appbundle-optimized   ✅ App Bundle (40-50 MB)
make prod-ios-optimized         ✅ iOS optimized
make prod-build-optimized       ✅ Complete build
```

### Size & Analysis
```bash
make check-apk-size             📊 Show APK size breakdown
make check-size                 📊 Show all build sizes
make analyze-apk                📊 Analyze APK contents
```

### Asset Optimization
```bash
make optimize-assets            🖼️ Optimize all images
make convert-png-webp           🖼️ PNG → WebP (save 25-30%)
make compress-images            🖼️ Compress JPG/PNG
```

### Development
```bash
make clean
make get
make format
make analyze
make test
```

See [MAKEFILE_OPTIMIZATION_GUIDE.md](MAKEFILE_OPTIMIZATION_GUIDE.md) for full documentation.

---

## 🌍 Environments

### LOCAL (Development)
```
API: Local server | Logging: Verbose | Build: Debug
```

### UAT (Testing)
```
API: UAT server | Logging: Standard | Build: Profile
```

### PROD (Production)
```
API: Production | Logging: Errors only | Build: Optimized Release
```

```bash
flutter run --dart-define=ENVIRONMENT=LOCAL
flutter run --dart-define=ENVIRONMENT=UAT
flutter run --dart-define=ENVIRONMENT=PROD
```

---

## 📦 App Size Optimization

**Current Status:** ✅ Optimized for Production

| Metric | Size | Savings |
|--------|------|---------|
| Original APK | 223 MB | - |
| Optimized APK | 158 MB | -29% |
| App Bundle (Play Store) | 40-50 MB | -77% |

**Optimizations Applied:**
✅ Code obfuscation (R8/ProGuard)  
✅ Resource shrinking  
✅ Icon tree-shaking (98% reduction)  
✅ Debug symbol splitting  
✅ Architecture-specific builds  

Detailed guides:
- [APP_SIZE_OPTIMIZATION_AUDIT.md](APP_SIZE_OPTIMIZATION_AUDIT.md) - Root cause analysis
- [SIZE_OPTIMIZATION_QUICK_START.md](SIZE_OPTIMIZATION_QUICK_START.md) - Quick reference
- [APP_SIZE_OPTIMIZATION_IMPLEMENTATION.md](APP_SIZE_OPTIMIZATION_IMPLEMENTATION.md) - Step-by-step

---

## 🔒 Security Features

✅ Emulator/simulator detection  
✅ Root/jailbreak detection  
✅ Screenshot prevention (sensitive screens)  
✅ Code obfuscation & minification  
✅ SSL pinning  
✅ Secure credential storage  
✅ Firebase security rules  
✅ Release signing (production)  

See [PRODUCTION_HARDENING_GUIDE.md](PRODUCTION_HARDENING_GUIDE.md) for details.

---

## 📁 Project Structure

```
wowcare2-mobile/
├── lib/
│   ├── app/                 # App configuration & routing
│   ├── core/                # Core utilities & network
│   ├── data/                # Data layer (models, repos)
│   ├── domain/              # Business logic (entities, usecases)
│   ├── presentation/        # UI layer (screens, widgets)
│   └── main.dart            # App entry point
├── android/                 # Android-specific config
├── ios/                     # iOS-specific config
├── assets/                  # Images, fonts, animations
├── pubspec.yaml             # Dart dependencies
├── Makefile                 # Build automation
└── README.md                # This file
```

---

## 📚 Documentation

**Getting Started**
- [MAKEFILE_OPTIMIZATION_GUIDE.md](MAKEFILE_OPTIMIZATION_GUIDE.md) - Command reference
- [Quick Start Guide](SIZE_OPTIMIZATION_QUICK_START.md) - 5-minute setup

**Optimization**
- [Size Optimization Audit](APP_SIZE_OPTIMIZATION_AUDIT.md) - Analysis & strategies
- [Implementation Guide](APP_SIZE_OPTIMIZATION_IMPLEMENTATION.md) - Step-by-step
- [Testing Checklist](APP_SIZE_OPTIMIZATION_CHECKLIST.md) - Verification

**Production**
- [Production Hardening](PRODUCTION_HARDENING_GUIDE.md) - Security setup
- [Deployment Guide](DEPLOYMENT_GUIDE.md) - Release procedures
- [Deployment Checklist](PRODUCTION_HARDENING_CHECKLIST.md) - Pre-release

---

## 🔄 Development Workflow

```bash
# Local development
flutter pub get
make local-run

# Code quality
make format
make analyze
make test

# Feature branch
git checkout -b feature/your-feature
# ... make changes ...
git commit -m "feat: your feature"
git push origin feature/your-feature

# Build & test
make prod-apk-optimized
adb install build/app/outputs/flutter-apk/app-release.apk

# Verify
make check-apk-size
make analyze-apk
```

---

## 🐛 Troubleshooting

**APK Build Issues**
```bash
# Clean and rebuild
make clean
flutter pub get
make prod-apk-optimized
```

**Size Still Large?**
```bash
# Analyze what's included
make analyze-apk

# Check for x86_64 (should be 0)
# See APP_SIZE_OPTIMIZATION_AUDIT.md for FFmpeg analysis
```

**iOS Build Fails**
```bash
cd ios
pod install --repo-update
cd ..
flutter pub get
```

See documentation for more troubleshooting tips.

---

## 📊 Statistics

| Metric | Value |
|--------|-------|
| Code Language | Dart 3.9.2 |
| Framework | Flutter 3.9.2 |
| Dependencies | 80+ packages |
| Min Android | API 21 (Android 5) |
| Min iOS | 15.0 |
| Architectures | arm64-v8a, armeabi-v7a |
| Environments | LOCAL, UAT, PROD |

---

## 🤝 Support

**Documentation:** See [docs/](docs/) directory  
**Issues:** Check [GitHub Issues](#)  
**Email:** support@wowcare.app  
**Website:** https://wowcare.app  

---

## 📄 License

© 2024 WowCare. All rights reserved.  
Proprietary software. Unauthorized copying prohibited.

---

## ✅ Status

**Version:** 1.0.0  
**Status:** ✅ Production Ready  
**Last Updated:** June 4, 2024  
**Build:** Optimized for mobile
