# GreenWay - Aplikasi Edukasi Lingkungan Berbasis Mobile

## Nama Kelompok
- **Kelompok :** [Nama Kelompok]

---

## Anggota Kelompok

### Mata Kuliah: Teknologi Pemrograman Mobile
1. [Nama Anggota 1]
2. [Nama Anggota 2]

### Mata Kuliah: Praktikum Teknologi Pemrograman Mobile
1. [Nama Anggota 1]
2. [Nama Anggota 2]

---

## 📱 Deskripsi Aplikasi

GreenWay adalah aplikasi mobile berbasis Flutter yang dirancang untuk meningkatkan kesadaran lingkungan melalui fitur-fitur edukatif dan interaktif. Aplikasi ini menyediakan:

- **AI Scan**: Fitur untuk menganalisis jenis sampah menggunakan AI dan memberikan rekomendasi cara penanganan yang tepat
- **Eco Hunt**: Game edukatif untuk mengumpulkan poin dengan menyelesaikan misi ramah lingkungan
- **Green Bot**: Chatbot untuk memberikan konsultasi dan tips seputar lingkungan
- **Currency Converter**: Konverter mata uang yang terintegrasi
- **User Profile**: Manajemen profil pengguna dengan autentikasi biometrik (fingerprint)

### Stack Teknologi

**Frontend (Mobile):**
- Flutter + Dart
- Provider / State Management
- SQLite (Local Database)
- Camera Integration

**Backend:**
- Node.js + Express.js
- MySQL Database
- JWT Authentication
- Groq API (untuk AI Features)

---

## 🧪 Hasil Testing

### Unit Testing
| Komponen | Status | Catatan |
|----------|--------|---------|
| Authentication | ✅ Passed | Login, Register, Token validation |
| AI Scan Feature | ✅ Passed | Image processing dan AI analysis |
| Eco Hunt Game | ✅ Passed | Point calculation, mission tracking |
| Profile Management | ✅ Passed | Update profile, Biometric auth |

### Integration Testing
| Skenario | Status | Catatan |
|----------|--------|---------|
| End-to-End Login | ✅ Passed | Login flow berfungsi normal |
| AI Analysis Request | ✅ Passed | Request ke backend dan AI API |
| Database Operations | ✅ Passed | CRUD operations berjalan lancar |
| API Communication | ✅ Passed | Request/Response handling |

### Security Testing
| Aspek | Status | Catatan |
|-------|--------|---------|
| Authentication | ✅ Passed | Token validation, JWT security |
| Authorization | ✅ Passed | Role-based access control |
| Data Encryption | ✅ Passed | Sensitive data handling |
| API Security | ✅ Passed | CORS, Rate limiting |

---

## 📂 Struktur Project

```
TugasAkhir_TPM-C_122_197/
├── greenway_backend/          # Backend Node.js
│   ├── index.js               # Main server
│   ├── package.json           # Dependencies
│   └── uploads/               # File upload directory
├── greenway_mobile/           # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/           # UI Screens
│   │   ├── services/          # API Services
│   │   ├── models/            # Data Models
│   │   ├── helpers/           # Utilities
│   │   ├── widgets/           # Reusable Widgets
│   │   └── config/            # Configuration
│   ├── pubspec.yaml           # Flutter dependencies
│   └── android/               # Android-specific files
├── security-tests/            # Security & Performance Tests
│   ├── blackbox.js
│   ├── whitebox.js
│   ├── security.js
│   ├── load.js
│   └── integration.js
└── README.md                  # This file
```

---

## 🚀 Cara Menjalankan

### Backend Setup
```bash
cd greenway_backend
npm install
# Setup .env file dengan konfigurasi database dan API keys
npm start
```

### Mobile Setup
```bash
cd greenway_mobile
flutter pub get
flutter run
```

---

## 📋 Requirements

- **Mobile**: Flutter 3.0+, Android SDK, iOS (optional)
- **Backend**: Node.js 14+, MySQL 5.7+
- **API Keys**: Groq API Key untuk fitur AI

---

## 📝 Catatan

[Tambahkan catatan penting atau informasi tambahan di sini]

---

## 📞 Kontak

[Informasi kontak kelompok jika diperlukan]

---

**Last Updated**: 2026-06-09
