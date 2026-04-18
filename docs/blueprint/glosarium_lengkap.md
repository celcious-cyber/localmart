# GLOSARIUM LENGKAP: LOCALMART KSB
**Kamus Istilah Strategis, Teknis, dan Operasional Dokumen Blueprint**

Glosarium ini disusun untuk memberikan pemahaman mendalam bagi pemangku kepentingan mengenai istilah-istilah 'berat' yang digunakan dalam naskah strategic masterplan LocalMart.

---

## 1. ARSITEKTUR & PENGEMBANGAN (Architecture & Development)

*   **AI-Augmentation:** Pendekatan pengembangan di mana kapasitas manusia diperbesar melalui penggunaan kecerdasan buatan untuk otomatisasi tugas dan peningkatan kualitas output.
*   **Clean Architecture:** Pola desain perangkat lunak yang memisahkan logika bisnis inti dari implementasi teknis eksternal (seperti database atau UI), sehingga sistem mudah diuji dan dipelihara.
*   **Decoupling:** Strategi pemisahan komponen sistem (Backend, Frontend, Admin) agar dapat beroperasi, diperbarui, dan diskalakan secara independen tanpa saling merusak.
*   **Goroutines:** Unit eksekusi asinkronus yang sangat ringan dalam bahasa pemrograman Go, memungkinkan server menangani ribuan tugas secara bersamaan dengan penggunaan memori minimal.
*   **High-Concurrency:** Kemampuan sistem untuk menangani banyak permintaan data yang masuk secara bersamaan dalam waktu yang sangat singkat tanpa penurunan performa.
*   **Modular Discovery:** Kemampuan sistem aplikasi untuk membagi penemuan produk atau layanan berdasarkan kategori bisnis (modul) yang berbeda dalam satu platform.
*   **Pair Programming (AI-Powered):** Teknik penulisan kode di mana pengembang manusia berkolaborasi langsung dengan asisten AI untuk validasi logika dan penulisan standar kode yang tinggi.
*   **Reverse Proxy (Nginx):** Server perantara yang menerima permintaan dari internet dan mengarahkannya ke server aplikasi internal, berfungsi sebagai lapisan keamanan dan optimasi.
*   **SDLC (Software Development Life Cycle):** Seluruh siklus hidup pengembangan perangkat lunak, mulai dari tahap perencanaan, desain, coding, testing, hingga maintenance.
*   **Single Core, Multi-Logic:** Arsitektur di mana satu mesin backend utama melayani berbagai logika bisnis yang berbeda melalui sistem tagging dan modularitas.
*   **Stateless Authentication:** Mekanisme pembuktian identitas di mana server tidak menyimpan riwayat sesi (session) pengguna di memori, melainkan memverifikasi setiap permintaan secara mandiri melalui token.
*   **VPS (Virtual Private Server):** Server virtual pribadi yang disewa di lingkungan cloud untuk menghosting aplikasi dengan kendali penuh atas sistem operasi dan sumber daya.

---

## 2. MANAJEMEN DATA & BASIS DATA (Data Management & Database)

*   **ACID (Atomicity, Consistency, Isolation, Durability):** Seperangkat prinsip yang menjamin setiap transaksi database berjalan dengan aman dan konsisten, mencegah kerusakan data saat terjadi kegagalan sistem.
*   **Auto-Backup:** Mekanisme pencadangan data secara otomatis dan berkala ke penyimpanan yang berbeda untuk mengantisipasi kehilangan data akibat bencana teknis.
*   **GORM:** Library Object-Relational Mapper untuk bahasa Go yang berfungsi menerjemahkan logika kode menjadi perintah database SQL secara aman dan cepat.
*   **JSONB:** Format penyimpanan data terenkripsi biner dalam PostgreSQL yang memungkinkan pencarian data fleksibel (non-relasional) dilakukan dengan kecepatan tinggi.
*   **Many-to-Many (M2M):** Skema relasi database di mana banyak baris data di satu tabel dapat berhubungan dengan banyak baris data di tabel lain (misal: satu toko memiliki banyak modul bisnis).
*   **PostgreSQL:** Sistem manajemen basis data relasional tingkat enterprise yang dikenal dengan keandalannya, fitur keamanannya, dan kemampuannya menangani beban data besar.
*   **Prepared Statements:** Metode pengiriman perintah ke database yang memisahkan antara struktur perintah dan data masukan, secara otomatis melumpuhkan serangan pembajakan data.
*   **Row-Level Locking:** Kemampuan database untuk mengunci hanya baris data tertentu yang sedang diubah, sehingga data lain di tabel yang sama tetap dapat diakses oleh pengguna lain secara bersamaan.

