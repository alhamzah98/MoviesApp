import 'package:url_launcher/url_launcher.dart';

/// Injectable launcher signature matching `url_launcher.launchUrl`.
typedef UrlLauncherCallback = Future<bool> Function(
  Uri uri, {
  LaunchMode mode,
});

/// Service responsible for validating YouTube trailer codes and launching
/// them in an external application or browser.
class TrailerLauncher {
  TrailerLauncher({UrlLauncherCallback? launcher})
      : _launcher = launcher ?? launchUrl;

  final UrlLauncherCallback _launcher;

  /// Standard YouTube video ID format: alphanumeric characters, dashes, and underscores.
  static final RegExp _validIdPattern = RegExp(r'^[a-zA-Z0-9_-]+$');

  /// Builds a secure, fixed-host HTTPS YouTube watch URI for a given [trailerCode].
  ///
  /// Returns `null` if the trailer code is missing, empty, or contains invalid characters.
  static Uri? buildUri(String? trailerCode) {
    if (trailerCode == null) return null;
    final trimmed = trailerCode.trim();
    if (trimmed.isEmpty) return null;
    if (!_validIdPattern.hasMatch(trimmed)) return null;

    return Uri.https('www.youtube.com', '/watch', {'v': trimmed});
  }

  /// Returns `true` if [trailerCode] is present and valid.
  static bool hasValidTrailerCode(String? trailerCode) {
    return buildUri(trailerCode) != null;
  }

  /// Launches the trailer in an external application.
  ///
  /// Returns `true` on successful launch, `false` otherwise. Never throws.
  Future<bool> launchTrailer(String? trailerCode) async {
    final uri = buildUri(trailerCode);
    if (uri == null) {
      return false;
    }

    try {
      return await _launcher(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
