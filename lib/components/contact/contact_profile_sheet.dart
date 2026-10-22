import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/chat_ui/block_user_dialog.dart';
import 'package:humming_bird/components/chat_ui/report_dialog.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/call_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_screen.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/pages/contacts/add_new_contact.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/user_profile_details.dart';

/// Profile sheet for a contact (contacts tab + shared-contact bubble).
///
/// Registered Humming Bird contact: large avatar, name, number, status pill,
/// three compact actions (Message / Voice Call / Video Call) then rounded
/// action rows (Add to Contacts, View Profile, Add to Group, Schedule,
/// Favorites, Block, Report).
/// Non-Humming contact: name, number, "Not on Humming Bird" pill, then
/// Add to Contacts + Invite to Humming Bird.
class ContactProfileSheet extends StatefulWidget {
  final User? user;
  final String name;
  final String number;
  final ImageProvider avatar;

  const ContactProfileSheet({
    super.key,
    this.user,
    required this.name,
    required this.number,
    required this.avatar,
  });

  /// Matches a shared phone number against known Humming Bird contacts.
  /// Returns the matching `User` or `null` (not registered).
  static User? findUserByNumber(String number) {
    if (number.isEmpty) return null;
    try {
      final contactController = Get.find<ContactController>();
      for (final u in contactController.hummingContacts) {
        if (u.userMobileNum != null && u.userMobileNum == number) {
          return u;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Builds the avatar image: shared `profile` path first, falling back to the
  /// matched user's image, then the default profile asset.
  static ImageProvider avatarProvider(String? profilePath, User? user) {
    final String url;
    if (profilePath != null && profilePath.isNotEmpty) {
      url = '${Endpoints.mediaBaseUrl}$profilePath';
    } else if ((user?.userImage?.isNotEmpty ?? false)) {
      url = '${Endpoints.mediaBaseUrl}${user!.userImage}';
    } else {
      url = '';
    }
    return url.isNotEmpty
        ? CachedNetworkImageProvider(url)
        : const AssetImage(AppAssets.defaultProfilePic);
  }

  /// Opens the sheet for a shared-contact bubble (`m_message_type` '6').
  /// Resolves the shared contact to a Humming Bird user by phone number when
  /// possible so Message / Voice Call / Video Call stay enabled.
  static Future<void> openFromJson(String msg) async {
    try {
      final data = jsonDecode(msg) as Map<String, dynamic>;
      final name = (data['name'] as String?)?.trim() ?? 'Unknown';
      final number = (data['number'] as String?) ?? '';
      final profile = (data['profile'] as String?) ?? '';

      final user = findUserByNumber(number);
      final avatar = avatarProvider(profile.isEmpty ? null : profile, user);

      await Get.bottomSheet(
        ContactProfileSheet(
          user: user,
          name: name,
          number: number,
          avatar: avatar,
        ),
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
      );
    } catch (_) {}
  }

  @override
  State<ContactProfileSheet> createState() => _ContactProfileSheetState();
}

class _ContactProfileSheetState extends State<ContactProfileSheet> {
  late final ContactController _contactController;

  @override
  void initState() {
    super.initState();
    _contactController = Get.find();
  }

  bool get _hasUser => widget.user != null;

  String get _userId => widget.user?.userId ?? '';

  void _openChat() {
    final user = widget.user;
    if (user == null) return;
    _contactController.addRecentlyContacted(user.userId ?? '');
    Get.back();
    final existingRoom = _contactController.checkIfRoomExists(user);
    Get.to(() => ChatScreen(
          name: _contactController.getAllContactsName(user),
          userNumber: user.userMobileNum ?? '',
          roomId: existingRoom.$1 ? existingRoom.$2?.rId ?? '0' : '0',
          userProfile: user.userImage ?? '',
          receiverId: user.userId ?? '',
        ));
  }

  void _openSchedule() {
    final user = widget.user;
    if (user == null) return;
    _contactController.addRecentlyContacted(user.userId ?? '');
    Get.back();
    final existingRoom = _contactController.checkIfRoomExists(user);
    Get.to(() => ScheduleScreen(
          name: widget.name,
          roomId: existingRoom.$1 ? existingRoom.$2?.rId ?? '0' : '0',
          receiverId: user.userId ?? '',
          roomUsers: '',
        ));
  }

  void _startCall(String type) {
    if (_userId.isEmpty) return;
    Get.back();
    Get.find<CallController>().initCall(_userId, type);
  }

  void _openAddToGroup() {
    final user = widget.user;
    if (user == null) return;
    if (_contactController.groupsList.isEmpty) {
      _contactController.fetchGroups();
    }
    Get.back();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddToGroupSheet(user: user),
    );
  }

  void _addToContacts() {
    if (widget.number.isEmpty) {
      Utils.showGetSnackBar('This contact has no phone number');
      return;
    }
    Get.back();
    Get.to(() => const AddContact(), arguments: {
      'name': widget.name,
      'number': widget.number,
    });
  }

  void _viewProfile() {
    final user = widget.user;
    if (user == null) return;
    final existingRoom = _contactController.checkIfRoomExists(user);
    Get.back();
    Get.to(() => UserProfileDetails(
          userName: widget.name,
          userProfile: user.userImage ?? '',
          userNumber: widget.number,
          userBio: user.userBio ?? '',
          roomId: existingRoom.$1 ? existingRoom.$2?.rId ?? '0' : '0',
        ));
  }

  void _inviteToHummingBird() {
    if (widget.number.isEmpty) {
      Utils.showGetSnackBar('This contact has no phone number');
      return;
    }
    Get.back();
    try {
      _contactController.sendInviteMessage(widget.number);
    } catch (_) {
      Utils.showGetSnackBar('Could not open the invite');
    }
  }

  Widget _buildStatusPill() {
    final bool registered = _hasUser;
    final Color fg =
        registered ? CustomColor.kPrimaryColor : CustomColor.kTextTertiary;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg.w,
        vertical: AppSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.pill.r),
        border: Border.all(color: fg.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            registered ? Icons.verified_rounded : Icons.person_off_outlined,
            size: 15.r,
            color: fg,
          ),
          SizedBox(width: 6.w),
          Text(
            registered ? 'Humming Bird Contact' : 'Not on Humming Bird',
            style: AppTextStyles.labelSm.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    if (!_hasUser) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ContactActionIcon(
          icon: Icons.chat_bubble_rounded,
          label: 'Message',
          color: CustomColor.kPrimaryColor,
          onTap: _openChat,
        ),
        SizedBox(width: 22.w),
        _ContactActionIcon(
          icon: Icons.call_rounded,
          label: 'Voice Call',
          color: CustomColor.kOnlineGreen,
          onTap: () => _startCall('audio'),
        ),
        SizedBox(width: 22.w),
        _ContactActionIcon(
          icon: Icons.videocam_rounded,
          label: 'Video Call',
          color: CustomColor.kPrimaryMedium,
          onTap: () => _startCall('video'),
        ),
      ],
    );
  }

  Widget _buildOptionsCard() {
    final bool registered = _hasUser;
    final List<Widget> tiles = [
      _ProfileOptionTile(
        icon: Icons.person_add_alt_1_rounded,
        iconColor: CustomColor.kPrimaryColor,
        label: 'Add to Contacts',
        onTap: _addToContacts,
      ),
    ];

    if (registered) {
      tiles.add(_ProfileOptionTile(
        icon: Icons.account_circle_rounded,
        iconColor: CustomColor.kPrimaryColor,
        label: 'View Profile',
        showDivider: true,
        onTap: _viewProfile,
      ));
      tiles.addAll([
        _ProfileOptionTile(
          icon: Icons.group_add_rounded,
          iconColor: CustomColor.kPrimaryColor,
          label: 'Add to Group',
          onTap: _openAddToGroup,
        ),
        _ProfileOptionTile(
          icon: Icons.schedule_rounded,
          iconColor: CustomColor.kPrimaryColor,
          label: 'Schedule Message',
          onTap: _openSchedule,
        ),
        _ProfileOptionTile(
          icon: _contactController.isFavoriteContact(_userId)
              ? Icons.star_rounded
              : Icons.star_outline_rounded,
          iconColor: CustomColor.kGoldAccent,
          label: _contactController.isFavoriteContact(_userId)
              ? 'Remove from Favorites'
              : 'Add to Favorites',
          onTap: () {
            _contactController.toggleFavoriteContact(_userId);
            setState(() {});
          },
        ),
        _ProfileOptionTile(
          icon: Icons.block_rounded,
          iconColor: CustomColor.kDangerRed,
          label: _contactController.checkIfUserIsBlocked(_userId)
              ? 'Unblock ${widget.name.split(' ')[0]}'
              : 'Block ${widget.name.split(' ')[0]}',
          onTap: () {
            Get.back();
            showDialog(
              context: context,
              builder: (_) => BlockUserDialog(
                userId: _userId,
                userName: widget.name.split(' ')[0],
              ),
            );
          },
        ),
        _ProfileOptionTile(
          icon: Icons.thumb_down_off_alt_rounded,
          iconColor: CustomColor.kDangerRed,
          label: 'Report ${widget.name.split(' ')[0]}',
          onTap: () {
            Get.back();
            showDialog(
              context: context,
              builder: (_) => ReportDialog(
                userId: _userId,
                userName: widget.name.split(' ')[0],
              ),
            );
          },
        ),
      ]);
    } else {
      tiles.add(_ProfileOptionTile(
        icon: Icons.send_rounded,
        iconColor: CustomColor.kPrimaryColor,
        label: 'Invite to Humming Bird',
        showDivider: true,
        onTap: _inviteToHummingBird,
      ));
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        border: Border.all(color: CustomColor.kLightBorder),
      ),
      child: Column(children: tiles),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CustomColor.kUltraLightPrimary,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxxl.r)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xxl.w,
            0,
            AppSpacing.xxl.w,
            MediaQuery.of(context).padding.bottom + AppSpacing.xxl.h,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: AppSpacing.lg.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.xl.h),
              CircleAvatar(
                radius: 44.r,
                backgroundColor: CustomColor.kPrimaryLight,
                backgroundImage: widget.avatar,
                onBackgroundImageError: (_, __) {},
              ),
              SizedBox(height: AppSpacing.lg.h),
              Text(
                widget.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.headingLg.copyWith(
                  fontWeight: FontWeight.w800,
                  color: CustomColor.kTextPrimary,
                ),
              ),
              if (widget.number.isNotEmpty) ...[
                SizedBox(height: AppSpacing.xs.h),
                Text(
                  widget.number,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMd.copyWith(
                    color: CustomColor.kTextSecondary,
                  ),
                ),
              ],
              SizedBox(height: AppSpacing.lg.h),
              Center(child: _buildStatusPill()),
              SizedBox(height: AppSpacing.xxxl.h),
              _buildActionRow(),
              SizedBox(height: AppSpacing.xxl.h),
              _buildOptionsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactActionIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ContactActionIcon({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return PressScale(
      pressedScale: 0.92,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, color: color, size: 22.r),
            ),
            SizedBox(height: AppSpacing.xs.h),
            Text(
              label,
              style: AppTextStyles.labelSm.copyWith(
                color: CustomColor.kTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileOptionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final bool showDivider;
  final VoidCallback? onTap;

  const _ProfileOptionTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.showDivider = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Container(
            width: 36.r,
            height: 36.r,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg.r),
            ),
            child: Icon(icon, color: iconColor, size: AppIcons.lg.r),
          ),
          title: Text(
            label,
            style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.w500),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: CustomColor.kTextTertiary,
            size: AppIcons.lg.r,
          ),
          onTap: onTap,
        ),
        if (showDivider)
          Padding(
            padding: EdgeInsets.only(left: AppSpacing.xxl.w),
            child: Divider(
              height: 1,
              thickness: 1,
              color: CustomColor.kTextTertiary.withValues(alpha: 0.08),
            ),
          ),
      ],
    );
  }
}

