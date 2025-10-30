# LinkApp

مشروع Android بسيط اسمه LinkApp.

متطلبات سريعة
- JDK 21 (Java 21) مطلوب لبناء هذا المشروع.
- Gradle و Android Gradle Plugin الموجودان في المشروع متوافقان مع Java 21.

إعداد Java 21 (موصى به — SDKMAN)
1. ثبّت SDKMAN إذا لم يكن مثبتًا:

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
```

2. ثبّت Temurin JDK 21 عبر SDKMAN:

```bash
sdk install java 21.0.8-tem
```

3. اجعل Gradle يستخدم هذا الـ JDK بإضافة (أو تعديل) `org.gradle.java.home` في `gradle.properties` داخل جذر المشروع:

```
org.gradle.java.home=/home/<username>/.sdkman/candidates/java/21.0.8-tem
```

بدلاً من ذلك يمكنك ضبط متغير البيئة `JAVA_HOME` لنفس المسار في جلسة الطرفية أو في ملف `~/.bashrc`.

أوامر شائعة

```bash
# من داخل مجلد المشروع
./gradlew clean assembleDebug    # بناء نسخة debug
./gradlew test                   # تشغيل اختبارات الوحدة
./gradlew lint                   # تشغيل lint
```

ملاحظات
- أضفت مؤقتًا `LoginActivity` و`activity_login.xml` حتى ينجح البناء؛ استبدلها بتطبيقك الفعلي إذا لزم.
- تم ضبط `org.gradle.java.home` في `gradle.properties` إلى JDK 21 المثبت عبر SDKMAN في هذا الجهاز.

إذا أردت أن أدفع التغييرات إلى remote (GitHub)، أعطني رابط المستودع أو صلاحية الرفع.
Updated: Thu Oct 30 03:47:06 PM EEST 2025
