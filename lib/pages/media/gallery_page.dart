import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/components/media/media_grid_item.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:intl/intl.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final RxList _mediaItems = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = true.obs;
  final RxBool _isMultiSelect = false.obs;
  final RxSet<String> _selectedIds = <String>{}.obs;

  int _selectedTab = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _sortNewest = true;

  static const _tabs = [
    'Media',
    'Videos',
    'Documents',
    'Links',
    'Audio',
    'Voice Notes',
  ];

  static const _tabTypes = <String?>[
    null,
    '2',
    '3',
    '5',
    '4',
    '6',
  ];

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGallery() async {
    _isLoading.value = true;
    try {
      final res = await ApiService().getData(path: Endpoints.mediaGallery);
      if (res['status'] == true && res['data'] != null) {
        _mediaItems.value = List<Map<String, dynamic>>.from(res['data']);
      }
    } catch (e) {
      _mediaItems.value = _getSampleData();
    } finally {
      _isLoading.value = false;
    }
  }

  List<Map<String, dynamic>> _getSampleData() {
    return [
      {
        'id': '1',
        'url': '',
        'type': '1',
        'created_at':
            DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': '2',
        'url': '',
        'type': '4',
        'duration': '0:30',
        'created_at':
            DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredItems {
    var items = List<Map<String, dynamic>>.from(_mediaItems);

    final typeFilter = _tabTypes[_selectedTab];
    if (typeFilter != null) {
      if (typeFilter == '5') {
        items = items.where((i) {
          final t = i['type']?.toString() ?? '';
          if (t == '5') return true;
          final text = (i['url']?.toString() ?? '').toLowerCase();
          return text.startsWith('http') ||
              text.contains('.com') ||
              text.contains('.net');
        }).toList();
      } else {
        items =
            items.where((i) => i['type']?.toString() == typeFilter).toList();
      }
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items.where((i) {
        final url = (i['url']?.toString() ?? '').toLowerCase();
        final text = (i['text']?.toString() ?? '').toLowerCase();
        final name = (i['filename']?.toString() ?? '').toLowerCase();
        return url.contains(q) || text.contains(q) || name.contains(q);
      }).toList();
    }

    items.sort((a, b) {
      final da = DateTime.tryParse(a['created_at'] ?? '');
      final db = DateTime.tryParse(b['created_at'] ?? '');
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return _sortNewest ? db.compareTo(da) : da.compareTo(db);
    });

    return items;
  }

  Map<String, List<Map<String, dynamic>>> _groupByDate(
      List<Map<String, dynamic>> items) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (final item in items) {
      String dateKey;
      try {
        final dt = DateTime.parse(item['created_at'] ?? '');
        final now = DateTime.now();
        if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
          dateKey = 'Today';
        } else if (dt == now.subtract(const Duration(days: 1))) {
          dateKey = 'Yesterday';
        } else {
          dateKey = DateFormat('MMMM d, yyyy').format(dt);
        }
      } catch (_) {
        dateKey = 'Unknown';
      }
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(item);
    }
    return grouped;
  }

  void _toggleSelect(String id) {
    if (_selectedIds.contains(id)) {
      _selectedIds.remove(id);
    } else {
      _selectedIds.add(id);
    }
    if (_selectedIds.isEmpty) _isMultiSelect.value = false;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(
        title: '',
        // The title is reactive, so it has to stay inside an Obx — a plain
        // String argument would be read once and never rebuild on selection.
        titleWidget: Obx(() => Text(
              _isMultiSelect.value
                  ? '${_selectedIds.length} Selected'
                  : 'Gallery',
              style: GoogleFonts.poppins(
                  color: CustomColor.kTextPrimary, fontWeight: FontWeight.w600),
            )),
        backgroundColor: CustomColor.kTextOnDark,
        actions: [
          Obx(() => _isMultiSelect.value
              ? TextButton(
                  onPressed: () {
                    _isMultiSelect.value = false;
                    _selectedIds.clear();
                  },
                  child: Text('Cancel',
                      style:
                          GoogleFonts.poppins(color: CustomColor.kPrimaryText)),
                )
              : const SizedBox.shrink()),
          if (_isMultiSelect.value)
            TextButton(
              onPressed: () {
                _isMultiSelect.value = false;
                _selectedIds.clear();
                CustomSnackbar.success(
                    title: 'Shared',
                    message: '${_selectedIds.length} items shared');
              },
              child: Text('Share',
                  style: GoogleFonts.poppins(color: CustomColor.kPrimaryText)),
            ),
        ],
      ),
      body: Obx(() {
        if (_isLoading.value) return _buildShimmer();
        return Column(
          children: [
            _buildFilterBar(),
            Expanded(
              child: _filteredItems.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadGallery,
                      child: _buildGalleryContent(),
                    ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: CustomColor.kWhite,
      padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 4.h),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 36.h,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: AppTextStyles.subtitle,
                    decoration: InputDecoration(
                      hintText: 'Search media...',
                      hintStyle: AppTextStyles.subtitle
                          .copyWith(color: CustomColor.kTextTertiary),
                      prefixIcon: Icon(Icons.search_rounded,
                          size: 18.r, color: CustomColor.kTextTertiary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              tooltip: 'Clear selection',
                              icon: Icon(Icons.clear_rounded, size: 16.r),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: CustomColor.kUltraLightBg,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 0.h, horizontal: 12.w),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: () => setState(() => _sortNewest = !_sortNewest),
                child: Container(
                  height: 36.h,
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  decoration: BoxDecoration(
                    color: CustomColor.kUltraLightBg,
                    borderRadius: BorderRadius.circular(AppRadius.lg.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _sortNewest
                            ? Icons.sort_rounded
                            : Icons.sort_by_alpha_rounded,
                        size: 16.r,
                        color: CustomColor.kPrimaryColor,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        _sortNewest ? 'Newest' : 'Oldest',
                        style: AppTextStyles.bodySm
                            .copyWith(color: CustomColor.kPrimaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          SizedBox(
            height: 32.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => SizedBox(width: 6.w),
              itemBuilder: (_, i) {
                final isSelected = _selectedTab == i;
                return GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? CustomColor.kPrimaryColor
                          : CustomColor.kUltraLightBg,
                      borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                    ),
                    child: Text(
                      _tabs[i],
                      style: AppTextStyles.bodySm.copyWith(
                          color: isSelected
                              ? CustomColor.kWhite
                              : CustomColor.kTextSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return GridView.builder(
      padding: EdgeInsets.all(8.r),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: 12,
      itemBuilder: (_, __) => Container(
        decoration: BoxDecoration(
          color: CustomColor.kUltraLightBg,
          borderRadius: BorderRadius.circular(AppRadius.md.r),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: CustomColor.kPrimaryColor,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final labels = ['', 'videos', 'documents', 'links', 'audio', 'voice notes'];
    final label = _selectedTab == 0 ? 'media' : labels[_selectedTab];
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined,
              size: 80.r, color: CustomColor.kTextTertiary),
          SizedBox(height: 16.h),
          Text(
            'No $label yet',
            style: AppTextStyles.headingMd
                .copyWith(color: CustomColor.kTextPrimary),
          ),
          SizedBox(height: 8.h),
          Text(
            '$label shared in chats\nwill appear here',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMd
                .copyWith(color: CustomColor.kTextSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryContent() {
    final items = _filteredItems;
    final grouped = _groupByDate(items);
    final dates = grouped.keys.toList()
      ..sort((a, b) {
        if (a == 'Today') return -1;
        if (b == 'Today') return 1;
        if (a == 'Yesterday') return -1;
        if (b == 'Yesterday') return 1;
        return a.compareTo(b);
      });

    return ListView.builder(
      padding: EdgeInsets.only(bottom: 16.h),
      itemCount: dates.length,
      itemBuilder: (_, sectionIndex) {
        final date = dates[sectionIndex];
        final sectionItems = grouped[date]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              child: Text(
                date,
                style: AppTextStyles.titleMd
                    .copyWith(color: CustomColor.kTextPrimary),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: sectionItems.length,
                itemBuilder: (_, index) {
                  final item = sectionItems[index];
                  final id = item['id'] ?? '';
                  final type = item['type'] ?? '1';
                  final url = item['url'] ?? '';
                  final fullUrl = url.startsWith('http')
                      ? url
                      : '$Endpoints.mediaBaseUrl$url';
                  final isSelected = _selectedIds.contains(id);

                  return MediaGridItem(
                    mediaUrl: fullUrl,
                    mediaType: type,
                    duration: item['duration'],
                    isSelected: isSelected,
                    onTap: () {
                      if (_isMultiSelect.value) {
                        _toggleSelect(id);
                      } else {
                        CustomSnackbar.show(
                            title: 'View', message: 'Opening viewer...');
                      }
                    },
                    onLongPress: () {
                      _isMultiSelect.value = true;
                      _toggleSelect(id);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
