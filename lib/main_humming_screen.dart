import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/app_back_button.dart';
import 'package:humming_bird/components/home/message_search.dart';
import 'package:humming_bird/components/home/filter_chips.dart';
import 'package:humming_bird/components/home/premium_bottom_nav.dart';
import 'package:humming_bird/components/home/schedule_notification_sheet.dart';
import 'package:humming_bird/components/home/schedule_carousel_section.dart';
import 'package:humming_bird/components/schedule/schedule_recipient_sheet.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/controllers/call_controller.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/calling/call_history_page.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_list.dart';
import 'package:humming_bird/pages/chats/chat_listings/archived_chats_screen.dart';
import 'package:humming_bird/pages/chats/chat_listings/single_chats_listing.dart';
import 'package:humming_bird/pages/contacts/chat_by_phone_screen.dart';
import 'package:humming_bird/pages/contacts/select_contact.dart';
import 'package:humming_bird/pages/groups/create_group_screen.dart';

import 'package:humming_bird/pages/status_updates/updates_screen.dart';
import 'package:humming_bird/pages/profile/you_profile_screen.dart';
import 'package:humming_bird/pages/setting/about/about_page.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/services/notification_service.dart';
import 'package:humming_bird/theme/app_animation.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class MainHummingScreen extends StatefulWidget {
  const MainHummingScreen({super.key});

  @override
  State<MainHummingScreen> createState() => _MainHummingScreenState();
}

