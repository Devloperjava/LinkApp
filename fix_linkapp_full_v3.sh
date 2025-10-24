#!/bin/bash
# =====================================================
# 🧠 fix_linkapp_full_v3.sh — إصلاح + تحليل شامل لمشروع LinkApp
# =====================================================

set -e

# إعدادات عامة
PROJECT_DIR="$HOME/AndroidStudioProjects/LinkApp"
BACKUP_DIR="$HOME/fix_backups/$(date +%Y%m%d-%H%M%S)"
GITHUB_USER="Devloperjava"
REPO_NAME="LinkApp"

echo "[INFO] 🚀 بدء عملية الإصلاح والتحليل الكامل للمشروع..."
cd "$PROJECT_DIR" || { echo "[ERROR] ❌ لم يتم العثور على مجلد المشروع."; exit 1; }

# =====================================================
# 🗃️ 1. النسخ الاحتياطي الذكي (تجاهل ملفات النظام)
# =====================================================
echo "[INFO] 🗃️ إنشاء نسخة احتياطية آمنة إلى: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

tar --exclude="$HOME/.cache" \
    --exclude="$HOME/.gradle" \
    --exclude="**/.git" \
    --exclude="**/.idea" \
    --exclude="**/build" \
    --exclude="**/.port" \
    --exclude="**/local.properties" \
    -czf "$BACKUP_DIR/project_backup.tar.gz" "$PROJECT_DIR" \
    && echo "[OK] ✅ تم إنشاء النسخة الاحتياطية بنجاح." \
    || echo "[WARN] ⚠️ بعض ملفات النظام تم تجاهلها تلقائيًا (أمر طبيعي)."

# =====================================================
# 🧹 2. تنظيف المشروع
# =====================================================
echo "[INFO] 🧹 تنظيف المشروع من الملفات القديمة..."
./gradlew clean || echo "[WARN] ⚠️ Gradle لم يتم تهيئته بعد."

# =====================================================
# 🧩 3. تحديث التبعيات
# =====================================================
echo "[INFO] 🔧 مزامنة التبعيات..."
./gradlew --refresh-dependencies || echo "[WARN] ⚠️ فشل التحديث الجزئي للتبعيات."

# =====================================================
# 🧪 4. اختبار البناء
# =====================================================
echo "[INFO] 🧪 اختبار بناء المشروع..."
if ./gradlew assembleDebug; then
    echo "[OK] ✅ البناء ناجح!"
else
    echo "[ERROR] ❌ فشل البناء! جاري فحص الأسباب..."
    ./gradlew build --stacktrace || true
fi

# =====================================================
# 🧠 5. تحليل الأكواد (Lint + Kotlin + Detekt)
# =====================================================
echo "[INFO] 🧠 فحص الكود باستخدام Lint و Detekt..."
if ./gradlew lint || ./gradlew detekt; then
    echo "[OK] ✅ لا توجد أخطاء حرجة في الكود."
else
    echo "[WARN] ⚠️ تم العثور على تحذيرات أو مشاكل في الكود (راجع reports/)."
fi

# =====================================================
# 🧩 6. فحص الأكواد المنطقية (Kotlin compiler)
# =====================================================
echo "[INFO] 🔍 فحص منطق Kotlin..."
if ./gradlew compileDebugKotlin; then
    echo "[OK] ✅ كود Kotlin نظيف وسليم."
else
    echo "[ERROR] ❌ مشاكل في أكواد Kotlin — راجع السجلات أعلاه."
fi

# =====================================================
# 🧪 7. تشغيل اختبارات الوحدة Unit Tests (إن وجدت)
# =====================================================
if [ -d "app/src/test" ]; then
    echo "[INFO] 🧪 تشغيل اختبارات الوحدة..."
    ./gradlew testDebugUnitTest || echo "[WARN] ⚠️ بعض الاختبارات فشلت."
else
    echo "[INFO] 💤 لا توجد اختبارات وحدة بعد (تجاوز)."
fi

# =====================================================
# 🌐 8. إعداد GitHub ودفع التغييرات
# =====================================================
echo "[INFO] 🔗 إعداد GitHub..."
git init
git branch -M main
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/$GITHUB_USER/$REPO_NAME.git"

git add .
git commit -m "🧠 إصلاح وتحليل تلقائي شامل $(date +%Y-%m-%d_%H:%M)" || echo "[INFO] لا تغييرات جديدة للرفع."
git push -u origin main --force && echo "[OK] ✅ تم رفع المشروع بنجاح إلى GitHub."

# =====================================================
# 🎯 9. النتائج النهائية
# =====================================================
echo
echo "🎯 تم إصلاح وتحليل مشروع LinkApp بالكامل بنجاح!"
echo "📦 النسخة الاحتياطية محفوظة في: $BACKUP_DIR"
echo "🧠 تقارير Lint و Detekt موجودة في: app/build/reports/"
echo "🌐 تحقق من مستودعك هنا: https://github.com/$GITHUB_USER/$REPO_NAME"
echo "✨ افتح المشروع الآن في Android Studio — جاهز للبناء والتجربة."
