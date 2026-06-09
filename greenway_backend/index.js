const express = require('express');
const bcrypt = require('bcrypt');
const mysql = require('mysql2');
const jwt = require('jsonwebtoken');
const cors = require('cors');
const multer = require('multer');
const path = require('path');
const fs = require('fs');

require('dotenv').config({ path: path.join(__dirname, '.env') });

const app = express();
const PORT = Number(process.env.PORT || 3000);
const JWT_SECRET = process.env.JWT_SECRET || 'dev-only-change-this-secret';
const PUBLIC_BASE_URL = process.env.PUBLIC_BASE_URL || `http://localhost:${PORT}`;
const aiModels = {
    ai_scan: process.env.AI_SCAN_MODEL || 'meta-llama/llama-4-scout-17b-16e-instruct',
    eco_hunt: process.env.ECO_HUNT_MODEL || 'meta-llama/llama-4-scout-17b-16e-instruct',
    chatbot: process.env.CHATBOT_MODEL || 'llama-3.3-70b-versatile',
};
const allowedOrigins = (process.env.CORS_ORIGINS || 'http://localhost:3000')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean);

app.use(express.json({ limit: '10mb' }));
app.use(cors({
    origin(origin, callback) {
        if (!origin || allowedOrigins.includes(origin)) return callback(null, true);
        return callback(new Error('Origin tidak diizinkan oleh CORS'));
    }
}));
app.use('/uploads', express.static(path.join(__dirname, 'uploads'))); // Akses publik folder foto

const db = mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'greenway_db',
    port: Number(process.env.DB_PORT || 3306),
    insecureAuth: true,
    ssl: false
});

function sendServerError(res, err, context) {
    console.error(`[${context}]`, err);
    return res.status(500).json({ message: 'Terjadi kesalahan server' });
}

function requireFields(fields, body) {
    return fields.every((field) => typeof body[field] === 'string' && body[field].trim() !== '');
}

function authenticateToken(req, res, next) {
    const authHeader = req.headers.Authorization || req.headers.authorization;
    const token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.slice(7) : null;
    if (!token) return res.status(401).json({ message: 'Token autentikasi wajib disertakan' });

    jwt.verify(token, JWT_SECRET, (err, user) => {
        if (err) return res.status(403).json({ message: 'Token tidak valid atau kedaluwarsa' });
        req.user = user;
        return next();
    });
}

function rejectUnauthenticatedMultipart(req, res, next) {
    const contentType = req.headers['content-type'] || '';
    const hasAuth = Boolean(req.headers.Authorization || req.headers.authorization);
    if (contentType.startsWith('multipart/form-data') && !hasAuth) {
        return res.status(415).json({ message: 'Upload file membutuhkan autentikasi dan format gambar valid' });
    }
    return next();
}

// Konfigurasi Multer untuk Simpan Gambar
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const dir = path.join(__dirname, 'uploads');
        if (!fs.existsSync(dir)) fs.mkdirSync(dir);
        cb(null, dir);
    },
    filename: (req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase();
        cb(null, `${Date.now()}-${Math.round(Math.random() * 1E9)}${ext}`);
    }
});
const upload = multer({
    storage,
    limits: { fileSize: 2 * 1024 * 1024 },
    fileFilter: (req, file, cb) => {
        const allowedMimeTypes = new Set(['image/jpeg', 'image/png', 'image/webp']);
        const allowedExts = new Set(['.jpg', '.jpeg', '.png', '.webp']);
        const ext = path.extname(file.originalname).toLowerCase();
        if (!allowedMimeTypes.has(file.mimetype) || !allowedExts.has(ext)) {
            return cb(new Error('Format file tidak didukung'));
        }
        return cb(null, true);
    }
});

app.post('/register', async (req, res) => {
    const { username, password, full_name } = req.body;
    if (!requireFields(['username', 'password', 'full_name'], req.body)) {
        return res.status(400).json({ message: 'Username, password, dan nama lengkap wajib diisi' });
    }
    if (password.length < 6) return res.status(400).json({ message: 'Password minimal 6 karakter' });

    const hashedPassword = await bcrypt.hash(password, 10);
    const query = "INSERT INTO users (username, password, full_name) VALUES (?, ?, ?)";
    db.query(query, [username.trim(), hashedPassword, full_name.trim()], (err) => {
        if (err) {
            if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ message: 'Username sudah digunakan' });
            return sendServerError(res, err, 'register');
        }
        res.status(201).json({ message: "User berhasil didaftarkan!" });
    });
});

app.post('/login', (req, res) => {
    const { username, password } = req.body;
    if (!requireFields(['username', 'password'], req.body)) {
        return res.status(400).json({ message: 'Username dan password wajib diisi' });
    }

    const query = "SELECT * FROM users WHERE username = ?";
    db.query(query, [username.trim()], async (err, results) => {
        if (err) return sendServerError(res, err, 'login');
        if (results.length === 0) return res.status(401).json({ message: "Username atau password salah" });
        const user = results[0];
        const isMatch = await bcrypt.compare(password, user.password);
        if (isMatch) {
            const token = jwt.sign({ id: user.id, username: user.username }, JWT_SECRET, { expiresIn: '1h' });
            res.json({ success: true, token, user: { id: user.id, name: user.full_name, image: user.profile_image } });
        } else {
            res.status(401).json({ message: "Username atau password salah" });
        }
    });
});

// Endpoint Update Profil & Foto
app.post('/update-profile', rejectUnauthenticatedMultipart, authenticateToken, upload.single('image'), (req, res) => {
    const { full_name } = req.body;
    if (!requireFields(['full_name'], req.body)) {
        return res.status(400).json({ message: 'Nama lengkap wajib diisi' });
    }

    let query = "UPDATE users SET full_name = ? WHERE id = ?";
    let params = [full_name.trim(), req.user.id];
    let newImageUrl = null;

    if (req.file) {
        newImageUrl = `${PUBLIC_BASE_URL}/uploads/${req.file.filename}`;
        query = "UPDATE users SET full_name = ?, profile_image = ? WHERE id = ?";
        params = [full_name.trim(), newImageUrl, req.user.id];
    }

    db.query(query, params, (err) => {
        if (err) return sendServerError(res, err, 'update-profile');
        res.json({
            message: "Profil berhasil diperbarui!", 
            full_name: full_name.trim(),
            image_url: newImageUrl 
        });
    });
});

app.post('/ai/chat', authenticateToken, async (req, res) => {
    if (!process.env.GROQ_API_KEY) {
        return res.status(503).json({ message: 'Layanan AI belum dikonfigurasi' });
    }
    const { feature = 'chatbot', messages, temperature, max_tokens } = req.body;
    const model = aiModels[feature];
    if (!model) {
        return res.status(400).json({ message: 'Fitur AI tidak dikenal' });
    }
    if (!Array.isArray(messages) || messages.length === 0) {
        return res.status(400).json({ message: 'Payload AI wajib menyertakan messages' });
    }

    try {
        const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
            method: 'POST',
            headers: {
                Authorization: `Bearer ${process.env.GROQ_API_KEY}`,
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                model,
                messages,
                temperature,
                max_tokens,
            }),
            signal: AbortSignal.timeout(30000),
        });
        const data = await response.json();
        return res.status(response.status).json(data);
    } catch (err) {
        return sendServerError(res, err, 'ai-chat');
    }
});

app.use((err, req, res, next) => {
    if (err instanceof multer.MulterError) {
        return res.status(400).json({ message: err.message });
    }
    if (err && err.message === 'Format file tidak didukung') {
        return res.status(415).json({ message: err.message });
    }
    return next(err);
});

app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
