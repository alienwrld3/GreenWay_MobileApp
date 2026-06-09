const { BASE_URL, post, uniqueUser } = require('./lib/httpClient');
const { assertTest, summary } = require('./lib/assertions');

async function main() {
  console.log(`Integration testing ${BASE_URL}\n`);

  const user = uniqueUser('int');
  const register = await post('/register', user);
  assertTest(
    'INT-01 Register user baru',
    [200, 201].includes(register.status),
    `status ${register.status}`
  );

  const login = await post('/login', {
    username: user.username,
    password: user.password,
  });
  assertTest(
    'INT-02 Login setelah register berhasil',
    login.status === 200 && login.json && login.json.token,
    `status ${login.status}`
  );

  assertTest(
    'INT-03 Response login berisi user profile minimal',
    login.json && login.json.user && login.json.user.id && login.json.user.name,
    login.json && login.json.user ? `user=${JSON.stringify(login.json.user)}` : 'user kosong'
  );

  summary();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
