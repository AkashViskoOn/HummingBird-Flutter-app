import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/pages/Schedule_Pages/schedule_screen.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

/// Schedule Anywhere: pick which conversation(s) to schedule a message into.
/// - `selectMode: false` → pick a chat and a new [ScheduleScreen] opens
///   (used by the Schedule tab's "New Schedule" button and the home carousel).
/// - `selectMode: true` → multi-select; pops with the chosen
///   `List<ScheduleRecipient>` so the existing [ScheduleScreen] keeps its
///   composer state and updates its "To" card in place.
class ScheduleRecipientSheet extends StatefulWidget {
  final List<ScheduleRecipient> initial;
  final bool selectMode;

  const ScheduleRecipientSheet({
    super.key,
    this.initial = const [],
    this.selectMode = false,
  });

  /// Pops with the picked `List<ScheduleRecipient>` (or `null` on dismiss).
  static Future<List<ScheduleRecipient>?> show(
    BuildContext context, {
    List<ScheduleRecipient> initial = const [],
    bool selectMode = false,
  }) {
    return showModalBottomSheet<List<ScheduleRecipient>>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.rounded.r)),
      ),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.86,
        child: ScheduleRecipientSheet(initial: initial, selectMode: selectMode),
      ),
    );
  }

  @override
  State<ScheduleRecipientSheet> createState() => _ScheduleRecipientSheetState();
}

class _ScheduleRecipientSheetState extends State<ScheduleRecipientSheet> {
  late final HomeController _home;
  late final ContactController _contact;
  final TextEditingController _search = TextEditingController();
  String _query = '';
  late final Set<String> _selected =
      widget.initial.map((r) => r.roomId).toSet();

  @override
  void initState() {
    super.initState();
    _home = Get.find();
    _contact = Get.find();
  }

  List<ScheduleRecipient> get _selectedRecipients =>
      _buildRecipients().where((r) => _selected.contains(r.roomId)).toList();

  void _toggle(ScheduleRecipient r) {
    setState(() {
      if (!_selected.remove(r.roomId)) _selected.add(r.roomId);
    });
  }

