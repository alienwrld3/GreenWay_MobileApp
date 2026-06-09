const { performance } = require('node:perf_hooks');

const BASE_URL = process.env.BASE_URL || 'http://127.0.0.1:3000';

function url(path) {
  return new URL(path, BASE_URL).toString();
}

async function request(method, path, options = {}) {
  const startedAt = performance.now();
  let response;
  let bodyText = '';
  let json = null;
  let error = null;

  try {
    response = await fetch(url(path), {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...(options.headers || {}),
      },
      body: options.rawBody !== undefined
        ? options.rawBody
        : options.body === undefined
          ? undefined
          : JSON.stringify(options.body),
      signal: AbortSignal.timeout(options.timeoutMs || 5000),
    });
    bodyText = await response.text();
    try {
      json = bodyText ? JSON.parse(bodyText) : null;
    } catch (_) {
      json = null;
    }
  } catch (err) {
    error = err;
  }

  return {
    status: response ? response.status : 0,
    ok: response ? response.ok : false,
    bodyText,
    json,
    error,
    durationMs: performance.now() - startedAt,
  };
}

async function get(path, options) {
  return request('GET', path, options);
}

async function post(path, body, options = {}) {
  return request('POST', path, { ...options, body });
}

function uniqueUser(prefix = 'gwtest') {
  const suffix = `${Date.now()}_${Math.random().toString(16).slice(2)}`;
  return {
    username: `${prefix}_${suffix}`,
    password: `Passw0rd!${suffix}`,
    full_name: `GreenWay Test ${suffix}`,
  };
}

module.exports = { BASE_URL, get, post, request, uniqueUser };
