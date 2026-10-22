import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class StatusPrivacySettings extends StatefulWidget {
  const StatusPrivacySettings({super.key});

  @override
  State<StatusPrivacySettings> createState() => _StatusPrivacySettingsState();
}

class _StatusPrivacySettingsState extends State<StatusPrivacySettings> {
  final StatusController _statusController = Get.find();
  String? _selected;
  List<int> _exceptIds = [];
  List<int> _shareIds = [];
  bool _saving = false;
  bool _userTouched = false;

  static const _options = [
    ('everyone', Icons.public, 'Everyone', 'All users can see your status'),
    (
      'contacts',
      Icons.people,
      'My Contacts',
      'Only your contacts can see your status'
    ),
    (
      'contacts_except',
      Icons.person_off,
      'My Contacts Except...',
      'Hide status from specific contacts'
    ),
    (
      'only_share',
      Icons.person_pin,
      'Only Share With...',
      'Only the people you choose can see your status'
    ),
    ('only_me', Icons.lock, 'Only Me', 'Nobody can see your status'),
  ];

  @override
  void initState() {
    super.initState();
    _loadFromController();
    _statusController.fetchPrivacy();
  }

  /// Syncs from the controller ONLY until the user starts editing — otherwise
  /// the Obx rebuild (fired by every privacy Rx change) would reset the
  /// selections the user is currently making.
  void _loadFromController() {
    if (_userTouched) return;
    final privacy = _statusController.privacy.value;
    if (privacy != null) {
      _selected = privacy.privacy ?? 'everyone';
      _exceptIds = List.of(privacy.exceptIds);
      _shareIds = List.of(privacy.shareIds);
    } else {
      _selected = 'everyone';
    }
  }

  Future<void> _save() async {
    _userTouched = true;
    final selected = _selected ?? 'everyone';
    if (selected == 'only_share' && _shareIds.isEmpty) {
      CustomSnackbar.show(
          title: 'Error', message: 'Select at least one person to share with');
      return;
    }
    setState(() => _saving = true);
    final ok = await _statusController.savePrivacy(
      privacy: selected,
      exceptIds: _exceptIds,
      shareIds: _shareIds,
    );
    setState(() => _saving = false);
    CustomSnackbar.success(
        title: ok ? 'Saved' : 'Failed',
        message:
            ok ? 'Status privacy updated' : 'Could not save privacy settings');
  }

