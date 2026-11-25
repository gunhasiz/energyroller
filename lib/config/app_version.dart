class AppVersion {
  static const String version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '1.0.0',
  );

  static const String commitHash = String.fromEnvironment(
    'COMMIT_HASH',
    defaultValue: 'dev',
  );

  static String get full => '$version.$commitHash';
}