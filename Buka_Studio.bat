@echo off
setlocal
echo ========================================================
echo  Mountify - Android Studio Environment
echo ========================================================

set "MOUNTIFY_ROOT=%~dp0"
if "%MOUNTIFY_ROOT:~-1%"=="\" set "MOUNTIFY_ROOT=%MOUNTIFY_ROOT:~0,-1%"

set "AUTOGRAM_TOOLCHAINS=F:\AutoGram\.toolchains"
set "STUDIO_EXE=%AUTOGRAM_TOOLCHAINS%\android-studio\bin\studio64.exe"

if not exist "%STUDIO_EXE%" (
    echo [ERROR] Android Studio tidak ditemukan di:
    echo %STUDIO_EXE%
    pause
    exit /b 1
)

:: Isolasi cache dan temporary Mountify di Drive E:
set "LOCAL_CACHE=%MOUNTIFY_ROOT%\.build-cache"
set "TEMP=%LOCAL_CACHE%\temp"
set "TMP=%LOCAL_CACHE%\temp"
if not exist "%TEMP%" mkdir "%TEMP%"

set "ANDROID_HOME=%AUTOGRAM_TOOLCHAINS%\android-sdk"
set "ANDROID_SDK_ROOT=%AUTOGRAM_TOOLCHAINS%\android-sdk"
set "JAVA_HOME=%AUTOGRAM_TOOLCHAINS%\jdk-17"
set "STUDIO_JDK=%AUTOGRAM_TOOLCHAINS%\android-studio\jbr"

echo Meluncurkan Android Studio untuk Mountify...
start "" "%STUDIO_EXE%" "%MOUNTIFY_ROOT%"
