# Hapus eject dari %LOCALAPPDATA%\eject dan dari PATH user
$installDir = Join-Path $env:LOCALAPPDATA "eject"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ($userPath) {
    $entries = $userPath -split ";" | Where-Object { $_ -ne "" -and $_ -ne $installDir }
    [Environment]::SetEnvironmentVariable("Path", ($entries -join ";"), "User")
}
Remove-Item -Recurse -Force $installDir -ErrorAction SilentlyContinue
Write-Host "eject sudah dihapus."
