# PowerShell Script to Pull Logs from Android Device
# Usage: .\pull_logs.ps1

$packageName = "com.example.collegebus"
$remotePath = "/data/user/0/$packageName/app_flutter/app_logs.txt"
$localPath = ".\app_logs.txt"

Write-Host "Checking connected devices..." -ForegroundColor Cyan
$devices = adb devices | Select-String "device$" | ForEach-Object { $_.ToString().Split("`t")[0] }

if ($devices.Count -eq 0) {
    Write-Host "No devices connected." -ForegroundColor Red
    exit
}

$selectedDevice = $null

if ($devices.Count -eq 1) {
    $selectedDevice = $devices[0]
} else {
    Write-Host "Multiple devices found:" -ForegroundColor Yellow
    for ($i = 0; $i -lt $devices.Count; $i++) {
        Write-Host "[$i] $($devices[$i])"
    }
    $index = Read-Host "Select device index (0-$($devices.Count-1))"
    $selectedDevice = $devices[$index]
}

Write-Host "Pulling logs from $selectedDevice..." -ForegroundColor Cyan

# Try direct pull (works on emulators/rooted)
# adb -s $selectedDevice pull $remotePath $localPath

# Use run-as for non-rooted production builds
cmd /c "adb -s $selectedDevice exec-out run-as $packageName cat app_flutter/app_logs.txt > $localPath"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Logs saved to $localPath" -ForegroundColor Green
    notepad $localPath
} else {
    Write-Host "Failed to pull logs. Ensure app is installed and debuggable." -ForegroundColor Red
}
