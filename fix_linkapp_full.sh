#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# fix_linkapp_full.sh — سكربت شامل لإصلاح مشروع Android وتهيئته بالكامل + CI/CD + Release automation
# Usage:
#   ./fix_linkapp_full.sh [--yes] [--release-on-success] [--github-user USER]
# Examples:
#   ./fix_linkapp_full.sh              # معاينة وتنفيذ محلي (لن يدفع لـ GitHub بدون --yes)
#   ./fix_linkapp_full.sh --yes        # تنفيذ وتسجيل commit ودفع التغييرات
#   ./fix_linkapp_full.sh --yes --release-on-success --github-user Devloperjava

# ------------------------- الإعدادات الافتراضية -------------------------
AUTO_APPLY=false        # إذا true فسيجري commit و push تلقائيًا
AUTO_CREATE_RELEASE=false
GITHUB_USER=${GITHUB_USER:-""}
PROJECT_ROOT="${1:-.}"

# parse args (supports flags anywhere)
ARGS=("$@")
for ((i=0;i<${#ARGS[@]};i++)); do
  case "${ARGS[$i]}" in
    --yes) AUTO_APPLY=true ;;
    --release-on-success) AUTO_CREATE_RELEASE=true ;;
    --github-user) i=$((i+1)); GITHUB_USER="${ARGS[$i]}" ;;
    --help|-h) echo "Usage: $0 [--yes] [--release-on-success] [--github-user USER]"; exit 0 ;;
  esac
done

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_DIR="${PROJECT_ROOT}/fix_backups/${TIMESTAMP}"
REPORT_FILE="${BACKUP_DIR}/report.txt"
BUILD_LOG="${BACKUP_DIR}/build.log"

mkdir -p "${BACKUP_DIR}"
echo "Fix run at: $(date)" > "${REPORT_FILE}"
echo "Project root: ${PROJECT_ROOT}" >> "${REPORT_FILE}"
echo "" >> "${REPORT_FILE}"

# ------------------------- helper functions -------------------------
echoinfo(){ echo -e "\033[1;34m[INFO]\033[0m $*"; echo "[INFO] $*" >> "${REPORT_FILE}"; }
echowarn(){ echo -e "\033[1;33m[WARN]\033[0m $*"; echo "[WARN] $*" >> "${REPORT_FILE}"; }
echoerr(){ echo -e "\033[1;31m[ERROR]\033[0m $*"; echo "[ERROR] $*" >> "${REPORT_FILE}"; }

# ------------------------- 0. basic checks -------------------------
if [[ ! -d "${PROJECT_ROOT}" ]]; then
  echoerr "المسار ${PROJECT_ROOT} غير موجود."
  exit 1
fi

cd "${PROJECT_ROOT}"
echoinfo "Working directory: $(pwd)"

# Detect repo name (settings.gradle or gradle settings)
REPO_NAME="$(basename "$(pwd)")"
if [[ -z "${GITHUB_USER}" ]]; then
  # try to read from existing remote
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    REMOTE_URL=$(git remote get-url origin 2>/dev/null || true)
    if [[ -n "$REMOTE_URL" ]]; then
      # extract user if possible
      if [[ "$REMOTE_URL" =~ github.com[:/]+([^/]+)/([^/.]+) ]]; then
        GITHUB_USER="${BASH_REMATCH[1]}"
        # REPO_NAME might be BASH_REMATCH[2]
        # but we'll keep local name
      fi
    fi
  fi
fi

echoinfo "Repository name: ${REPO_NAME}"
echoinfo "GitHub user (target): ${GITHUB_USER:-<not set>}"

# ------------------------- 1. full backup -------------------------
echoinfo "Creating full tar.gz backup of project to ${BACKUP_DIR}/project_backup.tar.gz"
tar -czf "${BACKUP_DIR}/project_backup.tar.gz" --exclude="${BACKUP_DIR}" -C "${PROJECT_ROOT}" . || true
echo "Backup created: ${BACKUP_DIR}/project_backup.tar.gz" >> "${REPORT_FILE}"

# ------------------------- 2. remove BOM from text files -------------------------
echoinfo "Removing UTF-8 BOM from text files where present..."
RE_EXT="(xml|kts|gradle|kt|java|properties|pro|txt|json|md|yaml|yml|sh)"
if command -v python3 >/dev/null 2>&1; then
  find . -type f -regextype posix-extended -regex ".*\.${RE_EXT}$" -print0 | while IFS= read -r -d '' f; do
    # skip backups
    case "$f" in "${BACKUP_DIR}"*) continue ;; esac
    if head -c 3 "$f" | od -An -t x1 | grep -qi 'ef bb bf'; then
      echoinfo "Removing BOM in: $f"
      python3 - <<PY
