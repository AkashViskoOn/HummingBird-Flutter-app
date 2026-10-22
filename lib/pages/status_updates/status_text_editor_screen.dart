import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/status_controller.dart';
import 'package:humming_bird/controllers/user_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/res/snackbar.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class StatusTextEditorScreen extends StatefulWidget {
  const StatusTextEditorScreen({super.key});

  @override
  State<StatusTextEditorScreen> createState() => _StatusTextEditorScreenState();
}

class _StatusTextEditorScreenState extends State<StatusTextEditorScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final TextEditingController _locationCtrl = TextEditingController();
  final TextEditingController _linkCtrl = TextEditingController();

  static const _bgColors = [
    CustomColor.kBlack,
    CustomColor.kInk800,
    CustomColor.kInk900,
    CustomColor.kBrandPurpleDeep,
    CustomColor.kBrandPurpleDeep,
    CustomColor.kBrandPurple,
    CustomColor.kDangerRed,
    CustomColor.kDangerRed,
    CustomColor.kDangerRed,
    CustomColor.kWarning,
    CustomColor.kWarningDark,
    CustomColor.kSuccess,
    CustomColor.kInfo,
    CustomColor.kInfo,
  ];

  static const _textColors = [
    CustomColor.kTextOnDark,
    Colors.black,
    CustomColor.kWarningSoft,
    CustomColor.kInfoSoft,
    CustomColor.kBrandPinkSoft,
    CustomColor.kSuccessSoft,
    CustomColor.kWarningSoft,
    CustomColor.kBrandPinkSoft,
  ];

  static const _emojis = [
    '😀',
    '😂',
    '😍',
    '😎',
    '🥳',
    '😢',
    '🔥',
    '❤️',
    '👍',
    '🙏',
    '✨',
    '🎉',
    '💯',
    '👋'
  ];

  static const _fontOptions = [
    ('Poppins', FontWeight.w500, 'poppins_regular'),
    ('Poppins Bold', FontWeight.w700, 'poppins_bold'),
    ('Lora', FontWeight.w400, 'lora'),
    ('Dancing Script', FontWeight.w500, 'dancing'),
    ('Pacifico', FontWeight.w400, 'pacifico'),
    ('Space Grotesk', FontWeight.w500, 'space'),
  ];

  int _bgIndex = 0;
  int _textColorIndex = 0;
  int _fontIndex = 0;
  final Set<String> _selectedMentions = {};
  bool _isUploading = false;

  StatusController get _statusCtrl => Get.find();

  TextStyle get _previewStyle {
    final font = _fontOptions[_fontIndex];
    switch (font.$3) {
      case 'lora':
        return GoogleFonts.lora(
          fontSize: 26.sp,
          fontWeight: font.$2,
          color: _textColors[_textColorIndex],
          height: 1.4,
        );
      case 'dancing':
        return GoogleFonts.dancingScript(
          fontSize: 30.sp,
          fontWeight: font.$2,
          color: _textColors[_textColorIndex],
          height: 1.3,
        );
      case 'pacifico':
        return GoogleFonts.pacifico(
          fontSize: 26.sp,
          fontWeight: font.$2,
          color: _textColors[_textColorIndex],
          height: 1.4,
        );
      case 'space':
        return GoogleFonts.spaceGrotesk(
          fontSize: 26.sp,
          fontWeight: font.$2,
          color: _textColors[_textColorIndex],
          height: 1.4,
        );
      default:
        return AppTextStyles.displayLarge
            .copyWith(color: _textColors[_textColorIndex], height: 1.4);
    }
  }

  Future<void> _share() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      CustomSnackbar.show(title: 'Error', message: 'Write something to share');
      return;
    }
    setState(() => _isUploading = true);
    try {
      final mentionIds = _selectedMentions.map(int.parse).toList();
      final result = await _statusCtrl.createUpdate(
        text,
        mediaType: 'text',
        bgColor:
            '#${_bgColors[_bgIndex].value.toRadixString(16).padLeft(8, '0').substring(2)}',
        fontStyle: _fontOptions[_fontIndex].$3,
        textColor:
            '#${_textColors[_textColorIndex].value.toRadixString(16).padLeft(8, '0').substring(2)}',
        location: _locationCtrl.text.trim().isEmpty
            ? null
            : _locationCtrl.text.trim(),
        link: _linkCtrl.text.trim().isEmpty ? null : _linkCtrl.text.trim(),
        mentions: mentionIds.isEmpty ? null : mentionIds,
      );
      if (result != null) {
        Get.back();
        CustomSnackbar.success(title: 'Success', message: 'Status shared');
      } else {
        CustomSnackbar.error(
            title: 'Failed', message: 'Could not share status');
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _pickMentions() async {
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

    Get.bottomSheet(
      isScrollControlled: true,
      Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Get.isDarkMode
              ? CustomColor.kDarkSurface
              : CustomColor.kTextOnDark,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xxl.r)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Text(
                  'Mention people',
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
                          final isSelected = _selectedMentions.contains(id);
                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedMentions.add(id);
                                } else {
                                  _selectedMentions.remove(id);
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
                    onPressed: () => Get.back(),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: CustomColor.kPrimaryFill),
                    child: Text('Done (${_selectedMentions.length})'),
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
  void dispose() {
    _textCtrl.dispose();
    _locationCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _barOn = CustomColor.onColor(_bgColors[_bgIndex]);
    return Scaffold(
      backgroundColor: _bgColors[_bgIndex],
      appBar: CommonAppBar(
        title: '',
        // The bar tracks the user's chosen status background, and those
        // swatches are not all dark. onColor() picks the label colour from the
        // swatch, so a light one no longer renders white-on-white.
        backgroundColor: _bgColors[_bgIndex],
        showBackButton: false,
        leading: IconButton(
          tooltip: 'Close',
          icon: Icon(Icons.close_rounded, color: _barOn),
          onPressed: () => Get.back(),
        ),
        actions: [
          _isUploading
              ? Padding(
                  padding: EdgeInsets.all(16.r),
                  child:
                      CircularProgressIndicator(color: _barOn, strokeWidth: 2),
                )
              : TextButton(
                  onPressed: _share,
                  child: Text(
                    'Share',
                    style: AppTextStyles.titleMd.copyWith(color: _barOn),
                  ),
                ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _textCtrl,
                maxLines: 6,
                autofocus: false,
                style: _previewStyle,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Type something...',
                  hintStyle: _previewStyle.copyWith(
                    color: CustomColor.kTextOnDark.withValues(alpha: 0.4),
                  ),
                  border: InputBorder.none,
                ),
              ),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 6.w,
                runSpacing: 6.h,
                children: _emojis.map((e) {
                  return GestureDetector(
                    onTap: () {
                      _textCtrl.text = _textCtrl.text + e;
                      _textCtrl.selection = TextSelection.collapsed(
                          offset: _textCtrl.text.length);
                      setState(() {});
                    },
                    child: Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: CustomColor.kTextOnDark.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.md.r),
                      ),
                      child: Text(e, style: TextStyle(fontSize: 18.sp)),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 20.h),
              _ToolLabel('Background'),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: List.generate(_bgColors.length, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _bgIndex = i),
                    child: Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: _bgColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _bgIndex == i
                              ? CustomColor.kTextOnDark
                              : CustomColor.kOverlay24,
                          width: _bgIndex == i ? 3 : 1,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 20.h),
              _ToolLabel('Font Style'),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: List.generate(_fontOptions.length, (i) {
                  final font = _fontOptions[i];
                  return GestureDetector(
                    onTap: () => setState(() => _fontIndex = i),
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: CustomColor.kTextOnDark
                            .withValues(alpha: _fontIndex == i ? 0.35 : 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.lg.r),
                        border: Border.all(
                          color: _fontIndex == i
                              ? CustomColor.kTextOnDark
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        font.$1,
                        style: AppTextStyles.bodySm
                            .copyWith(color: CustomColor.kTextOnDark),
                      ),
                    ),
                  );
                }),
              ),
              SizedBox(height: 20.h),
              _ToolLabel('Text Color'),
              SizedBox(height: 8.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: List.generate(_textColors.length, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _textColorIndex = i),
                    child: Container(
                      width: 32.r,
                      height: 32.r,
                      decoration: BoxDecoration(
                        color: _textColors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _textColorIndex == i
                              ? CustomColor.kTextOnDark
                              : CustomColor.kOverlay24,
                          width: _textColorIndex == i ? 3 : 1,
                        ),
                      ),
                      child: _textColorIndex == i
                          ? Icon(Icons.check_rounded,
                              size: 16.r,
                              color: _textColors[i].computeLuminance() > 0.5
                                  ? Colors.black
                                  : CustomColor.kTextOnDark)
                          : null,
                    ),
                  );
                }),
              ),
              SizedBox(height: 20.h),
              _ToolLabel('Mention People'),
              SizedBox(height: 8.h),
              GestureDetector(
                onTap: _pickMentions,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(AppRadius.xl.r),
                  decoration: BoxDecoration(
                    color: CustomColor.kTextOnDark.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.xl.r),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.alternate_email_rounded,
                          color: CustomColor.kTextOnDark, size: 20.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          _selectedMentions.isEmpty
                              ? 'Select people to mention'
                              : '${_selectedMentions.length} mentioned',
                          style: AppTextStyles.subtitle
                              .copyWith(color: CustomColor.kTextOnDark),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: CustomColor.kOverlay70),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              _ToolLabel('Location'),
              SizedBox(height: 8.h),
              TextField(
                controller: _locationCtrl,
                style: AppTextStyles.bodyMd
                    .copyWith(color: CustomColor.kTextOnDark),
                decoration: _inlineDecoration(
                    Icons.location_on_rounded, 'Add a location'),
              ),
              SizedBox(height: 16.h),
              _ToolLabel('Link'),
              SizedBox(height: 8.h),
              TextField(
                controller: _linkCtrl,
                style: AppTextStyles.bodyMd
                    .copyWith(color: CustomColor.kTextOnDark),
                decoration: _inlineDecoration(Icons.link_rounded, 'https://'),
                keyboardType: TextInputType.url,
              ),
              if (_selectedMentions.isNotEmpty) ...[
                SizedBox(height: 16.h),
                Text(
                  'Preview mentions',
                  style: AppTextStyles.caption
                      .copyWith(color: CustomColor.kOverlay54),
                ),
                SizedBox(height: 4.h),
                Text(
                  _selectedMentions.join(', '),
                  style: AppTextStyles.bodySm
                      .copyWith(color: CustomColor.kOverlay70),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inlineDecoration(IconData icon, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTextStyles.bodyMd.copyWith(color: CustomColor.kOverlay54),
      prefixIcon: Icon(icon, color: CustomColor.kOverlay54, size: 18.r),
      filled: true,
      fillColor: CustomColor.kOverlay12,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl.r),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _ToolLabel extends StatelessWidget {
  final String label;
  const _ToolLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.subtitle.copyWith(color: CustomColor.kOverlay70),
    );
  }
}
