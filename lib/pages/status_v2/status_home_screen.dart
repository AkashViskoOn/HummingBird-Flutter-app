import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/status_updates/status_create_sheet.dart';
import 'package:humming_bird/pages/status_updates/status_privacy_settings.dart';
import 'package:humming_bird/pages/status_updates/status_search_page.dart';
import 'package:humming_bird/pages/status_v2/status_archive_screen.dart';
import 'package:humming_bird/pages/status_v2/status_story_viewer.dart';
import 'package:humming_bird/pages/status_v2/widgets/status_ring_avatar.dart';
import 'package:humming_bird/pages/status_v2/widgets/status_skeleton.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// WhatsApp-style Status Home — opened from the Home header Status icon.
class StatusHomeScreen extends StatefulWidget {
  const StatusHomeScreen({super.key});

  @override
  State<StatusHomeScreen> createState() => _StatusHomeScreenState();
}

class _StatusHomeScreenState extends State<StatusHomeScreen> {
  late StatusController _ctrl;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<StatusController>()) {
      _ctrl = Get.find<StatusController>();
    } else {
      _ctrl = Get.put(StatusController(), permanent: true);
    }
    _ctrl.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Status', actions: [
        _headerAction(
          icon: Icons.search_rounded,
          tooltip: 'Search statuses',
          onTap: () => Get.to(() => const StatusSearchPage()),
        ),
        _headerAction(
          icon: Icons.privacy_tip_outlined,
          tooltip: 'Status privacy & settings',
          onTap: () => Get.to(() => const StatusPrivacySettings()),
        ),
        SizedBox(width: 8.w),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSheet,
        backgroundColor: CustomColor.kPrimaryFill,
        foregroundColor: CustomColor.kTextOnDark,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill.r),
        ),
        icon: const Icon(Icons.add_rounded),
        label: Text(
          'Add status',
          style:
              GoogleFonts.poppins(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => _ctrl.refreshAll(),
          color: CustomColor.kPrimaryColor,
          backgroundColor: CustomColor.kTextOnDark,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 100.h),
            // Obx keeps the whole status feed reactive: upload/delete/archive/
            // reaction changes in the controller re-render instantly instead
            // of requiring a manual refresh or screen re-entry.
            child: Obx(() => _buildContent()),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_ctrl.isLoading.value &&
        _ctrl.friendUpdates.isEmpty &&
        _ctrl.myStatuses.isEmpty) {
      return const StatusSkeleton();
    }
    if (_ctrl.friendUpdates.isEmpty && _ctrl.myStatuses.isEmpty) {
      return _buildEmptyState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildMyStatusSection(),
        ..._buildUpdatesSections(),
        if (_ctrl.mutedUsers.isNotEmpty) ...[
          _sectionHeader('Muted statuses'),
          _buildMutedSection(),
        ],
        if (_ctrl.archivedUpdates.isNotEmpty) _buildArchiveRow(),
        SizedBox(height: 8.h),
      ],
    );
  }

  // ── My Status ─────────────────────────────────────────────────
  Widget _buildMyStatusSection() {
    final my = _ctrl.myStatuses;
    final latest = my.isNotEmpty ? my.first : null;
    final myUser = Get.find<UserController>().user;
    final profileImage = myUser?.userImage;

    return GestureDetector(
      onTap: () {
        if (my.isNotEmpty) {
          _openMyStory(my);
        } else {
          _openCreateSheet();
        }
      },
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              StatusRingAvatar(
                imageUrl:
                    (profileImage?.isNotEmpty ?? false) ? profileImage : null,
                size: 62,
                isMyStatus: true,
              ),
              if (my.isEmpty)
                Positioned(
                  right: -2.r,
                  bottom: -2.r,
                  child: Container(
                    padding: EdgeInsets.all(2.r),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: CustomColor.kBackground,
                    ),
                    child: Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: CustomColor.kPrimaryColor,
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: CustomColor.kTextOnDark,
                        size: 16,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('My status', style: AppTextStyles.titleLg),
                SizedBox(height: 4.h),
                if (my.isEmpty)
                  Text('Add to my status', style: AppTextStyles.subtitle)
                else if (latest != null)
                  Text(
                    '${_timeText(latest.suCreatedAt)}  ·  ${latest.viewCount ?? 0} views',
                    style: AppTextStyles.subtitle,
                  ),
              ],
            ),
          ),
          if (my.isNotEmpty)
            GestureDetector(
              onTap: _openCreateSheet,
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: CustomColor.kUltraLightPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  size: 18,
                  color: CustomColor.kPrimaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Updates sections (Recent / Viewed) ────────────────────────
  List<Widget> _buildUpdatesSections() {
    final grouped = <String, List<FriendUpdate>>{};
    for (final f in _ctrl.friendUpdates) {
      final authorId = f.author?['user_id']?.toString() ?? 'unknown';
      grouped.putIfAbsent(authorId, () => []).add(f);
    }
    final groups = grouped.values.toList();

    final recent =
        groups.where((list) => list.any((f) => f.viewed != true)).toList();
    final viewed =
        groups.where((list) => list.every((f) => f.viewed == true)).toList();

    if (recent.isEmpty && viewed.isEmpty) {
      return [_buildEmptyState()];
    }

    return [
      if (recent.isNotEmpty) ...[
        _sectionHeader('Recent updates'),
        ...recent.map((u) => _friendRow(u)),
      ],
      if (viewed.isNotEmpty) ...[
        _sectionHeader('Viewed updates'),
        ...viewed.map((u) => _friendRow(u, muted: true)),
      ],
      SizedBox(height: 8.h),
    ];
  }

  Widget _friendRow(List<FriendUpdate> updates, {bool muted = false}) {
    final first = updates.first;
    final author = first.author;
    final name = _authorName(updates);
    final unviewed = updates.any((f) => f.viewed != true);

    return GestureDetector(
      onTap: () => _openFriendStory(updates),
      child: Padding(
        padding: EdgeInsets.only(top: AppSpacing.md.h),
        child: Row(
          children: [
            StatusRingAvatar(
              imageUrl: author?['user_image']?.toString(),
              size: 54,
              viewed: muted || !unviewed,
              fallbackChild: Container(
                width: 54.r,
                height: 54.r,
                color: CustomColor.kUltraLightBg,
                child: Icon(
                  Icons.person_rounded,
                  size: 28.r,
                  color: CustomColor.kPrimaryColor,
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.titleSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _subtitleFor(updates),
                    style: AppTextStyles.subtitle.copyWith(fontSize: 12.sp),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (unviewed)
              Container(
                width: 10.r,
                height: 10.r,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: CustomColor.kOnlineGreen,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMutedSection() {
    return Column(
      children: _ctrl.mutedUsers
          .take(8)
          .map(
            (u) => _mutedRow(u),
          )
          .toList(),
    );
  }

  Widget _mutedRow(Map<String, dynamic> user) {
    final userId = user['user_id']?.toString() ?? '';
    final name =
        '${user['user_first_name'] ?? ''} ${user['user_last_name'] ?? ''}'
            .trim();

    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.md.h),
      child: Row(
        children: [
          StatusRingAvatar(
            imageUrl: user['user_image']?.toString(),
            size: 46,
            viewed: true,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              name.isEmpty ? 'User' : name,
              style: AppTextStyles.bodyMd,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () async {
              await _ctrl.muteUser(userId);
              _ctrl.fetchMutedList();
            },
            style: TextButton.styleFrom(
              foregroundColor: CustomColor.kPrimaryColor,
            ),
            child: Text(
              'Unmute',
              style: GoogleFonts.poppins(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveRow() {
    return GestureDetector(
      onTap: () => Get.to(() => const StatusArchiveScreen()),
      child: Padding(
        padding: EdgeInsets.only(top: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.r),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: CustomColor.kUltraLightPrimary,
              ),
              child: const Icon(
                Icons.archive_rounded,
                color: CustomColor.kPrimaryColor,
                size: 20,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                'Archive (${_ctrl.archivedUpdates.length})',
                style: AppTextStyles.titleSm,
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: CustomColor.kTextTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),
          Container(
            width: 84.r,
            height: 84.r,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CustomColor.kUltraLightPrimary,
            ),
            child: const Icon(
              Icons.donut_large_rounded,
              color: CustomColor.kPrimaryColor,
              size: 44,
            ),
          ),
          SizedBox(height: 20.h),
          Text('No statuses yet', style: AppTextStyles.headingSm),
          SizedBox(height: 8.h),
          Text(
            'Tap “Add status” to share a moment',
            style: AppTextStyles.subtitle,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 100.h),
        ],
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────
  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: CustomColor.kTextOnDark,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
      ),
      builder: (_) => const StatusCreateSheet(),
    );
  }

  void _openMyStory(List<StatusModel> statuses) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusStoryViewer(
          myStatuses: statuses,
          myUser: {
            'user_id': Get.find<UserController>().user?.userId?.toString(),
            'user_first_name': Get.find<UserController>().user?.userFirstName,
            'user_last_name': Get.find<UserController>().user?.userLastName,
            'user_image': Get.find<UserController>().user?.userImage,
          },
        ),
      ),
    );
  }

  void _openFriendStory(List<FriendUpdate> updates) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StatusStoryViewer(
          updates: updates,
          initialIndex: 0,
        ),
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return IconButton(
      icon: Icon(icon, color: CustomColor.kPrimaryColor, size: 24.r),
      tooltip: tooltip,
      onPressed: onTap,
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 20.h, bottom: 4.h),
      child: Text(title, style: AppTextStyles.headingSm),
    );
  }

  String _authorName(List<FriendUpdate> updates) {
    final a = updates.first.author;
    final name = a != null
        ? '${a['user_first_name'] ?? ''} ${a['user_last_name'] ?? ''}'.trim()
        : '';
    return name.isNotEmpty ? name : (a?['user_name']?.toString() ?? 'User');
  }

  String _subtitleFor(List<FriendUpdate> updates) {
    final latest = updates.first.update;
    if (latest != null) {
      final count = updates.length;
      final t = _timeText(latest.suCreatedAt);
      return count > 1 ? '$t · $count stories' : t;
    }
    return '';
  }

  String _timeText(String? createdAt) {
    if (createdAt == null) return '';
    final dt = AppHelper.parseServerUtc(createdAt);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
