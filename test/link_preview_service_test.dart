import 'package:flutter_test/flutter_test.dart';
import 'package:humming_bird/services/link_preview_service.dart';

void main() {
  group('LinkPreviewService.extractLink', () {
    test('detects https urls', () {
      final info = LinkPreviewService.extractLink('https://google.com');
      expect(info, isNotNull);
      expect(info!.url, 'https://google.com');
    });

    test('detects www urls and normalizes to https', () {
      final info = LinkPreviewService.extractLink('a b www.google.com c');
      expect(info!.url, 'https://www.google.com');
      expect(info.raw, 'www.google.com');
    });

    test('detects bare domains and adds https scheme', () {
      final info = LinkPreviewService.extractLink('see google.com now');
      expect(info!.url, 'https://google.com');
    });

    test('keeps urls inside longer text', () {
      final info =
          LinkPreviewService.extractLink('watch https://youtube.com/watch now');
      expect(info!.url, 'https://youtube.com/watch');
    });

    test('returns null for plain text', () {
      expect(LinkPreviewService.extractLink('hello world'), isNull);
      expect(LinkPreviewService.extractLink(''), isNull);
      expect(LinkPreviewService.extractLink(null), isNull);
    });

    test('does not misdetect prose / numbers', () {
      expect(LinkPreviewService.extractLink('End. story'), isNull);
      expect(LinkPreviewService.extractLink('version 2.0 is out'), isNull);
      expect(LinkPreviewService.extractLink(r'it costs $9.99'), isNull);
      expect(LinkPreviewService.extractLink('no.comma.here'), isNotNull);
    });

    test('skips email addresses', () {
      expect(LinkPreviewService.extractLink('mail me@example.com'), isNull);
    });

    test('picks the first url when multiple are present', () {
      final info = LinkPreviewService.extractLink(
          'a https://google.com then https://youtube.com');
      expect(info!.url, 'https://google.com');
    });

    test('handles trailing punctuation', () {
      final info = LinkPreviewService.extractLink('go https://google.com.');
      expect(info!.url, 'https://google.com');
    });

    test('supports emoji mixed text', () {
      final info = LinkPreviewService.extractLink('🎉 https://github.com ✓');
      expect(info!.url, 'https://github.com');
    });

    test('supports long query parameters', () {
      final info = LinkPreviewService.extractLink(
          'https://example.com/watch?v=abc&list=PL123&index=4&t=1m20s');
      expect(info!.url,
          'https://example.com/watch?v=abc&list=PL123&index=4&t=1m20s');
    });
  });

  group('LinkPreviewService.normalizeUrl', () {
    test('rejects unsafe schemes', () {
      expect(LinkPreviewService.normalizeUrl('ftp://example.com'), isNull);
      expect(LinkPreviewService.normalizeUrl('file:///etc/passwd'), isNull);
      expect(LinkPreviewService.normalizeUrl('javascript:alert(1)'), isNull);
      expect(LinkPreviewService.normalizeUrl('tel:+123'), isNull);
    });

    test('accepts http and https', () {
      expect(LinkPreviewService.normalizeUrl('http://a.com'), 'http://a.com');
      expect(LinkPreviewService.normalizeUrl('https://a.com'), 'https://a.com');
      expect(LinkPreviewService.normalizeUrl('HTTPS://a.com'), 'https://a.com');
    });

    test('rejects empty hosts', () {
      expect(LinkPreviewService.normalizeUrl('https://'), isNull);
    });
  });

  group('LinkPreviewService.linkSummary', () {
    test('returns short domain label', () {
      expect(LinkPreviewService.linkSummary('https://youtube.com/watch'),
          '🔗 youtube.com');
      expect(LinkPreviewService.linkSummary('https://www.instagram.com/user'),
          '🔗 instagram.com');
    });

    test('falls back for non links', () {
      expect(LinkPreviewService.linkSummary('just text'), '🔗 Link');
    });
  });

  group('LinkPreviewService.extractAllLinks', () {
    test('returns every url in order with offsets', () {
      final hits = LinkPreviewService.extractAllLinks(
          'check https://google.com and https://youtube.com ok');
      expect(hits.length, 2);
      expect(hits[0].url, 'https://google.com');
      expect(hits[1].url, 'https://youtube.com');
      expect(hits[0].start, greaterThanOrEqualTo(0));
      expect(hits[0].end, greaterThan(hits[0].start));
      expect(hits[0].raw, 'https://google.com');
      expect(hits[1].start, greaterThan(hits[0].end));
    });

    test('excludes emails and plain prose', () {
      final hits = LinkPreviewService.extractAllLinks(
          'hello mail me@example.com version 2.0 end');
      expect(hits, isEmpty);
    });

    test('normalizes bare and www domains', () {
      final hits =
          LinkPreviewService.extractAllLinks('use google.com or www.a.co now');
      expect(hits.map((h) => h.url).toList(),
          ['https://google.com', 'https://www.a.co']);
    });

    test('trims trailing punctuation from every hit', () {
      final hits = LinkPreviewService.extractAllLinks(
          'a https://one.com., then https://two.com)');
      expect(hits[0].url, 'https://one.com');
      expect(hits[0].raw, 'https://one.com');
      expect(hits[1].url, 'https://two.com');
    });

    test('supports long query parameters and emoji text', () {
      final hits = LinkPreviewService.extractAllLinks(
          '🎉 https://example.com/?v=abc&list=PL1 then done');
      expect(hits.single.url, 'https://example.com/?v=abc&list=PL1');
    });
  });

  group('LinkPreviewService.isPlainUrlOnly', () {
    test('true when message is just the link', () {
      final info = LinkPreviewService.extractLink('https://google.com');
      expect(
          LinkPreviewService.isPlainUrlOnly('https://google.com', info!), true);
      final www = LinkPreviewService.extractLink('www.google.com');
      expect(LinkPreviewService.isPlainUrlOnly('www.google.com', www!), true);
    });

    test('false when there is surrounding text', () {
      final info =
          LinkPreviewService.extractLink('check https://google.com out');
      expect(
          LinkPreviewService.isPlainUrlOnly(
              'check https://google.com out', info!),
          false);
    });
  });
}
