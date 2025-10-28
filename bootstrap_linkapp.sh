#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# ============================================================
# LinkApp: Full Android project bootstrap script (XML UI Login)
# - Creates a Kotlin Android project skeleton (Gradle KTS)
# - Adds Login screen (XML), resources (strings/colors/styles)
# - Adds ConstraintLayout & Material deps, basic placeholders for Retrofit/Room/Firebase
# - Initializes git, optionally creates/pushes to GitHub via gh or remote URL
# ============================================================

# ----------------------------
# Configuration (عدل القيم هنا قبل التشغيل)
# ----------------------------
PROJECT_NAME="LinkApp"
PACKAGE="com.example.linkapp"
APP_MODULE="app"
MIN_SDK=21
TARGET_SDK=34
COMPILE_SDK=34
KOTLIN_VERSION="1.9.20"
GRADLE_PLUGIN_VERSION="8.3.2"

# GitHub settings:
# ضع رابط المستودع هنا إن أردت الدفع تلقائياً (مثال: https://github.com/username/LinkApp.git)
GITHUB_REPO=""

# إعدادات Git للمشروع
GIT_USER_NAME="${GIT_USER_NAME:-Your Name}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-you@example.com}"

# مكان إنشاء المشروع
ROOT_DIR="$(pwd)/${PROJECT_NAME}"

# Helpers
echoinfo(){ echo -e "\033[1;34m[INFO]\033[0m $*"; }
echoerr(){ echo -e "\033[1;31m[ERROR]\033[0m $*"; }
echowarn(){ echo -e "\033[1;33m[WARN]\033[0m $*"; }

# متطلبات
command -v java >/dev/null 2>&1 || { echoerr "Java JDK مطلوب. ثبته ثم أعد المحاولة."; exit 1; }
command -v git >/dev/null 2>&1 || { echoerr "git مطلوب. ثبته ثم أعد المحاولة."; exit 1; }

GH_AVAILABLE=false
if command -v gh >/dev/null 2>&1; then
  GH_AVAILABLE=true
fi

# ----------------------------
# Create project folders
# ----------------------------
echoinfo "إنشاء مجلد المشروع: ${ROOT_DIR}"
rm -rf "${ROOT_DIR}"
mkdir -p "${ROOT_DIR}"
cd "${ROOT_DIR}"

mkdir -p "${APP_MODULE}/src/main/java/$(echo "${PACKAGE}" | tr . /)"
mkdir -p "${APP_MODULE}/src/main/res/layout"
mkdir -p "${APP_MODULE}/src/main/res/values"
mkdir -p .github/workflows

# ----------------------------
# settings.gradle.kts + build.gradle.kts (root)
# ----------------------------
cat > settings.gradle.kts <<EOF
rootProject.name = "$PROJECT_NAME"
include(":$APP_MODULE")
EOF

cat > build.gradle.kts <<EOF
plugins {
    kotlin("jvm") version "$KOTLIN_VERSION" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
EOF

# ----------------------------
# Module build.gradle.kts (app)
# ----------------------------
cat > ${APP_MODULE}/build.gradle.kts <<EOF
plugins {
    id("com.android.application")
    kotlin("android")
    id("kotlin-kapt")
}

android {
    namespace = "$PACKAGE"
    compileSdk = $COMPILE_SDK

    defaultConfig {
        applicationId = "$PACKAGE"
        minSdk = $MIN_SDK
        targetSdk = $TARGET_SDK
        versionCode = 1
        versionName = "0.1.0"
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    implementation("org.jetbrains.kotlin:kotlin-stdlib:$KOTLIN_VERSION")

    // AndroidX + Material + ConstraintLayout
    implementation("androidx.core:core-ktx:1.11.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")
    implementation("androidx.constraintlayout:constraintlayout:2.1.4")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-ktx:2.6.2")

    // Networking (placeholder)
    implementation("com.squareup.retrofit2:retrofit:2.9.0")
    implementation("com.squareup.retrofit2:converter-moshi:2.9.0")
    implementation("com.squareup.okhttp3:okhttp:4.11.0")

    // Room (local DB) placeholder
    implementation("androidx.room:room-runtime:2.5.2")
    kapt("androidx.room:room-compiler:2.5.2")
    implementation("androidx.room:room-ktx:2.5.2")

    // Coroutines
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")

    // Firebase BOM placeholders
    implementation(platform("com.google.firebase:firebase-bom:32.4.0"))
    implementation("com.google.firebase:firebase-auth-ktx")
    implementation("com.google.firebase:firebase-firestore-ktx")
    implementation("com.google.firebase:firebase-messaging-ktx")

    // Image loading
    implementation("io.coil-kt:coil:2.4.0")
}
EOF

# ----------------------------
# gradle.properties
# ----------------------------
cat > gradle.properties <<EOF
org.gradle.jvmargs=-Xmx2048m
kotlin.code.style=official
android.useAndroidX=true
EOF

# ----------------------------
# AndroidManifest.xml
# ----------------------------
cat > ${APP_MODULE}/src/main/AndroidManifest.xml <<EOF
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="${PACKAGE}">

    <uses-permission android:name="android.permission.INTERNET" />

    <application
        android:allowBackup="true"
        android:label="${PROJECT_NAME}"
        android:icon="@mipmap/ic_launcher"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:theme="@style/Theme.LinkApp">
        <activity android:name="${PACKAGE}.MainActivity"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

# ----------------------------
# MainActivity.kt (XML-based UI)
# ----------------------------
MAIN_PATH="${APP_MODULE}/src/main/java/$(echo "${PACKAGE}" | tr . /)"
cat > "${MAIN_PATH}/MainActivity.kt" <<EOF
package ${PACKAGE}

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import com.google.android.material.button.MaterialButton
import com.google.android.material.textfield.TextInputEditText
import android.widget.Toast

class MainActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val btnLogin = findViewById<MaterialButton>(R.id.btnLogin)
        val btnChat = findViewById<MaterialButton>(R.id.btnChat)
        val etUsername = findViewById<TextInputEditText>(R.id.etUsername)
        val etPassword = findViewById<TextInputEditText>(R.id.etPassword)

        btnLogin.setOnClickListener {
            val user = etUsername?.text?.toString().orEmpty()
            val pass = etPassword?.text?.toString().orEmpty()
            Toast.makeText(this, "تسجيل الدخول: \$user", Toast.LENGTH_SHORT).show()
            // هنا تضيف لوجيك المصادقة (Firebase/Auth API)
        }

        btnChat.setOnClickListener {
            Toast.makeText(this, "بدء محادثة جديدة...", Toast.LENGTH_SHORT).show()
            // فتح Activity شاشة المحادثة لاحقًا
        }
    }
}
EOF

