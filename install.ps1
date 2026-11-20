# Installer eject-windows
# Jalankan: powershell -ExecutionPolicy Bypass -File install.ps1
# Memasang eject.vbs dan eject-auto.ps1 ke %LOCALAPPDATA%\eject lalu menambahkannya ke PATH user (permanen).

$ErrorActionPreference = "Stop"
$repoDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installDir = Join-Path $env:LOCALAPPDATA "eject"

Write-Host "==> Memasang ke $installDir"
New-Item -ItemType Directory -Force -Path $installDir | Out-Null
Copy-Item (Join-Path $repoDir "eject.vbs") $installDir -Force
Copy-Item (Join-Path $repoDir "eject-auto.ps1") $installDir -Force
Get-ChildItem $installDir | Unblock-File

Write-Host "==> Memastikan folder ada di PATH user"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($null -eq $userPath) { $userPath = "" }
$entries = $userPath -split ";" | Where-Object { $_ -ne "" }
if ($entries -notcontains $installDir) {
    $newPath = (($entries + $installDir) -join ";")
    [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
    Write-Host "    Menambahkan $installDir ke PATH"
} else {
    Write-Host "    Sudah ada di PATH"
}

Write-Host ""
Write-Host "Selesai. Tutup lalu buka CMD/PowerShell baru, kemudian coba:"
Write-Host "    eject      # pilih flashdisk dari daftar nama"
Write-Host "    eject E    # langsung eject drive E:"
