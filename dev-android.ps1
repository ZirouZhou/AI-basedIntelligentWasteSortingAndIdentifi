param(
  [string]$EmulatorName = "Pixel_10_Pro_XL",
  [int]$BackendPort = 8080,
  [switch]$SkipRun
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "[dev-android] $Message"
}

function Get-ListeningProcessId {
  param([int]$Port)
  $listener = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
    Select-Object -First 1

  if ($null -eq $listener) {
    return $null
  }

  return [int]$listener.OwningProcess
}

function Wait-ForPort {
  param(
    [int]$Port,
    [int]$TimeoutSeconds = 30
  )

  for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
    if (Get-ListeningProcessId -Port $Port) {
      return $true
    }
    Start-Sleep -Seconds 1
  }

  return $false
}

function Get-AndroidSdkPath {
  $candidates = @(
    $env:ANDROID_HOME,
    $env:ANDROID_SDK_ROOT,
    (Join-Path $env:LOCALAPPDATA "Android\sdk")
  ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

  foreach ($candidate in $candidates) {
    $adb = Join-Path $candidate "platform-tools\adb.exe"
    $emulator = Join-Path $candidate "emulator\emulator.exe"
    if ((Test-Path $adb) -and (Test-Path $emulator)) {
      return $candidate
    }
  }

  throw "Android SDK not found. Install Android Studio SDK and ensure adb/emulator are available."
}

function Get-FirstOnlineEmulator {
  param([string]$AdbPath)
  $devices = & $AdbPath devices

  foreach ($line in $devices) {
    if ($line -match "^(emulator-\d+)\s+device$") {
      return $Matches[1]
    }
  }

  return $null
}

function Get-FirstOfflineEmulator {
  param([string]$AdbPath)
  $devices = & $AdbPath devices

  foreach ($line in $devices) {
    if ($line -match "^(emulator-\d+)\s+offline$") {
      return $Matches[1]
    }
  }

  return $null
}

function Wait-ForEmulatorOnline {
  param(
    [string]$AdbPath,
    [int]$TimeoutSeconds = 180
  )

  for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
    $deviceId = Get-FirstOnlineEmulator -AdbPath $AdbPath
    if ($deviceId) {
      return $deviceId
    }
    Start-Sleep -Seconds 1
  }

  return $null
}

function Remove-OfflineEmulator {
  param([string]$AdbPath)

  $offline = Get-FirstOfflineEmulator -AdbPath $AdbPath
  if (-not $offline) {
    return
  }

  Write-Step "Found offline emulator session ($offline). Restarting adb to recover..."
  & $AdbPath kill-server | Out-Null
  Start-Sleep -Seconds 1
  & $AdbPath start-server | Out-Null
}

function Stop-EmulatorProcesses {
  $processes = Get-Process -Name emulator,qemu-system-x86_64 -ErrorAction SilentlyContinue
  if ($processes) {
    Write-Step "Stopping stale emulator processes..."
    $processes | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
  }
}

function Wait-ForBootCompleted {
  param(
    [string]$AdbPath,
    [string]$DeviceId,
    [int]$TimeoutSeconds = 180
  )

  for ($i = 0; $i -lt $TimeoutSeconds; $i++) {
    try {
      $boot = (& $AdbPath -s $DeviceId shell getprop sys.boot_completed 2>$null).Trim()
      if ($boot -eq "1") {
        return $true
      }
    } catch {
      # Keep waiting while emulator is booting.
    }
    Start-Sleep -Seconds 1
  }

  return $false
}

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$backendDir = Join-Path $repoRoot "backend"
$frontendDir = Join-Path $repoRoot "frontend"
$logDir = Join-Path $repoRoot ".dev-logs"

if (-not (Test-Path $backendDir)) {
  throw "backend folder not found: $backendDir"
}

if (-not (Test-Path $frontendDir)) {
  throw "frontend folder not found: $frontendDir"
}

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "flutter command not found in PATH."
}

if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
  throw "dart command not found in PATH."
}

if (-not (Test-Path $logDir)) {
  New-Item -Path $logDir -ItemType Directory | Out-Null
}

$sdkRoot = Get-AndroidSdkPath
$adbPath = Join-Path $sdkRoot "platform-tools\adb.exe"
$emulatorPath = Join-Path $sdkRoot "emulator\emulator.exe"

$backendProcess = $null
$backendAlreadyRunning = $false

try {
  $existingBackendPid = Get-ListeningProcessId -Port $BackendPort
  if ($existingBackendPid) {
    $backendAlreadyRunning = $true
    Write-Step "Backend already running on port $BackendPort (PID $existingBackendPid)."
  } else {
    $backendOutLog = Join-Path $logDir "backend.out.log"
    $backendErrLog = Join-Path $logDir "backend.err.log"
    Write-Step "Starting backend on port $BackendPort..."
    $backendProcess = Start-Process -FilePath "dart" `
      -ArgumentList @("run", "bin/server.dart") `
      -WorkingDirectory $backendDir `
      -WindowStyle Hidden `
      -RedirectStandardOutput $backendOutLog `
      -RedirectStandardError $backendErrLog `
      -PassThru

    if (-not (Wait-ForPort -Port $BackendPort -TimeoutSeconds 30)) {
      throw "Backend failed to start. Check logs: $backendOutLog and $backendErrLog"
    }
  }

  Write-Step "Resetting adb server..."
  & $adbPath kill-server | Out-Null
  & $adbPath start-server | Out-Null

  $deviceId = Get-FirstOnlineEmulator -AdbPath $adbPath
  if (-not $deviceId) {
    Stop-EmulatorProcesses
    Remove-OfflineEmulator -AdbPath $adbPath
    Write-Step "Launching Android emulator: $EmulatorName"
    $emulatorOutLog = Join-Path $logDir "emulator.out.log"
    $emulatorErrLog = Join-Path $logDir "emulator.err.log"
    Start-Process -FilePath $emulatorPath `
      -ArgumentList @("-avd", $EmulatorName, "-no-snapshot-load") `
      -WindowStyle Hidden `
      -RedirectStandardOutput $emulatorOutLog `
      -RedirectStandardError $emulatorErrLog | Out-Null
    $deviceId = Wait-ForEmulatorOnline -AdbPath $adbPath -TimeoutSeconds 300
  }

  if (-not $deviceId) {
    throw "No Android emulator became available. Check logs in $logDir."
  }

  Write-Step "Waiting for emulator boot completion on $deviceId..."
  if (-not (Wait-ForBootCompleted -AdbPath $adbPath -DeviceId $deviceId -TimeoutSeconds 300)) {
    throw "Emulator did not finish booting in time."
  }

  if ($SkipRun) {
    Write-Step "SkipRun enabled. Backend and emulator are ready. Device: $deviceId"
  } else {
    $apiBaseUrl = "http://10.0.2.2:$BackendPort"
    Write-Step "Running Flutter app on $deviceId with API_BASE_URL=$apiBaseUrl"

    Push-Location $frontendDir
    try {
      & flutter run -d $deviceId --dart-define="API_BASE_URL=$apiBaseUrl"
    } finally {
      Pop-Location
    }
  }
} finally {
  if (-not $backendAlreadyRunning -and $backendProcess -and -not $backendProcess.HasExited) {
    Write-Step "Stopping backend process started by this script (PID $($backendProcess.Id))."
    Stop-Process -Id $backendProcess.Id -Force -ErrorAction SilentlyContinue
  }
}
