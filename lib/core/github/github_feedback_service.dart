import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// The user's GitHub connection: a Personal Access Token plus the
/// "owner/repo" it may write to. Stored in the Android Keystore via
/// flutter_secure_storage — never in shared_preferences, because the
/// token can push commits.
class GithubFeedbackConfig {
  const GithubFeedbackConfig({required this.token, required this.repo});

  final String token;

  /// "owner/name" form, e.g. "manjo00/trackerapp".
  final String repo;

  String get owner => repo.split('/').first;
  String get name => repo.split('/').last;

  /// Loose shape check used by the settings dialog before saving.
  static bool isValidRepo(String value) =>
      RegExp(r'^[\w.-]+/[\w.-]+$').hasMatch(value.trim());
}

/// Outcome of a push, surfaced verbatim in a snackbar.
class GithubPushResult {
  const GithubPushResult.success(this.message) : success = true;
  const GithubPushResult.failure(this.message) : success = false;

  final bool success;
  final String message;
}

/// Publishes a Markdown file to a GitHub repository using the REST
/// Contents API (create-or-update): GET the path to learn the current
/// blob `sha` (404 = new file), then PUT with the base64 content.
class GithubFeedbackService {
  GithubFeedbackService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _kToken = 'github_feedback_token';
  static const String _kRepo = 'github_feedback_repo';
  static const Duration _timeout = Duration(seconds: 10);

  // ── Config ────────────────────────────────────────────────────────────

  Future<GithubFeedbackConfig?> loadConfig() async {
    final String? token = await _storage.read(key: _kToken);
    final String? repo = await _storage.read(key: _kRepo);
    if (token == null || token.isEmpty || repo == null || repo.isEmpty) {
      return null;
    }
    return GithubFeedbackConfig(token: token, repo: repo);
  }

  Future<void> saveConfig(GithubFeedbackConfig config) async {
    await _storage.write(key: _kToken, value: config.token.trim());
    await _storage.write(key: _kRepo, value: config.repo.trim());
  }

  // ── Push ──────────────────────────────────────────────────────────────

  Map<String, String> _headers(String token) => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      };

  /// Creates or updates [path] in the configured repo. Never throws —
  /// failures come back as a [GithubPushResult.failure] with a message
  /// short enough for a snackbar.
  Future<GithubPushResult> pushMarkdown({
    required GithubFeedbackConfig config,
    required String path,
    required String content,
    required String commitMessage,
  }) async {
    final Uri url = Uri.parse(
        'https://api.github.com/repos/${config.repo}/contents/$path');
    try {
      // 1. Existing file? Grab its sha so the PUT is an update.
      String? sha;
      final http.Response probe =
          await http.get(url, headers: _headers(config.token)).timeout(_timeout);
      if (probe.statusCode == 200) {
        final dynamic body = jsonDecode(probe.body);
        if (body is Map<String, dynamic>) sha = body['sha'] as String?;
      } else if (probe.statusCode == 401) {
        return const GithubPushResult.failure(
            'GitHub rejected the token — check it in Settings');
      } else if (probe.statusCode == 404) {
        // Either a new file (fine) or a wrong repo name; the PUT below
        // distinguishes them (a bad repo 404s on PUT too).
        sha = null;
      }

      // 2. Create or update.
      final http.Response put = await http
          .put(
            url,
            headers: _headers(config.token),
            body: jsonEncode({
              'message': commitMessage,
              'content': base64Encode(utf8.encode(content)),
              if (sha != null) 'sha': sha,
            }),
          )
          .timeout(_timeout);

      return switch (put.statusCode) {
        200 => const GithubPushResult.success('Updated on GitHub ✓'),
        201 => const GithubPushResult.success('Published to GitHub ✓'),
        401 => const GithubPushResult.failure(
            'GitHub rejected the token — check it in Settings'),
        404 => GithubPushResult.failure(
            'Repo ${config.repo} not found (or token lacks access)'),
        409 => const GithubPushResult.failure(
            'Conflict — try again in a moment'),
        _ => GithubPushResult.failure('GitHub error ${put.statusCode}'),
      };
    } catch (e) {
      // Timeouts and no-network land here. Include the real cause —
      // a bare "check your connection" already hid a bug once.
      final String detail = e.toString();
      return GithubPushResult.failure(
          'GitHub push failed: ${detail.length > 120 ? detail.substring(0, 120) : detail}');
    }
  }
}
