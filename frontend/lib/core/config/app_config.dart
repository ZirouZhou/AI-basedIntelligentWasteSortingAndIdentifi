// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — Application Configuration
// ------------------------------------------------------------------------------------------------
//
// [AppConfig] centralises all compile-time configuration values for the
// EcoSort AI mobile client. It provides the backend base URL, API timeout
// duration, and feature flags that control the behaviour of the app.
//
// In a production build, [baseUrl] should point to the real backend server.
// During development it can be pointed at a local instance or an emulator
// proxy.
// ------------------------------------------------------------------------------------------------

/// Static configuration constants for the EcoSort AI Flutter application.
class AppConfig {
  /// The base URL of the EcoSort AI backend REST API.
  ///
  /// On Android emulators, `10.0.2.2` maps to the host machine's `localhost`.
  /// Change this to your server's actual IP or domain in production.
  static const baseUrl = 'http://10.0.2.2:8080';

  /// HTTP request timeout [Duration] used by [ApiClient].
  ///
  /// If the backend does not respond within this window the client will throw
  /// a timeout exception, which triggers the local fallback classifier.
  static const apiTimeout = Duration(seconds: 5);

  /// Whether to use demo / mock data when the backend is unreachable.
  ///
  /// When `true`, [ApiClient] failures will be silently caught and replaced
  /// with locally computed results so the UI never appears broken.
  static const useMockFallback = true;
}
