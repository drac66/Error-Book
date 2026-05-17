const { createApp } = require('./src/app');
const { DEFAULT_PORT } = require('./src/config');

const port = Number(process.env.PORT || DEFAULT_PORT);
const server = createApp();

server.listen(port, () => {
  console.log(`Error Book mock API running at http://127.0.0.1:${port}`);
});
