import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

/// Real-time viewers list for an own status (with shares tab).
class StatusViewersScreen extends StatefulWidget {
  final StatusModel status;
  final bool isMine;
  final int tab;

  const StatusViewersScreen({
    super.key,
    required this.status,
    this.isMine = true,
    this.tab = 0,
  });

  @override
  State<StatusViewersScreen> createState() => _StatusViewersScreenState();
}

class _StatusViewersScreenState extends State<StatusViewersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late StatusController _ctrl;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.status.shareCount != null ? 2 : 1,
      vsync: this,
      initialIndex:
          widget.tab.clamp(0, widget.status.shareCount != null ? 1 : 0),
    );
    _ctrl = Get.find<StatusController>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await Future.wait([
      _ctrl.fetchViewers(widget.status.suId!),
      if (widget.status.shareCount != null)
        _ctrl.fetchShares(widget.status.suId!),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(
        title: 'Status viewers',
        bottom: TabBar(
          controller: _tabController,
          labelColor: CustomColor.kPrimaryColor,
          unselectedLabelColor: CustomColor.kTextTertiary,
          indicatorColor: CustomColor.kPrimaryColor,
          indicatorWeight: 3,
          labelStyle:
              GoogleFonts.poppins(fontSize: 13.sp, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 13.sp),
          tabs: [
            Tab(text: 'Viewers (${widget.status.viewCount ?? 0})'),
            if (widget.status.shareCount != null)
              Tab(text: 'Shares (${widget.status.shareCount})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        color: CustomColor.kPrimaryColor,
        backgroundColor: CustomColor.kTextOnDark,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildList(_ctrl.viewersMap[widget.status.suId] ?? [],
                subtitle: 'viewed_at'),
            if (widget.status.shareCount != null)
              _buildList(_ctrl.sharesMap[widget.status.suId] ?? [],
                  subtitle: 'shared_at'),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> users,
      {required String subtitle}) {
    if (_loading) {
      return const CustomLoading();
    }
    if (users.isEmpty) {
      return const AppEmptyState(
        icon: Icons.visibility_outlined,
        title: 'Nothing here yet',
        message: 'Activity related to this status appears here',
        layout: EmptyStateLayout.inline,
      );
    }
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      itemCount: users.length,
      separatorBuilder: (_, __) =>
          Divider(color: CustomColor.kLightBorder, height: 1.h),
      itemBuilder: (ctx, i) {
        final u = users[i];
        final name =
            '${u['user_first_name'] ?? ''} ${u['user_last_name'] ?? ''}'.trim();
        final timeText = _formatTime(u[subtitle]?.toString());

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 2.h),
          child: ListTile(
            contentPadding:
                EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
            dense: false,
            visualDensity: VisualDensity.compact,
            horizontalTitleGap: 12.w,
            leading: SizedBox(
              width: 46.r,
              height: 46.r,
              child: ClipOval(
                child: (u['user_image']?.toString().isNotEmpty ?? false)
                    ? CachedNetworkImage(
                        imageUrl: '${Endpoints.mediaBaseUrl}${u['user_image']}',
                        width: 46.r,
                        height: 46.r,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Image.asset(
                          AppAssets.defaultProfilePic,
                          width: 46.r,
                          height: 46.r,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        AppAssets.defaultProfilePic,
                        width: 46.r,
                        height: 46.r,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            title: Text(
              name.isEmpty ? 'User' : name,
              style: AppTextStyles.titleSm.copyWith(
                height: 1.2,
                letterSpacing: 0.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: timeText.isEmpty
                ? null
                : Text(
                    timeText,
                    style: AppTextStyles.subtitle.copyWith(
                      fontSize: 11.sp,
                      height: 1.4,
                    ),
                  ),
          ),
        );
      },
    );
  }

  String _formatTime(String? value) {
    if (value == null || value.isEmpty) return '';
    final dt = DateTime.tryParse(value);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
