const { BASE_URL, post } = require('./lib/httpClient');

const total = Number(process.env.LOAD_REQUESTS || 100);
const concurrency = Number(process.env.LOAD_CONCURRENCY || 10);

function percentile(values, p) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  const index = Math.min(sorted.length - 1, Math.ceil((p / 100) * sorted.length) - 1);
  return sorted[index];
}

async function worker(queue, results) {
  while (queue.length > 0) {
    queue.pop();
    const result = await post('/login', {
      username: `load_missing_${Math.random().toString(16).slice(2)}`,
      password: 'wrong',
    }, { timeoutMs: 10000 });
    results.push(result);
  }
}

async function runLoad(requests, workers) {
  const queue = Array.from({ length: requests });
  const results = [];
  const startedAt = Date.now();
  await Promise.all(Array.from({ length: workers }, () => worker(queue, results)));
  const elapsedMs = Date.now() - startedAt;
  return { results, elapsedMs };
}

async function main() {
  console.log(`Load testing ${BASE_URL}`);
  console.log(`requests=${total}, concurrency=${concurrency}\n`);

  const { results, elapsedMs } = await runLoad(total, concurrency);
  const durations = results.map((item) => item.durationMs);
  const errors = results.filter((item) => item.status >= 500 || item.status === 0);
  const expectedRejects = results.filter((item) => item.status === 401);

  console.log(`Completed: ${results.length}/${total}`);
  console.log(`Expected 401 rejects: ${expectedRejects.length}`);
  console.log(`Server/network errors: ${errors.length}`);
  console.log(`Average latency: ${(durations.reduce((a, b) => a + b, 0) / durations.length).toFixed(2)} ms`);
  console.log(`P95 latency: ${percentile(durations, 95).toFixed(2)} ms`);
  console.log(`Throughput: ${(results.length / (elapsedMs / 1000)).toFixed(2)} req/s`);

  if (errors.length > 0) process.exitCode = 1;
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
