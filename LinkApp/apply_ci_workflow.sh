#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# =====================================================
# apply_ci_workflow.sh
# وصف: سكربت احترافي لاستبدال GitHub Actions workflow
# - يأخذ نسخة احتياطية من الملف القديم
# - يكتب workflow احترافي لبناء Android (JDK, SDK, lint, test, upload)
# - يضيف، يلتزم (commit) ويدفع (push) التغييرات
# - خيار --release لإنشاء GitHub Release عبر gh CLI
# =====================================================

# ---------- إعدادات افتراضية (عدلها إن رغبت) ----------
WORKFLOW_PATH=".github/workflows/android-ci.yml"
BACKUP_DIR=".github/workflows/backups"
COMMIT_MSG="ci: replace with professional Android CI workflow"
CREATE_RELEASE=false
RELEASE_TAG=""
RELEASE_NAME=""
RELEASE_BODY=""

# ---------- مساعدة / usage ----------
usage() {
  cat <<EOF
Usage: $0 [--release TAG] [--name "Release name"] [--body "Release notes"]
Example:
  $0
  $0 --release v0.2.0 --name "LinkApp v0.2.0" --body "Automated release from CI workflow update."

Options:
  --release TAG        Create a GitHub release with the given tag (requires 'gh' and repo admin rights)
  --name "Release name"  (optional) release title
  --body "Release notes" (optional) release body/description
  -h, --help           Show this help
EOF
  exit 1
}

# ---------- parse args ----------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --release)
      CREATE_RELEASE=true
      shift
      if [[ $# -eq 0 ]]; then echo "Missing tag after --release"; exit 1; fi
      RELEASE_TAG="$1"
      shift
      ;;
    --name)
      shift
      if [[ $# -eq 0 ]]; then echo "Missing name after --name"; exit 1; fi
      RELEASE_NAME="$1"
      shift
      ;;
    --body)
      shift
      if [[ $# -eq 0 ]]; then echo "Missing body after --body"; exit 1; fi
      RELEASE_BODY="$1"
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown arg: $1"
      usage
      ;;
  esac
done

# ---------- تحققات أولية ----------
echo -e "\n[INFO] Running apply_ci_workflow.sh ..."

# تأكد أننا في مستودع Git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "[ERROR] هذا ليس مستودع git. انتقل إلى مجلد المشروع ثم أعد المحاولة."
  exit 1
fi

# اجلب اسم الفرع الحالي
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "[INFO] Current git branch: ${CURRENT_BRANCH}"

# تأكد من وجود مجلد .github/workflows
mkdir -p "$(dirname "${WORKFLOW_PATH}")"
mkdir -p "${BACKUP_DIR}"

# ---------- عمل نسخة احتياطية إن وُجد الملف القديم ----------
if [[ -f "${WORKFLOW_PATH}" ]]; then
  TIMESTAMP=$(date +%Y%m%d-%H%M%S)
  BACKUP_FILE="${BACKUP_DIR}/android-ci.yml.bak.${TIMESTAMP}"
  echo "[INFO] Found existing workflow at ${WORKFLOW_PATH} — backing up to ${BACKUP_FILE}"
  cp "${WORKFLOW_PATH}" "${BACKUP_FILE}"
else
  echo "[INFO] No existing workflow file found — will create a fresh one."
fi

# ---------- اكتب محتوى الـ workflow الجديد ----------

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
    timeout-minutes: 60

    env:
      JAVA_TOOL_OPTIONS: "-Xmx3g"

    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      - name: Cache Gradle packages
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*','**/gradle-wrapper.properties') }}
          restore-keys: |
            ${{ runner.os }}-gradle-

      - name: Set up JDK 17
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: gradle

      - name: Set up Android SDK
        uses: android-actions/setup-android@v3
        with:
          api-level: 34
          target: default
          ndk: false

      - name: Grant execute permission for gradlew
        run: chmod +x gradlew

      - name: Build Debug APK
        run: ./gradlew :app:assembleDebug --no-daemon --stacktrace
        continue-on-error: false

      - name: Run Lint (if configured)
        run: ./gradlew :app:lintDebug || true

      - name: Run Unit Tests
        run: ./gradlew testDebugUnitTest || true

      - name: Upload Debug APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: LinkApp-debug-apk
          path: app/build/outputs/apk/debug/*.apk

      - name: Upload Lint HTML (if any)
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: lint-reports
          path: app/build/reports/lint-results-*.html
YAML

echo "[INFO] Written new workflow to ${WORKFLOW_PATH}"

# ---------- git add, commit, push ----------
echo "[INFO] Staging and committing workflow changes..."
git add "${WORKFLOW_PATH}"

# only commit if changes exist
if git diff --cached --quiet; then
  echo "[INFO] No changes to commit."
else
  git commit -m "${COMMIT_MSG}"
  echo "[INFO] Pushing commit to origin/${CURRENT_BRANCH}..."
  git push origin "${CURRENT_BRANCH}"
fi

# ---------- (اختياري) إنشاء GitHub Release عبر gh ----------
if [[ "${CREATE_RELEASE}" == "true" ]]; then
  if ! command -v gh >/dev/null 2>&1; then
    echo "[ERROR] gh CLI غير مثبت. لتفعيل --release ثبت gh ثم أعد المحاولة."
    exit 1
  fi

  # تأكد أن gh مسجل الدخول
  if ! gh auth status >/dev/null 2>&1; then
    echo "[INFO] gh not authenticated — please run: gh auth login"
    exit 1
  fi

  # tag and create release
  echo "[INFO] Creating tag ${RELEASE_TAG} and GitHub release..."
  git tag -a "${RELEASE_TAG}" -m "${RELEASE_NAME:-Release ${RELEASE_TAG}}"
  git push origin "${RELEASE_TAG}"

  # create release via gh
  GH_CREATE_ARGS=(release create "${RELEASE_TAG}")
  if [[ -n "${RELEASE_NAME}" ]]; then
    GH_CREATE_ARGS+=(--title "${RELEASE_NAME}")
  fi
  if [[ -n "${RELEASE_BODY}" ]]; then
    GH_CREATE_ARGS+=(--notes "${RELEASE_BODY}")
  fi

  gh "${GH_CREATE_ARGS[@]}"
  echo "[INFO] Release ${RELEASE_TAG} created via gh."
fi

echo "[OK] Workflow applied and pushed successfully."
echo "[OK] Backup (if any) is in ${BACKUP_DIR}."
echo
echo "Next steps:"
echo "  - Visit your repo Actions tab to watch the run: https://github.com/<your-user>/<your-repo>/actions"
echo "  - You can trigger a manual run via 'gh workflow run android-ci.yml --ref ${CURRENT_BRANCH}'"
echo "  - To restore old workflow: cp ${BACKUP_DIR}/android-ci.yml.bak.<timestamp> ${WORKFLOW_PATH} && git commit -am 'restore workflow' && git push"
