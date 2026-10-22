import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/forward_message_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Quick Forward — an inline, Instagram-style one-tap forward picker.
///
/// Long-press "Forward" in the message action menu to open this instead of a
/// bottom sheet. It shows the 5 best 1:1 targets (most-recent-forwards first,
/// then most recent chats) in a floating card, and tapping a contact forwards
/// immediately with the EXISTING [ChatController.forwardMessages] pipeline.
///
/// Since 2026-09 this is a pure overlay widget — it opens a bottom sheet or a
/// dialog, and it never navigates unless the user taps "Search contacts"
/// (which falls back to the existing [ForwardMessageScreen] picker).
class QuickForwardPanel extends StatefulWidget {
  final List<String> messageIds;

  const QuickForwardPanel({super.key, required this.messageIds});

  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

  static void show(BuildContext context, {required List<String> messageIds}) {
    if (isShowing) return;
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => QuickForwardPanel(messageIds: messageIds),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }

  @override
  State<QuickForwardPanel> createState() => _QuickForwardPanelState();
}

class _QuickForwardPanelState extends State<QuickForwardPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  late final List<_QuickTarget> _targets;

  bool _sending = false;
  String? _pressedRoomId;

  @override
  void initState() {
    super.initState();
    _targets = _buildTargets();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    if (!mounted) return;
    _controller
      ..duration = const Duration(milliseconds: 140)
      ..reverse().whenCompleteOrCancel(() {
        if (mounted) QuickForwardPanel.dismiss();
      });
  }

  void _forwardTo(_QuickTarget target) {
    if (_sending) return;
    _sending = true;
    HapticFeedback.mediumImpact();
    setState(() => _pressedRoomId = null);
    Get.find<ChatController>()
        .forwardMessages(widget.messageIds, [target.roomId]);
    _close();
  }

  void _openSearch() {
    QuickForwardPanel.dismiss();
    Get.to(() => ForwardMessageScreen(messageIds: widget.messageIds));
  }

  /// Top-5 1:1 targets ranked by most-recent-forward ids then chat recency.
  /// Blocked contacts, the current user and duplicates are filtered out.
  ///
  /// Defensively wrapped: this runs in [initState], so any unexpected
  /// exception (e.g. cached user object not loaded yet) must not escape into
  /// the first build — an uncaught throw here surfaces as a red-screened /
  /// overflowed panel on the user's device.
  List<_QuickTarget> _buildTargets() {
    try {
      final home = Get.find<HomeController>();
      final contact = Get.find<ContactController>();
      final myId = Get.find<UserController>().userId;
      final recent = List<String>.from(
          GetStorage().read<List<dynamic>>('recent_forward_room_ids') ?? []);
      final map = <String, _QuickTarget>{};
      final pinned = home.getPinnedRoomIds().toSet();

      for (final room in home.singleChatsList) {
        if (room.rId == null) continue;
        if (map.containsKey(room.rId)) continue;
        final data = contact.getContactData(room);
        final receiverId = data.$2;
        if (receiverId.isNotEmpty && receiverId == myId) {
          continue;
        }
        if (receiverId.isNotEmpty && _isBlocked(contact, receiverId)) {
          continue;
        }
        final name = data.$1.isNotEmpty
            ? data.$1
            : (data.$3.isNotEmpty ? data.$3 : (room.rName ?? 'Unknown'));
        map[room.rId!] = _QuickTarget(
          roomId: room.rId!,
          receiverId: receiverId,
          name: name,
          subtitle: data.$4.isNotEmpty
              ? data.$4
              : (data.$3.isNotEmpty ? data.$3 : ''),
          imagePath: _userImage(contact, receiverId),
          recency: _updatedAt(room),
          pinned: pinned.contains(room.rId),
        );
      }

      final list = map.values.toList();
      list.sort((a, b) {
        final ai = recent.indexOf(a.roomId);
        final bi = recent.indexOf(b.roomId);
        if (ai >= 0 && bi < 0) return -1;
        if (ai < 0 && bi >= 0) return 1;
        if (ai >= 0 && bi >= 0) return ai.compareTo(bi);
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.recency.compareTo(a.recency);
      });
      return list.take(5).toList();
    } catch (_) {
      return const [];
    }
  }

  /// Null-safe blocked check. The shared implementation dereferences
  /// `userController.user!` / `userBlockList!`, which can throw before the
  /// user cache is ready — treat that as "not blocked" so the panel still
  /// opens cleanly.
  bool _isBlocked(ContactController contact, String receiverId) {
    try {
      return contact.checkIfUserIsBlocked(receiverId);
    } catch (_) {
      return false;
    }
  }

  String? _userImage(ContactController contact, String receiverId) {
    for (final u in contact.hummingContacts) {
      if (u.userId == receiverId && (u.userImage?.isNotEmpty ?? false)) {
        return u.userImage;
      }
    }
    return null;
  }

  int _updatedAt(Rooms room) => int.tryParse(room.rUpdatedAt ?? '0') ?? 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
    final textColor =
        isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    final secondaryText =
        isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _close,
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Container(
                color: Colors.black.withValues(alpha: 0.25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ),
        Center(
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Material(
                  color: Colors.transparent,
                  child: _buildCard(
                      context, isDark, bgColor, textColor, secondaryText),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    bool isDark,
    Color bgColor,
    Color textColor,
    Color secondaryText,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: screenWidth - 32.w < 360.w ? screenWidth - 32.w : 360.w,
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
          boxShadow: AppShadow.elevatedLight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, isDark, textColor),
            if (_targets.isNotEmpty) ...[
              SizedBox(height: 4.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 10.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final target in _targets)
                      Expanded(child: _buildAvatarTile(target, isDark)),
                  ],
                ),
              ),
              SizedBox(height: 12.h),
            ],
            Divider(
              height: 1,
              thickness: 0.5,
              color: isDark
                  ? CustomColor.kDarkDivider
                  : CustomColor.kLightBorder.withValues(alpha: 0.5),
            ),
            _buildSearchTile(context, secondaryText),
            SizedBox(height: 6.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Color textColor,
  ) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18.w, 8.h, 8.w, 2.h),
      child: Row(
        children: [
          Text(
            'Forward to',
            style: AppTextStyles.titleMd.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (widget.messageIds.length > 1) ...[
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.pill.r),
              ),
              child: Text(
                '${widget.messageIds.length} messages',
                style: AppTextStyles.caption.copyWith(
                  color: CustomColor.kPrimaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(width: 4.w),
          ],
          IconButton(
            tooltip: 'Close',
            padding: EdgeInsets.all(6.r),
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            onPressed: _close,
            icon: Icon(
              Icons.close_rounded,
              size: 20.r,
              color: isDark
                  ? CustomColor.kTextOnDarkSecondary
                  : CustomColor.kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarTile(_QuickTarget target, bool isDark) {
    final url = target.imagePath;
    final nameColor =
        isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _sending
          ? null
          : (_) => setState(() => _pressedRoomId = target.roomId),
      onTapCancel: () => setState(() => _pressedRoomId = null),
      onTap: _sending ? null : () => _forwardTo(target),
      child: AnimatedScale(
        scale: _pressedRoomId == target.roomId ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54.r,
              height: 54.r,
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.45),
                  width: 1.6,
                ),
              ),
              child: ClipOval(
                child: url != null && url.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: '${Endpoints.mediaBaseUrl}$url',
                        fit: BoxFit.cover,
                        placeholder: (_, __) => _avatarFallback(target),
                        errorWidget: (_, __, ___) => _avatarFallback(target),
                      )
                    : _avatarFallback(target),
              ),
            ),
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Center(
                child: Text(
                  target.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySm.copyWith(
                    color: nameColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTile(BuildContext context, Color secondaryText) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
      onTap: _openSearch,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_rounded,
              size: 20.r,
              color: CustomColor.kPrimaryColor,
            ),
            SizedBox(width: 8.w),
            Text(
              'Search contacts',
              style: AppTextStyles.bodySm.copyWith(
                color:
                    isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(_QuickTarget target) {
    return Container(
      width: 54.r,
      height: 54.r,
      color: CustomColor.kPrimaryColor,
      alignment: Alignment.center,
      child: Text(
        _initials(target.name),
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.w700,
          color: CustomColor.kTextOnDark,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }
}

class _QuickTarget {
  final String roomId;
  final String receiverId;
  final String name;
  final String subtitle;
  final String? imagePath;
  final int recency;
  final bool pinned;

  const _QuickTarget({
    required this.roomId,
    required this.receiverId,
    required this.name,
    required this.subtitle,
    this.imagePath,
    required this.recency,
    required this.pinned,
  });
}
