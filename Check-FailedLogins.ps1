<#
.SYNOPSIS
  Telt mislukte aanmeldingen en herstart systeem bij overschrijding van drempel.

.PARAMETER Threshold
  Het aantal toegestane mislukte aanmeldpogingen (standaard: 10)

.PARAMETER LogFile
  Pad naar logbestand (standaard: C:\Logs\FailedLoginMonitor.log)
#>

param (
    [int]$Threshold = 10,
    [string]$LogFile = "C:\Logs\FailedLoginMonitor.log"
)

# Zorg dat de logdirectory bestaat
$logDir = Split-Path $LogFile
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory -Force | Out-Null
}

# Tijdstempels
$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

# Haal mislukte aanmeldpogingen van vandaag op
$today = (Get-Date).Date
$failedLogins = Get-WinEvent -FilterHashtable @{
    LogName = 'Security';
    Id = 4625;
    StartTime = $today
} -ErrorAction SilentlyContinue

$count = $failedLogins.Count

# Log status
"$now - Failed login attempts today: $count (Threshold: $Threshold)" | Out-File -FilePath $LogFile -Append -Encoding utf8

# Herstart als nodig
if ($count -ge $Threshold) {
    "$now - Threshold exceeded. Rebooting system." | Out-File -FilePath $LogFile -Append -Encoding utf8
    Write-EventLog -LogName Application -Source "Application Error" -EntryType Warning -EventId 1000 -Message "Rebooting due to $count failed login attempts."
    Restart-Computer -Force
}