import sys
p=sys.argv[1]
with open(p,'rb') as fh:
    data=fh.read()
if data.startswith(b'\xef\xbb\xbf'):
    with open(p,'wb') as fh:
        fh.write(data[3:])
PY
      echo "Removed BOM: $f" >> "${REPORT_FILE}"
    fi
  done
else
  echowarn "python3 not available; skipping BOM removal."
fi

# ------------------------- 3. ensure XML header and strip leading junk -------------------------
echoinfo "Ensuring XML files start with XML declaration (and stripping any garbage before it)..."
find . -type f -name "*.xml" -not -path "./${BACKUP_DIR}/*" -print0 | while IFS= read -r -d '' xf; do
  if ! grep -q "<?xml" "$xf"; then
    echowarn "No XML header found in $xf — skipping auto-fix for safety."
    continue
  fi
  # remove any bytes before <?xml
  awk 'BEGIN{p=0} { if(p==0){i=index($0,"<?xml"); if(i>0){print substr($0,i); p=1}else next} if(p==1) print }' "$xf" > "${xf}.fixed" && mv "${xf}.fixed" "$xf"
  sed -i '1{s/^[[:space:]\xEF\xBB\xBF]*\(<\?xml\)/\1/}' "$xf" || true
  echo "Fixed xml header: $xf" >> "${REPORT_FILE}"
done

# ------------------------- 4. Fix 0dp width w/o constraints in ConstraintLayout -------------------------
echoinfo "Fixing android:layout_width=\"0dp\" without constraints inside res/layout files (conservative fix)..."
find . -type f -path "*/res/layout/*.xml" -print0 | while IFS= read -r -d '' lf; do
  # only if file contains 0dp
  if ! grep -q 'android:layout_width="0dp"' "$lf"; then continue; fi

  # For each element that has android:layout_width="0dp": check if that element/block contains app:layout_constraint...
  # If not, replace 0dp -> match_parent (conservative)
  perl -0777 -pe '
    while(/(<[^>]*android:layout_width\s*=\s*"0dp"[^>]*>)/sgi){
      my $elem=$1;
      if($elem !~ /app:layout_constraint/){
        (my $new = $elem) =~ s/android:layout_width="0dp"/android:layout_width="match_parent"/;
        $_ =~ s/\Q$elem\E/$new/;
      }
    }
    $_;
  ' "$lf" > "${lf}.tmp" && mv "${lf}.tmp" "$lf"
  echo "Checked/updated widths in: $lf" >> "${REPORT_FILE}"
done

# ------------------------- 5. Extract hardcoded android:text to strings.xml -------------------------
echoinfo "Extracting hardcoded android:text values from layouts into res/values/strings.xml..."
STRINGS_FILE="app/src/main/res/values/strings.xml"
mkdir -p "$(dirname "$STRINGS_FILE")"
if [[ ! -f "$STRINGS_FILE" ]] || ! grep -q "<resources" "$STRINGS_FILE"; then
  echo '<?xml version="1.0" encoding="utf-8"?>' > "$STRINGS_FILE"
  echo '<resources>' >> "$STRINGS_FILE"
  echo '</resources>' >> "$STRINGS_FILE"
fi

# extract and replace in layouts
TMP_EX="${BACKUP_DIR}/_strings_extracted.txt"
> "$TMP_EX"
find . -type f -path "*/res/layout/*.xml" -print0 | while IFS= read -r -d '' layout; do
  # skip if no android:text=
  if ! grep -q 'android:text=' "$layout"; then continue; fi

  # For safety: use perl to extract literal strings not referencing @string
  perl -0777 -pe '
    my $file=shift;
    my $out="";
    while(/(android:text\s*=\s*")([^"]*)(")/sgi){
      my ($full,$pref,$txt,$suf)=($&,$1,$2,$3);
      next if $txt =~ /^\@string\//;
      # generate a key from text (sanitized)
      my $san=lc($txt);
      $san =~ s/[^a-z0-9]+/_/g;
      $san =~ s/^_+|_+$//g;
      $san = substr($san,0,40) || "string_auto";
      my $key="${san}";
      # ensure uniqueness (append random suffix)
      $key .= "_".int(rand(9000)+1000);
      $out .= "$file|$key|$txt\n";
      my $rep = $pref . "\@string/$key" . $suf;
      s/\Q$full\E/$rep/;
    }
    $_;
  ' "$layout" > "${layout}.tmp" && mv "${layout}.tmp" "$layout"
done > "$TMP_EX" || true

