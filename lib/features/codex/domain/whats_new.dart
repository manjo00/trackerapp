import '../data/codex_topic.dart';

/// Topics introduced or changed in [version] — the Codex's "What's new" shelf.
List<CodexTopic> whatsNewTopics(List<CodexTopic> topics, String version) => [
      for (final CodexTopic t in topics)
        if (t.sinceVersion == version) t,
    ];

/// Topics for normal browsing: everything EXCEPT what is currently new, since
/// those are shown in their own section at the top. Once [version] moves on,
/// they reappear here in their own areas with no other change.
List<CodexTopic> browsableTopics(List<CodexTopic> topics, String version) => [
      for (final CodexTopic t in topics)
        if (t.sinceVersion != version) t,
    ];
