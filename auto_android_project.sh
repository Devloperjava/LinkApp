#!/bin/bash
# =============================================
# auto_android_project.sh
# سكربت شامل لإنشاء مشروع Android متكامل (LinkApp)
# =============================================

set -e

PROJECT_NAME="LinkApp"
PROJECT_DIR=~/AndroidStudioProjects/$PROJECT_NAME
PACKAGE_NAME="com.example.linkapp"
MAIN_ACTIVITY="MainActivity"
GITHUB_USER="Devloperjava"

echo "[⚙️] بدء إنشاء مشروع Android احترافي باسم $PROJECT_NAME ..."
mkdir -p "$PROJECT_DIR/app/src/main/java/com/example/linkapp"
mkdir -p "$PROJECT_DIR/app/src/main/res/layout"
mkdir -p "$PROJECT_DIR/app/src/main/res/values"
mkdir -p "$PROJECT_DIR/gradle/wrapper"

cd "$PROJECT_DIR"

# 🧩 gradle wrapper & settings
cat > settings.gradle.kts <<EOF
rootProject.name = "$PROJECT_NAME"
include(":app")
EOF

cat > build.gradle.kts <<EOF
plugins {
    id("com.android.application") version "8.2.0" apply false
    id("org.jetbrains.kotlin.android") version "1.9.10" apply false
}
EOF

# 🧩 app/build.gradle.kts
cat > app/build.gradle.kts <<EOF
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "$PACKAGE_NAME"
    compileSdk = 34

    defaultConfig {
        applicationId = "$PACKAGE_NAME"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }
    buildFeatures {
        viewBinding = true
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.9.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
}
EOF

# 🧩 AndroidManifest.xml
cat > app/src/main/AndroidManifest.xml <<EOF
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="$PACKAGE_NAME">

    <application
        android:label="$PROJECT_NAME"
        android:theme="@style/Theme.LinkApp">
        <activity android:name=".$MAIN_ACTIVITY">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
EOF

# 🧩 MainActivity.kt
cat > app/src/main/java/com/example/linkapp/MainActivity.kt <<EOF
package $PACKAGE_NAME

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import com.example.linkapp.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.textView.text = "👋 Welcome to LinkApp!"
    }
}
EOF

# 🧩 activity_main.xml
cat > app/src/main/res/layout/activity_main.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:orientation="vertical"
    android:gravity="center"
    android:background="#FFFFFF">

    <TextView
        android:id="@+id/textView"
        android:text="Loading..."
        android:textSize="20sp"
        android:textColor="#000000"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"/>
</LinearLayout>
EOF

# 🧩 values/colors.xml & strings.xml & styles.xml
cat > app/src/main/res/values/colors.xml <<EOF
<resources>
    <color name="purple_200">#BB86FC</color>
    <color name="purple_500">#6200EE</color>
    <color name="purple_700">#3700B3</color>
    <color name="teal_200">#03DAC5</color>
</resources>
EOF

cat > app/src/main/res/values/strings.xml <<EOF
<resources>
    <string name="app_name">$PROJECT_NAME</string>
</resources>
EOF

cat > app/src/main/res/values/styles.xml <<EOF
<resources>
    <style name="Theme.LinkApp" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <item name="colorPrimary">@color/purple_500</item>
        <item name="colorPrimaryVariant">@color/purple_700</item>
        <item name="colorOnPrimary">@android:color/white</item>
    </style>
</resources>
EOF

# 🧩 gradle wrapper simulation
cat > gradlew <<'EOF'
#!/usr/bin/env bash
echo "⚠️  Simulated Gradle Wrapper — please sync in Android Studio to generate real one."
EOF
chmod +x gradlew

# 🧩 CI Workflow
mkdir -p .github/workflows
cat > .github/workflows/android-ci.yml <<EOF
name: Android CI (LinkApp)
on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
      - name: Setup JDK
        uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
      - name: Gradle Build
        run: ./gradlew assembleDebug
EOF

# 🧩 Git init & push
git init
git branch -M main
git add .
git commit -m "feat: create full Android project structure for LinkApp"

echo "[🌐] إنشاء مستودع GitHub..."
gh repo create "$GITHUB_USER/$PROJECT_NAME" --public --source=. --remote=origin --push

echo "[✅] تم إنشاء مشروع Android ورفعه بنجاح!"
echo "📍 المسار: $PROJECT_DIR"
echo "🌍 GitHub: https://github.com/$GITHUB_USER/$PROJECT_NAME"
echo "🎯 افتحه الآن في Android Studio وشغّله!"
