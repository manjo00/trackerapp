import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// A newer build waiting on GitHub.
class UpdateInfo {
  const UpdateInfo({
    required this.version,
    required this.downloadUrl,
    this.notes,
  });

  /// Remote version, e.g. "1.2.0" (tag without the leading v).
  final String version;

  /// Direct browser URL of the attached .apk asset.
  final String downloadUrl;

  /// Release description (shown in the update dialog when present).
  final String? notes;
}

/// Checks a PUBLIC releases-only GitHub repo for a newer APK.
///
/// The app's source repo is private, so releases live in a second public
/// repo that hosts nothing but APKs — testers' phones can hit its API
/// unauthenticated. Publishing ritual (documented in CLAUDE.md): build the
/// release APK, create a GitHub release tagged `vX.Y.Z`, attach the APK.
class UpdateService {
  const UpdateService._();

  static const String _repo = 'manjo00/uplan-releases';
  static const String _latestUrl =
      'https://api.github.com/repos/$_repo/releases/latest';

  /// Throttle key — auto-checks run at most once per day (unauthenticated
  /// GitHub API allows 60 req/h/IP; also just polite).
  static const String _lastCheckKey = 'update_last_check_ms';
  static const Duration _autoCheckEvery = Duration(hours: 24);

  /// Returns the newer release, or null when up-to-date / offline / the
  /// repo has no releases yet. Never throws — an update check must not
  /// break app startup.
  static Future<UpdateInfo?> check() async {
    try {
      final http.Response response = await http
          .get(Uri.parse(_latestUrl))
          .timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return null;

      final dynamic body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;

      final String remote =
          (body['tag_name'] as String? ?? '').replaceFirst('v', '').trim();
      if (remote.isEmpty) return null;

      // First .apk asset is the build to install.
      String? apkUrl;
      final assets = body['assets'];
      if (assets is List) {
        for (final a in assets) {
          final String? name = a['name'] as String?;
          if (name != null && name.endsWith('.apk')) {
            apkUrl = a['browser_download_url'] as String?;
            break;
          }
        }
      }
      if (apkUrl == null) return null;

      final PackageInfo pkg = await PackageInfo.fromPlatform();
      if (!_isNewer(remote, pkg.version)) return null;

      return UpdateInfo(
        version: remote,
        downloadUrl: apkUrl,
        notes: body['body'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  /// [check], but only once per [_autoCheckEvery] — for the launch hook.
  static Future<UpdateInfo?> autoCheck(SharedPreferences prefs) async {
    final int last = prefs.getInt(_lastCheckKey) ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;
    if (now - last < _autoCheckEvery.inMilliseconds) return null;
    await prefs.setInt(_lastCheckKey, now);
    return check();
  }

  /// Opens the APK download in the browser; Android then offers install.
  static Future<void> download(UpdateInfo info) async {
    await launchUrl(
      Uri.parse(info.downloadUrl),
      mode: LaunchMode.externalApplication,
    );
  }

  /// "1.2.0" vs "1.1.3" — numeric segment-by-segment compare; missing
  /// segments count as 0 (so "1.2" == "1.2.0").
  static bool _isNewer(String remote, String local) {
    final List<int> r = _parts(remote);
    final List<int> l = _parts(local);
    for (int i = 0; i < 3; i++) {
      if (r[i] != l[i]) return r[i] > l[i];
    }
    return false;
  }

  static List<int> _parts(String v) {
    final List<String> raw = v.split('+').first.split('.');
    return List<int>.generate(
        3, (i) => i < raw.length ? int.tryParse(raw[i].trim()) ?? 0 : 0);
  }
}
