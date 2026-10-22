import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/services/link_preview_service.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Bubble content for a link message: the typed text (when the message is more
/// than just the URL) above a tappable, premium preview card. Everything else
/// about the bubble — alignment, theme, timestamp, status, reply, delete,
/// reactions, selection — is untouched.
class LinkMessageContent extends StatelessWidget {
  final String url;
  final Widget? body;

  const LinkMessageContent({super.key, required this.url, this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('link-content'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (body != null) ...[
          body!,
          SizedBox(height: 8.h),
        ],
        LinkPreviewCard(url: url),
      ],
    );
  }
}

/// Body text for multi-link messages: the primary URL (already previewed by
/// the card below) is hidden from the caption, and every remaining URL stays
/// visible and tappable. Plain prose keeps the exact same rendering and style.
class LinkifyBody extends StatelessWidget {
  final String text;
  final LinkTextInfo primary;
  final TextStyle style;
  final Color linkColor;

  const LinkifyBody({
    super.key,
    required this.text,
    required this.primary,
    required this.style,
    required this.linkColor,
  });

  @override
  Widget build(BuildContext context) {
    final hits = LinkPreviewService.extractAllLinks(text);
    if (hits.isEmpty) return Text(text, style: style);

    final spans = <InlineSpan>[];
    var cursor = 0;
    var primarySkipped = false;
    for (final hit in hits) {
      if (!primarySkipped && hit.url == primary.url) {
        primarySkipped = true;
        if (hit.start > cursor) {
          spans.add(TextSpan(text: text.substring(cursor, hit.start)));
        }
        cursor = hit.end;
        continue;
      }
      if (hit.start > cursor) {
        spans.add(TextSpan(text: text.substring(cursor, hit.start)));
      }
      spans.add(
        TextSpan(
          text: text.substring(hit.start, hit.end),
          style: style.copyWith(
            color: linkColor,
            fontWeight: FontWeight.w600,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () => LinkOpener.open(hit.url),
        ),
      );
      cursor = hit.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor)));
    }

    return Text.rich(
      TextSpan(style: style, children: spans),
      softWrap: true,
    );
  }
}

/// The actual link preview card. Loads metadata asynchronously (never inside
/// `build`), shows a subtle skeleton while waiting, and always falls back to a
/// clean domain + URL card when the site can't be previewed — the link stays
/// usable either way.
class LinkPreviewCard extends StatefulWidget {
  final String url;

  const LinkPreviewCard({super.key, required this.url});

  @override
  State<LinkPreviewCard> createState() => _LinkPreviewCardState();
}

class _LinkPreviewCardState extends State<LinkPreviewCard> {
  LinkPreview? _preview;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final cached = LinkPreviewService.cachedPreview(widget.url);
    if (cached != null) {
      _preview = cached;
      _loading = false;
    } else {
      LinkPreviewService.preview(widget.url).then((preview) {
        if (mounted) {
          setState(() {
            _preview = preview;
            _loading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardWidth =
        (MediaQuery.of(context).size.width * 0.60).clamp(220.0, 320.0);
    return Container(
      width: cardWidth,
      decoration: BoxDecoration(
        color: isDark
            ? CustomColor.kTextOnDark.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
      ),
      clipBehavior: Clip.antiAlias,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _loading
            ? _LinkSkeleton(width: cardWidth)
            : _preview != null && _preview!.ok
                ? _buildRichCard(cardWidth, _preview!, isDark)
                : _buildFallbackCard(cardWidth, isDark),
      ),
    );
  }

  Widget _buildRichCard(double width, LinkPreview preview, bool isDark) {
    return InkWell(
      onTap: () => LinkOpener.open(widget.url),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (preview.imageUrl != null && preview.imageUrl!.isNotEmpty)
            ClipRRect(
              child: SizedBox(
                height: width * 9 / 16,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: preview.imageUrl!,
                  fit: BoxFit.cover,
                  httpHeaders: const {
                    'User-Agent':
                        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36',
                  },
                  placeholder: (_, __) => ColoredBox(
                    color: isDark
                        ? CustomColor.kTextOnDark.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.055),
                  ),
                  errorWidget: (_, __, ___) => ColoredBox(
                    color: isDark
                        ? CustomColor.kTextOnDark.withValues(alpha: 0.07)
                        : Colors.black.withValues(alpha: 0.055),
                  ),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(AppSpacing.md.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (preview.title != null && preview.title!.isNotEmpty)
                  Text(
                    preview.title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: isDark
                        ? AppTextStyles.titleMdOnDark
                        : AppTextStyles.titleSm,
                  ),
                if (preview.description != null &&
                    preview.description!.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 3.h),
                    child: Text(
                      preview.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        fontSize: 12.5.sp,
                        color: isDark
                            ? CustomColor.kTextOnDarkMuted
                            : CustomColor.kTextSecondary,
                      ),
                    ),
                  ),
                Padding(
                  padding: EdgeInsets.only(top: 6.h),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 12.r,
                        color: CustomColor.kPrimaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Flexible(
                        child: Text(
                          preview.domain,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: CustomColor.kPrimaryColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackCard(double width, bool isDark) {
    final domain = LinkPreviewService.domainOf(widget.url);
    return InkWell(
      onTap: () => LinkOpener.open(widget.url),
      child: Padding(
        padding:
            EdgeInsets.symmetric(horizontal: AppSpacing.lg.w, vertical: 14.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.md.r),
              ),
              child: Icon(
                Icons.link_rounded,
                size: 20.r,
                color: CustomColor.kPrimaryColor,
              ),
            ),
            SizedBox(width: 12.w),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    domain,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: isDark
                        ? AppTextStyles.titleMdOnDark
                        : AppTextStyles.titleSm,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    widget.url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySm.copyWith(
                      fontSize: 12.sp,
                      color: isDark
                          ? CustomColor.kTextOnDarkMuted
                          : CustomColor.kTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Subtle static placeholder blocks — keeps the chat fully usable while the
/// preview loads. Deliberately no animation/spinner.
class _LinkSkeleton extends StatelessWidget {
  final double width;

  const _LinkSkeleton({required this.width});

  @override
  Widget build(BuildContext context) {
    final blockColor = Theme.of(context).brightness == Brightness.dark
        ? CustomColor.kOverlay8
        : Colors.black.withValues(alpha: 0.06);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: width * 9 / 16,
          width: double.infinity,
          child: ColoredBox(color: blockColor),
        ),
        Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: width * 0.62,
                height: 11.h,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(AppRadius.xs.r),
                ),
              ),
              SizedBox(height: 7.h),
              Container(
                width: width * 0.82,
                height: 9.h,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(AppRadius.xs.r),
                ),
              ),
              SizedBox(height: 7.h),
              Container(
                width: width * 0.40,
                height: 8.h,
                decoration: BoxDecoration(
                  color: blockColor,
                  borderRadius: BorderRadius.circular(AppRadius.xs.r),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
