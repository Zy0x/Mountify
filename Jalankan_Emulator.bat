@echo off
setlocal
echo ========================================================
echo  Mountify - Android Emulator Launcher
echo ========================================================

set "MOUNTIFY_ROOT=%~dp0"
if "%MOUNTIFY_ROOT:~-1%"=="\" set "MOUNTIFY_ROOT=%MOUNTIFY_ROOT:~0,-1%"

set "AUTOGRAM_TOOLCHAINS=F:\AutoGram\.toolchains"
set "ANDROID_HOME=%AUTOGRAM_TOOLCHAINS%\android-sdk"
set "ANDROID_SDK_ROOT=%AUTOGRAM_TOOLCHAINS%\android-sdk"
set "JAVA_HOME=%AUTOGRAM_TOOLCHAINS%\jdk-17"

:: Isolasi AVD dan cache Mountify di Drive E:
set "ANDROID_USER_HOME=%MOUNTIFY_ROOT%\.build-cache\android"
set "ANDROID_AVD_HOME=%MOUNTIFY_ROOT%\.build-cache\android\avd"
set "TEMP=%MOUNTIFY_ROOT%\.build-cache\temp"
set "TMP=%MOUNTIFY_ROOT%\.build-cache\temp"

if not exist "%ANDROID_AVD_HOME%" mkdir "%ANDROID_AVD_HOME%"
if not exist "%TEMP%" mkdir "%TEMP%"

set "AVD_NAME=Mountify_Device"

:: Buat AVD jika belum ada
if not exist "%ANDROID_AVD_HOME%\%AVD_NAME%.avd" (
    echo [INFO] Membuat Android Virtual Device: %AVD_NAME%...
    echo no | "%ANDROID_HOME%\cmdline-tools\latest\bin\avdmanager.bat" create avd -n "%AVD_NAME%" -k "system-images;android-34;google_apis;x86_64" --force
)

echo [INFO] Menjalankan Android Emulator (%AVD_NAME%)...
start "" "%ANDROID_HOME%\emulator\emulator.exe" -avd "%AVD_NAME%" -gpu host -no-audio -no-boot-anim

echo [INFO] Menunggu emulator selesai booting...
"%ANDROID_HOME%\platform-tools\adb.exe" wait-for-device
:wait_boot
for /f "tokens=*" %%i in ('"%ANDROID_HOME%\platform-tools\adb.exe" shell getprop sys.boot_completed 2^>nul') do set "BOOT=%%i"
if not "%BOOT%"=="1" (
    timeout /t 2 /nobreak >nul
    goto wait_boot
)

echo [INFO] Memasang app-debug.apk ke emulator...
if exist "%MOUNTIFY_ROOT%\app\build\outputs\apk\debug\app-debug.apk" (
    "%ANDROID_HOME%\platform-tools\adb.exe" install -r "%MOUNTIFY_ROOT%\app\build\outputs\apk\debug\app-debug.apk"
    echo [INFO] Menjalankan Mountify di emulator...
    "%ANDROID_HOME%\platform-tools\adb.exe" shell am start -n app.mountify.debug/app.mountify.MainActivity
) else (
    echo [WARNING] app-debug.apk belum dikompilasi di app\build\outputs\apk\debug\app-debug.apk
)

echo ========================================================
echo  Emulator siap digunakan!
echo ========================================================
pause
