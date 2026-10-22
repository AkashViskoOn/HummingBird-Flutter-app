import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/res/colors.dart';

/// Media thumbnail shown inside reply previews (composer + in-bubble reply).
/// Images/videos render a cached thumbnail; documents/audio/contacts get a
/// colored type icon.
class ReplyMediaThumb extends StatelessWidget {
  final Messages message;
  final double size;

  const ReplyMediaThumb({super.key, required this.message, this.size = 44});

  String get _type => message.mMessageType?.trim() ?? '0';

  bool get _isMedia => _type == '1' || _type == '4';

  @override
  Widget build(BuildContext context) {
    final s = size.r;
    if (_isMedia) {
      final url = AppHelper.resolveMediaUrl(message.mMedia);
      if (url.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md.r),
          child: SizedBox(
            width: s,
            height: s,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  memCacheWidth: (s * 2).round(),
                  placeholder: (_, __) => Container(
                    color: Colors.black.withValues(alpha: 0.25),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: CustomColor.kTextOnDark,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => _buildIconFallback(s),
                ),
                if (_type == '4')
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      color: CustomColor.kOverlay70,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    }
    return _buildIconFallback(s);
  }

  Widget _buildIconFallback(double s) {
    final accent = AppHelper.mediaAccentColor(
      fileType: _type,
      mediaUrl: message.mMedia ?? '',
    );
    return Container(
      width: s,
      height: s,
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.md.r),
      ),
      child: Icon(
        AppHelper.mediaTypeIcon(fileType: _type),
        color: accent,
        size: s * 0.5,
      ),
    );
  }
}
