# Rancangan Pengujian GreenWay

## Ruang Lingkup

Aplikasi yang diuji:

- Backend Node/Express: `greenway_backend/index.js`
- Mobile Flutter: `greenway_mobile/lib/screens/*.dart`
- Fokus endpoint: `/register`, `/login`, `/update-profile`, `/uploads`
- Fokus mobile: login, register, update profil, Eco Hunt, AI Scan, Green Bot

## White Box Testing

Tujuan: memeriksa struktur kode, alur logika, dan kontrol keamanan dari source code.

Kasus uji:

| ID | Area | Skenario | Ekspektasi |
| --- | --- | --- | --- |
| WB-01 | SQL | Query memakai parameter binding | Tidak ada string concatenation untuk input user |
| WB-02 | Password | Password disimpan dengan hash | Ada `bcrypt.hash` dan `bcrypt.compare` |
| WB-03 | JWT | Secret tidak hard-coded | Secret berasal dari environment |
| WB-04 | CORS | CORS tidak terbuka bebas di produksi | Origin dibatasi |
| WB-05 | Upload | File upload divalidasi tipe dan ukuran | Ada `fileFilter` dan `limits` |
| WB-06 | Mobile secret | API key tidak berada di source client | Key dipindah ke backend/env |
| WB-07 | Error handling | Error database tidak membocorkan detail | Response umum, detail di log server |

Script: `npm run test:whitebox`

## Black Box Testing

Tujuan: menguji aplikasi dari sisi pengguna/API tanpa membaca source.

Kasus uji:

| ID | Endpoint | Skenario | Ekspektasi |
| --- | --- | --- | --- |
| BB-01 | `POST /login` | Body kosong | HTTP 400/401, tidak crash |
| BB-02 | `POST /login` | User tidak ada | HTTP 401 |
| BB-03 | `POST /register` | Data valid unik | HTTP 200/201 |
| BB-04 | `POST /register` | Field kosong | HTTP 400, bukan 500 |
| BB-05 | `GET /uploads/not-found.jpg` | File tidak ada | HTTP 404 |

Script: `npm run test:blackbox`

## Security Testing

Tujuan: mencari risiko umum secara aman pada aplikasi sendiri.

Kasus uji:

| ID | Risiko | Skenario | Ekspektasi |
| --- | --- | --- | --- |
| SEC-01 | SQL Injection | Username berisi `' OR '1'='1` | Login tetap gagal |
| SEC-02 | Brute force | Beberapa login gagal cepat | Ada rate limit atau minimal semua gagal |
| SEC-03 | Upload abuse | Upload `.txt` sebagai image | Ditolak |
| SEC-04 | Auth bypass | Update profil tanpa token | Ditolak |
| SEC-05 | Secret exposure | Hard-coded JWT/API key | Tidak ditemukan |

Script: `npm run test:security`

## STLC

### Unit Testing

Unit yang perlu diuji:

- Validasi input register/login.
- Hash password.
- Generate dan verify JWT.
- Validasi upload file.
- Parser JSON dari Eco Hunt.
- Local database score di Flutter.

Script awal: `npm run test:whitebox`

### Load Testing

Tujuan: mengukur respons saat traffic normal meningkat.

Parameter default:

- Total request: 100
- Concurrency: 10
- Endpoint: `/login`

Metrik:

- Success rate
- Error rate
- Average latency
- P95 latency

Script: `npm run test:load`

### Stress Testing

Tujuan: mengetahui batas saat concurrency dinaikkan bertahap.

Parameter default:

- Concurrency steps: 10, 25, 50, 100
- Request per step: 100

Metrik:

- Error rate per step
- P95 latency per step
- Titik mulai gagal/timeout

Script: `npm run test:stress`

### Integration Testing

Tujuan: menguji alur antar-komponen.

Kasus uji:

| ID | Alur | Ekspektasi |
| --- | --- | --- |
| INT-01 | Register user baru lalu login | Token diterima |
| INT-02 | Login lalu update profil | Profil berubah |
| INT-03 | Mobile login ke backend | Session tersimpan |

Script: `npm run test:integration`

## Temuan Awal dari Source

Temuan ini berdasarkan pembacaan source saat skrip dibuat:

- JWT secret masih hard-coded (`SECRET_KEY`).
- API key Groq hard-coded di beberapa file Flutter.
- Endpoint update profil belum memakai autentikasi token.
- Upload image belum membatasi MIME/extension/ukuran.
- CORS masih terbuka.
- Error database dikirim langsung ke client.
- URL backend dan image masih hard-coded ke IP lokal.
