#Requires -Version 5.1
# Полная подготовка и сборка release APK GPN VPN.
$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $PSScriptRoot
$Flutter = "C:\Users\venya\flutter\bin\flutter.bat"
$Dart = "C:\Users\venya\flutter\bin\dart.bat"
$ApiBase = if ($env:GPN_API_BASE) { $env:GPN_API_BASE } else { "https://giga-gpn.space" }

Set-Location $Root

Write-Host "=== 1/4 Download hiddify-core Android ===" -ForegroundColor Cyan
& "$PSScriptRoot\prepare-android.ps1"

Write-Host "=== 2/4 flutter pub get ===" -ForegroundColor Cyan
& $Flutter pub get

Write-Host "=== 3/4 code generation ===" -ForegroundColor Cyan
& $Dart run build_runner build --delete-conflicting-outputs

Write-Host "=== 4/4 build APK ===" -ForegroundColor Cyan
& $Flutter build apk --release --dart-define=GPN_API_BASE=$ApiBase

$apk = Join-Path $Root "build\app\outputs\flutter-apk\app-release.apk"
if (Test-Path $apk) {
    $size = [math]::Round((Get-Item $apk).Length / 1MB, 1)
    Write-Host ""
    Write-Host "READY: $apk ($size MB)" -ForegroundColor Green
} else {
    Write-Host "APK not found - build failed" -ForegroundColor Red
    exit 1
}