---

## 3. KEAMANAN & PRIVASI (Security & Privacy)

*   **Active Order Guard:** Logika keamanan yang melarang penghapusan entitas (akun/toko) jika masih terdapat transaksi yang sedang berjalan untuk melindungi hak konsumen.
*   **CORS (Cross-Origin Resource Sharing):** Mekanisme keamanan web yang menentukan apakah sebuah situs web diizinkan untuk mengakses data dari server API yang berbeda.
*   **CSP (Content Security Policy):** Lapisan keamanan tambahan yang membantu mendeteksi dan memitigasi jenis serangan tertentu, termasuk pencurian data dan peretasan situs.
*   **CSRF (Cross-Site Request Forgery):** Jenis celah keamanan di mana penyerang berupaya memaksa pengguna melakukan aksi yang tidak diinginkan di platform yang sudah terautentikasi.
*   **Environment Variables (.env):** Cara penyimpanan konfigurasi sensitif (seperti kunci rahasia atau password database) di luar kode sumber aplikasi untuk keamanan maksimal.
*   **HS256:** Algoritma enkripsi yang digunakan untuk menandatangani token keamanan secara digital guna menjamin bahwa token tersebut tidak dimanipulasi oleh pihak luar.
*   **JWT (JSON Web Token):** Standar industri untuk pertukaran informasi identitas yang aman dalam bentuk objek JSON terenkripsi.
*   **Self-Destruction Logic (Data Privacy):** Protokol penghapusan permanen di mana sistem tidak hanya menghapus data di database, tetapi juga menghapus aset fisik (seperti foto) dari server penyimpanan.
*   **SQL Injection:** Teknik peretasan di mana penyerang mencoba menyisipkan perintah database berbahaya melalui formulir masukan pengguna.
*   **XSS (Cross-Site Scripting):** Serangan keamanan di mana peretas mencoba menyuntikkan skrip berbahaya ke dalam halaman web yang dilihat oleh pengguna lain.

---

## 4. FINANSIAL & COMPLIANCE (Financial & Compliance)

*   **Alternative Credit Scoring:** Penggunaan data perilaku transaksi harian (non-konvensional) untuk menilai kelayakan kredit pelaku UMKM yang tidak memiliki agunan bank.
*   **Audit Trail:** Rekam jejak permanen dan tidak dapat diubah dari setiap aksi atau perubahan data yang terjadi dalam sistem, digunakan untuk kebutuhan pemeriksaan/audit keuangan.
*   **Financial Inclusion:** Upaya penyediaan akses layanan keuangan yang terjangkau dan aman bagi masyarakat yang selama ini belum terjangkau oleh perbankan konvensional.
*   **Idempotency Key:** Kunci unik yang disertakan dalam proses pembayaran untuk menjamin bahwa transaksi yang sama tidak akan diproses dua kali meskipun terjadi gangguan jaringan atau pengulangan perintah.
*   **OJK Compliance:** Kepatuhan terhadap standar regulasi yang ditetapkan oleh Otoritas Jasa Keuangan terkait operasional teknologi finansial dan perlindungan data konsumen.
*   **Open Banking:** Praktik di mana lembaga perbankan memberikan akses data atau layanan (seperti Virtual Account) kepada platform pihak ketiga melalui integrasi API yang aman.
*   **Payment Gateway:** Layanan perantara yang memfasilitasi transaksi pembayaran secara online antara pembeli, penjual, dan lembaga perbankan.
*   **Webhooks:** Notifikasi asinkronus dari satu sistem ke sistem lain (misal: bank memberi tahu server LocalMart bahwa pembayaran telah diterima secara otomatis).

---

## 5. STRATEGI BISNIS & OPERASIONAL (Business Strategy & Operations)

