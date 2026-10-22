import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/Models/status_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/components/scheduled_moments/moment_card.dart';
import 'package:humming_bird/controllers/scheduled_moment_controller.dart';
import 'package:humming_bird/pages/scheduled_moments/moment_calendar_page.dart';
import 'package:humming_bird/pages/scheduled_moments/schedule_moment_sheet.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class ScheduledMomentsPage extends StatefulWidget {
  final int initialTab;

  const ScheduledMomentsPage({super.key, this.initialTab = 0});

  @override
  State<ScheduledMomentsPage> createState() => _ScheduledMomentsPageState();
}

class _ScheduledMomentsPageState extends State<ScheduledMomentsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final ScheduledMomentController _controller = Get.find();

  @override
  void initState() {
    super.initState();
    _tabCtrl =
        TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: CommonAppBar(
        title: 'Scheduled Moments',
        backgroundColor:
            isDark ? CustomColor.kDarkSurface : CustomColor.kLightSurface,
        actions: [
          IconButton(
            tooltip: 'Pick date',
            icon: Icon(Icons.calendar_month_rounded,
                color: CustomColor.kPrimaryColor),
            onPressed: () => Get.to(() => const MomentCalendarPage()),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: CustomColor.kPrimaryColor,
          labelColor: CustomColor.kPrimaryColor,
          unselectedLabelColor: CustomColor.kTextTertiary,
          labelStyle: AppTextStyles.bodySm,
          unselectedLabelStyle: AppTextStyles.bodySm,
          tabs: const [
            Tab(text: 'Scheduled'),
            Tab(text: 'Published'),
            Tab(text: 'Drafts'),
            Tab(text: 'All'),
          ],
        ),
      ),
      body: Obx(() {
        if (_controller.isLoading.value) {
          return const CustomLoading();
        }
        if (_controller.errorMessage.value.isNotEmpty) {
          return AppEmptyState(
            icon: Icons.movie_creation_outlined,
            title: 'Could not load moments',
            message: _controller.errorMessage.value,
            actionLabel: 'Try Again',
            onAction: _controller.fetchScheduledMoments,
          );
        }
        return TabBarView(
          controller: _tabCtrl,
          children: [
            _buildList(
                _controller.scheduledMoments.where((m) => m.isPending).toList(),
                isDark),
            _buildList(_controller.publishedMoments, isDark),
            _buildList(_controller.draftMoments, isDark),
            _buildList(_controller.scheduledMoments, isDark),
          ],
        );
      }),
    );
  }

  Widget _buildList(List<ScheduledMoment> moments, bool isDark) {
    if (moments.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 120),
          child: AppEmptyState(
            icon: Icons.movie_creation_outlined,
            title: 'No moments yet',
            message: 'Create a moment from the Updates tab.',
            layout: EmptyStateLayout.inline,
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: CustomColor.kPrimaryColor,
      onRefresh: () => _controller.fetchScheduledMoments(),
      child: ListView.builder(
        padding: EdgeInsets.fromLTRB(
            16.r, 16.r, 16.r, 16.r + MediaQuery.of(context).padding.bottom),
        itemCount: moments.length,
        itemBuilder: (_, i) {
          final moment = moments[i];
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: MomentCard(
              moment: moment,
              onEdit: () => _editMoment(moment),
              onDelete: () => _deleteMoment(moment),
              onDuplicate: () => _duplicateMoment(moment),
              onPublish: moment.isPending ? () => _publishMoment(moment) : null,
            ),
          );
        },
      ),
    );
  }

  void _editMoment(ScheduledMoment moment) {
    if (moment.smId == null) return;
    Get.bottomSheet(
      ScheduleMomentSheet(
        content: moment.smContent ?? '',
        mediaPath: moment.smMediaUrl,
        mediaType: moment.smMediaType,
      ),
      isScrollControlled: true,
    );
  }

  void _deleteMoment(ScheduledMoment moment) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete Moment',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          TextButton(
            onPressed: () async {
              if (moment.smId != null) {
                await _controller.deleteMoment(moment.smId!);
                _controller.scheduledMoments
                    .removeWhere((m) => m.smId == moment.smId);
                _controller.publishedMoments
                    .removeWhere((m) => m.smId == moment.smId);
                _controller.draftMoments
                    .removeWhere((m) => m.smId == moment.smId);
              }
              Get.back();
            },
            child:
                Text('Delete', style: TextStyle(color: CustomColor.kDangerRed)),
          ),
        ],
      ),
    );
  }

  void _publishMoment(ScheduledMoment moment) {
    if (moment.smId == null) return;
    _controller.publishNow(moment.smId!);
    CustomSnackbar.success(title: 'Published', message: 'Moment published now');
  }

  void _duplicateMoment(ScheduledMoment moment) {
    if (moment.smId == null) return;
    _controller.duplicateMoment(moment.smId!);
    CustomSnackbar.show(
        title: 'Duplicate', message: 'Moment duplicated as draft');
  }
}
