import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/rooms_model.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/home_controller.dart';
import 'package:humming_bird/pages/groups/create_group_screen.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/res/colors.dart';

class ForwardMessageScreen extends StatefulWidget {
  final List<String> messageIds;
  const ForwardMessageScreen({super.key, required this.messageIds});

  @override
  State<ForwardMessageScreen> createState() => _ForwardMessageScreenState();
}

class _ForwardMessageScreenState extends State<ForwardMessageScreen> {
  static const Color _primary = CustomColor.kPrimaryColor;
  static const Color _secondary = CustomColor.kBrandSecondary;
  static const Color _bg = CustomColor.kSurfaceTintMuted;
  static const Color _card = CustomColor.kWhite;
  static const Color _border = CustomColor.kSurfaceTintStrong;
  static const Color _text = CustomColor.kInk800;
  static const Color _subtitle = CustomColor.kSlate500;

  late HomeController _home;
  late ChatController _chat;
  late ContactController _contact;

  final Set<String> _selected = {};
  final TextEditingController _search = TextEditingController();
  String _query = '';
  Map<String, _ForwardTarget> _targets = {};

  @override
  void initState() {
    super.initState();
    _home = Get.find();
    _chat = Get.find();
    _contact = Get.find();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<_ForwardTarget> _buildTargets() {
    final pinnedIds = _home.getPinnedRoomIds().toSet();
    final map = <String, _ForwardTarget>{};
    final contactIds = _contact.hummingContacts
        .map((u) => u.userId)
        .whereType<String>()
        .toSet();

    for (final room in _home.singleChatsList) {
      if (room.rId == null) continue;
      final data = _contact.getContactData(room);
      final receiverId = data.$2;
      final name = data.$1.isNotEmpty
          ? data.$1
          : (data.$3.isNotEmpty ? data.$3 : (room.rName ?? 'Unknown'));
      final subtitle =
          data.$4.isNotEmpty ? data.$4 : (data.$3.isNotEmpty ? data.$3 : '');
      final user = _contact.hummingContacts
          .where((u) => u.userId == receiverId)
          .firstOrNull;
      map[room.rId!] = _ForwardTarget(
        room: room,
        isGroup: false,
        roomId: room.rId!,
        name: name,
        subtitle: subtitle,
        receiverId: receiverId,
        imagePath:
            (user?.userImage?.isNotEmpty ?? false) ? user!.userImage : null,
        unread: int.tryParse(_home.updateUnreadMsgCounter(room.rId!)) ?? 0,
        pinned: pinnedIds.contains(room.rId),
        verified: contactIds.contains(receiverId),
      );
    }

    for (final room in _home.groupsList) {
      if (room.rId == null) continue;
      map[room.rId!] = _ForwardTarget(
        room: room,
        isGroup: true,
        roomId: room.rId!,
        name: room.rName?.isNotEmpty == true ? room.rName! : 'Group',
        subtitle: 'Group',
        receiverId: '',
        imagePath: (room.rAvatar?.isNotEmpty ?? false) ? room.rAvatar : null,
        unread: int.tryParse(_home.updateUnreadMsgCounter(room.rId!)) ?? 0,
        pinned: pinnedIds.contains(room.rId),
        verified: false,
      );
    }

    return map.values.toList();
  }

  List<_ForwardTarget> _visibleTargets() {
    final all = _buildTargets();
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((t) {
      return t.name.toLowerCase().contains(q) ||
          (t.isGroup && 'group'.contains(q)) ||
          t.subtitle.toLowerCase().contains(q);
    }).toList();
  }

  List<Widget> _sectionedRows(List<_ForwardTarget> visible) {
    if (_query.trim().isNotEmpty) {
      if (visible.isEmpty) return [_emptyResults()];
      return [
        _sectionHeader('Results'),
        ...visible.map(_buildRow),
      ];
    }

    final frequentIds = _contact.getRecentlyContacted().toSet();
    final contactIds = _contact.hummingContacts
        .map((u) => u.userId)
        .whereType<String>()
        .toSet();

    final pinned = visible.where((t) => t.pinned).toList();
    final frequent = visible
        .where((t) =>
            !t.pinned && !t.isGroup && frequentIds.contains(t.receiverId))
        .toList();
    final recent = visible
        .where((t) =>
            !t.pinned &&
            !t.isGroup &&
            !frequentIds.contains(t.receiverId) &&
            !contactIds.contains(t.receiverId))
        .toList()
      ..sort((a, b) => _updatedAt(b.room).compareTo(_updatedAt(a.room)));
    final groups = visible.where((t) => t.isGroup && !t.pinned).toList();
    final contacts = visible
        .where((t) =>
            !t.pinned &&
            !t.isGroup &&
            !frequentIds.contains(t.receiverId) &&
            contactIds.contains(t.receiverId))
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final rows = <Widget>[];
    if (pinned.isNotEmpty) {
      rows.add(_sectionHeader('Pinned'));
      rows.addAll(pinned.map(_buildRow));
    }
    if (frequent.isNotEmpty) {
      rows.add(_sectionHeader('Frequently Contacted'));
      rows.addAll(frequent.map(_buildRow));
    }
    if (recent.isNotEmpty) {
      rows.add(_sectionHeader('Recent Chats'));
      rows.addAll(recent.map(_buildRow));
    }
    if (groups.isNotEmpty) {
      rows.add(_sectionHeader('Groups'));
      rows.addAll(groups.map(_buildRow));
    }
    if (contacts.isNotEmpty) {
      rows.add(_sectionHeader('Contacts'));
      rows.addAll(contacts.map(_buildRow));
    }
    return rows;
  }

  int _updatedAt(Rooms room) => int.tryParse(room.rUpdatedAt ?? '0') ?? 0;

  void _toggle(_ForwardTarget target) {
    setState(() {
      if (!_selected.remove(target.roomId)) {
        _selected.add(target.roomId);
      }
    });
  }

  void _forward() {
    if (_selected.isEmpty) return;
    _chat.forwardMessages(widget.messageIds, _selected.toList());
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: _bg,
        splashFactory: InkRipple.splashFactory,
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: Obx(() {
          _targets = {for (final t in _buildTargets()) t.roomId: t};
          final visible = _visibleTargets();
          return Scaffold(
            backgroundColor: _bg,
            body: Column(
              children: [
                _buildAppBar(),
                _buildSearchField(),
                _buildSelectedChips(),
                Expanded(
                  child: visible.isEmpty && _query.trim().isEmpty
                      ? _emptyState()
                      : ListView(
                          padding: EdgeInsets.only(
                            bottom: 24.h,
                          ),
                          children: _sectionedRows(visible),
                        ),
                ),
                _buildBottomBar(),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
          bottom: BorderSide(color: _border, width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.rounded.r),
                onTap: () => Get.back(),
                child: Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: _primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: _primary.withValues(alpha: 0.18)),
                  ),
                  child: Icon(Icons.close_rounded, size: 26.r, color: _primary),
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Text(
                  'Forward to',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: _text,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.rounded.r),
                onTap: () => Get.to(() => const CreateGroupScreen()),
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 9.h),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [_primary, _secondary],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.rounded.r),
                    boxShadow: [
                      BoxShadow(
                        color: _primary.withValues(alpha: 0.28),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded,
                          size: 18.r, color: CustomColor.kTextOnDark),
                      SizedBox(width: 4.w),
                      Text(
                        'New Group',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: CustomColor.kTextOnDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      color: _bg,
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        style: TextStyle(fontSize: 14.sp, color: _text),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search people, groups...',
          hintStyle: TextStyle(fontSize: 14.sp, color: _subtitle),
          prefixIcon: Icon(Icons.search_rounded, size: 22.r, color: _primary),
          filled: true,
          fillColor: _card,
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 13.h),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.rounded.r),
            borderSide: BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.rounded.r),
            borderSide: BorderSide(color: _primary, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedChips() {
    final chips = _selected
        .map((id) => _targets[id])
        .whereType<_ForwardTarget>()
        .toList();
    return AnimatedSize(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      child: chips.isEmpty
          ? const SizedBox(width: double.infinity)
          : Container(
              color: _bg,
              padding: EdgeInsets.only(bottom: 8.h),
              child: SizedBox(
                height: 64.h,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: chips.length,
                  separatorBuilder: (_, __) => SizedBox(width: 8.w),
                  itemBuilder: (context, index) => _buildChip(chips[index]),
                ),
              ),
            ),
    );
  }

  Widget _buildChip(_ForwardTarget target) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        border: Border.all(color: _primary.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: 6.w),
          _buildAvatar(target, 26.r),
          SizedBox(width: 6.w),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 110.w),
            child: Text(
              target.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 13.sp, fontWeight: FontWeight.w600, color: _text),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
            onTap: () => _toggle(target),
            child: Padding(
              padding: EdgeInsets.all(6.r),
              child: Icon(Icons.close_rounded,
                  size: 16.r, color: _primary.withValues(alpha: 0.8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(_ForwardTarget target) {
    final isSelected = _selected.contains(target.roomId);
    return Material(
      color: isSelected ? _primary.withValues(alpha: 0.07) : Colors.transparent,
      child: InkWell(
        onTap: () => _toggle(target),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: _border.withValues(alpha: 0.6)),
            ),
          ),
          child: Row(
            children: [
              _buildSelectionCircle(isSelected),
              SizedBox(width: 12.w),
              _buildAvatar(target, 44.r),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            target.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.sp,
                              fontWeight: FontWeight.w600,
                              color: _text,
                            ),
                          ),
                        ),
                        if (target.verified) ...[
                          SizedBox(width: 4.w),
                          Icon(Icons.verified_rounded,
                              size: 13.r, color: _primary),
                        ],
                      ],
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      target.subtitle.isEmpty
                          ? 'Humming Bird user'
                          : target.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.sp, color: _subtitle),
                    ),
                  ],
                ),
              ),
              if (target.unread > 0) ...[
                SizedBox(width: 8.w),
                _buildUnreadBadge(target.unread),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionCircle(bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutBack,
      width: 22.r,
      height: 22.r,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? _primary : Colors.transparent,
        border: Border.all(
          color: selected ? _primary : _border,
          width: 2,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded,
              size: 14.r, color: CustomColor.kTextOnDark)
          : null,
    );
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _secondary],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11.sp,
          fontWeight: FontWeight.w700,
          color: CustomColor.kTextOnDark,
        ),
      ),
    );
  }

  Widget _buildAvatar(_ForwardTarget target, double size) {
    final url = target.imagePath;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: _border, width: 1.2),
      ),
      child: ClipOval(
        child: url != null && url.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: '${Endpoints.mediaBaseUrl}$url',
                fit: BoxFit.cover,
                placeholder: (_, __) => _avatarFallback(target, size),
                errorWidget: (_, __, ___) => _avatarFallback(target, size),
              )
            : _avatarFallback(target, size),
      ),
    );
  }

  Widget _avatarFallback(_ForwardTarget target, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors:
              target.isGroup ? [_secondary, _primary] : [_primary, _secondary],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(target.name),
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

  Widget _sectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
          color: _primary,
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64.r,
            height: 64.r,
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.forward_rounded, size: 28.r, color: _primary),
          ),
          SizedBox(height: 16.h),
          Text(
            'No chats yet',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: _text,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Start a conversation to forward messages',
            style: TextStyle(fontSize: 13.sp, color: _subtitle),
          ),
          SizedBox(height: 16.h),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
            onTap: () => _home.fetchSingleChats(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primary, _secondary],
                ),
                borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded,
                      size: 16.r, color: CustomColor.kTextOnDark),
                  SizedBox(width: 6.w),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                      color: CustomColor.kTextOnDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyResults() {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 60.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
                size: 42.r, color: _subtitle.withValues(alpha: 0.5)),
            SizedBox(height: 10.h),
            Text(
              'No results for "${_query.trim()}"',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13.sp, color: _subtitle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final count = _selected.length;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      height: count == 0 ? 0 : null,
      decoration: BoxDecoration(
        color: _bg,
        border: Border(
          top: BorderSide(color: _border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
          child: Opacity(
            opacity: count == 0 ? 0 : 1,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
              onTap: count == 0 ? null : _forward,
              child: Container(
                height: 52.h,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primary, _secondary],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
                  boxShadow: [
                    BoxShadow(
                      color: _primary.withValues(alpha: 0.32),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.forward_rounded,
                        size: 20.r, color: CustomColor.kTextOnDark),
                    SizedBox(width: 8.w),
                    Text(
                      'Forward ($count)',
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w700,
                        color: CustomColor.kTextOnDark,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ForwardTarget {
  final Rooms room;
  final bool isGroup;
  final String roomId;
  final String name;
  final String subtitle;
  final String receiverId;
  final String? imagePath;
  final int unread;
  final bool pinned;
  final bool verified;

  const _ForwardTarget({
    required this.room,
    required this.isGroup,
    required this.roomId,
    required this.name,
    required this.subtitle,
    required this.receiverId,
    this.imagePath,
    required this.unread,
    required this.pinned,
    required this.verified,
  });
}
