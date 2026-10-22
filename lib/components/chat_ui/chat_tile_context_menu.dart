import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ChatTileContextMenu {
  ChatTileContextMenu._();

  static OverlayEntry? _entry;

  static bool get isShowing => _entry != null;

  static void show({
    required BuildContext context,
    required Offset position,
    required bool isPinned,
    required bool isMuted,
    required bool isUnread,
    bool isGroup = false,
    bool isGroupAdmin = false,
    bool isArchived = false,
    bool isSelected = false,
    required VoidCallback onPin,
    required VoidCallback onToggleUnread,
    required VoidCallback onArchive,
    required VoidCallback onMute,
    required VoidCallback onViewScheduled,
    required VoidCallback onViewContact,
    required VoidCallback onDelete,
    required VoidCallback onSelect,
  }) {
    dismiss();

    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;

    final menuWidth = 220.w;
    final itemHeight = 38.h;
    const itemCount = 8;
    final padV = 8.h;
    final menuHeight = itemCount * itemHeight + padV * 2;

    double top = position.dy;
    double left = position.dx;

    if (top + menuHeight > screenSize.height - 16) {
      top = screenSize.height - menuHeight - 16;
    }
    if (left + menuWidth > screenSize.width - 12) {
      left = screenSize.width - menuWidth - 12;
    }
    if (left < 12) left = 12;
    if (top < MediaQuery.of(context).padding.top + 4) {
      top = MediaQuery.of(context).padding.top + 4;
    }

    _entry = OverlayEntry(
      builder: (_) => Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            GestureDetector(
              onTap: dismiss,
              onPanDown: (_) => dismiss(),
              child: Container(color: Colors.transparent),
            ),
            Positioned(
              top: top,
              left: left,
              child: _ContextMenuCard(
                isPinned: isPinned,
                isMuted: isMuted,
                isUnread: isUnread,
                isGroup: isGroup,
                isGroupAdmin: isGroupAdmin,
                isArchived: isArchived,
                isSelected: isSelected,
                onPin: () {
                  dismiss();
                  onPin();
                },
                onSelect: () {
                  dismiss();
                  onSelect();
                },
                onToggleUnread: () {
                  dismiss();
                  onToggleUnread();
                },
                onArchive: () {
                  dismiss();
                  onArchive();
                },
                onMute: () {
                  dismiss();
                  onMute();
                },
                onViewScheduled: () {
                  dismiss();
                  onViewScheduled();
                },
                onViewContact: () {
                  dismiss();
                  onViewContact();
                },
                onDelete: () {
                  dismiss();
                  onDelete();
                },
              ),
            ),
          ],
        ),
      ),
    );

    overlay.insert(_entry!);
  }

  static void dismiss() {
    _entry?.remove();
    _entry = null;
  }
}

class _ContextMenuCard extends StatelessWidget {
  final bool isPinned;
  final bool isMuted;
  final bool isUnread;
  final bool isGroup;
  final bool isGroupAdmin;
  final bool isArchived;
  final bool isSelected;
  final VoidCallback onPin;
  final VoidCallback onToggleUnread;
  final VoidCallback onArchive;
  final VoidCallback onMute;
  final VoidCallback onViewScheduled;
  final VoidCallback onViewContact;
  final VoidCallback onDelete;
  final VoidCallback onSelect;

  const _ContextMenuCard({
    required this.isPinned,
    required this.isMuted,
    required this.isUnread,
    required this.isGroup,
    required this.isGroupAdmin,
    required this.isArchived,
    required this.isSelected,
    required this.onPin,
    required this.onToggleUnread,
    required this.onArchive,
    required this.onMute,
    required this.onViewScheduled,
    required this.onViewContact,
    required this.onDelete,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220.w,
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: CustomColor.kWhite.withValues(alpha: 0.96),
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MenuItem(
                  icon: isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                  label: isPinned ? 'Unpin Chat' : 'Pin Chat',
                  color: CustomColor.kPrimaryColor,
                  onTap: onPin,
                ),
                _MenuItem(
                  icon: isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_checked_rounded,
                  label: isSelected ? 'Unselect Chat' : 'Select Chat',
                  color: CustomColor.kPrimaryColor,
                  onTap: onSelect,
                ),
                _MenuItem(
                  icon: isUnread
                      ? Icons.drafts_rounded
                      : Icons.mark_as_unread_rounded,
                  label: isUnread ? 'Mark Read' : 'Mark Unread',
                  color: CustomColor.kPrimaryColor,
                  onTap: onToggleUnread,
                ),
                _MenuItem(
                  icon: isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                  label: isArchived ? 'Unarchive Chat' : 'Archive Chat',
                  color: CustomColor.kPrimaryColor,
                  onTap: onArchive,
                ),
                _MenuItem(
                  icon: isMuted
                      ? Icons.notifications_rounded
                      : Icons.notifications_off_outlined,
                  label: isMuted ? 'Unmute' : 'Mute Notifications',
                  color: CustomColor.kPrimaryColor,
                  onTap: onMute,
                ),
                _MenuItem(
                  icon: Icons.calendar_today_rounded,
                  label: 'View Scheduled',
                  color: CustomColor.kPrimaryColor,
                  onTap: onViewScheduled,
                ),
                _MenuItem(
                  icon: isGroup
                      ? Icons.info_outline_rounded
                      : Icons.person_outline_rounded,
                  label: isGroup ? 'Group Info' : 'View Contact',
                  color: CustomColor.kPrimaryColor,
                  onTap: onViewContact,
                ),
                const Divider(
                    height: 1, thickness: 0.5, indent: 14, endIndent: 14),
                _MenuItem(
                  icon: isGroup
                      ? (isGroupAdmin
                          ? Icons.delete_outline_rounded
                          : Icons.logout_rounded)
                      : Icons.delete_outline_rounded,
                  label: isGroup
                      ? (isGroupAdmin ? 'Delete Group' : 'Exit Group')
                      : 'Delete Chat',
                  isDestructive: true,
                  onTap: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.color,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDestructive
        ? CustomColor.kDangerRed
        : (color ?? CustomColor.kPrimaryColor);
    return SizedBox(
      height: 48.h,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(icon, size: 20.r, color: effectiveColor),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isDestructive
                        ? CustomColor.kDangerRed
                        : CustomColor.kTextPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
