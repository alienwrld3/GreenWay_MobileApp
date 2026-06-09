# GreenWay Test Suite

Folder ini berisi rancangan dan skrip pengujian untuk tugas:

- White box testing
- Black box testing
- Security testing
- STLC: Unit testing, load testing, stress testing, integration testing

Semua skrip hanya ditujukan untuk project lokal/izin sendiri. Jalankan backend lebih dulu:

```powershell
node greenway_backend/index.js
```

Lalu jalankan pengujian:

```powershell
npm run test:whitebox
npm run test:blackbox
npm run test:security
npm run test:load
npm run test:stress
npm run test:integration
npm run test:all
```

Variabel opsional:

```powershell
$env:BASE_URL="http://127.0.0.1:3000"
$env:LOAD_REQUESTS="100"
$env:LOAD_CONCURRENCY="10"
$env:STRESS_STEPS="10,25,50,100"
```

Catatan hasil penting:

- White box akan memindai risiko kode seperti hard-coded secret/API key, CORS terbuka, upload tanpa filter, dan endpoint tanpa autentikasi.
- Black box menguji respons endpoint dari luar tanpa membaca implementasi.
- Security test berisi payload defensif untuk validasi SQL injection, brute force ringan, dan upload file tidak valid.
- Load/stress test memakai request ringan agar aman untuk laptop lokal.
- Integration test mengecek alur register lalu login.
