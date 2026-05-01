const String baseUrl = String.fromEnvironment(
  'BASE_URL',
  defaultValue: 'https://collageapp-server-production.up.railway.app',
);

const bool offlineMode = bool.fromEnvironment(
  'OFFLINE_MODE',
  defaultValue: false,
);

const String cloudinaryCloudName = String.fromEnvironment(
  'CLOUDINARY_CLOUD_NAME',
  defaultValue: '',
);

const String cloudinaryUploadPreset = String.fromEnvironment(
  'CLOUDINARY_UPLOAD_PRESET',
  defaultValue: '',
);

const String cloudinaryFolder = String.fromEnvironment(
  'CLOUDINARY_FOLDER',
  defaultValue: 'collage_app',
);