class _MainHummingScreenState extends State<MainHummingScreen>
    with TickerProviderStateMixin {
  late HomeController homeController;
  late UserController userController;
  late ChatController chatController;
  late ContactController contactController;
  late CallController callController;
  late BirdController birdController;
  final FocusNode _searchFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentNavIndex = 0;
  final RxInt _unreadCount = 0.obs;
  final ScrollController _headerScrollController = ScrollController();
  bool _searchBarHidden = false;

  static const double _toolbarH = 56;
  static const double _searchBarH = 50;

  @override
  void initState() {
    super.initState();
    _currentNavIndex = 0;
    _headerScrollController.addListener(_onHeaderScroll);
    homeController = Get.put(HomeController());
    contactController = Get.put(ContactController());
    chatController = Get.put(ChatController());
    callController = Get.put(CallController());
    userController = Get.find();
    birdController = Get.find();
    userController.getUser();
    // Preload the next scheduled messages for the home "Upcoming" summary so
    // it is populated (not a stale/empty skeleton) when the home screen shows.
    birdController.getScheduledMessages();
    // Explicitly refresh the room lists. GetX reuses the already-registered
    // controllers on a re-login (MainHummingScreen initState runs again but
    // Get.put() returns the previous instances), so ContactController.onInit —
    // the original fetch trigger — does not run a second time. Without this a
    // fresh login after logout would keep showing stale rooms.
    homeController.fetchSingleChats();
    homeController.fetchGroupChats();
    ever(homeController.totalUnreadCount, (val) => _unreadCount.value = val);
    _unreadCount.value = homeController.totalUnreadCount.value;
    // Ensure FCM token registration + notification permissions are requested
    // after login even if the contacts permission flow was skipped.
    try {
      final notificationService = NotificationService();
      notificationService.startIfNeeded();
    } catch (_) {}
  }

  @override
  void dispose() {
    _headerScrollController.removeListener(_onHeaderScroll);
    _headerScrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onHeaderScroll() {
    if (!_headerScrollController.hasClients) return;
    final hidden = _headerScrollController.offset > 1.0;
    if (hidden != _searchBarHidden) {
      setState(() => _searchBarHidden = hidden);
    }
  }

  void _revealSearchBar() {
    FocusScope.of(context).unfocus();
    if (_headerScrollController.hasClients) {
      _headerScrollController.animateTo(
        0,
        duration: AppAnimation.medium,
        curve: Curves.easeOutCubic,
      );
    }
    Future<void>.delayed(AppAnimation.medium, () {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
    });
  }

  void _onNavTap(int index) {
    setState(() => _currentNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      body: _buildBody(),
      bottomNavigationBar: PremiumBottomNav(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
      floatingActionButton: _currentNavIndex == 0 ? _buildFab() : null,
    );
  }

  Widget _buildBody() {
    // No AnimatedSwitcher/ValueKey here on purpose. Keying the IndexedStack on
    // _currentNavIndex threw away the entire subtree on every tab tap, so all
    // five tabs lost their scroll offsets, controllers and fetched state. An
    // IndexedStack already keeps every child alive; only `index` needs to move.
    return IndexedStack(
      index: _currentNavIndex,
      children: [
        _buildChatHome(),
        const CallHistoryPage(),
        _buildStatusPlaceholder(),
        _buildScheduleTab(),
        const YouProfileScreen(),
      ],
    );
  }

  // ── Chat Home (Bottom Nav Index 0) ────────────────────────────
  Widget _buildChatHome() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        NestedScrollView(
          controller: _headerScrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                toolbarHeight: _toolbarH,
                collapsedHeight: _toolbarH,
                backgroundColor:
                    isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
                surfaceTintColor: Colors.transparent,
                // leadingWidth: 40,
                // titleSpacing: 8.w,
                title: _buildHeaderTitle(),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Row(
                      children: [
                        _buildSearchIconButton(),
                        SizedBox(width: 4.w),
                        _buildNotificationBell(),
                        SizedBox(width: 4.w),
                        _buildPremiumAddButton(),
                      ],
                    ),
                  ),
                ],
              ),
              SliverPersistentHeader(
                floating: true,
                delegate: _SearchBarDelegate(
                  searchBar: _buildSearchBar(),
                ),
              ),
              SliverToBoxAdapter(
                child: ScheduleCarouselSection(
                  onViewAll: () => setState(() => _currentNavIndex = 3),
                  onNewSchedule: () => ScheduleRecipientSheet.show(context),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyFilterChipsDelegate(
                  filterChips: _buildFilterChips(),
                ),
              ),
            ];
          },
          body: _buildTabContent(),
        ),
        Obx(() {
          if (chatController.selectedRoomList.isEmpty) {
            return const SizedBox.shrink();
          }
          return Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildSelectionToolbar(isDark),
          );
        }),
      ],
    );
  }

  Widget _buildHeaderTitle() {
    return SizedBox(
      height: 42.h,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Image.asset(
          "assets/images/logo1.jpg", // your logo
          height: 34.h,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) {
            return Text(
              "HummingBird",
              style: AppTextStyles.headingLg.copyWith(
                fontWeight: FontWeight.w700,
                color: CustomColor.kTextPrimary,
              ),
            );
          },
        ),
      ),
    );
  }

  List<String> _selectedRoomIds() =>
      List<String>.from(chatController.selectedRoomList);

  void _onSelectAllRooms() {
    final ids = [
      ...homeController.singleChatsList.map((r) => r.rId).whereType<String>(),
      ...homeController.groupsList.map((r) => r.rId).whereType<String>(),
    ];
    chatController.selectAllRooms(ids);
  }

  Future<void> _onArchiveSelectedRooms() async {
    final ids = _selectedRoomIds();
    for (final id in ids) {
      await homeController.toggleArchive(id);
    }
    chatController.clearRoomSelection();
  }

  void _onMarkReadSelectedRooms() {
    final ids = _selectedRoomIds();
    for (final id in ids) {
      homeController.makeUnreadReadMessage(id);
    }
    homeController.update(['update-card']);
    chatController.clearRoomSelection();
  }

  void _onDeleteSelectedRooms() {
    final ids = _selectedRoomIds();
    if (ids.isEmpty) return;
    Get.defaultDialog(
      title: 'Delete chats',
      middleText:
          'Delete ${ids.length} selected chat${ids.length == 1 ? '' : 's'}?',
      textCancel: 'Cancel',
      textConfirm: 'Delete',
      confirmTextColor: CustomColor.kTextOnDark,
      buttonColor: CustomColor.kDangerRed,
      cancel: TextButton(
        onPressed: () => Get.back(),
        child: Text(
          'Cancel',
          style: AppTextStyles.headingSm
              .copyWith(color: CustomColor.kTextSecondary),
        ),
      ),
      onConfirm: () {
        for (final id in ids) {
          homeController.deleteRoomAndSync(id);
        }
        chatController.clearRoomSelection();
        Get.back();
      },
    );
  }

  Widget _buildSelectionToolbar(bool isDark) {
    return Container(
      color: CustomColor.kPrimaryColor,
      // SafeArea already applies the top inset; adding it here as padding
      // double-pads the toolbar on notched devices.
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _toolbarH.h,
          child: Row(
            children: [
              AppBackButton(
                color: CustomColor.kTextOnDark,
                onTap: () => chatController.clearRoomSelection(),
              ),
              Expanded(
                child: Obx(() => Text(
                      '${chatController.selectedRoomList.length} selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headingMd.copyWith(
                        color: CustomColor.kTextOnDark,
                        fontWeight: FontWeight.w600,
                      ),
                    )),
              ),
              _buildSelectionAction(
                tooltip: 'Select all',
                icon: Icons.checklist_rounded,
                onTap: _onSelectAllRooms,
              ),
              _buildSelectionAction(
                tooltip: 'Archive',
                icon: Icons.outbox_rounded,
                onTap: _onArchiveSelectedRooms,
              ),
              _buildSelectionAction(
                tooltip: 'Mark as read',
                icon: Icons.done_all_rounded,
                onTap: _onMarkReadSelectedRooms,
              ),
              _buildSelectionAction(
                tooltip: 'Delete',
                icon: Icons.delete_outline_rounded,
                onTap: _onDeleteSelectedRooms,
              ),
              SizedBox(width: 6.w),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionAction({
    required String tooltip,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.w),
          child: Icon(icon, color: CustomColor.kTextOnDark, size: 22.r),
        ),
      ),
    );
  }

  Widget _buildSearchIconButton() {
    return IgnorePointer(
      ignoring: !_searchBarHidden,
      child: AnimatedOpacity(
        opacity: _searchBarHidden ? 1 : 0,
        duration: AppAnimation.normal,
        curve: Curves.easeOut,
        child: AnimatedScale(
          scale: _searchBarHidden ? 1 : 0.4,
          duration: AppAnimation.normal,
          curve: Curves.easeOutBack,
          child: _buildHeaderCircleIcon(
            icon: Icons.search_rounded,
            tooltip: 'Search',
            onTap: _revealSearchBar,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCircleIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightBg,
            border: Border.all(
              color: isDark
                  ? CustomColor.kDarkBorder
                  : CustomColor.kLightBorder.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
            size: 20.r,
          ),
        ),
      ),
    );
  }

  void _showNewChatOptions() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? CustomColor.kDarkSurface
              : CustomColor.kTextOnDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
        ),
        child: SafeArea(
          bottom: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? CustomColor.kTextOnDarkMuted.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'New Chat',
                style: Theme.of(context).brightness == Brightness.dark
                    ? AppTextStyles.headingMdOnDark
                    : AppTextStyles.headingMd,
              ),
              SizedBox(height: 10.h),
              ListTile(
                leading: Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child: Icon(Icons.contacts_rounded,
                      color: CustomColor.kPrimaryColor, size: 22.r),
                ),
                title: Text(
                  'Device Contacts',
                  style: Theme.of(context).brightness == Brightness.dark
                      ? AppTextStyles.bodyMdOnDark
                      : AppTextStyles.bodyMd,
                ),
                subtitle: Text(
                  'Choose from your phone contacts',
                  style: Theme.of(context).brightness == Brightness.dark
                      ? AppTextStyles.captionOnDark
                      : AppTextStyles.caption,
                ),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: CustomColor.kTextTertiary),
                onTap: () {
                  Get.back();
                  Get.to(() => const AllContactsScreen());
                },
              ),
              Divider(
                  height: 1,
                  thickness: 1,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? CustomColor.kDarkDivider
                      : CustomColor.kLightBorder),
              SizedBox(height: 4.h),
              ListTile(
                leading: Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child: Icon(Icons.phone_rounded,
                      color: CustomColor.kPrimaryColor, size: 22.r),
                ),
                title: Text(
                  'Message Any Mobile Number',
                  style: Theme.of(context).brightness == Brightness.dark
                      ? AppTextStyles.bodyMdOnDark
                      : AppTextStyles.bodyMd,
                ),
                subtitle: Text(
                  'Start a conversation using a phone number',
                  style: Theme.of(context).brightness == Brightness.dark
                      ? AppTextStyles.captionOnDark
                      : AppTextStyles.caption,
                ),
                trailing: Icon(Icons.chevron_right_rounded,
                    color: CustomColor.kTextTertiary),
                onTap: () {
                  Get.back();
                  Get.to(() => const ChatByPhoneScreen());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumAddButton() {
    return Tooltip(
      message: 'New Chat',
      child: GestureDetector(
        onTap: () => Get.to(() => const AllContactsScreen()),
        child: Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            color: CustomColor.kPrimaryColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(Icons.add_rounded,
              color: CustomColor.kTextOnDark, size: 20.r),
        ),
      ),
    );
  }

  // ── Schedule Notification Bell ─────────────────────────────────────────────────
  Widget _buildNotificationBell() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: 'Notifications',
      child: GestureDetector(
        onTap: _showScheduleNotifications,
        child: Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color:
                isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightBg,
            border: Border.all(
              color: isDark
                  ? CustomColor.kDarkBorder
                  : CustomColor.kLightBorder.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            color: isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
            size: 20.r,
          ),
        ),
      ),
    );
  }

  void _showScheduleNotifications() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const ScheduleNotificationSheet(),
    );
  }

  // ── Premium Search Bar ────────────────────────────────────────
  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(top: 3.0),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8.w),
        decoration: BoxDecoration(
          color: isDark ? CustomColor.kDarkInputFill : CustomColor.kTextOnDark,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          border: Border.all(
            color: isDark
                ? CustomColor.kDarkBorder
                : CustomColor.kLightBorder.withValues(alpha: 0.6),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          focusNode: _searchFocusNode,
          controller: homeController.searchController,
          textAlignVertical: TextAlignVertical.center,
          style: AppTextStyles.bodyMd.copyWith(
            color: isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
          ),
          cursorColor: CustomColor.kPrimaryMedium,
          decoration: InputDecoration(
            hintText: 'Search messages, people, groups\u2026',
            hintStyle: AppTextStyles.bodySm.copyWith(
              color: isDark
                  ? CustomColor.kTextOnDarkMuted
                  : CustomColor.kTextTertiary,
            ),
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 4.w),
              child: Icon(
                Icons.search_rounded,
                color: isDark
                    ? CustomColor.kTextOnDarkMuted
                    : CustomColor.kTextSecondary,
                size: AppIcons.lg.r,
              ),
            ),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (homeController.searchController.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      homeController.searchController.clear();
                      homeController.searchInChats('');
                    },
                    icon: Icon(Icons.close_rounded,
                        color: isDark
                            ? CustomColor.kTextOnDarkMuted
                            : CustomColor.kTextTertiary,
                        size: AppIcons.md.r),
                  ),
                Container(
                  width: 1,
                  height: 20.h,
                  color: isDark
                      ? CustomColor.kDarkDivider
                      : CustomColor.kLightBorder,
                ),
                Padding(
                  padding: EdgeInsets.only(right: 4.w, left: 8.w),
                  child: GestureDetector(
                    onTap: () {
                      homeController.searching.value =
                          !homeController.searching.value;
                      homeController.update(['search-update']);
                    },
                    child: Obx(
                      () => Icon(
                        homeController.searching.value
                            ? Icons.close_rounded
                            : Icons.tune_rounded,
                        color: CustomColor.kPrimaryColor,
                        size: AppIcons.md.r,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            filled: false,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 0.w, vertical: 6.h),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onChanged: (val) {
            homeController.searchInChats(val);
          },
        ),
      ),
    );
  }

  // ── Filter Chips ──────────────────────────────────────────────
  Widget _buildFilterChips() {
    return
        //  Obx(() =>
        Container(
      margin: EdgeInsets.symmetric(horizontal: 8.w),
      child: Padding(
        padding: EdgeInsets.only(top: 5.h),
        child: ChatFilterChips(
          selectedFilter: homeController.selectedFilter,
          unreadCount: _unreadCount,
          onMoreTap: _showMoreOptions,
        ),
      ),
      // )
    );
  }

  // ── Tab Content ───────────────────────────────────────────────
  Widget _buildTabContent() {
    return Obx(() {
      if (homeController.searching.value) {
        return const SearchedMessages();
      }
      return SingleChatListing(selectedFilter: homeController.selectedFilter);
    });
  }

  // ── Updates Tab (Bottom Nav Index 2) ─────────────────────────
  Widget _buildStatusPlaceholder() {
    return const UpdatesScreen();
  }

  // ── Schedule Tab (Bottom Nav Index 3) ─────────────────────────
  Widget _buildScheduleTab() {
    return const ScheduleMessagesList(showHeader: true);
  }

  // ── Premium FAB ───────────────────────────────────────────────
  Widget _buildFab() {
    return SpeedDial(
      icon: Icons.edit_rounded,
      activeIcon: Icons.close_rounded,
      overlayColor: CustomColor.kDarkSurface,
      overlayOpacity: 0.5,
      foregroundColor: CustomColor.kTextOnDark,
      backgroundColor: CustomColor.kPrimaryColor,
      buttonSize: Size(56.r, 56.r),
      childrenButtonSize: Size(50.r, 50.r),
      spacing: 8.h,
      spaceBetweenChildren: 6.h,
      elevation: 8,
      iconTheme: const IconThemeData(size: 24),
      childPadding: EdgeInsets.zero,
      children: [
        SpeedDialChild(
          child: const Icon(Icons.chat_bubble_rounded,
              color: CustomColor.kTextOnDark),
          label: 'New Chat',
          labelStyle: AppTextStyles.label,
          backgroundColor: CustomColor.kPrimaryColor,
          shape: const CircleBorder(),
          onTap: () => _showNewChatOptions(),
        ),
        SpeedDialChild(
          child: const Icon(Icons.group_add_rounded,
              color: CustomColor.kTextOnDark),
          label: 'New Group',
          labelStyle: AppTextStyles.label,
          backgroundColor: CustomColor.kPrimaryDark,
          shape: const CircleBorder(),
          onTap: () => Get.to(() => const CreateGroupScreen()),
        ),
        SpeedDialChild(
          child: const Icon(Icons.schedule_send_rounded,
              color: CustomColor.kTextOnDark),
          label: 'New Schedule',
          labelStyle: AppTextStyles.label,
          backgroundColor: CustomColor.kWarningFill,
          shape: const CircleBorder(),
          onTap: () => setState(() => _currentNavIndex = 3),
        ),
        SpeedDialChild(
          child:
              const Icon(Icons.phone_rounded, color: CustomColor.kTextOnDark),
          label: 'Call',
          labelStyle: AppTextStyles.label,
          backgroundColor: CustomColor.kSuccessFill,
          shape: const CircleBorder(),
          onTap: () => setState(() => _currentNavIndex = 1),
        ),
        SpeedDialChild(
          child: const Icon(Icons.more_horiz_rounded,
              color: CustomColor.kTextOnDark),
          label: 'More',
          labelStyle: AppTextStyles.label,
          backgroundColor: CustomColor.kDarkSurface2,
          shape: const CircleBorder(),
          onTap: () => _showMoreOptions(),
        ),
      ],
    );
  }

  void _showMoreOptions() {
    final ctx = _scaffoldKey.currentContext;
    if (ctx == null) return;
    showModalBottomSheet(
      context: ctx,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('More Options', style: AppTextStyles.headingLg),
              SizedBox(height: 16.h),
              ListTile(
                leading: const Icon(Icons.archive_rounded),
                title: const Text('Archived Chats'),
                onTap: () {
                  Get.back();
                  Get.to(() => const ArchivedChatsScreen());
                },
              ),
              ListTile(
                leading: const Icon(Icons.star_rounded),
                title: const Text('Starred Messages'),
                onTap: () {
                  Get.back();
                  homeController.selectedFilter.value = 'Favorites';
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_rounded),
                title: const Text('Settings'),
                // Settings live on the "You" tab (index 4), which is the live
                // settings hub. This used to only pop the sheet and navigate
                // nowhere.
                onTap: () {
                  Get.back();
                  _onNavTap(4);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_rounded),
                title: const Text('About'),
                onTap: () {
                  Get.back();
                  Get.to(() => const AboutPage());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Sticky Filter Chips Delegate ────────────────────────────────────────────
class _StickyFilterChipsDelegate extends SliverPersistentHeaderDelegate {
  final Widget filterChips;

  _StickyFilterChipsDelegate({
    required this.filterChips,
  });

  @override
  double get minExtent => 44.h;

  @override
  double get maxExtent => 44.h;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 44.h,
      color: isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      child: Column(
        children: [
          SizedBox(height: 6.h),
          Expanded(
            child: filterChips,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_) => false;
}

class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget searchBar;

  _SearchBarDelegate({
    required this.searchBar,
  });

  @override
  double get minExtent => 0;

  @override
  double get maxExtent => _MainHummingScreenState._searchBarH;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: maxExtent,
      color: isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      child: Align(
        alignment: Alignment.topCenter,
        child: searchBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_) => false;
}