  Future<void> _pickUsers({required bool forExcept}) async {
    final contactCtrl = Get.find<ContactController>();
    final userCtrl = Get.find<UserController>();
    final myId = userCtrl.user?.userId?.toString();
    if (contactCtrl.hummingContacts.isEmpty) {
      try {
        await contactCtrl.getHummingContacts();
      } catch (_) {}
    }
    final users = contactCtrl.hummingContacts
        .where((u) => u.userId?.toString() != myId)
        .toList();
    if (!mounted) return;

    final selected = <String>{
      ...(forExcept ? _exceptIds : _shareIds).map((e) => e.toString()),
    };

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Get.isDarkMode
              ? CustomColor.kDarkSurface
              : CustomColor.kTextOnDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Text(
                  forExcept ? 'Hide status from' : 'Share status with',
                  style: AppTextStyles.headingSm.copyWith(
                      color: Get.isDarkMode
                          ? CustomColor.kTextOnDark
                          : CustomColor.kTextPrimary),
                ),
              ),
              Divider(
                  height: 1,
                  color: Get.isDarkMode
                      ? CustomColor.kDarkDivider
                      : CustomColor.kLightBorder),
              Expanded(
                child: users.isEmpty
                    ? Center(
                        child: Text(
                          'No contacts found',
                          style: GoogleFonts.poppins(
                              color: CustomColor.kTextTertiary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: users.length,
                        itemBuilder: (ctx, i) {
                          final u = users[i];
                          final id = u.userId?.toString() ?? '';
                          return CheckboxListTile(
                            value: selected.contains(id),
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  selected.add(id);
                                } else {
                                  selected.remove(id);
                                }
                              });
                            },
                            secondary: CircleAvatar(
                              backgroundColor: CustomColor.kPrimaryColor
                                  .withValues(alpha: 0.1),
                              backgroundImage: (u.userImage?.isNotEmpty ??
                                      false)
                                  ? NetworkImage(
                                      '${Endpoints.mediaBaseUrl}${u.userImage}')
                                  : null,
                              onBackgroundImageError:
                                  (u.userImage?.isNotEmpty ?? false)
                                      ? (_, __) {}
                                      : null,
                              child: const Icon(Icons.person_rounded),
                            ),
                            title: Text(
                              '${u.userFirstName ?? ''} ${u.userLastName ?? ''}'
                                  .trim(),
                              style: AppTextStyles.bodyMd,
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: EdgeInsets.all(16.r),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        if (forExcept) {
                          _exceptIds = selected.map(int.parse).toList();
                        } else {
                          _shareIds = selected.map(int.parse).toList();
                        }
                      });
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColor.kPrimaryFill),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? CustomColor.kDarkBackground : CustomColor.kBackground,
      appBar: CommonAppBar(title: 'Status Privacy'),
      body: Obx(() {
        _loadFromController();
        return ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            _buildSection(
              isDark: isDark,
              title: 'Who can see my status',
              children: _options
                  .map((v) => _buildOption(
                        isDark: isDark,
                        icon: v.$2,
                        title: v.$3,
                        subtitle: v.$4,
                        isSelected: _selected == v.$1,
                        onTap: () {
                          _userTouched = true;
                          setState(() => _selected = v.$1);
                          if (v.$1 == 'contacts_except') {
                            _pickUsers(forExcept: true);
                          } else if (v.$1 == 'only_share') {
                            _pickUsers(forExcept: false);
                          }
                        },
                      ))
                  .toList(),
            ),
            if (_selected == 'contacts_except')
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  '${_exceptIds.length} contact(s) hidden',
                  style: AppTextStyles.bodySm
                      .copyWith(color: CustomColor.kTextTertiary),
                ),
              ),
            if (_selected == 'only_share')
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  '${_shareIds.length} contact(s) selected',
                  style: AppTextStyles.bodySm
                      .copyWith(color: CustomColor.kTextTertiary),
                ),
              ),
            SizedBox(height: 16.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: CustomColor.kPrimaryFill,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                ),
                child: _saving
                    ? SizedBox(
                        width: 20.w,
                        height: 20.h,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: CustomColor.kTextOnDark),
                      )
                    : Text('Save', style: AppTextStyles.titleMd),
              ),
            ),
            SizedBox(height: 24.h),
            _buildSection(
              isDark: isDark,
              title: 'Muted Users',
              subtitle: 'Status updates from muted users will be hidden',
              children: [
                Obx(() {
                  if (_statusController.mutedUsers.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Text(
                        'No muted users',
                        style: AppTextStyles.subtitle
                            .copyWith(color: CustomColor.kTextTertiary),
                      ),
                    );
                  }
                  return Column(
                    children: _statusController.mutedUsers
                        .map((u) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: CustomColor.kPrimaryFill,
                                child: Text(
                                  _initialOf(u['user_first_name']?.toString()),
                                  style: GoogleFonts.poppins(
                                      color: CustomColor.kTextOnDark),
                                ),
                              ),
                              title: Text(
                                '${u['user_first_name'] ?? ''} ${u['user_last_name'] ?? ''}'
                                    .trim(),
                                style: AppTextStyles.bodyMd,
                              ),
                              trailing: IconButton(
                                tooltip: 'Read receipts',
                                icon: const Icon(Icons.volume_up,
                                    color: CustomColor.kPrimaryColor),
                                onPressed: () => _statusController
                                    .muteUser(u['user_id'].toString()),
                              ),
                            ))
                        .toList(),
                  );
                }),
              ],
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSection({
    required bool isDark,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTextStyles.headingSm.copyWith(
                color: isDark
                    ? CustomColor.kTextOnDark
                    : CustomColor.kTextPrimary)),
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.only(top: 4.h),
            child: Text(subtitle,
                style: AppTextStyles.bodySm
                    .copyWith(color: CustomColor.kTextTertiary)),
          ),
        SizedBox(height: 8.h),
        ...children,
      ],
    );
  }

  String _initialOf(String? name) {
    final trimmed = (name ?? '').trim();
    return trimmed.isEmpty ? '?' : trimmed[0].toUpperCase();
  }

  Widget _buildOption({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.lg.r),
        ),
        child: Icon(icon, color: CustomColor.kPrimaryColor, size: 20.r),
      ),
      title: Text(title, style: AppTextStyles.bodyMd),
      subtitle: Text(subtitle,
          style:
              AppTextStyles.caption.copyWith(color: CustomColor.kTextTertiary)),
      trailing: Radio<String>(
          value: title, groupValue: _selected, onChanged: (_) => onTap()),
      onTap: onTap,
    );
  }
}
