import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/call_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class CallHistoryPage extends StatefulWidget {
  const CallHistoryPage({super.key});

  @override
  State<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.find<CallController>();
  final _tabs = ['All', 'Missed', 'Outgoing', 'Incoming', 'Rejected'];
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  bool _isMultiSelectMode = false;
  final Set<String> _selectedIds = {};

  bool get _isDark => Get.isDarkMode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isMultiSelectMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isMultiSelectMode) {
          _exitMultiSelect();
        }
      },
      child: Scaffold(
        backgroundColor:
            _isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
        appBar: CommonAppBar(
          title: _isMultiSelectMode
              ? '${_selectedIds.length} selected'
              : 'Call History',
          backgroundColor:
              _isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
          actions: _buildAppBarActions(),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(190.h),
            child: Column(
              children: [
                _buildSpeedDial(),
                _buildSearchBar(),
                _buildTabBar(),
              ],
            ),
          ),
        ),
        body: Obx(() {
          if (controller.callHistory.isEmpty) {
            return _buildEmptyState();
          }
          return TabBarView(
            controller: _tabController,
            children: _tabs.map((tab) {
              final filtered = _filteredHistory(tab);
              if (filtered.isEmpty) {
                return _buildEmptyState();
              }
              return _buildHistoryList(filtered);
            }).toList(),
          );
        }),
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (_isMultiSelectMode) {
      return [
        TextButton(
          onPressed: _selectedIds.isEmpty ? null : _confirmDeleteSelected,
          child: Text(
            'Delete Selected',
            style: AppTextStyles.label.copyWith(
                color: _selectedIds.isEmpty
                    ? CustomColor.kTextTertiary
                    : CustomColor.kDangerRed),
          ),
        ),
        IconButton(
          tooltip: 'Exit selection',
          icon: Icon(
            Icons.close_rounded,
            color: _isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
          ),
          onPressed: _exitMultiSelect,
        ),
      ];
    }
    return [
      IconButton(
        tooltip: 'Select calls',
        icon: Icon(
          Icons.edit_rounded,
          color: _isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
        ),
        onPressed: _enterMultiSelect,
      ),
      PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert_rounded,
          color: _isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
        ),
        onSelected: (value) {
          if (value == 'clear_all') _confirmClearAll();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(
            value: 'clear_all',
            child: Text('Clear All'),
          ),
        ],
      ),
    ];
  }

  void _enterMultiSelect() {
    setState(() {
      _isMultiSelectMode = true;
      _selectedIds.clear();
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _isMultiSelectMode = false;
      _selectedIds.clear();
    });
  }

  void _confirmDeleteSelected() {
    Get.dialog(
      AlertDialog(
        backgroundColor:
            _isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        ),
        title: Text(
          'Delete entries?',
          style: GoogleFonts.poppins(
            color: _isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Delete ${_selectedIds.length} selected entries?',
          style: GoogleFonts.poppins(
            color: _isDark
                ? CustomColor.kTextOnDarkSecondary
                : CustomColor.kTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: CustomColor.kTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              for (final id in _selectedIds) {
                controller.deleteCallHistoryEntry(id);
              }
              _exitMultiSelect();
              Get.back();
            },
            child: Text(
              'Delete',
              style: GoogleFonts.poppins(
                  color: CustomColor.dangerTextFor(_isDark)),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor:
            _isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        ),
        title: Text(
          'Clear all history?',
          style: GoogleFonts.poppins(
            color: _isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This will delete all call history entries.',
          style: GoogleFonts.poppins(
            color: _isDark
                ? CustomColor.kTextOnDarkSecondary
                : CustomColor.kTextSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: Get.back,
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: CustomColor.kTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.deleteAllCallHistory();
              Get.back();
            },
            child: Text(
              'Clear All',
              style: GoogleFonts.poppins(
                  color: CustomColor.dangerTextFor(_isDark)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = _isDark;
    return Container(
      color: isDark ? CustomColor.kDarkBackground : CustomColor.kWhite,
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 8.h),
      child: Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: isDark ? CustomColor.kOverlay8 : CustomColor.kUltraLightBg,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          border: Border.all(
            color: isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder,
          ),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          onChanged: (_) => setState(() {}),
          style: AppTextStyles.bodyMd.copyWith(
              color:
                  isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary),
          decoration: InputDecoration(
            hintText: 'Search by name...',
            hintStyle: AppTextStyles.bodyMd.copyWith(
                color: isDark
                    ? CustomColor.kTextOnDarkMuted.withValues(alpha: 0.8)
                    : CustomColor.kTextTertiary),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: isDark
                  ? CustomColor.kTextOnDarkMuted
                  : CustomColor.kTextTertiary,
              size: 20.r,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    child: Icon(
                      Icons.clear_rounded,
                      color: isDark
                          ? CustomColor.kTextOnDarkMuted
                          : CustomColor.kTextTertiary,
                      size: 18.r,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 8.h),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedDial() {
    return Obx(() {
      final isDark = _isDark;
      final contacts = controller.speedDialContacts;
      return Container(
        height: 90.h,
        color: isDark ? CustomColor.kDarkSurface2 : CustomColor.kWhite,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 4.h),
              child: Text(
                'SPEED DIAL',
                style: AppTextStyles.labelSm.copyWith(
                    color: isDark
                        ? CustomColor.kTextOnDarkMuted
                        : CustomColor.kTextTertiary,
                    letterSpacing: 1),
              ),
            ),
            SizedBox(height: 4.h),
            if (contacts.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'Call frequently to add speed dial contacts',
                    style: AppTextStyles.error.copyWith(
                        color: isDark
                            ? CustomColor.kTextOnDarkMuted
                            : CustomColor.kTextTertiary),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  itemCount: contacts.length,
                  itemBuilder: (_, i) {
                    final contact = contacts[i];
                    final name = contact['contactName']?.toString() ?? '';
                    final image = contact['contactImage']?.toString() ?? '';
                    return Entrance(
                      delayFactor: (i % 8) * 0.05,
                      child: GestureDetector(
                        onTap: () => _showCallOptions(contact),
                        child: Container(
                          width: 64.w,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 22.r,
                                backgroundColor: CustomColor.kUltraLightPrimary,
                                backgroundImage: image.isNotEmpty
                                    ? _imageProvider(image)
                                    : null,
                                onBackgroundImageError: (_, __) {},
                                child: image.isEmpty
                                    ? Text(
                                        _initialOf(name),
                                        style: AppTextStyles.headingSm.copyWith(
                                            color: CustomColor.kPrimaryDark),
                                      )
                                    : null,
                              ),
                              SizedBox(height: 3.h),
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSm.copyWith(
                                    color: isDark
                                        ? CustomColor.kTextOnDarkSecondary
                                        : CustomColor.kTextSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildTabBar() {
    final isDark = _isDark;
    return Container(
      color: isDark ? CustomColor.kDarkSurface2 : CustomColor.kWhite,
      padding: EdgeInsets.fromLTRB(12.w, 4.h, 12.w, 8.h),
      child: Container(
        height: 36.h,
        decoration: BoxDecoration(
          color: isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightBg,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
        ),
        child: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicatorPadding: EdgeInsets.zero,
          labelPadding: EdgeInsets.zero,
          labelColor: isDark ? CustomColor.kTextOnDark : CustomColor.kWhite,
          unselectedLabelColor:
              isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary,
          labelStyle: AppTextStyles.bodySm,
          unselectedLabelStyle: AppTextStyles.bodySm,
          indicator: BoxDecoration(
            color: CustomColor.kPrimaryColor,
            borderRadius: BorderRadius.circular(AppRadius.lg.r),
          ),
          tabs: _tabs
              .map((t) => Tab(
                    child: Text(t),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<Map<String, dynamic>> entries) {
    final grouped = _groupByDate(entries);

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      itemCount: grouped.length,
      itemBuilder: (_, i) {
        final item = grouped[i];
        if (item is String) {
          return Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
            child: Text(
              item,
              style: AppTextStyles.label.copyWith(
                  color: _isDark
                      ? CustomColor.kTextOnDarkMuted
                      : CustomColor.kTextTertiary),
            ),
          );
        }
        final entry = item as Map<String, dynamic>;
        final id = entry['id']?.toString() ?? '';

        final tile = _CallHistoryTile(
          entry: entry,
          isDark: _isDark,
          isMultiSelectMode: _isMultiSelectMode,
          isSelected: _selectedIds.contains(id),
          onSelect: () => _toggleSelection(id),
          onTap: _isMultiSelectMode
              ? () => _toggleSelection(id)
              : () => _showCallOptions(entry),
          onLongPress: () => _showCallDetails(entry),
        );

        if (_isMultiSelectMode) {
          return Entrance(delayFactor: (i % 8) * 0.05, child: tile);
        }

        return Entrance(
          delayFactor: (i % 8) * 0.05,
          child: Slidable(
            endActionPane: ActionPane(
              motion: const BehindMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => controller.deleteCallHistoryEntry(id),
                  backgroundColor: CustomColor.kDangerFill,
                  foregroundColor: CustomColor.kTextOnDark,
                  icon: Icons.delete_rounded,
                  label: 'Delete',
                  borderRadius: BorderRadius.circular(AppRadius.xl.r),
                ),
              ],
            ),
            child: tile,
          ),
        );
      },
    );
  }

  List<dynamic> _groupByDate(List<Map<String, dynamic>> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekAgo = today.subtract(const Duration(days: 7));

    String labelFor(DateTime dt) {
      final d = DateTime(dt.year, dt.month, dt.day);
      if (!d.isBefore(today)) return 'Today';
      if (d == yesterday) return 'Yesterday';
      if (!d.isBefore(weekAgo)) return 'This Week';
      if (!d.isBefore(DateTime(now.year, now.month - 1))) return 'Last Month';
      return 'Earlier';
    }

    final result = <dynamic>[];
    String? lastLabel;
    for (final entry in entries) {
      final dtStr = entry['dateTime']?.toString() ?? '';
      final dt = DateTime.tryParse(dtStr);
      final label = dt != null ? labelFor(dt) : 'Earlier';
      if (label != lastLabel) {
        result.add(label);
        lastLabel = label;
      }
      result.add(entry);
    }
    return result;
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      icon: Icons.phone_missed_outlined,
      title: 'No call history',
      message: 'Your calls will appear here',
    );
  }

  List<Map<String, dynamic>> _filteredHistory(String filter) {
    final all = controller.callHistory;
    List<Map<String, dynamic>> filtered;
    switch (filter) {
      case 'Missed':
        filtered = all.where((e) => e['status'] == 'missed').toList();
        break;
      case 'Outgoing':
        filtered = all.where((e) => e['direction'] == 'outgoing').toList();
        break;
      case 'Incoming':
        filtered = all.where((e) => e['direction'] == 'incoming').toList();
        break;
      case 'Rejected':
        filtered = all.where((e) => e['status'] == 'rejected').toList();
        break;
      default:
        filtered = all.toList();
    }
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return filtered;
    return filtered.where((e) {
      final name = (e['contactName']?.toString() ?? '').toLowerCase();
      return name.contains(query);
    }).toList();
  }

  void _showCallOptions(Map<String, dynamic> entry) {
    final id = entry['contactId']?.toString() ?? '';
    final name = entry['contactName']?.toString() ?? 'Contact';

    if (id.isEmpty) {
      Utils.showGetSnackBar('Contact info not available');
      return;
    }

    final isDark = _isDark;
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 96.w, 32.h),
        decoration: BoxDecoration(
          color: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? CustomColor.kTextOnDark.withValues(alpha: 0.2)
                      : CustomColor.kLightBorder,
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              SizedBox(height: 20.h),
              CircleAvatar(
                radius: 32.r,
                backgroundColor: CustomColor.kUltraLightPrimary,
                child: Text(
                  _initialOf(name),
                  style: AppTextStyles.displayLarge
                      .copyWith(color: CustomColor.kPrimaryDark),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                name,
                style: AppTextStyles.headingMd.copyWith(
                    color: isDark
                        ? CustomColor.kTextOnDark
                        : CustomColor.kTextPrimary),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _CallOptionButton(
                    icon: Icons.phone_rounded,
                    label: 'Audio',
                    onTap: () {
                      Get.back();
                      controller.initCall(id, 'audio');
                    },
                  ),
                  _CallOptionButton(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    onTap: () {
                      Get.back();
                      controller.initCall(id, 'video');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCallDetails(Map<String, dynamic> entry) {
    final name = entry['contactName']?.toString() ?? 'Unknown';
    final dateTimeStr = entry['dateTime']?.toString() ?? '';
    final status = entry['status']?.toString() ?? '';
    final direction = entry['direction']?.toString() ?? '';
    final callType = entry['callType']?.toString() ?? 'audio';
    final duration = entry['duration'] as int? ?? 0;

    DateTime? dateTime = DateTime.tryParse(dateTimeStr);
    final fullDate = dateTime != null
        ? DateFormat('EEEE, MMMM d, yyyy – HH:mm:ss').format(dateTime)
        : 'N/A';

    final durationStr = _formatLongDuration(duration);

    final isDark = _isDark;
    Get.bottomSheet(
      SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: isDark
                      ? CustomColor.kTextOnDark.withValues(alpha: 0.2)
                      : CustomColor.kLightBorder,
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                name,
                style: AppTextStyles.headingMd.copyWith(
                    color: isDark
                        ? CustomColor.kTextOnDark
                        : CustomColor.kTextPrimary),
              ),
              SizedBox(height: 16.h),
              _DetailRow(label: 'Date & Time', value: fullDate, isDark: isDark),
              _DetailRow(
                label: 'Direction',
                value: _capitalize(direction),
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Status',
                value: _capitalize(status),
                isDark: isDark,
              ),
              _DetailRow(
                label: 'Call Type',
                value: _capitalize(callType),
                isDark: isDark,
              ),
              _DetailRow(label: 'Duration', value: durationStr, isDark: isDark),
            ],
          ),
        ),
      ),
      backgroundColor: isDark ? CustomColor.kDarkSurface : CustomColor.kWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
    );
  }

  String _formatLongDuration(int seconds) {
    if (seconds <= 0) return 'N/A';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')} mins';
  }

  String _initialOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  ImageProvider _imageProvider(String url) {
    if (url.isNotEmpty) {
      return CachedNetworkImageProvider(
          url.startsWith('http') ? url : '${Endpoints.mediaBaseUrl}$url');
    }
    return const AssetImage(AppAssets.defaultProfilePic);
  }
}

class _CallHistoryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isMultiSelectMode;
  final bool isSelected;
  final VoidCallback? onSelect;

  const _CallHistoryTile({
    required this.entry,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
    this.isMultiSelectMode = false,
    this.isSelected = false,
    this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final status = entry['status']?.toString() ?? 'missed';
    final direction = entry['direction']?.toString() ?? 'incoming';
    final callType = entry['callType']?.toString() ?? 'audio';
    final name = entry['contactName']?.toString() ?? 'Unknown';
    final duration = entry['duration'] as int? ?? 0;
    final dateTimeStr = entry['dateTime']?.toString() ?? '';

    final Color statusColor;
    switch (status) {
      case 'answered':
        statusColor = CustomColor.kOnlineGreen;
        break;
      case 'missed':
        statusColor = CustomColor.kDangerRed;
        break;
      case 'rejected':
        statusColor = CustomColor.kGoldAccent;
        break;
      default:
        statusColor =
            isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;
    }

    final IconData directionIcon = direction == 'outgoing'
        ? Icons.arrow_outward_rounded
        : Icons.arrow_back_rounded;

    DateTime? dateTime;
    String displayDate = '';
    if (dateTimeStr.isNotEmpty) {
      dateTime = DateTime.tryParse(dateTimeStr);
      if (dateTime != null) {
        final now = DateTime.now();
        if (DateUtils.isSameDay(dateTime, now)) {
          displayDate = DateFormat('HH:mm').format(dateTime);
        } else if (now.difference(dateTime).inDays == 1) {
          displayDate = 'Yesterday';
        } else {
          displayDate = DateFormat('MM/dd/yy').format(dateTime);
        }
      }
    }

    final durationStr = _formatDuration(duration);

    final primaryTextColor =
        isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    final secondaryTextColor =
        isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
    final mutedTextColor =
        isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: Container(
          padding: EdgeInsets.all(12.r),
          decoration: BoxDecoration(
            color: isMultiSelectMode && isSelected
                ? CustomColor.kPrimaryColor.withValues(alpha: 0.12)
                : isDark
                    ? CustomColor.kDarkSurface
                    : CustomColor.kWhite,
            borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
            border: Border.all(
              color: isMultiSelectMode && isSelected
                  ? CustomColor.kPrimaryColor.withValues(alpha: 0.4)
                  : isDark
                      ? CustomColor.kDarkBorder
                      : CustomColor.kLightBorder,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8.r,
                      offset: Offset(0, 2.r),
                    ),
                  ],
          ),
          child: Row(
            children: [
              if (isMultiSelectMode)
                GestureDetector(
                  onTap: onSelect,
                  child: Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: Container(
                      width: 24.r,
                      height: 24.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? CustomColor.kPrimaryColor
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? CustomColor.kPrimaryColor
                              : mutedTextColor,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(
                              Icons.check_rounded,
                              color: CustomColor.kTextOnDark,
                              size: 16.sp,
                            )
                          : null,
                    ),
                  ),
                ),
              Builder(
                builder: (_) {
                  final contactImage = entry['contactImage']?.toString() ?? '';
                  final hasImage = contactImage.isNotEmpty;
                  final imgProvider = hasImage
                      ? CachedNetworkImageProvider(
                          contactImage.startsWith('http')
                              ? contactImage
                              : '${Endpoints.mediaBaseUrl}$contactImage')
                      : null;
                  return CircleAvatar(
                    radius: 24.r,
                    backgroundColor:
                        CustomColor.kPrimaryMedium.withValues(alpha: 0.15),
                    backgroundImage: imgProvider,
                    child: hasImage
                        ? null
                        : Text(
                            _initialOf(name),
                            style: AppTextStyles.headingMd
                                .copyWith(color: CustomColor.kPrimaryDark),
                          ),
                  );
                },
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.titleMd
                          .copyWith(color: primaryTextColor),
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Icon(directionIcon, size: 14.r, color: statusColor),
                        SizedBox(width: 4.w),
                        Icon(
                          callType == 'video'
                              ? Icons.videocam_rounded
                              : Icons.phone_rounded,
                          size: 14.r,
                          color: statusColor,
                        ),
                        if (durationStr.isNotEmpty) ...[
                          SizedBox(width: 8.w),
                          Icon(
                            Icons.timer_outlined,
                            size: 14.r,
                            color: mutedTextColor,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            durationStr,
                            style: AppTextStyles.bodySm
                                .copyWith(color: mutedTextColor),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayDate,
                        style: AppTextStyles.error
                            .copyWith(color: secondaryTextColor),
                      ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.md.r),
                    ),
                    child: Text(
                      _labelFor(status),
                      style: AppTextStyles.labelSm.copyWith(color: statusColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _initialOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  String _formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _labelFor(String status) {
    switch (status) {
      case 'answered':
        return 'Answered';
      case 'missed':
        return 'Missed';
      case 'rejected':
        return 'Rejected';
      default:
        return status.toUpperCase();
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _DetailRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.subtitle.copyWith(
                color: isDark
                    ? CustomColor.kTextOnDarkMuted
                    : CustomColor.kTextTertiary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.subtitle.copyWith(
                  color: isDark
                      ? CustomColor.kTextOnDark
                      : CustomColor.kTextPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _CallOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CallOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              gradient: CustomColor.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.25),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.r),
                ),
              ],
            ),
            child: Icon(icon, color: CustomColor.kTextOnDark, size: 24.r),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: AppTextStyles.subtitle.copyWith(
                color: isDark
                    ? CustomColor.kTextOnDarkSecondary
                    : CustomColor.kTextSecondary),
          ),
        ],
      ),
    );
  }
}
