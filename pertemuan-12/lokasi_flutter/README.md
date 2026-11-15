# Lokasi Saya

Praktikum Mobile Programming Modul 12. Aplikasi mengambil satu posisi terkini
setiap kali pengguna menekan tombol, lalu meminta alamat ke geocoder perangkat.

## Jalankan di Android

1. Siapkan Flutter, Android SDK, dan perangkat atau emulator Android dengan
   layanan lokasi aktif. Pada emulator, atur posisi melalui Extended Controls.
2. Dari folder ini, jalankan `flutter pub get` dan `flutter run`.
3. Tekan **Tampilkan lokasi saat ini** dan izinkan akses saat aplikasi digunakan.
   Kartu menampilkan koordinat dan informasi alamat yang tersedia.

Untuk menguji kegagalan, matikan layanan lokasi dan tekan tombol lagi. Untuk
menguji penolakan permanen, blokir izin lewat pengaturan aplikasi dan coba lagi.

## Verifikasi kode

```text
flutter analyze
flutter test
```

Tes widget menjalankan empat keadaan UI dengan hasil layanan lokasi sintetis.
Untuk merekam ulang, berikan direktori yang sudah ada lewat
`--dart-define=SCREENSHOT_DIR=<path-absolut>` pada `flutter test`.
