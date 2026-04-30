const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://collageapp-server-production.up.railway.app',
);

const bool offlineMode = bool.fromEnvironment(
  'OFFLINE_MODE',
  defaultValue: false,
);
