#Requires -Version 5.1
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

$CoreVersion = "4.1.0"
$BaseUrl = "https://github.com/hiddify/hiddify-core/releases/download/v$CoreVersion"
$AndroidOut = Join-Path $Root "android\app\libs"

New-Item -ItemType Directory -Force -Path $AndroidOut | Out-Null

Write-Host "Downloading hiddify-lib-android v$CoreVersion..."
$tmp = Join-Path $env:TEMP "hiddify-lib-android.tgz"
Invoke-WebRequest -Uri "$BaseUrl/hiddify-lib-android.tar.gz" -OutFile $tmp -UseBasicParsing
tar -xzf $tmp -C $AndroidOut
Remove-Item $tmp -Force

Write-Host "Android libs:"
Get-ChildItem $AndroidOut | ForEach-Object { Write-Host "  $($_.Name)" }
