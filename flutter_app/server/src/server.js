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
const cloudinaryCloudName = process.env.CLOUDINARY_CLOUD_NAME || '';
const cloudinaryUploadPreset = process.env.CLOUDINARY_UPLOAD_PRESET || '';
const cloudinaryFolder = process.env.CLOUDINARY_FOLDER || 'collage_app';

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
const notificationClients = new Set();

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

function isDataUri(value) {
  return typeof value === 'string' && /^data:[^;]+;base64,/i.test(value);
}

async function uploadDataUriToCloudinary(value) {
  if (!cloudinaryCloudName || !cloudinaryUploadPreset || !isDataUri(value)) {
    return value;
  }

  const body = new URLSearchParams({
    file: value,
    upload_preset: cloudinaryUploadPreset,
    folder: cloudinaryFolder,
  });
  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${cloudinaryCloudName}/auto/upload`,
    { method: 'POST', body },
  );
  const text = await response.text();
  if (!response.ok) {
    throw clientError(`Cloudinary upload failed: ${text}`, 502);
  }
  const data = JSON.parse(text);
  return data.secure_url || data.url || value;
}

async function prepareStoredFiles(payload) {
  const next = { ...payload };
  const fileFields = ['pdfUrl', 'fileUrl', 'url', 'imageUrl'];
  for (const field of fileFields) {
    if (isDataUri(next[field])) {
      next[field] = await uploadDataUriToCloudinary(next[field]);
    }
  }
  return next;
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

function writeSse(res, event, data) {
  res.write(`event: ${event}\n`);
  res.write(`data: ${JSON.stringify(data)}\n\n`);
}

function matchesNotificationLevel(rowLevelId, requestedLevelId) {
  return !rowLevelId || !requestedLevelId || rowLevelId === requestedLevelId;
}

function emitNotification(row) {
  const normalized = normalizeDoc(row);
  const rowLevelId = (normalized.levelId || '').toString();
  for (const client of notificationClients) {
    if (matchesNotificationLevel(rowLevelId, client.levelId)) {
      writeSse(client.res, 'notification', normalized);
    }
  }
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

app.get('/api/notifications/stream', async (req, res, next) => {
  try {
    const levelId = (req.query.levelId || '').toString();
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.flushHeaders?.();

    const client = { levelId, res };
    notificationClients.add(client);

    const Model = getModel('notifications');
    const rows = await Model.find({
      $or: [{ levelId }, { levelId: '' }, { levelId: { $exists: false } }],
    })
      .sort('-timestamp')
      .limit(50)
      .lean();
    writeSse(res, 'snapshot', rows.map(normalizeDoc));

    const heartbeat = setInterval(() => {
      writeSse(res, 'ping', { time: new Date().toISOString() });
    }, 25000);

    req.on('close', () => {
      clearInterval(heartbeat);
      notificationClients.delete(client);
    });
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
    const payload = await prepareStoredFiles(req.body);
    payload.id = (payload.id || new mongoose.Types.ObjectId()).toString();
    const doc = await Model.create(payload);
    const normalized = normalizeDoc(doc);
    if (req.params.collection === 'notifications') {
      emitNotification(normalized);
    }
    res.status(201).json(normalized);
  } catch (error) {
    next(error);
  }
});

app.put('/api/:collection/bulk', async (req, res, next) => {
  try {
    const Model = getModel(req.params.collection);
    const items = Array.isArray(req.body.items) ? req.body.items : null;
    if (!items) throw clientError('Expected body: { "items": [...] }');

    const normalized = [];
    for (const item of items) {
      const prepared = await prepareStoredFiles(item);
      normalized.push({
        ...prepared,
        id: (item.id || item._id || new mongoose.Types.ObjectId()).toString(),
      });
    }

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
    const payload = await prepareStoredFiles(req.body);
    const row = await Model.findOneAndUpdate(
      {
        $or: [
          { id },
          { studentCode: id },
          { code: id },
          mongoose.Types.ObjectId.isValid(id) ? { _id: id } : { _id: null },
        ],
      },
      { $set: payload },
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