if [[ -s "$TMP_EX" ]]; then
  # append unique entries to strings.xml
  cut -d'|' -f2- "$TMP_EX" | while IFS='|' read -r key val; do
    if ! grep -q "name=\"$key\"" "$STRINGS_FILE"; then
      # escape xml chars
      safe=$(echo "$val" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g;')
      sed -i "/<\/resources>/i \ \ <string name=\"$key\">$safe</string>" "$STRINGS_FILE"
      echo "Added string $key -> $val" >> "${REPORT_FILE}"
    fi
  done
  rm -f "$TMP_EX"
else
  echoinfo "No hardcoded layout strings found that needed extraction."
fi

# ------------------------- 6. Ensure .gitignore and README exist -------------------------
echoinfo "Ensuring .gitignore and README.md exist..."
if [[ ! -f .gitignore ]]; then
  cat > .gitignore <<'GITIGN'
# Gradle
.gradle
/build
**/build

# Local configuration
local.properties
*.iml

# Android Studio
/.idea
/*.iml

# Gradle wrapper
/.gradle

# MacOS
.DS_Store
GITIGN
  echo ".gitignore created." >> "${REPORT_FILE}"
fi

if [[ ! -f README.md ]]; then
  cat > README.md <<EOF
# ${REPO_NAME}

This is an automatically generated Android project skeleton for ${REPO_NAME}.
Use Android Studio to open this project and sync Gradle.
EOF
  echo "README.md created." >> "${REPORT_FILE}"
fi

# ------------------------- 7. Handle nested .git repos -------------------------
echoinfo "Detecting nested .git repositories (sub-repos) and handling them..."
find . -type d -name ".git" -print | while IFS= read -r gdir; do
  # ignore root .git
  if [[ "$(realpath "$gdir")" == "$(realpath .)/.git" ]]; then
    continue
  fi
  nested_parent=$(dirname "$gdir")
  echowarn "Found nested git repo: ${nested_parent} (will backup and remove .git)"
  mkdir -p "${BACKUP_DIR}/nested_git"
  tar -czf "${BACKUP_DIR}/nested_git/$(basename "$nested_parent")-git-backup.tar.gz" -C "$nested_parent" .git || true
  rm -rf "${nested_parent}/.git"
  # if the nested folder was being tracked as submodule, remove from index
  git rm -r --cached "$nested_parent" 2>/dev/null || true
  echo "Removed nested git and backed up: ${nested_parent}" >> "${REPORT_FILE}"
done

# ------------------------- 8. Ensure gradlew exists and is executable -------------------------
echoinfo "Ensuring gradlew exists and is executable..."
if [[ -f "./gradlew" ]]; then
  chmod +x ./gradlew || true
  echoinfo "gradlew is present."
else
  if command -v gradle >/dev/null 2>&1; then
    echoinfo "Gradle found system-wide — generating gradle wrapper..."
    gradle wrapper
    chmod +x ./gradlew || true
    echo "Generated gradle wrapper." >> "${REPORT_FILE}"
  else
    echowarn "gradlew missing and system Gradle not found. You should open project in Android Studio to generate the wrapper."
  fi
fi

# ------------------------- 9. Try local build (if gradlew present) -------------------------
if [[ -f "./gradlew" ]]; then
  echoinfo "Attempting local build: ./gradlew clean assembleDebug — logs will be in ${BUILD_LOG}"
  set +e
  ./gradlew clean assembleDebug --no-daemon --stacktrace > "${BUILD_LOG}" 2>&1
  BUILD_EXIT=$?
  set -e
  if [[ $BUILD_EXIT -eq 0 ]]; then
    echoinfo "Local build SUCCESS."
    echo "BUILD SUCCESS" >> "${REPORT_FILE}"
  else
    echoerr "Local build FAILED (exit code ${BUILD_EXIT}). See ${BUILD_LOG} for details."
    echo "BUILD FAILED (exit ${BUILD_EXIT}). See build.log." >> "${REPORT_FILE}"
  fi
else
  echowarn "Skipping local build: gradlew not available."
  echo "No gradlew -> build skipped" >> "${REPORT_FILE}"
fi

# ------------------------- 10. Git commit changes locally -------------------------
echoinfo "Staging changes and creating a local commit (if any changes were made)."
git add -A
if git diff --cached --quiet; then
  echoinfo "No changes to commit."
else
  git commit -m "chore: auto-fix project resources & CI setup [auto]" || true
  echoinfo "Local commit created. Run 'git show --name-only HEAD' to review."
  echo "Local commit created." >> "${REPORT_FILE}"
fi

# ------------------------- 11. Ensure GitHub repo remote and push if requested -------------------------
if [[ -n "${GITHUB_USER}" ]] && command -v gh >/dev/null 2>&1; then
  REMOTE_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
  if git ls-remote "$REMOTE_URL" &>/dev/null; then
    echoinfo "Remote repo ${GITHUB_USER}/${REPO_NAME} exists on GitHub."
    git remote add origin "$REMOTE_URL" 2>/dev/null || git remote set-url origin "$REMOTE_URL"
  else
    echoinfo "Remote repo does not exist. Creating via gh..."
    gh repo create "${GITHUB_USER}/${REPO_NAME}" --public --source=. --remote=origin --push || echowarn "gh create failed or repo exists; ensure you have permissions."
  fi

  if [[ "${AUTO_APPLY}" == true ]]; then
    echoinfo "Pushing commits to origin/main (force if necessary)..."
    git push -u origin main --force
    echoinfo "Push complete."
  else
    echowarn "AUTO_APPLY is false — not pushing changes automatically. Use --yes to enable push."
  fi
else
  if [[ -z "${GITHUB_USER}" ]]; then
    echowarn "GitHub user not provided; skipping remote/push steps. Use --github-user <user> or set GITHUB_USER env var."
  else
    echowarn "gh CLI not available, cannot create remote automatically. Please add remote manually and push."
  fi
fi

# ------------------------- 12. Create advanced CI/CD workflow that publishes release on success -------------------------
echoinfo "Creating advanced GitHub Actions workflow .github/workflows/android-release-ci.yml"
mkdir -p .github/workflows
cat > .github/workflows/android-release-ci.yml <<'YAML'
name: Android CI & Release

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]
  workflow_dispatch:

jobs:
  build:
    name: Build Debug APK
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

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

      - name: Grant gradlew permission
        run: chmod +x gradlew

      - name: Cache Gradle
        uses: actions/cache@v4
        with:
          path: |
            ~/.gradle/caches
            ~/.gradle/wrapper
          key: ${{ runner.os }}-gradle-${{ hashFiles('**/*.gradle*','**/gradle-wrapper.properties') }}

      - name: Build Debug APK
        run: ./gradlew :app:assembleDebug --no-daemon --stacktrace

      - name: Upload APK artifact
        uses: actions/upload-artifact@v4
        with:
          name: LinkApp-debug-apk
          path: app/build/outputs/apk/debug/*.apk

  release:
    name: Create Release (if build success)
    runs-on: ubuntu-latest
    needs: build
    if: needs.build.result == 'success'
    steps:
      - name: Download artifact
        uses: actions/download-artifact@v4
        with:
          name: LinkApp-debug-apk
          path: ./artifact

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: "v${{ github.run_number }}"
          name: "LinkApp v${{ github.run_number }}"
          files: ./artifact/*.apk
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
YAML

git add .github/workflows/android-release-ci.yml || true
git commit -m "ci: add android build+release workflow" || true

if [[ "${AUTO_APPLY}" == true ]]; then
  echoinfo "Pushing CI workflow..."
  git push origin main
  echoinfo "Triggering workflow via gh (workflow_dispatch)..."
  if command -v gh >/dev/null 2>&1; then
    gh workflow run android-release-ci.yml --ref main || echowarn "Failed to trigger workflow via gh CLI."
  fi
else
  echowarn "CI workflow written but not pushed (use --yes to push and trigger)."
fi

# ------------------------- 13. Optionally create GitHub release after successful build locally (if requested) -------------------------
if [[ "${AUTO_CREATE_RELEASE}" == true ]] && command -v gh >/dev/null 2>&1; then
  echoinfo "Attempting to create a GitHub release (local) - tag will be autogenerated."
  TAG="v$(date +%Y%m%d%H%M%S)"
  git tag -a "${TAG}" -m "Automated release ${TAG}"
  git push origin "${TAG}"
  gh release create "${TAG}" --generate-notes || echowarn "gh release create failed."
  echoinfo "Release ${TAG} created."
fi

# ------------------------- 14. Final report -------------------------
echo "" >> "${REPORT_FILE}"
echo "Summary Report - $(date)" >> "${REPORT_FILE}"
echo "Backup created at: ${BACKUP_DIR}/project_backup.tar.gz" >> "${REPORT_FILE}"
if [[ -f "${BUILD_LOG}" ]]; then
  echo "Last build log tail:" >> "${REPORT_FILE}"
  tail -n 80 "${BUILD_LOG}" >> "${REPORT_FILE}" || true
fi

echoinfo "Done. Report: ${REPORT_FILE}"
echoinfo "Backups in: ${BACKUP_DIR}"
echoinfo "If you pushed changes, check GitHub Actions for build and release status."
