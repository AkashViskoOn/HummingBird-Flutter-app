import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_dimensions.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class GroupContextSheet {
  GroupContextSheet._();

  static Future<void> show({
    required BuildContext context,
    required String groupName,
    String groupAvatar = '',
    required bool isAdmin,
    required bool isMuted,
    required bool isFavorite,
    required VoidCallback onGroupInfo,
    required VoidCallback onClearChat,
    required VoidCallback onToggleMute,
    required VoidCallback onToggleFavorite,
    required VoidCallback onExitGroup,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      isDismissible: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.modalRadius.r)),
      ),
      builder: (bottomContext) => _GroupSheetContent(
        groupName: groupName,
        groupAvatar: groupAvatar,
        isAdmin: isAdmin,
        isMuted: isMuted,
        isFavorite: isFavorite,
        onGroupInfo: onGroupInfo,
        onClearChat: onClearChat,
        onToggleMute: onToggleMute,
        onToggleFavorite: onToggleFavorite,
        onExitGroup: onExitGroup,
      ),
    );
  }
}

class _GroupSheetContent extends StatelessWidget {
  final String groupName;
  final String groupAvatar;
  final bool isAdmin;
  final bool isMuted;
  final bool isFavorite;
  final VoidCallback onGroupInfo;
  final VoidCallback onClearChat;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleFavorite;
  final VoidCallback onExitGroup;

  const _GroupSheetContent({
    required this.groupName,
    required this.groupAvatar,
    required this.isAdmin,
    required this.isMuted,
    required this.isFavorite,
    required this.onGroupInfo,
    required this.onClearChat,
    required this.onToggleMute,
    required this.onToggleFavorite,
    required this.onExitGroup,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: dark ? CustomColor.kDarkSurface : CustomColor.kWhite,
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppDimensions.modalRadius.r)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + AppSpacing.xl.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _GroupHeader(
                groupName: groupName,
                groupAvatar: groupAvatar,
                dark: dark,
                onClose: () => Navigator.of(context).pop(),
              ),
              _MenuDivider(),
              _GroupOptionRow(
                icon: Icons.info_outline_rounded,
                label: 'Group Info',
                fontsize: 14.sp,
                onTap: () {
                  Navigator.of(context).pop();
                  onGroupInfo();
                },
              ),
              _GroupOptionRow(
                icon: isMuted
                    ? Icons.notifications_rounded
                    : Icons.notifications_off_outlined,
                label: isMuted ? 'Unmute Notifications' : 'Mute Notifications',
                fontsize: 14.sp,
                onTap: () {
                  Navigator.of(context).pop();
                  onToggleMute();
                },
              ),
              _GroupOptionRow(
                icon:
                    isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                label:
                    isFavorite ? 'Remove from Favourites' : 'Add to Favourites',
                fontsize: 14.sp,
                onTap: () {
                  Navigator.of(context).pop();
                  onToggleFavorite();
                },
              ),
              _GroupOptionRow(
                icon: Icons.delete_sweep_outlined,
                label: 'Clear Chat',
                fontsize: 14.sp,
                onTap: () {
                  Navigator.of(context).pop();
                  onClearChat();
                },
              ),
              _MenuDivider(),
              _GroupOptionRow(
                icon: Icons.delete_outline_rounded,
                label: isAdmin ? 'Delete Group' : 'Exit Group',
                fontsize: 14.sp,
                isDestructive: true,
                onTap: () {
                  Navigator.of(context).pop();
                  onExitGroup();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String groupName;
  final String groupAvatar;
  final bool dark;
  final VoidCallback onClose;

  const _GroupHeader({
    required this.groupName,
    required this.groupAvatar,
    required this.dark,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppDimensions.cardPaddingH.w,
        vertical: AppSpacing.lg.h,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.avatarLg.r),
            child: SizedBox(
              width: AppDimensions.avatarLg.w,
              height: AppDimensions.avatarLg.h,
              child: groupAvatar.trim().isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: groupAvatar,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          _AvatarFallback(child: Icons.groups_rounded),
                      errorWidget: (_, __, ___) =>
                          _AvatarFallback(child: Icons.groups_rounded),
                    )
                  : _AvatarFallback(child: Icons.groups_rounded),
            ),
          ),
          SizedBox(width: AppSpacing.lg.w),
          Expanded(
            child: Text(
              groupName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.headingSm.copyWith(
                color:
                    dark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Close',
            onPressed: onClose,
            icon: Icon(
              Icons.close_rounded,
              size: 22.r,
              color: dark
                  ? CustomColor.kTextOnDarkMuted
                  : CustomColor.kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final IconData child;

  const _AvatarFallback({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: CustomColor.kPrimaryColor.withValues(alpha: 0.12),
      child: Icon(
        child,
        size: 30.r,
        color: CustomColor.kPrimaryColor,
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      indent: 14,
      endIndent: 14,
    );
  }
}

class _GroupOptionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double fontsize;
  final bool isDestructive;
  final VoidCallback onTap;

  const _GroupOptionRow({
    required this.icon,
    required this.label,
    this.fontsize = 14,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg.r),
      onTap: () {
        Navigator.of(context).pop();
        onTap();
      },
      child: _MenuItem(
        icon: icon,
        label: label,
        fontsize: fontsize,
        isDestructive: isDestructive,
        onTap: onTap,
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double fontsize;
  final bool isDestructive;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.fontsize = 14,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final IconData effectiveIcon =
        isDestructive ? Icons.delete_outline_rounded : icon;
    final Color effectiveIconColor =
        isDestructive ? CustomColor.kDangerRed : CustomColor.kPrimaryColor;
    return SizedBox(
      height: 48.h,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(effectiveIcon, size: 20.r, color: effectiveIconColor),
              SizedBox(width: 14.w),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodySm.copyWith(
                    color: isDark
                        ? CustomColor.kTextOnDark
                        : CustomColor.kTextPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: fontsize,
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