*   **BEP (Break-Even Point):** Titik di mana total pendapatan sama dengan total biaya operasional, menandakan bisnis mulai masuk ke fase menghasilkan laba.
*   **Big Data Analytics:** Analisis terhadap kumpulan data besar untuk menemukan pola tersembunyi, tren pasar, dan informasi berguna untuk pengambilan keputusan strategis.
*   **Capital Outflow:** Larinya arus modal atau uang dari suatu daerah ke luar (nasional/global), yang jika tidak dikendalikan dapat melemahkan ekonomi daerah tersebut.
*   **Community Trust:** Kekuatan ekonomi yang berbasis pada landasan kepercayaan dan kedekatan budaya antar masyarakat di suatu lokalitas.
*   **Dynamic Reinvestment:** Strategi memutar kembali keuntungan atau surplus perusahaan ke dalam pengembangan teknologi dan ekspansi pasar secara berkala.
*   **Economies of Scale:** Penghematan biaya yang diperoleh melalui peningkatan skala operasional, di mana biaya per unit menjadi lebih rendah seiring bertambahnya jumlah pengguna.
*   **Evidence-Based Policy:** Kebijakan publik atau bisnis yang diambil berdasarkan bukti data yang kuat dan akurat dari lapangan, bukan sekadar asumsi.
*   **Giant's Friction:** Hambatan atau kesulitan yang dialami perusahaan besar (nasional) saat mencoba beroperasi di tingkat lokal yang sangat spesifik karena struktur yang terlalu kaku.
*   **Hyper-Local Edge:** Keunggulan strategis yang dimiliki platform lokal karena pemahaman yang lebih dalam terhadap geografis, budaya, dan kebutuhan spesifik masyarakat setempat.
*   **Lean Team Model:** Struktur organisasi minimalis yang mengutamakan produktivitas tinggi dan efisiensi biaya melalui pemanfaatan teknologi maksimal.
*   **Logistics Overhead:** Biaya tambahan atau hambatan yang muncul dalam distribusi barang, terutama pada wilayah geografi yang sulit atau rantai kurir yang tidak efisien.
*   **OPEX (Operational Expenditure):** Biaya harian yang dikeluarkan perusahaan untuk menjalankan operasional bisnis, seperti biaya server dan gaji tim.
*   **Resource Optimization:** Upaya memaksimalkan penggunaan sumber daya (seperti CPU dan RAM server) untuk mendapatkan performa tertinggi dengan biaya serendah mungkin.

---

## 6. USER EXPERIENCE & FRONTEND (UX & Frontend)

*   **Category Locking:** Mekanisme penguncian pilihan kategori produk berdasarkan jenis layanan toko untuk menjaga kualitas dan keteraturan data marketplace.
*   **Deep Linking:** Penggunaan tautan spesifik yang langsung mengarahkan pengguna ke bagian atau fitur tertentu di dalam aplikasi, bukan hanya ke halaman depan.
*   **Flutter:** Framework buatan Google untuk membangun aplikasi mobile yang indah dan berperforma tinggi untuk Android dan iOS dari satu basis kode.
*   **GetX:** Solusi manajemen status aplikasi di Flutter yang sangat cepat, memungkinkan antarmuka aplikasi bereaksi secara instan terhadap perubahan data.
*   **LocalStorage:** Ruang penyimpanan kecil di dalam peramban web yang digunakan untuk menyimpan preferensi atau status navigasi pengguna secara permanen.
*   **Permanent Controllers:** Komponen dalam aplikasi yang tetap aktif di memori untuk menjaga agar data masukan pengguna tidak hilang saat berpindah-pindah layar.
*   **Smart Onboarding:** Proses perkenalan atau pendaftaran pengguna baru yang dirancang secara cerdas untuk meminimalisir kesulitan dan mempercepat waktu penggunaan aktif.
*   **State Recovery:** Kemampuan aplikasi untuk mengembalikan tampilan dan data ke posisi terakhir sebelum terjadi interupsi (seperti refresh halaman atau aplikasi tertutup).
*   **Zero-Entry Friction:** Strategi untuk menghilangkan hambatan teknis atau administratif bagi pengguna baru (terutama UMKM) saat ingin bergabung ke platform.
*   **Zero-Friction UX:** Filosofi desain antarmuka yang mengutamakan kemudahan ekstrem agar pengguna dapat mencapai tujuannya tanpa kebingungan atau hambatan sinyal.
