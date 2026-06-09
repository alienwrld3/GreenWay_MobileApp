const { BASE_URL, get, post, uniqueUser } = require('./lib/httpClient');
const { assertTest, summary } = require('./lib/assertions');

async function main() {
  console.log(`Black box testing ${BASE_URL}\n`);

  const emptyLogin = await post('/login', {});
  assertTest(
    'BB-01 Login body kosong tidak crash',
    [400, 401].includes(emptyLogin.status),
    `status ${emptyLogin.status}`
  );

  const missingUser = await post('/login', {
    username: `missing_${Date.now()}`,
    password: 'wrong',
  });
  assertTest(
    'BB-02 Login user tidak ada ditolak',
    missingUser.status === 401,
    `status ${missingUser.status}`
  );

  const user = uniqueUser('bb');
  const register = await post('/register', user);
  assertTest(
    'BB-03 Register data valid berhasil',
    [200, 201].includes(register.status),
    `status ${register.status}`
  );

  const invalidRegister = await post('/register', {
    username: '',
    password: '',
    full_name: '',
  });
  assertTest(
    'BB-04 Register field kosong divalidasi',
    [400, 422].includes(invalidRegister.status),
    `status ${invalidRegister.status}`
  );

  const notFoundUpload = await get('/uploads/not-found.jpg');
  assertTest(
    'BB-05 Static upload tidak ditemukan mengembalikan 404',
    notFoundUpload.status === 404,
    `status ${notFoundUpload.status}`
  );

  summary();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
