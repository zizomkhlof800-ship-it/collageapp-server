# CollageApp Backend

Express + MongoDB Atlas backend for the Flutter app.

## Setup

1. Copy `.env.example` to `.env`.
2. Put your MongoDB Atlas connection string in `MONGODB_URI`.
3. Run:

```bash
npm install
npm start
```

The API runs on `http://localhost:3000` by default.

## API

Generic collection endpoints:

- `GET /health`
- `GET /api/:collection`
- `GET /api/:collection/:id`
- `POST /api/:collection`
- `PATCH /api/:collection/:id`
- `DELETE /api/:collection/:id`
- `PUT /api/:collection/bulk`

Allowed collections match the Flutter data stores:
`students`, `teachers`, `announcements`, `schedules`, `exams`, `materials`,
`attendance`, `exam_results`, `question_bank`, `notifications`, `assignments`,
`submissions`, `library`, and `messages`.
