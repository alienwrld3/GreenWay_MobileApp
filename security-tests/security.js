const { BASE_URL, post, request } = require('./lib/httpClient');
const { assertTest, record, summary } = require('./lib/assertions');

async function rawMultipart() {
  const boundary = `----greenway${Date.now()}`;
  const body = [
    `--${boundary}`,
    'Content-Disposition: form-data; name="username"',
    '',
    'security_user',
    `--${boundary}`,
    'Content-Disposition: form-data; name="full_name"',
    '',
    'Security User',
    `--${boundary}`,
    'Content-Disposition: form-data; name="image"; filename="not-image.txt"',
    'Content-Type: text/plain',
    '',
    'this is not an image',
    `--${boundary}--`,
    '',
  ].join('\r\n');

  const startedAt = Date.now();
  let response;
  let error = null;
  try {
    response = await fetch(`${BASE_URL}/update-profile`, {
      method: 'POST',
      headers: { 'Content-Type': `multipart/form-data; boundary=${boundary}` },
      body,
      signal: AbortSignal.timeout(5000),
    });
    await response.text();
  } catch (err) {
    error = err;
  }

  return {
    status: response ? response.status : 0,
    ok: response ? response.ok : false,
    error,
    durationMs: Date.now() - startedAt,
  };
}

async function main() {
  console.log(`Security testing ${BASE_URL}\n`);

  const injection = await post('/login', {
    username: "' OR '1'='1",
    password: 'anything',
  });
  assertTest(
    'SEC-01 SQL injection login ditolak',
    injection.status === 401,
    `status ${injection.status}`
  );

  const bruteAttempts = [];
  for (let i = 0; i < 8; i += 1) {
    bruteAttempts.push(post('/login', { username: `missing_${i}`, password: 'wrong' }));
  }
  const bruteResults = await Promise.all(bruteAttempts);
  const allRejected = bruteResults.every((item) => item.status === 401);
  const hasRateLimit = bruteResults.some((item) => item.status === 429);
  record(
    'SEC-02 Brute force ringan ditolak/rate-limited',
    allRejected || hasRateLimit,
    hasRateLimit ? 'rate limit aktif' : 'semua kredensial salah ditolak, rate limit belum terlihat'
  );

  const upload = await rawMultipart();
  assertTest(
    'SEC-03 Upload non-image ditolak',
    [400, 415].includes(upload.status),
    `status ${upload.status}`
  );

  const profileNoAuth = await post('/update-profile', {
    username: 'security_user',
    full_name: 'No Auth',
  });
  assertTest(
    'SEC-04 Update profil tanpa token ditolak',
    [401, 403].includes(profileNoAuth.status),
    `status ${profileNoAuth.status}`
  );

  summary();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
