param(
    [string]$DriveLetter = ""
)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Notifikasi non-blocking yang hilang otomatis setelah beberapa detik (tidak perlu klik OK)
function Show-Notify($title, $msg, $type) {
    # $type: "Info", "Warning", "Error", "None"
    $notifyIcon = New-Object System.Windows.Forms.NotifyIcon
    $notifyIcon.Icon = [System.Drawing.SystemIcons]::Information
    $notifyIcon.Visible = $true
    $notifyIcon.BalloonTipTitle = $title
    $notifyIcon.BalloonTipText = $msg
    $notifyIcon.BalloonTipIcon = $type
    $notifyIcon.ShowBalloonTip(4000)  # 4000 ms = 4 detik

    # Tunggu sebentar biar balloon sempat muncul sebelum icon di-dispose
    Start-Sleep -Milliseconds 4300
    $notifyIcon.Dispose()
}

# 1. Kumpulkan semua disk yang terhubung via USB/SD, beserta nama dan drive letter-nya
function Get-UsbDrives {
    $result = @()
    try {
        $usbDisks = Get-Disk | Where-Object { $_.BusType -in @('USB', 'SD') }
        foreach ($disk in $usbDisks) {
            $partitions = Get-Partition -DiskNumber $disk.Number -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter }
            foreach ($p in $partitions) {
                $vol = Get-Volume -DriveLetter $p.DriveLetter -ErrorAction SilentlyContinue
                $label = if ($vol -and $vol.FileSystemLabel) { $vol.FileSystemLabel } else { "(Tanpa Label)" }
                $sizeGB = [math]::Round($disk.Size / 1GB, 1)
                $friendly = $disk.FriendlyName
                $displayName = "$label - $friendly ($($p.DriveLetter): , $sizeGB GB)"
                $result += [PSCustomObject]@{
                    DriveLetter = "$($p.DriveLetter):"
                    DisplayName = $displayName
                }
            }
        }
    } catch {}
    return $result
}

# 2. Fungsi eject satu drive letter
function Eject-Drive($d) {
    try {
        $shell = New-Object -ComObject Shell.Application
        $shell.Windows() | ForEach-Object {
            if ($_.LocationURL -like "file:///$($d.Replace(':',''))*") {
                $_.Quit()
            }
        }
    } catch {}

    Start-Sleep -Milliseconds 400

    $shellApp = New-Object -ComObject Shell.Application
    $driveObj = $shellApp.Namespace(17).ParseName($d)
    if (-not $driveObj) { return $false }

    try {
        $driveObj.InvokeVerb("Eject")
        return $true
    } catch {
        return $false
    }
}

# 3. Fungsi proses eject + retry + notifikasi (biar tidak duplikat kode di 3 tempat)
function Process-Eject($target, $displayName) {
    $ok = Eject-Drive $target
    if (-not $ok) {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Start-Process explorer.exe
        Start-Sleep -Seconds 2
        $ok = Eject-Drive $target
    }

    if ($ok) {
        Show-Notify "Eject Drive" "Berhasil di-eject: $displayName" "Info"
    } else {
        Show-Notify "Eject Drive" "Gagal eject $displayName (masih dipakai proses lain)." "Warning"
    }
}

# ============================================================
# MODE 1: Drive letter diberikan langsung lewat parameter -> proses tanpa dialog
# ============================================================
if ($DriveLetter -ne "") {
    $target = "$($DriveLetter.TrimEnd(':')):"
    Process-Eject $target $target
    exit
}

# ============================================================
# MODE 2: Tanpa parameter -> tampilkan dialog pilihan nama flashdisk
# ============================================================
$drives = Get-UsbDrives

if ($drives.Count -eq 0) {
    Show-Notify "Eject Drive" "Tidak ada flashdisk/SD card yang terdeteksi." "Warning"
    exit
}

if ($drives.Count -eq 1) {
    Process-Eject $drives[0].DriveLetter $drives[0].DisplayName
    exit
}

# Lebih dari satu drive -> tampilkan form pilihan (ini tetap perlu interaksi klik, wajar karena memang harus memilih)
$form = New-Object System.Windows.Forms.Form
$form.Text = "Pilih Flashdisk untuk Eject"
$form.Size = New-Object System.Drawing.Size(420, 320)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false
$form.TopMost = $true

$label = New-Object System.Windows.Forms.Label
$label.Text = "Pilih flashdisk yang mau di-eject:"
$label.Location = New-Object System.Drawing.Point(10, 10)
$label.Size = New-Object System.Drawing.Size(380, 20)
$form.Controls.Add($label)

$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location = New-Object System.Drawing.Point(10, 35)
$listBox.Size = New-Object System.Drawing.Size(385, 180)
foreach ($d in $drives) {
    [void]$listBox.Items.Add($d.DisplayName)
}
$listBox.SelectedIndex = 0
$form.Controls.Add($listBox)

$btnOk = New-Object System.Windows.Forms.Button
$btnOk.Text = "Eject"
$btnOk.Location = New-Object System.Drawing.Point(215, 230)
$btnOk.Size = New-Object System.Drawing.Size(80, 30)
$btnOk.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.Controls.Add($btnOk)
$form.AcceptButton = $btnOk

$btnCancel = New-Object System.Windows.Forms.Button
$btnCancel.Text = "Batal"
$btnCancel.Location = New-Object System.Drawing.Point(305, 230)
$btnCancel.Size = New-Object System.Drawing.Size(80, 30)
$btnCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
$form.Controls.Add($btnCancel)
$form.CancelButton = $btnCancel

$result = $form.ShowDialog()

if ($result -ne [System.Windows.Forms.DialogResult]::OK -or $listBox.SelectedIndex -lt 0) {
    exit
}

$selected = $drives[$listBox.SelectedIndex]
Process-Eject $selected.DriveLetter $selected.DisplayName
