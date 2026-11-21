#!/usr/bin/env bash
# اجرا از داخل پوشه پروژه:  bash tool/setup_android.sh
set -e
flutter create --platforms=android --org com.camros --project-name baguette . >/dev/null
M=android/app/src/main/AndroidManifest.xml
# نام اپ + جلوگیری از Auto Backup (چون کلید دیتابیس در Keystore است و با DB بازیابی نمی‌شود)
sed -i 's/android:label="[^"]*"/android:label="باگت"/' "$M"
grep -q allowBackup "$M" || sed -i 's/<application/<application android:allowBackup="false"/' "$M"
# minSdk 23 برای flutter_secure_storage / SQLCipher
F=android/app/build.gradle
[ -f "$F" ] || F=android/app/build.gradle.kts
sed -i 's/minSdk = flutter.minSdkVersion/minSdk = 23/; s/minSdkVersion flutter.minSdkVersion/minSdkVersion 23/' "$F"
flutter pub get
dart run flutter_launcher_icons
echo "تمام. اجرا: flutter run"
