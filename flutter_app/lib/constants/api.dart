const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'http://localhost:3000',
);

const bool offlineMode = bool.fromEnvironment(
  'OFFLINE_MODE',
  defaultValue: false,
);
