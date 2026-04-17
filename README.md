# 🛒 LocalMart Project Ecosystem

**LocalMart** adalah platform *Hyper-local Super App* yang dirancang untuk memperkuat ekosistem ekonomi digital di tingkat daerah (seperti Sumbawa Barat). Platform ini menghubungkan pelaku usaha lokal, penyedia jasa, pengemudi, dan pengguna dalam satu ekosistem yang terintegrasi, aman, dan modern.

## 🌟 Visi Proyek
Membangun jembatan digital bagi UMKM dan layanan lokal agar dapat bersaing di era digital dengan user experience kelas premium, sekaligus memudahkan masyarakat dalam memenuhi kebutuhan sehari-hari mulai dari makanan, transportasi, hingga jasa profesional.

## 🚀 Fitur Utama
- **Modular Discovery**: Sistem pencarian dan penemuan produk yang cerdas di berbagai kategori (Food, Rental, Kost, UMKM, dll).
- **Real-time Interaction**: Sistem pengiriman pesan langsung antara pembeli dan penjual untuk negosiasi dan konfirmasi.
- **Store Management**: Dashboard mandiri bagi pemilik toko untuk mengelola stok, status pesanan, dan profil toko.
- **Secure Transaction**: Alur checkout yang teroptimasi dengan dukungan berbagai metode pembayaran lokal.
- **Admin Control Center**: Panel manajemen terpusat untuk memoderasi konten, banner promo, dan verifikasi mitra.

## 🛠 Teknologi & Arsitektur
Proyek ini menggunakan arsitektur **Decoupled** (Terpisah) untuk skalabilitas maksimal:
- **Backend (API Core)**: Dibangun dengan **Golang (Gin Framework)** yang ringan dan performa tinggi, menggunakan **GORM** untuk manajemen database SQLite.
- **Frontend (Mobile App)**: Dikembangkan dengan **Flutter** menggunakan state management **GetX** untuk performa UI yang reaktif dan *smooth*.
- **Admin Panel (CMS)**: Aplikasi web berbasis **HTML5 & Vanilla Javascript** yang mandiri, memberikan kontrol penuh atas konten aplikasi tanpa membebani server API.

---

## 📁 Struktur Direktori
- `backend/`: API Server menggunakan Golang (Gin Framework).
- `admin-panel/`: Dashboard CMS menggunakan HTML/JS murni (Mandiri).
- `frontend/`: Aplikasi mobile menggunakan Flutter (Dart).

---

## 🚀 Cara Menjalankan Sistem

### 1. Backend (API)
Pastikan Anda memiliki [Go](https://go.dev/) terinstall.
```bash
cd backend
go run cmd/api/main.go
```
*Server akan berjalan di `http://localhost:8080`*

### 2. Admin Panel (CMS)
Admin Panel sekarang berjalan secara mandiri dan tidak lagi dilayani oleh backend.
- Gunakan **Live Server** (ekstensi VS Code).
- Klik kanan pada `admin-panel/index.html` -> `Open with Live Server`.
- Secara default akan berjalan di `http://localhost:5500`.

> **Konfigurasi API:** Jika backend Anda berjalan di port yang berbeda, ubah variabel `API_URL` di bagian atas file `admin-panel/js/admin.js`.

### 3. Frontend (Flutter App)
```bash
cd frontend
flutter run
```

---

## 🔐 Konfigurasi CORS & IP LAN
Jika Anda ingin mengakses Admin Panel dari perangkat lain dalam jaringan (IP LAN):
1. Cek IP lokal mesin Anda (misal: `192.168.1.10`).
2. Jalankan Admin Panel menggunakan server yang mendukung binding IP atau update `ADMIN_PANEL_URL` di `.env` (untuk referensi).
3. Backend secara otomatis mengizinkan origin dari request (`Access-Control-Allow-Origin: origin`), sehingga selama browser mengirimkan header Origin, koneksi akan berhasil.

---

## 🛠 Pengembangan
- **Database**: Menggunakan SQLite (`localmart.db`).
- **Auth**: Menggunakan JWT untuk Admin dan User.
- **Uploads**: Gambar disimpan di folder `backend/uploads/` dan dapat diakses via `http://localhost:8080/uploads/filename`.
