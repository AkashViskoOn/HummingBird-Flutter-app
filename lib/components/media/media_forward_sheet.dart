import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/message_api.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class MediaForwardSheet extends StatefulWidget {
  final String messageId;
  final String mediaId;
  final List<Rooms>? rooms;

  const MediaForwardSheet({
    super.key,
    required this.messageId,
    required this.mediaId,
    this.rooms,
  });

  static void show(
    BuildContext context, {
    required String messageId,
    required String mediaId,
  }) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MediaForwardSheet(
        messageId: messageId,
        mediaId: mediaId,
      ),
    );
  }

  @override
  State<MediaForwardSheet> createState() => _MediaForwardSheetState();
}

class _MediaForwardSheetState extends State<MediaForwardSheet> {
  final TextEditingController _searchController = TextEditingController();
  final RxList _filteredRooms = <Rooms>[].obs;
  final RxString _selectedRoomId = ''.obs;
  final RxBool _forwarding = false.obs;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  void _loadRooms() {
    final homeController = Get.find<HomeController>();
    final rooms =
        (widget.rooms != null) ? widget.rooms! : homeController.singleChatsList;
    _filteredRooms.value = List.from(rooms);
  }

  void _search(String query) {
    final homeController = Get.find<HomeController>();
    final rooms =
        (widget.rooms != null) ? widget.rooms! : homeController.singleChatsList;
    if (query.isEmpty) {
      _filteredRooms.value = List.from(rooms);
    } else {
      _filteredRooms.value = rooms.where((r) {
        final name = r.rName ?? '';
        final mobile = r.userNumbers ?? '';
        final q = query.toLowerCase();
        return name.toLowerCase().contains(q) ||
            mobile.toLowerCase().contains(q);
      }).toList();
    }
  }

  Future<void> _forward() async {
    if (_selectedRoomId.value.isEmpty) return;
    _forwarding.value = true;
    try {
      await MessageApi().forwardMessage(
        messageIds: [widget.messageId],
        roomIds: [_selectedRoomId.value],
      );
      Get.back();
      CustomSnackbar.success(
          title: 'Forwarded', message: 'Message forwarded successfully');
    } catch (e) {
      CustomSnackbar.error(
          title: 'Error', message: 'Failed to forward message');
    } finally {
      _forwarding.value = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final screenHeight = mediaQuery.size.height;
    final sheetHeight = ((screenHeight * 0.7) - bottomInset)
        .clamp(screenHeight * 0.2, screenHeight)
        .toDouble();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: sheetHeight,
        decoration: BoxDecoration(
          color: CustomColor.kDarkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 12.h),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CustomColor.kOverlay8,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: CustomColor.kTextOnDark.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Text(
                        'Forward to',
                        style: AppTextStyles.headingMd
                            .copyWith(color: CustomColor.kTextOnDark),
                      ),
                      const Spacer(),
                      Obx(() => _forwarding.value
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: CircularProgressIndicator(
                                color: CustomColor.kPrimaryColor,
                                strokeWidth: 2,
                              ),
                            )
                          : GestureDetector(
                              onTap: _forward,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 6.h),
                                decoration: BoxDecoration(
                                  color: _selectedRoomId.value.isNotEmpty
                                      ? CustomColor.kPrimaryColor
                                      : CustomColor.kPrimaryColor
                                          .withValues(alpha: 0.3),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md.r),
                                ),
                                child: Text(
                                  'Send',
                                  style: AppTextStyles.label
                                      .copyWith(color: CustomColor.kTextOnDark),
                                ),
                              ),
                            )),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Container(
                    height: 44.h,
                    decoration: BoxDecoration(
                      color: CustomColor.kDarkSurface2,
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      border: Border.all(
                        color: CustomColor.kOverlay6,
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: AppTextStyles.bodyMd
                          .copyWith(color: CustomColor.kTextOnDark),
                      decoration: InputDecoration(
                        hintText: 'Search contacts...',
                        hintStyle: AppTextStyles.bodyMd.copyWith(
                            color:
                                CustomColor.kTextOnDark.withValues(alpha: 0.3)),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: CustomColor.kTextOnDark.withValues(alpha: 0.3),
                          size: 20.r,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onChanged: _search,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Obx(() {
                if (_filteredRooms.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.forward_to_inbox_rounded,
                    title: 'No conversations found',
                    message: 'Start a chat first to forward media',
                    layout: EmptyStateLayout.inline,
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: _filteredRooms.length,
                  separatorBuilder: (_, __) => Divider(
                    color: CustomColor.kOverlay4,
                    height: 1,
                  ),
                  itemBuilder: (_, index) {
                    final room = _filteredRooms[index] as Rooms;
                    final isSelected = _selectedRoomId.value == room.rId;
                    return _buildRoomTile(room, isSelected);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTile(Rooms room, bool isSelected) {
    final name = room.rName ?? 'Unknown';
    final mobile = room.userNumbers ?? '';

    return InkWell(
      onTap: () {
        _selectedRoomId.value = room.rId ?? '';
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        color: isSelected
            ? CustomColor.kPrimaryColor.withValues(alpha: 0.1)
            : null,
        child: Row(
          children: [
            Container(
              width: 48.r,
              height: 48.r,
              decoration: BoxDecoration(
                color: CustomColor.kPrimaryLight.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTextStyles.headingMd
                      .copyWith(color: CustomColor.kTextOnDark),
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppTextStyles.titleMd
                        .copyWith(color: CustomColor.kTextOnDark),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    mobile,
                    style: AppTextStyles.bodySm.copyWith(
                        color: CustomColor.kTextOnDark.withValues(alpha: 0.4)),
                  ),
                ],
              ),
            ),
            Obx(() {
              final sel = _selectedRoomId.value == room.rId;
              return Container(
                width: 22.r,
                height: 22.r,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sel ? CustomColor.kPrimaryColor : Colors.transparent,
                  border: Border.all(
                    color: sel
                        ? CustomColor.kPrimaryColor
                        : CustomColor.kTextOnDark.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: sel
                    ? Icon(Icons.check,
                        color: CustomColor.kTextOnDark, size: 14.r)
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }
}
