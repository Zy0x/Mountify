@echo off
setlocal
echo ========================================================
echo  Mountify - Pasang & Jalankan di Emulator
echo ========================================================

set "MOUNTIFY_ROOT=%~dp0"
if "%MOUNTIFY_ROOT:~-1%"=="\" set "MOUNTIFY_ROOT=%MOUNTIFY_ROOT:~0,-1%"

set "AUTOGRAM_TOOLCHAINS=F:\AutoGram\.toolchains"
set "ANDROID_HOME=%AUTOGRAM_TOOLCHAINS%\android-sdk"
set "JAVA_HOME=%AUTOGRAM_TOOLCHAINS%\jdk-17"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%"

echo [1/3] Memeriksa koneksi emulator...
adb.exe devices
adb.exe wait-for-device

echo [2/3] Memasang app-debug.apk ke emulator...
if exist "%MOUNTIFY_ROOT%\app\build\outputs\apk\debug\app-debug.apk" (
    adb.exe install -r "%MOUNTIFY_ROOT%\app\build\outputs\apk\debug\app-debug.apk"
) else (
    echo [ERROR] Berkas APK tidak ditemukan di:
    echo %MOUNTIFY_ROOT%\app\build\outputs\apk\debug\app-debug.apk
    pause
    exit /b 1
)

echo [3/3] Meluncurkan aplikasi Mountify...
adb.exe shell am start -n app.mountify.debug/app.mountify.MainActivity

echo.
echo ========================================================
echo  Aplikasi Mountify berhasil dipasang dan diluncurkan!
echo ========================================================
timeout /t 5

