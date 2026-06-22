/// App-wide environment (`dev` | `staging` | `prod`).
enum Environment { dev, staging, prod }

extension EnvironmentX on Environment {
  bool get isProd => this == Environment.prod;

  /// True for local QA builds (`dev` and `staging`).
  bool get isDevOrStaging =>
      this == Environment.dev || this == Environment.staging;
}

/// Resolves the active environment for startup.
///
/// Uses [localDefault] from `main` (`kAppEnvironment`) when `--dart-define=ENV`
/// is not set. CI/release may pass `ENV=prod` to override without editing source.
/// Unknown or misspelled `ENV` values fall back to [Environment.dev].
Environment resolveAppEnvironment({required Environment localDefault}) {
  const raw = String.fromEnvironment('ENV');
  if (raw.isEmpty) return localDefault;

  switch (raw.trim().toLowerCase()) {
    case 'staging':
      return Environment.staging;
    case 'prod':
    case 'production':
      return Environment.prod;
    case 'dev':
    case 'local':
      return Environment.dev;
    default:
      return Environment.dev;
  }
}
