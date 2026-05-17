const fs = require('fs');
const path = require('path');
const { matchesMistake, normalizeMistake, seedMistakes, statsFor } = require('./mistake');

class JsonMistakeStore {
  constructor(dbPath) {
    this.dbPath = dbPath;
  }

  list(filters = {}) {
    return this.load().filter((mistake) => matchesMistake(mistake, filters));
  }

  create(input) {
    const data = this.load();
    const item = normalizeMistake(input);
    data.unshift(item);
    this.save(data);
    return item;
  }

  update(id, input) {
    const data = this.load();
    const index = data.findIndex((item) => item.id === id);
    if (index < 0) return null;
    data[index] = normalizeMistake({ ...input, id }, data[index]);
    this.save(data);
    return data[index];
  }

  delete(id) {
    const data = this.load();
    const next = data.filter((item) => item.id !== id);
    this.save(next);
    return next.length !== data.length;
  }

  random() {
    const data = this.load();
    if (!data.length) return null;
    return data[Math.floor(Math.random() * data.length)];
  }

  stats() {
    return statsFor(this.load());
  }

  load() {
    if (!fs.existsSync(this.dbPath)) {
      const seeded = seedMistakes();
      this.save(seeded);
      return seeded;
    }

    try {
      const parsed = JSON.parse(fs.readFileSync(this.dbPath, 'utf-8'));
      if (!Array.isArray(parsed)) throw new Error('Database root must be an array');
      return parsed.map((item) => normalizeMistake(item));
    } catch {
      const seeded = seedMistakes();
      this.save(seeded);
      return seeded;
    }
  }

  save(data) {
    fs.mkdirSync(path.dirname(this.dbPath), { recursive: true });
    fs.writeFileSync(this.dbPath, `${JSON.stringify(data, null, 2)}\n`, 'utf-8');
  }
}

module.exports = {
  JsonMistakeStore
};