class _AddToGroupSheet extends StatelessWidget {
  final User user;

  const _AddToGroupSheet({required this.user});

  void _addToGroup(BuildContext context, Rooms group) {
    final mobile = user.userMobileNum;
    if (mobile == null || mobile.isEmpty) {
      Utils.showGetSnackBar('Cannot add: contact has no phone number');
      return;
    }
    final contactController = Get.find<ContactController>();
    contactController.groupParticipants.clear();
    contactController.groupParticipants.add(user);
    Get.find<GroupController>().addGroupMembers(group.rId);
  }

  @override
  Widget build(BuildContext context) {
    final contactController = Get.find<ContactController>();
    final groupController = Get.find<GroupController>();
    return SafeArea(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.62,
        decoration: BoxDecoration(
          color: CustomColor.kUltraLightPrimary,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xxxl.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: CustomColor.kTextTertiary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.pill.r),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.xl.h),
            Text(
              'Add to Group',
              style:
                  AppTextStyles.headingMd.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: AppSpacing.xs.h),
            Text(
              'Select a group to add ${contactController.getAllContactsName(user)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(
                color: CustomColor.kTextSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.lg.h),
            Expanded(
              child: GetBuilder<ContactController>(
                builder: (_) {
                  final groups = contactController.groupsList;
                  if (groups.isEmpty) {
                    return const CustomLoading(message: 'Syncing groups\u2026');
                  }
                  return ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: groups.length,
                    separatorBuilder: (_, __) =>
                        SizedBox(height: AppSpacing.sm.h),
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      final isPending = (group.rIsPending ?? '0') == '1';
                      return Material(
                        color: CustomColor.kLightSurface,
                        borderRadius:
                            BorderRadius.circular(AppRadius.rounded.r),
                        child: ListTile(
                          onTap: () => _addToGroup(context, group),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.rounded.r),
                          ),
                          leading: CircleAvatar(
                            radius: 24.r,
                            backgroundColor: CustomColor.kPrimaryLight,
                            backgroundImage:
                                groupController.getGroupImage(group.rId ?? ''),
                            onBackgroundImageError: (_, __) {},
                          ),
                          title: Text(
                            group.rName ?? 'Group',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMd
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            isPending ? 'Pending group' : 'Tap to add',
                            style: AppTextStyles.labelSm.copyWith(
                              color: isPending
                                  ? CustomColor.kGoldAccent
                                  : CustomColor.kTextTertiary,
                            ),
                          ),
                          trailing: Container(
                            width: 34.r,
                            height: 34.r,
                            decoration: BoxDecoration(
                              color: CustomColor.kPrimaryColor
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.person_add_alt_1_rounded,
                              color: CustomColor.kPrimaryColor,
                              size: 18.r,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