# ----------------------------
# activity_main.xml (نكتبها باستخدام printf لتجنب BOM)
# ----------------------------
ACTIVITY_XML="${APP_MODULE}/src/main/res/layout/activity_main.xml"
printf '%s\n' '<?xml version="1.0" encoding="utf-8"?>' > "${ACTIVITY_XML}"
cat >> "${ACTIVITY_XML}" <<'EOF'
<androidx.constraintlayout.widget.ConstraintLayout
    xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:app="http://schemas.android.com/apk/res-auto"
    xmlns:tools="http://schemas.android.com/tools"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:padding="0dp"
    android:background="@color/white"
    tools:context=".MainActivity">

    <ImageView
        android:id="@+id/logoImage"
        android:layout_width="100dp"
        android:layout_height="100dp"
        android:src="@mipmap/ic_launcher"
        app:layout_constraintTop_toTopOf="parent"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_marginTop="56dp" />

    <TextView
        android:id="@+id/tvWelcome"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:text="@string/welcome_text"
        android:textColor="@android:color/black"
        android:textSize="22sp"
        android:textStyle="bold"
        android:gravity="center"
        app:layout_constraintTop_toBottomOf="@id/logoImage"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_marginTop="12dp" />

    <com.google.android.material.textfield.TextInputLayout
        android:id="@+id/usernameLayout"
        style="@style/Widget.MaterialComponents.TextInputLayout.OutlinedBox"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:hint="@string/hint_username"
        app:layout_constraintTop_toBottomOf="@id/tvWelcome"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_marginStart="28dp"
        android:layout_marginEnd="28dp"
        android:layout_marginTop="24dp">

        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/etUsername"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:inputType="textPersonName" />
    </com.google.android.material.textfield.TextInputLayout>

    <com.google.android.material.textfield.TextInputLayout
        android:id="@+id/passwordLayout"
        style="@style/Widget.MaterialComponents.TextInputLayout.OutlinedBox"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:hint="@string/hint_password"
        app:endIconMode="password_toggle"
        app:layout_constraintTop_toBottomOf="@id/usernameLayout"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_marginStart="28dp"
        android:layout_marginEnd="28dp"
        android:layout_marginTop="12dp">

        <com.google.android.material.textfield.TextInputEditText
            android:id="@+id/etPassword"
            android:layout_width="match_parent"
            android:layout_height="wrap_content"
            android:inputType="textPassword" />
    </com.google.android.material.textfield.TextInputLayout>

    <com.google.android.material.button.MaterialButton
        android:id="@+id/btnLogin"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:text="@string/action_login"
        android:textAllCaps="false"
        app:cornerRadius="12dp"
        app:layout_constraintTop_toBottomOf="@id/passwordLayout"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_marginStart="28dp"
        android:layout_marginEnd="28dp"
        android:layout_marginTop="18dp" />

    <com.google.android.material.button.MaterialButton
        android:id="@+id/btnChat"
        android:layout_width="0dp"
        android:layout_height="wrap_content"
        android:text="@string/action_start_chat"
        android:textAllCaps="false"
        app:cornerRadius="12dp"
        app:layout_constraintTop_toBottomOf="@id/btnLogin"
        app:layout_constraintStart_toStartOf="parent"
        app:layout_constraintEnd_toEndOf="parent"
        android:layout_marginStart="28dp"
        android:layout_marginEnd="28dp"
        android:layout_marginTop="12dp" />

</androidx.constraintlayout.widget.ConstraintLayout>
EOF

