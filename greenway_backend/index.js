const express = require('express');
const bcrypt = require('bcrypt');
const mysql = require('mysql2');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

const app = express();
app.use(express.json());
app.use(cors());
app.use('/uploads', express.static('uploads')); // Akses publik folder foto

const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: '',
    database: 'greenway_db'
});

// Konfigurasi Multer untuk Simpan Gambar
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const dir = './uploads';
        if (!fs.existsSync(dir)) fs.mkdirSync(dir);
        cb(null, dir);
    },
    filename: (req, file, cb) => {
        cb(null, Date.now() + path.extname(file.originalname));
    }
});
const upload = multer({ storage: storage });

app.post('/register', async (req, res) => {
    const { username, password, full_name } = req.body;
    const hashedPassword = await bcrypt.hash(password, 10);
    const query = "INSERT INTO users (username, password, full_name) VALUES (?, ?, ?)";
    db.query(query, [username, hashedPassword, full_name], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.json({ message: "User berhasil didaftarkan!" });
    });
});

app.post('/login', (req, res) => {
    const { username, password } = req.body;
    const query = "SELECT * FROM users WHERE username = ?";
    db.query(query, [username], async (err, results) => {
        if (err || results.length === 0) return res.status(401).json({ message: "User tidak ditemukan" });
        const user = results[0];
        const isMatch = await bcrypt.compare(password, user.password);
        if (isMatch) {
            const token = jwt.sign({ id: user.id }, 'SECRET_KEY', { expiresIn: '1h' });
            res.json({ success: true, token, user: { id: user.id, name: user.full_name, image: user.profile_image } });
        } else {
            res.status(401).json({ message: "Password salah" });
        }
    });
});

// Endpoint Update Profil & Foto
app.post('/update-profile', upload.single('image'), (req, res) => {
    const { username, full_name } = req.body;
    let query = "UPDATE users SET full_name = ? WHERE username = ?";
    let params = [full_name, username];
    let newImageUrl = null;

    if (req.file) {
        newImageUrl = `http://192.168.1.24:3000/uploads/${req.file.filename}`;
        query = "UPDATE users SET full_name = ?, profile_image = ? WHERE username = ?";
        params = [full_name, newImageUrl, username];
    }

    db.query(query, params, (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        // Kirim balik image_url ke Flutter[cite: 12]
        res.json({ 
            message: "Profil berhasil diperbarui!", 
            full_name: full_name,
            image_url: newImageUrl 
        });
    });
});

app.listen(3000, () => console.log("Server running on port 3000"));