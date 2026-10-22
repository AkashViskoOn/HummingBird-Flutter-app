import 'package:flutter/material.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/chat_ui/mention_suggestion_bar.dart';

/// Message bubble text with WhatsApp-style mention highlighting.
/// Highlights "@Name" occurrences for the mentioned member ids, using the
/// same token format the suggestion bar inserts (@first-name / number).
class MentionRichText extends StatelessWidget {
  final String text;
  final List<String> mentionIds;
  final List<User> members;
  final TextStyle? style;
  final Color highlightColor;

  const MentionRichText({
    super.key,
    required this.text,
    required this.mentionIds,
    required this.members,
    required this.style,
    required this.highlightColor,
  });

  List<String> get _mentionNames {
    final names = <String>[];
    for (final id in mentionIds) {
      for (final member in members) {
        if (member.userId == id) {
          names.add(mentionTokenFor(member));
          break;
        }
      }
    }
    return names;
  }

  @override
  Widget build(BuildContext context) {
    final names = _mentionNames;
    if (names.isEmpty) {
      return Text(text, style: style, softWrap: true);
    }

    final matches = <(int, int)>[];
    for (final name in names) {
      final re = RegExp('@${RegExp.escape(name)}', caseSensitive: false);
      for (final m in re.allMatches(text)) {
        matches.add((m.start, m.end));
      }
    }
    matches.sort((a, b) => a.$1.compareTo(b.$1));

    final spans = <TextSpan>[];
    var last = 0;
    for (final (start, end) in matches) {
      if (start < last) continue; // overlapping match — skip
      if (start > last) {
        spans.add(TextSpan(text: text.substring(last, start)));
      }
      spans.add(TextSpan(
        text: text.substring(start, end),
        style: style?.copyWith(
          color: highlightColor,
          fontWeight: FontWeight.w600,
        ),
      ));
      last = end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return Text.rich(
      TextSpan(style: style, children: spans),
      softWrap: true,
    );
  }
}
