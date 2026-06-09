const results = [];

function record(name, passed, detail = '') {
  results.push({ name, passed, detail });
  const mark = passed ? 'PASS' : 'FAIL';
  console.log(`[${mark}] ${name}${detail ? ` - ${detail}` : ''}`);
}

function assertTest(name, condition, detail = '') {
  record(name, Boolean(condition), detail);
}

function summary() {
  const passed = results.filter((item) => item.passed).length;
  const failed = results.length - passed;
  console.log(`\nSummary: ${passed}/${results.length} passed, ${failed} failed`);
  if (failed > 0) process.exitCode = 1;
}

module.exports = { assertTest, record, summary };
