#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =====================================================
# apply_ci_workflow_auto.sh
# سكربت احترافي متكامل لإنشاء / تحديث GitHub Actions
# بعد رفع التعديلات، يقوم تلقائيًا بتشغيل الـ Workflow على GitHub Actions
# =====================================================

WORKFLOW_PATH=".github/workflows/android-ci.yml"
BACKUP_DIR=".github/workflows/backups"
COMMIT_MSG="ci: replace with professional Android CI workflow (auto-trigger)"
WORKFLOW_FILE_NAME="android-ci.yml"

echo -e "\n[INFO] تشغيل السكربت الاحترافي apply_ci_workflow_auto.sh ..."

# التأكد من وجود git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[❌] هذا ليس مجلد مشروع git. تأكد أنك داخل مجلد المشروع الصحيح."
  exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "[INFO] الفرع الحالي: ${CURRENT_BRANCH}"

mkdir -p "$(dirname "${WORKFLOW_PATH}")"
mkdir -p "${BACKUP_DIR}"

# نسخة احتياطية إذا كان الملف موجودًا
if [[ -f "${WORKFLOW_PATH}" ]]; then
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  BACKUP_FILE="${BACKUP_DIR}/android-ci.yml.bak.${TIMESTAMP}"
  echo "[INFO] نسخة احتياطية من الملف القديم: ${BACKUP_FILE}"
  cp "${WORKFLOW_PATH}" "${BACKUP_FILE}"
fi

# كتابة ملف الـ workflow الجديد
cat > "${WORKFLOW_PATH}" <<'YAML'
name: Android CI (LinkApp)

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  workflow_dispatch: {}

jobs:
  build:
    name: Build & Test (assembleDebug, lint, test)
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Cache Gradle packages
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*', '**/gradle-wrapper.properties') }}
          restore-keys: |
            ${{ runner.os }}-gradle-

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Android SDK
        uses: android-actions/setup-android@v3
        with:
          api-level: 34
          target: default

      - name: Build Debug APK
        run: ./gradlew assembleDebug --stacktrace

      - name: Run Unit Tests
        run: ./gradlew testDebugUnitTest

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: LinkApp-debug-apk
          path: app/build/outputs/apk/debug/*.apk
YAML

echo "[✅] تم إنشاء ملف Workflow جديد: ${WORKFLOW_PATH}"

# تنفيذ git add / commit / push
git add "${WORKFLOW_PATH}"
if git diff --cached --quiet; then
  echo "[ℹ️] لا يوجد تغييرات جديدة لرفعها."
else
  git commit -m "${COMMIT_MSG}"
  git push origin "${CURRENT_BRANCH}"
  echo "[✅] تم رفع التغييرات إلى GitHub بنجاح."
fi

# تشغيل الـ Workflow تلقائيًا بعد الرفع
if command -v gh >/dev/null 2>&1; then
  echo "[⚙️] تشغيل الـ Workflow تلقائيًا على GitHub Actions ..."
  if gh auth status >/dev/null 2>&1; then
    gh workflow run "${WORKFLOW_FILE_NAME}" --ref "${CURRENT_BRANCH}" || echo "[⚠️] لم يتم تشغيل الـ workflow تلقائيًا (تحقق من الاسم أو صلاحيات gh)."
  else
    echo "[❌] gh CLI غير مسجّل الدخول. نفّذ: gh auth login"
  fi
else
  echo "[❌] gh CLI غير مثبت. لتشغيل الـ workflow تلقائيًا، ثبّت gh أولًا."
fi

echo "[🎯] تم تنفيذ كل الخطوات بنجاح."
echo "[➡️] تحقق الآن من صفحة Actions على GitHub لترى التنفيذ قيد العمل:"
echo "     https://github.com/Devloperjava/LinkApp/actions"
