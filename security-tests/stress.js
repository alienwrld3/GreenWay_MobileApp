const { spawnSync } = require('node:child_process');
const path = require('node:path');

const steps = (process.env.STRESS_STEPS || '10,25,50,100')
  .split(',')
  .map((item) => Number(item.trim()))
  .filter(Boolean);

const requestsPerStep = Number(process.env.STRESS_REQUESTS_PER_STEP || 100);

for (const concurrency of steps) {
  console.log(`\n=== Stress step: concurrency ${concurrency} ===`);
  const result = spawnSync(process.execPath, [path.join(__dirname, 'load.js')], {
    stdio: 'inherit',
    env: {
      ...process.env,
      LOAD_REQUESTS: String(requestsPerStep),
      LOAD_CONCURRENCY: String(concurrency),
    },
  });

  if (result.status !== 0) {
    process.exitCode = result.status || 1;
    break;
  }
}
