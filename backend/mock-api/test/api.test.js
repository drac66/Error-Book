const assert = require('assert/strict');
const fs = require('fs');
const os = require('os');
const path = require('path');
const test = require('node:test');
const { createApp } = require('../src/app');

async function withServer(fn) {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'error-book-api-'));
  const dbPath = path.join(dir, 'db.json');
  const server = createApp({ dbPath, port: 0 });

  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const { port } = server.address();
  const baseUrl = `http://127.0.0.1:${port}`;

  try {
    await fn(baseUrl, dbPath);
  } finally {
    await new Promise((resolve) => server.close(resolve));
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

async function requestJson(url, options) {
  const res = await fetch(url, options);
  const body = await res.json();
  return { res, body };
}

test('lists and filters mistakes by keyword and category', async () => {
  await withServer(async (baseUrl) => {
    const all = await requestJson(`${baseUrl}/mistakes`);
    assert.equal(all.res.status, 200);
    assert.equal(all.body.length, 2);

    const byCategory = await requestJson(`${baseUrl}/mistakes?category=${encodeURIComponent('Java')}`);
    assert.equal(byCategory.body.length, 1);
    assert.equal(byCategory.body[0].category, 'Java');

    const byKeyword = await requestJson(`${baseUrl}/mistakes?keyword=${encodeURIComponent('二分')}`);
    assert.equal(byKeyword.body.length, 1);
    assert.equal(byKeyword.body[0].id, 'm002');
  });
});

test('creates, updates, deletes, randomizes and reports stats', async () => {
  await withServer(async (baseUrl) => {
    const created = await requestJson(`${baseUrl}/mistakes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ question: '空指针', category: 'Java', tags: ['异常'] })
    });
    assert.equal(created.res.status, 201);
    assert.equal(created.body.category, 'Java');
    assert.deepEqual(created.body.tags, ['异常']);
    assert.equal(created.body.questionImagePath, '');

    const updated = await requestJson(`${baseUrl}/mistakes/${encodeURIComponent(created.body.id)}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ reason: '调用前未判空', category: '' })
    });
    assert.equal(updated.res.status, 200);
    assert.equal(updated.body.reason, '调用前未判空');
    assert.equal(updated.body.category, '未分类');

    const random = await requestJson(`${baseUrl}/mistakes/random`);
    assert.equal(random.res.status, 200);
    assert.ok(random.body === null || random.body.id);

    const stats = await requestJson(`${baseUrl}/stats`);
    assert.equal(stats.res.status, 200);
    assert.equal(stats.body.total, 3);
    assert.equal(stats.body.byCategory['未分类'], 1);

    const deleted = await requestJson(`${baseUrl}/mistakes/${encodeURIComponent(created.body.id)}`, {
      method: 'DELETE'
    });
    assert.equal(deleted.res.status, 200);
    assert.deepEqual(deleted.body, { ok: true });
  });
});

test('returns 400 for invalid json request bodies', async () => {
  await withServer(async (baseUrl) => {
    const invalid = await requestJson(`${baseUrl}/mistakes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: '{'
    });
    assert.equal(invalid.res.status, 400);
    assert.deepEqual(invalid.body, { error: 'invalid json' });
  });
});