# ----------------------------
# strings.xml
# ----------------------------
STRINGS_XML="${APP_MODULE}/src/main/res/values/strings.xml"
printf '%s\n' '<?xml version="1.0" encoding="utf-8"?>' > "${STRINGS_XML}"
cat >> "${STRINGS_XML}" <<EOF
<resources>
    <string name="app_name">${PROJECT_NAME}</string>
    <string name="welcome_text">مرحبًا بك في LinkApp</string>
    <string name="hint_username">اسم المستخدم</string>
    <string name="hint_password">كلمة المرور</string>
    <string name="action_login">تسجيل الدخول</string>
    <string name="action_start_chat">بدء محادثة</string>
</resources>
EOF

# ----------------------------
# colors.xml و styles.xml
# ----------------------------
cat > ${APP_MODULE}/src/main/res/values/colors.xml <<EOF
<resources>
    <color name="white">#FFFFFF</color>
    <color name="purple_500">#6200EE</color>
    <color name="purple_700">#3700B3</color>
    <color name="black">#000000</color>
</resources>
EOF

cat > ${APP_MODULE}/src/main/res/values/styles.xml <<EOF
<resources>
    <style name="Theme.LinkApp" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <item name="colorPrimary">@color/purple_500</item>
        <item name="colorPrimaryVariant">@color/purple_700</item>
        <item name="colorOnPrimary">@color/white</item>
        <item name="android:statusBarColor">@color/purple_700</item>
    </style>
</resources>
EOF

# ----------------------------
# proguard (placeholder) + .gitignore + README
# ----------------------------
cat > ${APP_MODULE}/proguard-rules.pro <<EOF
# Add your proguard rules here
EOF

cat > .gitignore <<EOF
.gradle
/local.properties
/.idea
/build
/captures
.externalNativeBuild
**/build/
*.iml
.DS_Store
EOF

cat > README.md <<EOF
# ${PROJECT_NAME}

Auto-generated skeleton for LinkApp (Kotlin + XML login screen).

How to build:
1. Install Android SDK & JDK.
2. Open the project in Android Studio or run: ./gradlew :${APP_MODULE}:assembleDebug

Notes:
- Add google-services.json into ${APP_MODULE}/src if you use Firebase.
- Complete networking/auth logic (Retrofit/Firebase/Signal Protocol...) later.
EOF

# ----------------------------
# Git init & initial commit
# ----------------------------
echoinfo "تهيئة git..."
git init
git config user.name "${GIT_USER_NAME}"
git config user.email "${GIT_USER_EMAIL}"
git add .
git commit -m "chore: initial LinkApp skeleton (XML login screen, dependencies)"

# ----------------------------
# GitHub remote / gh create
# ----------------------------
if [[ -n "${GITHUB_REPO}" ]]; then
  echoinfo "Adding remote origin: ${GITHUB_REPO}"
  git remote add origin "${GITHUB_REPO}"
  git branch -M main
  echoinfo "Pushing to ${GITHUB_REPO}..."
  git push -u origin main || echowarn "Push failed: verify credentials or repo permissions."
else
  if ${GH_AVAILABLE}; then
    echoinfo "Creating GitHub repo via gh: ${PROJECT_NAME}"
    gh repo create "${PROJECT_NAME}" --public --confirm || echowarn "gh repo create failed"
    REMOTE_URL=$(git config --get remote.origin.url || true)
    if [[ -z "${REMOTE_URL}" ]]; then
      GH_USER=$(gh api user --jq .login)
      REMOTE_URL="https://github.com/${GH_USER}/${PROJECT_NAME}.git"
      git remote add origin "${REMOTE_URL}" || true
    fi
    git branch -M main
    git push -u origin main || echowarn "Push failed: check gh auth or network."
  else
    echowarn "gh CLI غير موجود ولم تقدم GITHUB_REPO — المشروع محليًا فقط."
  fi
fi

# ----------------------------
# Create a simple GitHub Actions workflow to build APK
# ----------------------------
cat > .github/workflows/android-ci.yml <<EOF
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
      - uses: actions/checkout@v4
      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          java-version: '17'
          distribution: 'temurin'
      - name: Grant execute permission for gradlew
        run: chmod +x gradlew
      - name: Build Debug APK
        run: ./gradlew :${APP_MODULE}:assembleDebug
      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: linkapp-debug-apk
          path: ${APP_MODULE}/build/outputs/apk/debug/*.apk
EOF

git add .github || true
git commit -m "ci: add Android CI workflow" || true

echoinfo "تم إنشاء مشروع ${PROJECT_NAME} في: ${ROOT_DIR}"
echoinfo "افتحه في Android Studio، مزامنة Gradle، ثم شغّل التطبيق."

echo
echoinfo "نِقاط مهمة لاحقة:"
cat <<EOF
- أضف google-services.json داخل ${APP_MODULE}/src عند استخدام Firebase.
- أكمل تحقيق المصادقة والتخزين (Firebase/Auth, Firestore or custom backend).
- لتنفيذ E2EE فعلياً، ادمج بروتوكول Signal أو libsodium (يتطلب تصميم معماري دقيق).
EOF

exit 0
