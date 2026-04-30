const express = require('express');
const cors = require('cors');
const mongoose = require('mongoose');
const morgan = require('morgan');
const fs = require('fs');
const path = require('path');

loadEnvFile();

const app = express();
const port = Number(process.env.PORT || 3000);
const mongoUri = process.env.MONGODB_URI;
const corsOrigin = process.env.CORS_ORIGIN || '*';

function loadEnvFile() {
  const envPath = path.join(__dirname, '..', '.env');
  if (!fs.existsSync(envPath)) return;

  const lines = fs.readFileSync(envPath, 'utf8').split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const equalsIndex = trimmed.indexOf('=');
    if (equalsIndex === -1) continue;

    const key = trimmed.slice(0, equalsIndex).trim();
    let value = trimmed.slice(equalsIndex + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (!process.env[key]) process.env[key] = value;
  }
}

const allowedCollections = new Set([
  'students',
  'teachers',
  'announcements',
  'schedules',
  'exams',
  'materials',
  'attendance',
  'exam_results',
  'question_bank',
  'notifications',
  'assignments',
  'submissions',
  'library',
  'messages',
  'live_sessions',
]);

const models = new Map();

function getModel(collectionName) {
  if (!allowedCollections.has(collectionName)) {
    const error = new Error(`Unknown collection: ${collectionName}`);
    error.status = 404;
    throw error;
  }

  if (!models.has(collectionName)) {
    const schema = new mongoose.Schema({}, {
      strict: false,
      timestamps: true,
      versionKey: false,
      collection: collectionName,
    });
    schema.index({ id: 1 });
    models.set(collectionName, mongoose.model(collectionName, schema));
  }

  return models.get(collectionName);
}

function normalizeDoc(doc) {
  const row = doc.toObject ? doc.toObject() : { ...doc };
  row.id = (row.id || row._id || '').toString();
  row._id = row._id ? row._id.toString() : row.id;
  return row;
}

function buildQuery(query) {
  const mongoQuery = {};
  for (const [key, value] of Object.entries(query)) {
    if (key === 'sort' || key === 'limit' || key === 'skip') continue;
    if (value === undefined || value === null || value === '') continue;
    if (value === 'true') {
      mongoQuery[key] = true;
    } else if (value === 'false') {
      mongoQuery[key] = false;
    } else {
      mongoQuery[key] = value;
    }
  }
  return mongoQuery;
}

function clientError(message, status = 400) {
  const error = new Error(message);
  error.status = status;
  return error;
}

app.use(cors({ origin: corsOrigin }));
app.use(express.json({ limit: '100mb' }));
app.use(morgan('dev'));

app.get('/', (_req, res) => {
  res.json({
    ok: true,
    name: 'CollageApp API',
    health: '/health',
  });
});

app.get('/health', async (_req, res) => {
  res.json({
    status: 'ok',
    ok: mongoose.connection.readyState === 1,
    database: mongoose.connection.name || null,
    time: new Date().toISOString(),
  });
});

app.get('/api/:collection', async (req, res, next) => {
  try {
    const Model = getModel(req.params.collection);
    const sort = req.query.sort || '-createdAt';
    const limit = Math.min(Number(req.query.limit || 5000), 10000);
    const rows = await Model.find(buildQuery(req.query))
      .sort(sort)
      .limit(limit)
      .lean();
    res.json({ items: rows.map(normalizeDoc) });
  } catch (error) {
    next(error);
  }
});

app.get('/api/:collection/:id', async (req, res, next) => {
  try {
    const Model = getModel(req.params.collection);
    const id = req.params.id;
    const row = await Model.findOne({
      $or: [
        { id },
        mongoose.Types.ObjectId.isValid(id) ? { _id: id } : { _id: null },
      ],
    }).lean();
    if (!row) throw clientError('Document not found', 404);
    res.json(normalizeDoc(row));
  } catch (error) {
    next(error);
  }
});

app.post('/api/:collection', async (req, res, next) => {
  try {
    const Model = getModel(req.params.collection);
    const payload = { ...req.body };
    payload.id = (payload.id || new mongoose.Types.ObjectId()).toString();
    const doc = await Model.create(payload);
    res.status(201).json(normalizeDoc(doc));
  } catch (error) {
    next(error);
  }
});

app.put('/api/:collection/bulk', async (req, res, next) => {
  try {
    const Model = getModel(req.params.collection);
    const items = Array.isArray(req.body.items) ? req.body.items : null;
    if (!items) throw clientError('Expected body: { "items": [...] }');

    const normalized = items.map((item) => ({
      ...item,
      id: (item.id || item._id || new mongoose.Types.ObjectId()).toString(),
    }));

    await Model.deleteMany({});
    if (normalized.length > 0) await Model.insertMany(normalized, { ordered: false });
    res.json({ ok: true, count: normalized.length });
  } catch (error) {
    next(error);
  }
});

app.patch('/api/:collection/:id', async (req, res, next) => {
  try {
    const Model = getModel(req.params.collection);
    const id = req.params.id;
    const row = await Model.findOneAndUpdate(
      {
        $or: [
          { id },
          { studentCode: id },
          { code: id },
          mongoose.Types.ObjectId.isValid(id) ? { _id: id } : { _id: null },
        ],
      },
      { $set: req.body },
      { new: true },
    );
    if (!row) throw clientError('Document not found', 404);
    res.json(normalizeDoc(row));
  } catch (error) {
    next(error);
  }
});

app.delete('/api/:collection/:id', async (req, res, next) => {
  try {
    const Model = getModel(req.params.collection);
    const id = req.params.id;
    const result = await Model.deleteOne({
      $or: [
        { id },
        { studentCode: id },
        { code: id },
        mongoose.Types.ObjectId.isValid(id) ? { _id: id } : { _id: null },
      ],
    });
    res.json({ ok: result.deletedCount > 0 });
  } catch (error) {
    next(error);
  }
});

app.use((error, _req, res, _next) => {
  const status = error.status || 500;
  res.status(status).json({
    error: error.message || 'Server error',
  });
});

async function start() {
  if (!mongoUri) {
    throw new Error('MONGODB_URI is required. Copy .env.example to .env or set the environment variable.');
  }

  await mongoose.connect(mongoUri);
  app.listen(port, () => {
    console.log(`CollageApp API running on http://localhost:${port}`);
  });
}

start().catch((error) => {
  console.error(error);
  process.exit(1);
});
