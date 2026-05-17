const http = require('http');
const { URL } = require('url');
const { DEFAULT_DB_PATH, DEFAULT_PORT } = require('./config');
const { readJsonBody, sendJson } = require('./http');
const { JsonMistakeStore } = require('./store');

function createApp(options = {}) {
  const store = options.store || new JsonMistakeStore(options.dbPath || process.env.DB_PATH || DEFAULT_DB_PATH);
  const port = options.port || DEFAULT_PORT;

  return http.createServer(async (req, res) => {
    if (req.method === 'OPTIONS') return sendJson(res, 200, { ok: true });

    const url = new URL(req.url, `http://127.0.0.1:${port}`);
    const pathname = url.pathname;

    try {
      if (pathname === '/health' && req.method === 'GET') {
        return sendJson(res, 200, { ok: true, count: store.stats().total });
      }

      if (pathname === '/mistakes' && req.method === 'GET') {
        const keyword = url.searchParams.get('keyword') || '';
        const category = url.searchParams.get('category') || '全部分类';
        return sendJson(res, 200, store.list({ keyword, category }));
      }

      if (pathname === '/mistakes/random' && req.method === 'GET') {
        return sendJson(res, 200, store.random());
      }

      if (pathname === '/mistakes' && req.method === 'POST') {
        const body = await readJsonBody(req);
        return sendJson(res, 201, store.create(body));
      }

      if (pathname.startsWith('/mistakes/') && req.method === 'PUT') {
        const id = decodeURIComponent(pathname.split('/')[2] || '');
        const body = await readJsonBody(req);
        const updated = store.update(id, body);
        return updated ? sendJson(res, 200, updated) : sendJson(res, 404, { error: 'not found' });
      }

      if (pathname.startsWith('/mistakes/') && req.method === 'DELETE') {
        const id = decodeURIComponent(pathname.split('/')[2] || '');
        store.delete(id);
        return sendJson(res, 200, { ok: true });
      }

      if (pathname === '/stats' && req.method === 'GET') {
        return sendJson(res, 200, store.stats());
      }

      return sendJson(res, 404, { error: 'not found' });
    } catch (error) {
      if (error instanceof SyntaxError) {
        return sendJson(res, 400, { error: 'invalid json' });
      }
      return sendJson(res, 500, { error: 'internal server error' });
    }
  });
}

module.exports = {
  createApp
};
