@echo off
setlocal
echo ========================================================
echo  MountX - Pasang & Jalankan di Emulator
echo ========================================================

set "MOUNTX_ROOT=%~dp0"
if "%MOUNTX_ROOT:~-1%"=="\" set "MOUNTX_ROOT=%MOUNTX_ROOT:~0,-1%"

set "AUTOGRAM_TOOLCHAINS=F:\AutoGram\.toolchains"
set "ANDROID_HOME=%AUTOGRAM_TOOLCHAINS%\android-sdk"
set "JAVA_HOME=%AUTOGRAM_TOOLCHAINS%\jdk-17"
set "PATH=%JAVA_HOME%\bin;%ANDROID_HOME%\platform-tools;%PATH%"

echo [1/3] Memeriksa koneksi emulator...
adb.exe devices
adb.exe wait-for-device

echo [2/3] Memasang app-debug.apk ke emulator...
if exist "%MOUNTX_ROOT%\app\build\outputs\apk\debug\app-debug.apk" (
    adb.exe install -r "%MOUNTX_ROOT%\app\build\outputs\apk\debug\app-debug.apk"
) else (
    echo [ERROR] Berkas APK tidak ditemukan di:
    echo %MOUNTX_ROOT%\app\build\outputs\apk\debug\app-debug.apk
    pause
    exit /b 1
)

echo [3/3] Meluncurkan aplikasi MountX...
adb.exe shell am start -n app.mountx.debug/app.mountx.MainActivity

echo.
echo ========================================================
echo  Aplikasi MountX berhasil dipasang dan diluncurkan!
echo ========================================================
timeout /t 5

