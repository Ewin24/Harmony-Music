@echo off
REM install.bat — Installs Harmony-Music on a connected Android device via ADB (Windows version).
REM
REM Usage:
REM   install.bat                  auto-detects device ABI and installs
REM   install.bat <apk-file>       installs a specific APK
REM   install.bat --check          just checks if the device is connected

setlocal enabledelayedexpansion

REM Defaults
set APK_FILE=
set CHECK_ONLY=false

REM Parse args
if "%1"=="" goto :main
if /i "%1"=="--check" set CHECK_ONLY=true& goto :main
if /i "%1"=="--help" goto :help
if /i "%1"=="-h" goto :help
set APK_FILE=%1
goto :main

:help
echo Usage: install.bat [apk-file] [--check]
echo   apk-file    Install a specific APK instead of auto-detecting
echo   --check     Only check device connection and ABI
exit /b 0

:main
REM Check adb
where adb >nul 2>nul
if errorlevel 1 (
    echo Error: adb not found in PATH.
    echo Install Android Platform Tools: https://developer.android.com/studio/releases/platform-tools
    exit /b 1
)

echo Checking for connected devices...
for /f "tokens=1" %%i in ('adb devices ^| findstr /R "device$"') do (
    echo   %%i
)

adb devices | findstr /R "device$" >nul
if errorlevel 1 (
    echo No device connected. Connect a device with USB debugging enabled.
    exit /b 1
)

REM Auto-detect ABI if no APK specified
if "%APK_FILE%"=="" (
    echo.
    echo Detecting device ABI...
    for /f "tokens=*" %%a in ('adb shell getprop ro.product.cpu.abi') do set ABI=%%a
    echo   ABI: !ABI!
    
    if /i "!ABI!"=="arm64-v8a" set APK_FILE=Harmony-Music-v1.12.2-arm64-v8a.apk
    if /i "!ABI!"=="armeabi-v7a" set APK_FILE=Harmony-Music-v1.12.2-armeabi-v7a.apk
    if /i "!ABI!"=="x86_64" set APK_FILE=Harmony-Music-v1.12.2-x86_64.apk
    
    if "!APK_FILE!"=="" (
        echo Unknown ABI '!ABI!', falling back to universal APK
        set APK_FILE=Harmony-Music-v1.12.2-universal-release.apk
    )
)

REM Get script directory
set SCRIPT_DIR=%~dp0
set APK_PATH=%SCRIPT_DIR%%APK_FILE%

if not exist "%APK_PATH%" (
    echo APK not found: %APK_PATH%
    echo Available APKs:
    dir /b "%SCRIPT_DIR%*.apk" 2>nul
    exit /b 1
)

echo.
echo APK to install:
echo   %APK_FILE%

if "%CHECK_ONLY%"=="true" (
    echo.
    echo Device check passed.
    exit /b 0
)

REM Confirm
echo.
set /p CONFIRM="Install on connected device? [y/N] "
if /i not "%CONFIRM%"=="y" (
    echo Aborted.
    exit /b 0
)

REM Install
echo.
echo Installing...
adb install -r "%APK_PATH%"

if errorlevel 1 (
    echo Installation failed.
    exit /b 1
)

echo.
echo Installed successfully.
echo.
echo Launching app...
adb shell am start -n com.anandnet.harmonymusic/.MainActivity 2>nul

echo.
echo Done. If something went wrong, run: adb logcat ^| findstr /i harmony
endlocal
