import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:humming_bird/database/local_database.dart';
import 'package:url_launcher/url_launcher.dart';

/// Parsed/enriched metadata for a single URL inside a chat message.
///
/// [ok] is `false` when the site was unreachable, blocked pre-fetch or carried
/// no usable metadata — the UI then renders the clean fallback card instead of
/// a broken/error state.
class LinkPreview {
  final String url;
  final String domain;
  final String? title;
  final String? description;
  final String? imageUrl;
  final bool ok;

  const LinkPreview({
    required this.url,
    required this.domain,
    this.title,
    this.description,
    this.imageUrl,
    this.ok = false,
  });

  factory LinkPreview.fallback(String url) =>
      LinkPreview(url: url, domain: LinkPreviewService.domainOf(url));

  Map<String, dynamic> toCacheJson() => {
        'ok': ok,
        'domain': domain,
        'title': title,
        'description': description,
        'image': imageUrl,
      };

  factory LinkPreview.fromCacheJson(Map<String, dynamic> json, String url) {
    return LinkPreview(
      url: url,
      domain: (json['domain'] as String?) ?? LinkPreviewService.domainOf(url),
      title: json['title'] as String?,
      description: json['description'] as String?,
      imageUrl: json['image'] as String?,
      ok: json['ok'] == true,
    );
  }
}

/// Detected URL inside a message: the raw substring the user typed plus the
/// normalized, safe-to-open URL.
class LinkTextInfo {
  final String raw;
  final String url;
  const LinkTextInfo(this.raw, this.url);
}

/// One detected URL with its character offsets inside the original text —
/// used to build tappable spans (see `LinkPreviewService.extractAllLinks`) so
/// multi-link messages keep secondary URLs clickable next to the primary
/// preview card.
class LinkHit {
  final String raw;
  final String url;
  final int start;
  final int end;
  const LinkHit(this.raw, this.url, this.start, this.end);
}

/// URL detection, normalization, OpenGraph/Twitter-card preview fetching and
/// Hive-backed caching. Purely additive — the message itself is never mutated
/// and the payload travelling over the socket stays an ordinary text message.
class LinkPreviewService {
  LinkPreviewService._();

  /// Matches `https://…`, `www.…` and bare domains (`google.com`, `a.b.co`).
  /// Bare domains require at least two dot-separated alpha labels so plain
  /// prose ("end. story", "v2.0", "$9.99") is never misdetected.
  static final RegExp _linkCandidate = RegExp(
    r'''(?:https?://|www\.)[^\s<>"']+|(?:[a-zA-Z0-9](?:[a-zA-Z0-9-]*[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}(?::\d+)?(?:/[^\s<>"']*)?''',
    caseSensitive: false,
  );

  static const _trailingPunct = '.,;:!?)]}\u201d\u2019\u201c\u2018';

  static final _memoryCache = <String, LinkPreview>{};
  static final _inflight = <String, Future<LinkPreview>>{};

  // ── Detection & normalization ────────────────────────────────────────────

  /// Returns the first link found in [text], or `null` when there is none.
  static LinkTextInfo? extractLink(String? text) {
    final hits = extractAllLinks(text);
    if (hits.isEmpty) return null;
    final hit = hits.first;
    return LinkTextInfo(hit.raw, hit.url);
  }

  /// Every sniffed URL in [text], in order of appearance, with safe-to-open
  /// normalized URLs and source offsets. Normal prose, numbers and emails are
  /// never misdetected (same rules as [extractLink]).
  static List<LinkHit> extractAllLinks(String? text) {
    final hits = <LinkHit>[];
    if (text == null || text.isEmpty) return hits;
    for (final match in _linkCandidate.allMatches(text)) {
      final matchStart = match.start;
      if (matchStart > 0 && text[matchStart - 1] == '@') continue;
      String raw = match.group(0)!.trim();
      while (raw.isNotEmpty && _trailingPunct.contains(raw[raw.length - 1])) {
        raw = raw.substring(0, raw.length - 1);
      }
      if (raw.isEmpty) continue;
      final normalized = normalizeUrl(raw);
      if (normalized != null) {
        hits.add(LinkHit(raw, normalized, matchStart, matchStart + raw.length));
      }
    }
    return hits;
  }

  static String? detectFirstUrl(String? text) => extractLink(text)?.url;

  static bool isLink(String? text) => extractLink(text) != null;

  /// `google.com` / `www.google.com` → `https://google.com`. Only http/https
  /// survives; anything else (local schemes, `file:`, `data:` …) is rejected.
  static String? normalizeUrl(String? raw) {
    if (raw == null) return null;
    var t = raw.trim();
    if (t.isEmpty) return null;

    final schemeMatch = RegExp(r'^([a-zA-Z][a-zA-Z0-9+.\-]*):').firstMatch(t);
    if (schemeMatch != null) {
      final scheme = schemeMatch.group(1)!.toLowerCase();
      if (!scheme.contains('.')) {
        if (scheme != 'http' && scheme != 'https') return null;
      }
    } else {
      t = 'https://$t';
    }

    final uri = Uri.tryParse(t);
    if (uri == null) return null;
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return null;
    final host = uri.host;
    if (host.isEmpty) return null;
    return uri.toString();
  }

  static String domainOf(String url) {
    try {
      final host = Uri.parse(url).host;
      return host.isEmpty ? url : host.replaceFirst(RegExp(r'^www\.'), '');
    } catch (_) {
      return url;
    }
  }

  /// True when [text] is exactly the link (a raw URL pasted with no extra
  /// words around it) — used to decide whether the bubble shows the preview
  /// card alone or the typed text above it.
  static bool isPlainUrlOnly(String? text, LinkTextInfo info) {
    final trimmed = (text ?? '').trim().replaceFirst(RegExp(r'\.$'), '');
    return trimmed == info.url || trimmed == info.raw;
  }

