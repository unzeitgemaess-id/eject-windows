# eject-windows

Command `eject` untuk Windows: eject flashdisk, SD card, atau HDD/SSD eksternal dari CMD/PowerShell tanpa membuka File Explorer dan tanpa jendela terminal yang tertinggal.

- `eject` memilih flashdisk lewat dialog berisi nama drive (label, model, huruf drive, ukuran). Kalau hanya ada satu drive USB/SD, langsung diproses.
- `eject E` langsung eject drive `E:`.
- Hasilnya muncul sebagai notifikasi yang hilang sendiri setelah 4 detik, tanpa tombol OK.
- Drive internal (C:, D:, dst) tidak pernah ikut terdaftar karena deteksi memakai bus type USB/SD.
- Kalau eject pertama gagal, Explorer di-restart sekali lalu dicoba ulang (menangani handle yang masih dipegang Explorer, termasuk Recent Files).

## Instalasi

```powershell
git clone https://github.com/unzeitgemaess-id/eject-windows.git
cd eject-windows
powershell -ExecutionPolicy Bypass -File install.ps1
```

Tutup dan buka lagi CMD/PowerShell, lalu jalankan `eject`. Installer menyalin file ke `%LOCALAPPDATA%\eject` dan menambahkannya ke PATH user secara permanen, tanpa hak administrator. Setelah `git pull`, jalankan `install.ps1` lagi untuk memperbarui.

## Isi repositori

| File | Fungsi |
|---|---|
| `eject.vbs` | Launcher senyap, jalan tanpa jendela yang berkedip |
| `eject-auto.ps1` | Logika utama: deteksi drive, dialog pilihan, eject, notifikasi |
| `install.ps1` / `uninstall.ps1` | Pasang dan hapus |

## Troubleshooting

- **SmartScreen memblokir file:** klik kanan file, Properties, centang Unblock. Installer sudah melakukan ini otomatis.
- **`eject` tidak dikenali:** pastikan terminal dibuka ulang setelah instalasi.
- **Gagal eject karena masih dipakai:** ada aplikasi lain yang membuka file di drive itu. Cek lewat `resmon` (CPU, Associated Handles).

## Lisensi

MIT
