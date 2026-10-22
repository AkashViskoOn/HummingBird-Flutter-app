import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// @-mention helpers for group chats (WhatsApp-style mention).

/// Display name used as the "@token" inside the message text.
String mentionTokenFor(User member) {
  final first = (member.userFirstName ?? '').trim();
  if (first.isNotEmpty) return first;
  final number = (member.userMobileNum ?? '').trim();
  return number.isNotEmpty ? number : 'user';
}

/// Returns the text typed after the last "@" before the cursor (no space),
/// or null when the user is not composing a mention right now.
String? mentionQueryAt(TextEditingController controller) {
  final text = controller.text;
  final sel = controller.selection;
  if (!sel.isValid || !sel.isCollapsed) return null;
  final upTo = text.substring(0, sel.baseOffset);
  final at = upTo.lastIndexOf('@');
  if (at < 0) return null;
  final after = upTo.substring(at + 1);
  if (after.contains(' ')) return null;
  return after;
}

/// Suggestion bar shown above the composer while typing "@" in a group chat.
/// Listens to the controller itself, so it only rebuilds its own subtree.
class MentionSuggestionBar extends StatefulWidget {
  final TextEditingController controller;
  final List<User> members;
  final void Function(String userId, String token) onMentionSelected;

  const MentionSuggestionBar({
    super.key,
    required this.controller,
    required this.members,
    required this.onMentionSelected,
  });

  @override
  State<MentionSuggestionBar> createState() => _MentionSuggestionBarState();
}

class _MentionSuggestionBarState extends State<MentionSuggestionBar> {
  String? _query;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant MentionSuggestionBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final query = mentionQueryAt(widget.controller);
    if (query != _query) setState(() => _query = query);
  }

  void _insertMention(User member) {
    final token = mentionTokenFor(member);
    final controller = widget.controller;
    final text = controller.text;
    final sel = controller.selection;
    if (!sel.isValid || !sel.isCollapsed) return;
    final at = text.substring(0, sel.baseOffset).lastIndexOf('@');
    if (at < 0) return;

    final afterCursor = text.substring(sel.baseOffset);
    final spaceIdx = afterCursor.indexOf(' ');
    final rest = spaceIdx >= 0 ? afterCursor.substring(spaceIdx + 1) : '';

    final replacement = '@$token ';
    controller.text = '${text.substring(0, at)}$replacement$rest';
    controller.selection =
        TextSelection.collapsed(offset: at + replacement.length);
    widget.onMentionSelected(member.userId ?? '', token);
  }

  @override
  Widget build(BuildContext context) {
    final query = _query;
    if (query == null) return const SizedBox.shrink();

    final q = query.toLowerCase();
    final suggestions = widget.members.where((m) {
      final name = mentionTokenFor(m).toLowerCase();
      final number = (m.userMobileNum ?? '').toLowerCase();
      return name.contains(q) || number.contains(q);
    }).toList();
    if (suggestions.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(
          AppSpacing.lg.w, AppSpacing.sm.h, AppSpacing.lg.w, 0),
      constraints: BoxConstraints(maxHeight: 264.h),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kScrim20,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xs.h),
          itemCount: suggestions.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            thickness: 0.5,
            indent: AppSpacing.xl.w,
            endIndent: AppSpacing.xl.w,
          ),
          itemBuilder: (context, index) {
            final member = suggestions[index];
            final image = (member.userImage ?? '').trim();
            return InkWell(
              onTap: () => _insertMention(member),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl.w, vertical: AppSpacing.sm.h),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18.r,
                      backgroundColor:
                          CustomColor.kPrimaryColor.withValues(alpha: 0.12),
                      backgroundImage: image.isNotEmpty
                          ? CachedNetworkImageProvider(
                              '${Endpoints.mediaBaseUrl}$image')
                          : null,
                      child: image.isEmpty
                          ? Text(
                              mentionTokenFor(member)
                                  .characters
                                  .first
                                  .toUpperCase(),
                              style: AppTextStyles.bodyMd.copyWith(
                                color: CustomColor.kPrimaryColor,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                    SizedBox(width: AppSpacing.xl.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mentionTokenFor(member),
                            style: AppTextStyles.bodyMd.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if ((member.userMobileNum ?? '').isNotEmpty)
                            Text(
                              member.userMobileNum!,
                              style: AppTextStyles.chatPreview.copyWith(
                                color: CustomColor.kTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(width: AppSpacing.lg.w),
                    Icon(
                      Icons.alternate_email_rounded,
                      size: 20.r,
                      color: CustomColor.kPrimaryColor,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