  /// Short, clean label for chat-list previews, replies and notifications.
  static String linkSummary(String? text) {
    final info = extractLink(text);
    if (info == null) return '🔗 Link';
    final domain = domainOf(info.url);
    return domain.isEmpty ? '🔗 Link' : '🔗 $domain';
  }

  // ── Preview loading with caching ─────────────────────────────────────────

  /// Returns a previously cached preview (from memory or Hive), or `null`
  /// when the URL has never been resolved in this session.
  static LinkPreview? cachedPreview(String rawUrl) {
    final url = normalizeUrl(rawUrl);
    if (url == null) return null;
    final cached = _memoryCache[url];
    if (cached != null) return cached;
    final stored = LocalDatabase.getLinkPreview(url);
    if (stored == null) return null;
    try {
      final parsed = LinkPreview.fromCacheJson(
          jsonDecode(stored) as Map<String, dynamic>, url);
      _memoryCache[url] = parsed;
      return parsed;
    } catch (_) {
      return null;
    }
  }

  static void _storeCache(LinkPreview preview) {
    _memoryCache[preview.url] = preview;
    try {
      LocalDatabase.saveLinkPreview(
          preview.url, jsonEncode(preview.toCacheJson()));
    } catch (_) {}
  }

  /// Asynchronous, cached, single-flight preview lookup. Never throws and
  /// always returns a value — a failed/unreachable URL yields the fallback
  /// `ok:false` preview so the UI shows the clean fallback card.
  static Future<LinkPreview> preview(String rawUrl) async {
    final url = normalizeUrl(rawUrl);
    if (url == null) {
      return LinkPreview.fallback(rawUrl.trim());
    }
    final cached = cachedPreview(url);
    if (cached != null) return cached;

    Future<LinkPreview> existing = _inflight[url] ??= _fetch(url);
    try {
      final preview = await existing;
      _storeCache(preview);
      return preview;
    } catch (_) {
      final fallback = LinkPreview.fallback(url);
      _storeCache(fallback);
      return fallback;
    } finally {
      _inflight.remove(url);
    }
  }

  static Future<LinkPreview> _fetch(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: const {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0 Mobile Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'en',
        },
      ).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 400) {
        return LinkPreview.fallback(url);
      }
      final finalUrl = response.request?.url.toString() ?? url;
      return _parseHtml(response.body, finalUrl) ?? LinkPreview.fallback(url);
    } catch (_) {
      return LinkPreview.fallback(url);
    }
  }

  static LinkPreview? _parseHtml(String html, String finalUrl) {
    final metaRe = RegExp(r'<meta[^>]*>', caseSensitive: false);
    final contentRe = RegExp(
      r'''content\s*=\s*["'](.*?)["']''',
      caseSensitive: false,
      dotAll: true,
    );
    final nameRe = RegExp(
      r'''(?:property|name|itemprop)\s*=\s*["'](.*?)["']''',
      caseSensitive: false,
    );

    String? ogTitle;
    String? ogDescription;
    String? ogImage;

    for (final tag in metaRe.allMatches(html)) {
      final tagText = tag.group(0)!;
      final contentMatch = contentRe.firstMatch(tagText);
      if (contentMatch == null) continue;
      final nameMatch = nameRe.firstMatch(tagText);
      final key = nameMatch?.group(1)?.toLowerCase().trim() ?? '';
      final value = _htmlDecode(contentMatch.group(1)!.trim());
      if (key == 'og:title' || key == 'twitter:title') {
        ogTitle ??= value;
      } else if (key == 'og:description' || key == 'twitter:description') {
        ogDescription ??= value;
      } else if (key == 'og:image' || key == 'twitter:image') {
        ogImage ??= value;
      }
    }

    String? title = ogTitle;
    if (title == null) {
      final titleMatch = RegExp(r'<title[^>]*>(.*?)</title>',
              caseSensitive: false, dotAll: true)
          .firstMatch(html);
      title =
          titleMatch == null ? null : _htmlDecode(titleMatch.group(1)!.trim());
    }

    if (title == null && ogDescription == null) return null;

    String? imageUrl = ogImage;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      imageUrl = Uri.parse(finalUrl).resolve(imageUrl).toString();
      if (!(imageUrl.startsWith('https://') ||
          imageUrl.startsWith('http://'))) {
        imageUrl = null;
      }
    }

    return LinkPreview(
      url: finalUrl,
      domain: domainOf(finalUrl),
      title: title,
      description: ogDescription,
      imageUrl: imageUrl,
      ok: true,
    );
  }

  static String _htmlDecode(String input) {
    var out = input.replaceAllMapped(
      RegExp(r'&#(\d+);'),
      (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 10)),
    );
    const map = {
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&apos;': "'",
      '&#39;': "'",
      '&nbsp;': ' ',
    };
    map.forEach((k, v) => out = out.replaceAll(k, v));
    out = out
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return out;
  }
}

/// Opens a validated link in the device's default handler (browser or the
/// platform app for the domain — YouTube app, Instagram app, browser, …).
/// Reuses `url_launcher`; treats URLs as untrusted input and only ever runs
/// http/https.
class LinkOpener {
  LinkOpener._();

  static Future<void> open(String rawUrl) async {
    final url = LinkPreviewService.normalizeUrl(rawUrl);
    if (url == null) return;
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'http' && uri.scheme != 'https') return;
      if (uri.host.isEmpty) return;
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      // Never crash on a malformed / unlaunchable link.
    }
  }
}
