# Demo CRUD Flutter

Aplikasi praktikum Modul XIII memakai endpoint JSONPlaceholder. Jalankan
`flutter pub get`, sambungkan perangkat Android, lalu jalankan `flutter run`.

- **Baca contoh** memuat post uji nomor 1.
- **Tambah post** mengirim data dari formulir. Card menampilkan respons server.
- **Update** dan **Delete** tersedia melalui menu Card. Keduanya memakai
  endpoint post uji nomor 1, karena ID hasil POST bersifat simulasi.
- Data pada layar disimpan selama sesi aplikasi. JSONPlaceholder mensimulasikan
  perubahan pada server.

Jalankan `flutter analyze` dan `flutter test` untuk memeriksa proyek. Tes
menggunakan respons HTTP sintetis. Untuk merekam ulang tangkapan layar, jalankan
`flutter test --dart-define=SCREENSHOT_DIR=<folder-yang-sudah-ada>`.
