@echo off
setlocal
echo ========================================================
echo  Mountify - Pasang & Jalankan di Emulator
echo  100%% Zero-C Drive Isolation (F:\AutoGram Storage)
echo ========================================================

set "AUTOGRAM_ROOT=F:\AutoGram"
set "GRADLE_USER_HOME=%AUTOGRAM_ROOT%\.build-cache\gradle"
set "ANDROID_USER_HOME=%AUTOGRAM_ROOT%\.build-cache\android-user-home"
set "ANDROID_HOME=%AUTOGRAM_ROOT%\.toolchains\android-sdk"
set "JAVA_HOME=%AUTOGRAM_ROOT%\.toolchains\jdk-17"
set "TEMP=%AUTOGRAM_ROOT%\.build-cache\temp"
set "TMP=%AUTOGRAM_ROOT%\.build-cache\temp"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%"

echo [1/3] Memeriksa koneksi emulator...
adb.exe devices
adb.exe wait-for-device

echo [2/3] Memasang app-debug.apk ke emulator...
adb.exe install -r "E:\Data\GitHub\Mountify\app\build\outputs\apk\debug\app-debug.apk"

echo [3/3] Meluncurkan aplikasi Mountify...
adb.exe shell am start -n app.mountify.debug/app.mountify.MainActivity

echo.
echo ========================================================
echo  Aplikasi Mountify berhasil dipasang dan diluncurkan!
echo ========================================================
timeout /t 5
