const fs = require('node:fs');
const path = require('node:path');
const { assertTest, record, summary } = require('./lib/assertions');

const root = path.resolve(__dirname, '..');
const backend = fs.readFileSync(path.join(root, 'greenway_backend', 'index.js'), 'utf8');

function readIfExists(filePath) {
  return fs.existsSync(filePath) ? fs.readFileSync(filePath, 'utf8') : '';
}

function collectDartFiles(dir) {
  if (!fs.existsSync(dir)) return [];
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  return entries.flatMap((entry) => {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) return collectDartFiles(fullPath);
    return entry.name.endsWith('.dart') ? [fullPath] : [];
  });
}

const dartFiles = collectDartFiles(path.join(root, 'greenway_mobile', 'lib'));
const dartSource = dartFiles.map(readIfExists).join('\n');

console.log('White box testing GreenWay source\n');

assertTest(
  'WB-01 SQL memakai parameter binding',
  /WHERE username = \?/.test(backend) && /VALUES \(\?, \?, \?\)/.test(backend),
  'query login/register memakai placeholder'
);

assertTest(
  'WB-02 Password memakai bcrypt',
  /bcrypt\.hash/.test(backend) && /bcrypt\.compare/.test(backend),
  'hash dan compare ditemukan'
);

record(
  'WB-03 JWT secret tidak hard-coded',
  !/jwt\.sign\([^)]*['"]SECRET_KEY['"]/.test(backend),
  /SECRET_KEY/.test(backend) ? 'JWT secret masih hard-coded' : 'tidak ditemukan secret literal'
);

record(
  'WB-04 CORS dibatasi',
  !/app\.use\(cors\(\)\)/.test(backend),
  /app\.use\(cors\(\)\)/.test(backend) ? 'CORS masih terbuka untuk semua origin' : 'CORS terkonfigurasi'
);

record(
  'WB-05 Upload membatasi tipe dan ukuran file',
  /fileFilter/.test(backend) && /limits/.test(backend),
  'multer sebaiknya memakai fileFilter dan limits'
);

record(
  'WB-06 API key tidak hard-coded di Flutter',
  !/(gsk_|sk-)[A-Za-z0-9_\-]{20,}/.test(dartSource),
  'API key ditemukan di source Flutter'
);

record(
  'WB-07 Endpoint update profile dilindungi autentikasi',
  /Authorization/.test(backend) && /jwt\.verify/.test(backend) && /\/update-profile/.test(backend),
  'endpoint update-profile belum memverifikasi token'
);

record(
  'WB-08 Error database tidak dibocorkan langsung',
  !/res\.status\(500\)\.json\(\{\s*error:\s*err\.message\s*\}\)/.test(backend),
  'err.message dikirim ke client'
);

summary();
