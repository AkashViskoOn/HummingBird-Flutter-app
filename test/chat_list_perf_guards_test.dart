import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural performance guards for the message list.
///
/// These read the real source file rather than mock the whole GetX stack, and
/// assert the invariants that the client-performance score rests on:
///   1. The message list is a lazy `builder` list (reverse virtualized), not a
///      `ListView(children: ...)` — so off-screen messages are never built.
///   2. Every item's return is wrapped in a `RepaintBoundary`, so an animation
///      or repaint in one bubble is isolated and cannot repaint siblings.
///   3. A *settled* bubble renders bare — the Opacity/Transform entrance
///      wrappers drop out at value 1.0, so scrolled lists do not carry a
///      compositing layer per bubble.
///
/// If a future refactor breaks any of these, the performance regression is
/// caught here instead of on a real device.
void main() {
  final source = File('lib/pages/chats/chat_screens/chat_screen.dart')
      .readAsStringSync();

  group('chat message list perf invariants', () {
    test('list is lazy (builder), not ListView(children:)', () {
      expect(source, contains('ScrollablePositionedList.builder'),
          reason: 'message list must stay a builder list');
      expect(source, isNot(contains('ListView(children:')),
          reason: 'a children-list builds every message eagerly');
    });

    test('itemBuilder is wrapped in RepaintBoundary', () {
      // Find the first 'return RepaintBoundary(' at the top of the body after
      // itemBuilder — crude but sufficient: if the boundary is removed, the
      // marker disappears from the item area entirely.
      expect(source, contains('return RepaintBoundary('),
          reason: 'each bubble must sit inside a RepaintBoundary');
      final itemBuilderPos = source.indexOf('itemBuilder:');
      final firstBoundary = source.indexOf('return RepaintBoundary(');
      expect(itemBuilderPos, isNot(-1));
      // The isolated boundary must appear inside/after the itemBuilder, not
      // somewhere warm outside it (e.g. around the whole list).
      expect(firstBoundary, greaterThan(itemBuilderPos),
          reason: 'RepaintBoundary must be inside the per-item builder');
    });

    test('settled bubbles drop Opacity/Transform entrance wrappers', () {
      expect(source, contains('if (value >= 1.0)'),
          reason: 'a settled bubble must not keep compositing wrappers');
      expect(source, contains('return child!;'),
          reason: 'settled bubble renders the bare child');
    });

    test('no raw Image.network inside the chat screen list area', () {
      // Images must resolve through CachedNetworkImage so the scroll rebuild
      // never re-fetches a full decode from the network on a cache miss.
      expect(source, isNot(contains('Image.network(')),
          reason: 'raw Image.network bypasses the disk/memory image cache');
      expect(source, contains('CachedNetworkImage'),
          reason: 'list images go through the cached image widget');
    });
  });
}