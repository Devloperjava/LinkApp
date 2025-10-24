#!/bin/bash
set -e

PROJECT_NAME="LinkApp"
GITHUB_USER="Devloperjava"
REPO_URL="https://github.com/$GITHUB_USER/$PROJECT_NAME.git"

echo "🚀 بدء إنشاء مشروع Android احترافي باسم $PROJECT_NAME ..."

# حذف أي مشروع قديم بنفس الاسم
rm -rf "$PROJECT_NAME"
mkdir -p "$PROJECT_NAME/app/src/main/java/com/example/$PROJECT_NAME"
mkdir -p "$PROJECT_NAME/app/src/main/res/layout"
mkdir -p "$PROJECT_NAME/app/src/main/res/values"
mkdir -p "$PROJECT_NAME/.github/workflows"

cd "$PROJECT_NAME"

# ===== إنشاء ملفات Android أساسية =====
cat <<EOF > settings.gradle.kts
rootProject.name = "$PROJECT_NAME"
include(":app")
EOF

cat <<EOF > build.gradle.kts
plugins {
    id("com.android.application") version "8.0.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.0" apply false
}
EOF

cat <<EOF > app/build.gradle.kts
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.example.${PROJECT_NAME,,}"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.example.${PROJECT_NAME,,}"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.10.1")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}
EOF

# ===== ملفات الموارد =====
cat <<EOF > app/src/main/AndroidManifest.xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.${PROJECT_NAME,,}">
    <application
        android:label="$PROJECT_NAME"
        android:theme="@style/Theme.AppCompat.Light.NoActionBar">
        <activity android:name=".MainActivity">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

cat <<EOF > app/src/main/java/com/example/$PROJECT_NAME/MainActivity.kt
package com.example.${PROJECT_NAME,,}

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
    }
}
EOF

cat <<EOF > app/src/main/res/layout/activity_main.xml
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical">
    <TextView
        android:text="مرحبًا بك في $PROJECT_NAME!"
        android:textSize="22sp"
        android:textStyle="bold"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"/>
</LinearLayout>
EOF

cat <<EOF > app/src/main/res/values/strings.xml
<resources>
    <string name="app_name">$PROJECT_NAME</string>
</resources>
EOF

# ===== سير عمل CI/CD =====
cat <<EOF > .github/workflows/android-ci.yml
name: Android CI

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: إعداد JDK
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '17'
      - name: بناء التطبيق
        run: ./gradlew build
EOF

# ===== تهيئة git =====
git init -q
git add .
git commit -m "✨ إنشاء مشروع Android احترافي تلقائيًا"
git branch -M main

# ===== إعداد GitHub =====
if git ls-remote "$REPO_URL" &> /dev/null; then
  echo "🔗 المستودع موجود مسبقًا، سيتم التحديث..."
  git remote add origin "$REPO_URL" 2>/dev/null || git remote set-url origin "$REPO_URL"
else
  echo "🌐 إنشاء مستودع جديد على GitHub..."
  gh repo create "$GITHUB_USER/$PROJECT_NAME" --public --source=. --remote=origin --push
fi

git push -u origin main --force
echo "✅ تم إنشاء المشروع ورفعه بنجاح إلى GitHub!"
