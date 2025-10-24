#!/bin/bash
set -e

echo "⚙️ إعداد Android CI متكامل خالٍ من الأخطاء..."

mkdir -p .github/workflows/backups
BACKUP_FILE=".github/workflows/backups/android-ci.yml.bak.$(date +%Y%m%d-%H%M%S)"
WORKFLOW_FILE=".github/workflows/android-ci.yml"

if [ -f "$WORKFLOW_FILE" ]; then
  cp "$WORKFLOW_FILE" "$BACKUP_FILE"
  echo "📦 تم أخذ نسخة احتياطية من الملف القديم: $BACKUP_FILE"
fi

cat > "$WORKFLOW_FILE" <<'YAML'
name: Android CI (LinkApp)

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - name: 🧾 Checkout source code
        uses: actions/checkout@v4

      - name: ☕ Setup JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
          cache: gradle

      - name: 🔧 Prepare Gradle wrapper
        run: chmod +x ./gradlew

      - name: 🏗️ Build Debug APK
        run: ./gradlew clean assembleDebug --stacktrace

      - name: 📦 Upload Debug APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: LinkApp-debug
          path: app/build/outputs/apk/debug/app-debug.apk

  verify:
    runs-on: ubuntu-latest
    needs: build
    steps:
      - name: ✅ Verification step
        run: echo "Build completed successfully!"
YAML

echo "✅ تم إنشاء workflow جديد آمن وحديث."

git add .github/workflows/android-ci.yml
git commit -m "fix: rebuild stable Android CI workflow"
git push origin main

echo "🚀 تم رفع workflow الجديد إلى GitHub. تحقق من صفحة Actions بعد دقيقة:"
echo "👉 https://github.com/Devloperjava/LinkApp/actions"
