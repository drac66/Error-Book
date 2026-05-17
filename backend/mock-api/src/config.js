const path = require('path');

const DEFAULT_PORT = 8787;
const DEFAULT_DB_PATH = path.join(__dirname, '..', 'db.json');

module.exports = {
  DEFAULT_DB_PATH,
  DEFAULT_PORT
};