  void _confirm(BuildContext context) {
    Navigator.pop(context, _selectedRecipients);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<ScheduleRecipient> _buildRecipients() {
    final list = <ScheduleRecipient>[];

    for (final room in _home.singleChatsList) {
      if (room.rId == null) continue;
      final data = _contact.getContactData(room);
      final name = data.$1.isNotEmpty
          ? data.$1
          : (data.$3.isNotEmpty ? data.$3 : (room.rName ?? 'Unknown'));
      list.add(ScheduleRecipient(
        roomId: room.rId!,
        receiverId: data.$2,
        roomUsers: (room.rUsers?.isNotEmpty ?? false) ? room.rUsers! : data.$2,
        name: name,
        subtitle:
            data.$4.isNotEmpty ? data.$4 : (data.$3.isNotEmpty ? data.$3 : ''),
        imagePath: _userImage(data.$2),
        isGroup: false,
        recency: int.tryParse(room.rUpdatedAt ?? '0') ?? 0,
      ));
    }

    for (final room in _home.groupsList) {
      if (room.rId == null) continue;
      list.add(ScheduleRecipient(
        roomId: room.rId!,
        receiverId: '',
        roomUsers: room.rUsers ?? '',
        name: room.rName?.isNotEmpty == true ? room.rName! : 'Group',
        subtitle: 'Group',
        imagePath: (room.rAvatar?.isNotEmpty ?? false) ? room.rAvatar : null,
        isGroup: true,
        recency: int.tryParse(room.rUpdatedAt ?? '0') ?? 0,
      ));
    }

    final q = _query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? list
        : list
            .where((r) =>
                r.name.toLowerCase().contains(q) ||
                (r.isGroup && 'group'.contains(q)) ||
                r.subtitle.toLowerCase().contains(q))
            .toList();
    filtered.sort((a, b) {
      if (a.isGroup != b.isGroup) return a.isGroup ? 1 : -1;
      return b.recency.compareTo(a.recency);
    });
    return filtered;
  }

  String? _userImage(String receiverId) {
    for (final u in _contact.hummingContacts) {
      if (u.userId == receiverId && (u.userImage?.isNotEmpty ?? false)) {
        return u.userImage;
      }
    }
    return null;
  }

  void _openSchedule(ScheduleRecipient r) {
    Navigator.pop(context);
    Get.to(() => ScheduleScreen(
          name: r.name,
          roomId: r.roomId,
          receiverId: r.receiverId,
          roomUsers: r.roomUsers,
          forGroup: r.isGroup,
          messageContext: null,
        ));
  }

  void _onRowTap(ScheduleRecipient r) {
    if (widget.selectMode) {
      _toggle(r);
    } else {
      _openSchedule(r);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
    final textColor =
        isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    final secondaryText =
        isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.rounded.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: 36.w,
              height: 4.h,
              margin: EdgeInsets.only(top: 10.h, bottom: 6.h),
              decoration: BoxDecoration(
                color: secondaryText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppRadius.xxs.r),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 8.h),
              child: Row(
                children: [
                  Container(
                    width: 42.r,
                    height: 42.r,
                    decoration: BoxDecoration(
                      gradient: CustomColor.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                    ),
                    child: Icon(Icons.schedule_send_rounded,
                        color: CustomColor.kTextOnDark, size: 22.r),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.selectMode
                              ? 'Choose recipients'
                              : 'Schedule Anywhere',
                          style: AppTextStyles.titleMd.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          widget.selectMode
                              ? 'Pick one or more chats to schedule into'
                              : 'Pick a chat to schedule a message into',
                          style: AppTextStyles.bodySm
                              .copyWith(color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 8.h),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                style: AppTextStyles.bodyMd.copyWith(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search chats & groups...',
                  hintStyle:
                      AppTextStyles.bodySm.copyWith(color: secondaryText),
                  prefixIcon: Icon(Icons.search_rounded,
                      size: 22.r, color: CustomColor.kPrimaryColor),
                  filled: true,
                  fillColor: isDark
                      ? CustomColor.kDarkSurface2
                      : CustomColor.kUltraLightBg,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.rounded.r),
                    borderSide: BorderSide(
                      color: isDark
                          ? CustomColor.kDarkBorder
                          : CustomColor.kLightBorder,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.rounded.r),
                    borderSide: BorderSide(
                        color: CustomColor.kPrimaryColor, width: 1.4),
                  ),
                ),
              ),
            ),
            Expanded(
              child: _buildList(),
            ),
            if (widget.selectMode) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 12.h),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(
                    top: BorderSide(
                        color: isDark
                            ? CustomColor.kDarkBorder
                            : CustomColor.kLightBorder),
                  ),
                ),
                child: InkWell(
                  onTap: () => _confirm(context),
                  borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
                  child: Container(
                    height: 50.h,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: CustomColor.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
                      boxShadow: [
                        BoxShadow(
                          color: CustomColor.kPrimaryGlow,
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Text(
                      _selected.isEmpty ? 'Done' : 'Done (${_selected.length})',
                      style: AppTextStyles.titleSm.copyWith(
                        color: CustomColor.kTextOnDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recipients = _buildRecipients();

    if (recipients.isEmpty) {
      return AppEmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: _query.trim().isEmpty
            ? 'No chats yet'
            : 'No results for "$_query"',
        message: _query.trim().isEmpty
            ? 'Start a conversation first'
            : 'Try a different search term',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: 16.h),
      itemCount: recipients.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        indent: 66.w,
        endIndent: 16.w,
        color: isDark
            ? CustomColor.kDarkDivider
            : CustomColor.kLightBorder.withValues(alpha: 0.5),
      ),
      itemBuilder: (_, i) => _buildRow(recipients[i]),
    );
  }

  Widget _buildRow(ScheduleRecipient r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _selected.contains(r.roomId);
    return InkWell(
      onTap: () => _onRowTap(r),
      child: Container(
        color: widget.selectMode && selected
            ? CustomColor.kPrimaryColor.withValues(alpha: 0.06)
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              _buildAvatar(r, 42.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleSm.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? CustomColor.kTextOnDark
                            : CustomColor.kTextPrimary,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      r.subtitle.isEmpty ? 'Humming Bird user' : r.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(
                        color: isDark
                            ? CustomColor.kTextOnDarkMuted
                            : CustomColor.kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.selectMode)
                Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  size: 22.r,
                  color: selected
                      ? CustomColor.kPrimaryColor
                      : (isDark
                          ? CustomColor.kTextOnDarkMuted
                          : CustomColor.kTextTertiary),
                )
              else
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppRadius.pill.r),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.schedule_rounded,
                          size: 14.r, color: CustomColor.kPrimaryColor),
                      SizedBox(width: 4.w),
                      Text(
                        'Schedule',
                        style: AppTextStyles.caption.copyWith(
                          color: CustomColor.kPrimaryColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(ScheduleRecipient r, double size) {
    final url = r.imagePath;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
            color: isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder,
            width: 1.2),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: '${Endpoints.mediaBaseUrl}$url',
                fit: BoxFit.cover,
                placeholder: (_, __) => _avatarFallback(r, size),
                errorWidget: (_, __, ___) => _avatarFallback(r, size),
              )
            : _avatarFallback(r, size),
      ),
    );
  }

  Widget _avatarFallback(ScheduleRecipient r, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: r.isGroup
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CustomColor.kBrandSecondary,
                  CustomColor.kPrimaryColor
                ],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  CustomColor.kPrimaryColor,
                  CustomColor.kBrandSecondary
                ],
              ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(r.name),
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w700,
          color: CustomColor.kTextOnDark,
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final second = parts.length > 1 ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }
}

class ScheduleRecipient {
  final String roomId;
  final String receiverId;
  final String roomUsers;
  final String name;
  final String subtitle;
  final String? imagePath;
  final bool isGroup;
  final int recency;

  const ScheduleRecipient({
    required this.roomId,
    required this.receiverId,
    required this.roomUsers,
    required this.name,
    required this.subtitle,
    this.imagePath,
    required this.isGroup,
    required this.recency,
  });
}
