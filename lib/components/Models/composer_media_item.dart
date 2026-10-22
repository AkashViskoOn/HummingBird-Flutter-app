import 'dart:io';

/// The kind of media held in a composer slot.
enum ComposerMediaType { image, video, document }

/// Lifecycle of a composer item from selection to send.
///
/// Items stay queued until the user hits send; while sending they move to
/// [sending] (with a per-item progress) and end as [done] or [failed].
/// Failed items stay in the composer so the user can retry without re-picking.
enum ComposerSendState { queued, sending, sendingVideo, done, failed }

/// A single pending media slot in the media composer.
///
/// This is deliberately NOT a Hive model — it is transient UI/composer state,
/// never persisted, so it does not need a registered adapter.
class ComposerMediaItem {
  ComposerMediaItem({
    required this.id,
    required this.type,
    required this.file,
    this.thumbnailPath,
    this.videoDuration,
    this.caption = '',
  });

  /// Session-unique id used to key pages, remove operations and progress.
  final String id;

  final ComposerMediaType type;

  /// The actual file on disk that will be uploaded.
  File file;

  /// Decoded first-frame thumbnail for videos (optional until captured).
  String? thumbnailPath;

  /// Video length in seconds (videos only).
  String? videoDuration;

  /// Per-media caption typed by the user in the composer.
  String caption;

  ComposerSendState state = ComposerSendState.queued;

  /// 0.0 → 1.0 while [state] is [ComposerSendState.sending].
  double progress = 0;

  bool get isImage => type == ComposerMediaType.image;
  bool get isVideo => type == ComposerMediaType.video;
  bool get isDocument => type == ComposerMediaType.document;
  bool get failed => state == ComposerSendState.failed;
}
