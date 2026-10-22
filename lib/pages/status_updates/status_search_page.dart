import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class StatusSearchPage extends StatefulWidget {
  const StatusSearchPage({super.key});

  @override
  State<StatusSearchPage> createState() => _StatusSearchPageState();
}

class _StatusSearchPageState extends State<StatusSearchPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  final StatusController _ctrl = Get.find();
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String val) {
    _debounce?.cancel();
    if (val.trim().isEmpty) {
      _ctrl.searchResults.clear();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _ctrl.searchStatuses(keyword: val.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      appBar: CommonAppBar(
        title: '',
        titleWidget: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: _onSearch,
          decoration: InputDecoration(
            hintText: 'Search statuses...',
            hintStyle: GoogleFonts.poppins(color: CustomColor.kTextTertiary),
            border: InputBorder.none,
          ),
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          IconButton(
            tooltip: 'Filters',
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilters(context),
          ),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isSearching.value) {
          return const CustomLoading();
        }
        if (_ctrl.searchResults.isEmpty) {
          return _searchCtrl.text.isEmpty
              ? const AppEmptyState(
                  icon: Icons.search_rounded,
                  title: 'Search statuses',
                  message: 'Search statuses by user, content, or date.',
                )
              : const AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No results found',
                  message: 'Try a different search term.',
                );
        }
        return ListView.builder(
          padding: EdgeInsets.fromLTRB(
              16.w, 16.w, 16.w, 16.w + MediaQuery.of(context).padding.bottom),
          itemCount: _ctrl.searchResults.length,
          itemBuilder: (ctx, i) {
            final item = _ctrl.searchResults[i];
            final update = item['update'] as Map<String, dynamic>?;
            final author = item['author'] as Map<String, dynamic>?;
            final name = author != null
                ? '${author['user_first_name'] ?? ''} ${author['user_last_name'] ?? ''}'
                    .trim()
                : 'Unknown';
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              decoration: BoxDecoration(
                color:
                    isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark,
                borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: CustomColor.kPrimaryFill,
                  child: Text(name.isEmpty ? '?' : name[0].toUpperCase(),
                      style:
                          GoogleFonts.poppins(color: CustomColor.kTextOnDark)),
                ),
                title: Text(name, style: AppTextStyles.bodyMd),
                subtitle: Text(
                  update?['su_content']?.toString() ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySm
                      .copyWith(color: CustomColor.kTextTertiary),
                ),
                trailing: Text(
                  _dateOnly(update?['su_created_at']?.toString()),
                  style: AppTextStyles.caption
                      .copyWith(color: CustomColor.kTextTertiary),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  void _showFilters(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Filter By', style: AppTextStyles.headingSm),
              SizedBox(height: 16.h),
              Wrap(
                spacing: 8.w,
                children: ['text', 'image', 'video', 'voice']
                    .map((t) => FilterChip(
                          label: Text(t),
                          onSelected: (_) {
                            _ctrl.searchStatuses(
                                keyword: _searchCtrl.text, mediaType: t);
                            Navigator.pop(ctx);
                          },
                        ))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateOnly(String? value) {
    if (value == null || value.length < 10) return value ?? '';
    return value.substring(0, 10);
  }
}
