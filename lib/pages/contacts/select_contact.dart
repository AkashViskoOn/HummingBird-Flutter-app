import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/contact/contact_profile_sheet.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/widgets/image_viewer_widget.dart';
import 'package:humming_bird/pages/contacts/add_new_contact.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_icons.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_animation.dart';

class AllContactsScreen extends StatefulWidget {
  const AllContactsScreen({super.key});

  @override
  State<AllContactsScreen> createState() => _AllContactsScreenState();
}

class _AllContactsScreenState extends State<AllContactsScreen> {
  final ContactController contactController = Get.find();
  final UserController userController = Get.find();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      contactController.syncContactsOnOpen();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshContacts() async {
    _searchController.clear();
    try {
      await contactController.refreshContacts();
    } catch (_) {}
  }

  ImageProvider _userAvatar(User user) {
    final image = user.userImage ?? '';
    if (image.isNotEmpty) {
      return CachedNetworkImageProvider('${Endpoints.mediaBaseUrl}$image');
    }
    return const AssetImage(AppAssets.defaultProfilePic);
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'HB';
    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  Widget _buildSectionHeader(String letter) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          AppSpacing.xxl.w, AppSpacing.md.h, AppSpacing.xxl.w, AppSpacing.xs.h),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: CustomColor.kPrimaryLight,
              borderRadius: BorderRadius.circular(AppRadius.sm.r),
            ),
            child: Text(
              letter,
              style: AppTextStyles.label.copyWith(
                color: CustomColor.kPrimaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          SizedBox(width: AppSpacing.sm.w),
          Text(
            letter == '#' ? 'Others' : 'Letter $letter',
            style: AppTextStyles.bodySm.copyWith(
              color: CustomColor.kTextTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, List<User>> _groupContactsByAlphabet(List<User> contacts) {
    final map = <String, List<User>>{};
    for (final user in contacts) {
      final name = contactController.getAllContactsName(user);
      String letter = name.trim().isNotEmpty ? name[0].toUpperCase() : '#';
      if (!RegExp(r'^[A-Z]$').hasMatch(letter)) {
        letter = '#';
      }
      map.putIfAbsent(letter, () => []);
      map[letter]!.add(user);
    }
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return {for (final k in sortedKeys) k: map[k]!};
  }

  void _showProfilePreview(User user) {
    final name = contactController.getAllContactsName(user);
    final avatar = _userAvatar(user);
    Get.bottomSheet(
      ContactProfileSheet(
        user: user,
        name: name,
        number: user.userMobileNum ?? '',
        avatar: avatar,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.kUltraLightPrimary,
      appBar: CommonAppBar(title: 'Contacts', actions: [
        Obx(
          () => IconButton(
            tooltip: 'Refresh contacts',
            onPressed: contactController.isFetchingContacts.value
                ? null
                : _refreshContacts,
            icon: contactController.isFetchingContacts.value
                ? SizedBox(
                    width: 20.r,
                    height: 20.r,
                    child: const CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ),
        SizedBox(width: 6.w),
      ]),
      body: RefreshIndicator(
        color: CustomColor.kPrimaryColor,
        onRefresh: _refreshContacts,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 10.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SearchField(
                      controller: _searchController,
                      onChanged: (value) => contactController.searchContacts(
                        value,
                        forAllContacts: true,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(
                      () => AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: contactController.isFetchingContacts.value
                            ? const _SyncBanner()
                            : _SummaryRow(
                                hummingCount:
                                    contactController.hummingContacts.length,
                                inviteCount:
                                    contactController.phoneContacts.length,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _NewContactTile(
                  onTap: () => Get.to(() => const AddContact()),
                ),
              ),
            ),
            GetBuilder<ContactController>(
              id: 'update-contacts-search',
              builder: (_) {
                final hummingContacts = contactController.hummingContacts;
                final inviteContacts = contactController.phoneContacts;
                final isSearching = _searchController.text.trim().isNotEmpty;

                if (!contactController.isFetchingContacts.value &&
                    hummingContacts.isEmpty &&
                    inviteContacts.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      icon: Icons.contacts_rounded,
                      title: 'No contacts found',
                      message:
                          'Pull down or tap refresh to sync your phone contacts.',
                    ),
                  );
                }

                Widget hummingTile(User user) => _HummingContactTile(
                      user: user,
                      name: contactController.getAllContactsName(user),
                      avatar: _userAvatar(user),
                      onTap: () => _showProfilePreview(user),
                      onAvatarTap: () {
                        final image = user.userImage ?? '';
                        if (image.isNotEmpty) {
                          Get.to(() => FullScreenImageView(
                                url: '${Endpoints.mediaBaseUrl}$image',
                              ));
                        }
                      },
                    );

                if (isSearching) {
                  return SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      if (hummingContacts.isNotEmpty)
                        _SectionHeader(
                          title: 'Contacts on Humming Bird',
                          count: hummingContacts.length,
                        ),
                      ...hummingContacts.map(hummingTile),
                      if (inviteContacts.isNotEmpty)
                        _SectionHeader(
                          title: 'Invite Contacts',
                          count: inviteContacts.length,
                        ),
                      ...inviteContacts.map(
                        (contact) => _InviteContactTile(
                          contact: contact,
                          initials: _initials(contact.displayName),
                          onInvite: () {
                            if (contact.phones.isNotEmpty) {
                              contactController
                                  .sendInviteMessage(contact.phones[0].number);
                            }
                          },
                        ),
                      ),
                      SizedBox(height: 24.h),
                    ]),
                  );
                }

                final favoriteIds = contactController.getFavoriteContacts();
                final favoriteUsers = hummingContacts
                    .where((u) =>
                        u.userId != null && favoriteIds.contains(u.userId))
                    .toList();

                final recentIds = contactController.getRecentlyContacted();
                final recentUsers = recentIds
                    .map((id) =>
                        hummingContacts.firstWhereOrNull((u) => u.userId == id))
                    .whereType<User>()
                    .toList();

                final grouped = _groupContactsByAlphabet(hummingContacts);

                return SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    if (favoriteUsers.isNotEmpty) ...[
                      _SectionHeader(
                          title: '⭐ Favorites', count: favoriteUsers.length),
                      SizedBox(
                        height: 88.h,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.xxl.w),
                          itemCount: favoriteUsers.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(width: AppSpacing.xl.w),
                          itemBuilder: (context, index) {
                            final user = favoriteUsers[index];
                            return Entrance(
                              delayFactor: (index % 8) * 0.05,
                              child: _FavoriteChip(
                                user: user,
                                name:
                                    contactController.getAllContactsName(user),
                                avatar: _userAvatar(user),
                                onTap: () => _showProfilePreview(user),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    if (recentUsers.isNotEmpty) ...[
                      _SectionHeader(
                          title: '🕐 Recently Contacted',
                          count: recentUsers.length),
                      ...recentUsers.map(hummingTile),
                    ],
                    ...grouped.entries.expand((entry) => [
                          _buildSectionHeader(entry.key),
                          ...entry.value.map(hummingTile),
                        ]),
                    if (inviteContacts.isNotEmpty)
                      _SectionHeader(
                        title: 'Invite Contacts',
                        count: inviteContacts.length,
                      ),
                    ...inviteContacts.map(
                      (contact) => _InviteContactTile(
                        contact: contact,
                        initials: _initials(contact.displayName),
                        onInvite: () {
                          if (contact.phones.isNotEmpty) {
                            contactController
                                .sendInviteMessage(contact.phones[0].number);
                          }
                        },
                      ),
                    ),
                    SizedBox(height: 24.h),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({
    required this.controller,
    required this.onChanged,
  });

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimation.cardHover,
      curve: AppAnimation.easeInOut,
      decoration: BoxDecoration(
        color: CustomColor.kLightSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        border: Border.all(
          color: _isFocused
              ? CustomColor.kPrimaryColor.withValues(alpha: 0.4)
              : Colors.transparent,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: _isFocused
                ? CustomColor.kPrimaryColor.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: _isFocused ? 12 : 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        textAlignVertical: TextAlignVertical.center,
        style: AppTextStyles.bodyMd,
        decoration: InputDecoration(
          hintText: 'Search contacts',
          hintStyle:
              AppTextStyles.bodyMd.copyWith(color: CustomColor.kTextTertiary),
          prefixIcon: Icon(Icons.search_rounded,
              color: _isFocused
                  ? CustomColor.kPrimaryColor
                  : CustomColor.kTextTertiary),
          filled: true,
          fillColor: CustomColor.kLightSurface,
          contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl.w + 2, vertical: AppSpacing.xxl.h - 3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final int hummingCount;
  final int inviteCount;

  const _SummaryRow({
    required this.hummingCount,
    required this.inviteCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(label: 'Humming', value: hummingCount),
        SizedBox(width: 8.w),
        _StatChip(label: 'Invite', value: inviteCount),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg.w + 1, vertical: AppSpacing.sm.h + 1),
      decoration: BoxDecoration(
        color: CustomColor.kLightSurface,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border:
            Border.all(color: CustomColor.kTextTertiary.withValues(alpha: 0.2)),
        boxShadow: AppShadow.cardLight,
      ),
      child: Text(
        '$value $label',
        style: AppTextStyles.bodySm.copyWith(
            color: CustomColor.kTextSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: AppAnimation.medium,
      curve: AppAnimation.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: child,
        ),
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl.w, vertical: AppSpacing.lg.h),
        decoration: BoxDecoration(
          color: CustomColor.kLightSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          border: Border.all(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(
              width: AppIcons.xxxl.r - 10,
              height: AppIcons.xxxl.r - 10,
              child: CircularProgressIndicator.adaptive(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(CustomColor.kPrimaryColor),
              ),
            ),
            SizedBox(width: AppSpacing.lg.w),
            Text(
              'Syncing contacts',
              style: AppTextStyles.label
                  .copyWith(color: CustomColor.kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.xxl.w, AppSpacing.xxxl.h - 2.h,
          AppSpacing.xxl.w, AppSpacing.md.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Row(
              children: [
                Container(
                  width: AppSpacing.xxs.w + 1,
                  height: AppSpacing.xxl.h,
                  decoration: BoxDecoration(
                    gradient: CustomColor.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.xxs.r),
                  ),
                ),
                SizedBox(width: AppSpacing.md.w),
                Flexible(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.titleSm
                        .copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md.w, vertical: AppSpacing.xxs.h),
            decoration: BoxDecoration(
              color: CustomColor.kPrimaryLight,
              borderRadius: BorderRadius.circular(AppRadius.lg.r),
            ),
            child: Text(
              count.toString(),
              style: AppTextStyles.bodySm.copyWith(
                  color: CustomColor.kPrimaryColor,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _HummingContactTile extends StatefulWidget {
  final User user;
  final String name;
  final ImageProvider avatar;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  const _HummingContactTile({
    required this.user,
    required this.name,
    required this.avatar,
    required this.onTap,
    required this.onAvatarTap,
  });

  @override
  State<_HummingContactTile> createState() => _HummingContactTileState();
}

class _HummingContactTileState extends State<_HummingContactTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final displayName = widget.name.trim().isEmpty
        ? widget.user.userMobileNum ?? ''
        : widget.name;
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl.w, vertical: AppSpacing.xs.h),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppAnimation.fast,
          curve: AppAnimation.easeInOut,
          transform: _isPressed
              ? (Matrix4.diagonal3Values(0.97, 0.97, 1))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            color: CustomColor.kLightSurface,
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            boxShadow: [
              BoxShadow(
                color: _isPressed
                    ? CustomColor.kPrimaryColor.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.04),
                blurRadius: _isPressed ? 4 : 8,
                offset: Offset(0, _isPressed ? 1 : 3),
              ),
            ],
          ),
          child: ListTile(
            minLeadingWidth: 0,
            contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xl.w, vertical: AppSpacing.sm.h - 1),
            leading: InkWell(
              onTap: widget.onAvatarTap,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: CircleAvatar(
                radius: AppSpacing.section,
                backgroundImage: widget.avatar,
                onBackgroundImageError: (_, __) {},
              ),
            ),
            title: Text(
              displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              widget.user.userMobileNum ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500),
            ),
            trailing: Container(
              padding: EdgeInsets.all(AppSpacing.md.r),
              decoration: BoxDecoration(
                color: CustomColor.kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.message_rounded,
                color: CustomColor.kPrimaryColor,
                size: AppIcons.md.r,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteContactTile extends StatelessWidget {
  final Contact contact;
  final String initials;
  final VoidCallback onInvite;

  const _InviteContactTile({
    required this.contact,
    required this.initials,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    final number = contact.phones.isNotEmpty ? contact.phones[0].number : '';
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxl.w, vertical: AppSpacing.xs.h),
      child: Container(
        decoration: BoxDecoration(
          color: CustomColor.kLightSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
          boxShadow: AppShadow.cardLight,
        ),
        child: ListTile(
          minLeadingWidth: 0,
          contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl.w, vertical: AppSpacing.sm.h - 1),
          leading: CircleAvatar(
            radius: AppSpacing.section,
            backgroundColor: CustomColor.kPrimaryColor.withValues(alpha: 0.12),
            child: Text(
              initials,
              style: AppTextStyles.subtitle.copyWith(
                color: CustomColor.kPrimaryColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          title: Text(
            contact.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            number,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500),
          ),
          trailing: AnimatedContainer(
            duration: AppAnimation.cardHover,
            decoration: BoxDecoration(
              gradient: CustomColor.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
            ),
            child: TextButton.icon(
              onPressed: number.isEmpty ? null : onInvite,
              icon: Icon(Icons.person_add_alt_1_rounded,
                  size: AppIcons.md.r - 1, color: CustomColor.kTextOnDark),
              label: Text('Invite',
                  style: AppTextStyles.buttonSm
                      .copyWith(color: CustomColor.kTextOnDark)),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl.w, vertical: AppSpacing.sm.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xxxl.r)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteChip extends StatelessWidget {
  final User user;
  final String name;
  final ImageProvider avatar;
  final VoidCallback onTap;

  const _FavoriteChip({
    required this.user,
    required this.name,
    required this.avatar,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 26.r,
            backgroundImage: avatar,
            onBackgroundImageError: (_, __) {},
          ),
          SizedBox(height: 4.h),
          SizedBox(
            width: 60.w,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewContactTile extends StatelessWidget {
  final VoidCallback onTap;

  const _NewContactTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: CustomColor.kLightSurface,
      borderRadius: BorderRadius.circular(AppRadius.xl.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            minLeadingWidth: 0,
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl.w,
              vertical: AppSpacing.sm.h - 1,
            ),
            leading: Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: CustomColor.kPrimaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.person_add_alt_1_rounded,
                color: CustomColor.kPrimaryColor,
                size: 22.r,
              ),
            ),
            title: Text(
              'New contact',
              style:
                  AppTextStyles.titleMd.copyWith(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              'Add a person to your contacts',
              style: AppTextStyles.bodySm.copyWith(fontWeight: FontWeight.w500),
            ),
            trailing: Icon(Icons.chevron_right_rounded,
                color: CustomColor.kTextTertiary),
          ),
        ),
      ),
    );
  }
}
