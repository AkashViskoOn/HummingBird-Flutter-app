import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/controllers/chat_customization_controller.dart';
import 'package:humming_bird/components/chat_ui/brand_bubble_artwork.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class ChatCustomizationPage extends StatefulWidget {
  const ChatCustomizationPage({super.key});

  @override
  State<ChatCustomizationPage> createState() => _ChatCustomizationPageState();
}

class _ChatCustomizationPageState extends State<ChatCustomizationPage> {
  late ChatCustomizationController controller;

  static const _bubbleStyles = [
    _BubbleStyleOption(ChatCustomizationController.kStylePremium, 'Premium'),
    _BubbleStyleOption(ChatCustomizationController.kStyleModern, 'Classic'),
    _BubbleStyleOption(ChatCustomizationController.kStyleRounded, 'Rounded'),
    _BubbleStyleOption(ChatCustomizationController.kStyleMinimal, 'Minimal'),
    _BubbleStyleOption(ChatCustomizationController.kStyleWhatsapp, 'WhatsApp'),
    _BubbleStyleOption(ChatCustomizationController.kStyleCompact, 'Compact'),
  ];

  static const _accentOptions = [
    CustomColor.kPrimaryColor,
    CustomColor.kSuccess,
    CustomColor.kBrandPurple,
    CustomColor.kWarning,
    CustomColor.kDangerRed,
    CustomColor.kBrandPink,
  ];

  static const _sentColorOptions = [
    CustomColor.kPrimaryColor,
    CustomColor.kSuccess,
    CustomColor.kBrandPurple,
    CustomColor.kWarning,
    CustomColor.kDangerRed,
    CustomColor.kBrandPink,
  ];

  static const _receivedColorOptions = [
    CustomColor.kSurfaceTint,
    CustomColor.kWhite,
    CustomColor.kBrandPurpleSoft,
    CustomColor.kWarningSoft,
    CustomColor.kDangerSoft,
    CustomColor.kSurfaceTint,
  ];

  @override
  void initState() {
    super.initState();
    controller = Get.find();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Chat Customization'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GetBuilder<ChatCustomizationController>(
                builder: (_) {
                  return ListView(
                    padding: EdgeInsets.all(AppSpacing.page.w),
                    children: [
                      _buildLivePreview(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildBubbleStyleSection(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildMessageColorSection(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildTextColorSection(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildTypographySection(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildRadiusSection(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildPaddingSection(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildSizeSection(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildShadowSection(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildBorderSection(),
                      SizedBox(height: AppSpacing.xsection.h),
                      _buildBehaviorSection(),
                      SizedBox(height: AppSpacing.xl.h),
                      _buildResetButton(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl.w),
      decoration: BoxDecoration(
        color: CustomColor.kWhite,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        boxShadow: [
          BoxShadow(
            color: CustomColor.kPrimaryColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.titleMd.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.md.h),
          child,
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.titleMd.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── Live preview ────────────────────────────────────────────────────────────
  Widget _buildLivePreview() {
    return _buildSectionCard(
      title: 'Live Preview',
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md.w),
        decoration: BoxDecoration(
          color: CustomColor.kUltraLightBg,
          borderRadius: BorderRadius.circular(AppRadius.xl.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _previewBubble(isMe: false),
            _previewBubble(isMe: true),
          ],
        ),
      ),
    );
  }

  Widget _previewBubble({required bool isMe}) {
    return Flexible(
      child: Container(
        padding: controller.bubblePadding(isMe: isMe, isMedia: false),
        constraints: BoxConstraints(maxWidth: 0.38.sw),
        decoration: controller.bubbleDecoration(
          isMe: isMe,
          isSelected: false,
          isDark: false,
          isMedia: false,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMe ? 'Hey! How are you?' : 'I am good, thanks!',
              style: controller.messageTextStyle(isMe: isMe, isDark: false),
            ),
            SizedBox(height: 2.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '10:30 AM',
                style: controller.timestampStyle(isMe: isMe),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bubble style ────────────────────────────────────────────────────────────
  Widget _buildBubbleStyleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Bubble Style'),
        SizedBox(height: AppSpacing.md.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _bubbleStyles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: MediaQuery.sizeOf(context).width < 420 ? 2 : 3,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.35,
          ),
          itemBuilder: (context, index) {
            final option = _bubbleStyles[index];
            final selected = controller.bubbleStyle.value == option.key;
            final isPremium =
                option.key == ChatCustomizationController.kStylePremium;
            return Entrance(
                delayFactor: (index % 8) * 0.05,
                child: GestureDetector(
                  onTap: () {
                    controller.setBubbleStyle(option.key);
                    setState(() {});
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: CustomColor.kWhite,
                          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                          border: Border.all(
                            color: selected
                                ? CustomColor.kPrimaryColor
                                : CustomColor.kLightBorder,
                            width: selected ? 2.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: CustomColor.kPrimaryColor
                                  .withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _miniBubbleRow(controller),
                            SizedBox(height: AppSpacing.sm.h),
                            Text(
                              option.label,
                              style: AppTextStyles.label.copyWith(
                                fontSize: 10.sp,
                                fontWeight: isPremium
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? (isPremium
                                        ? CustomColor.kPrimaryDark
                                        : CustomColor.kPrimaryColor)
                                    : CustomColor.kTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isPremium)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              gradient: CustomColor.primaryGradient,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm.r),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 7,
                                fontWeight: FontWeight.w800,
                                color: CustomColor.kTextOnDark,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ));
          },
        ),
        if (controller.bubbleStyle.value ==
            ChatCustomizationController.kStylePremium)
          Padding(
            padding: EdgeInsets.only(top: AppSpacing.md.h),
            child: Container(
              padding: EdgeInsets.all(AppSpacing.md.w),
              decoration: BoxDecoration(
                color: CustomColor.kUltraLightPrimary,
                borderRadius: BorderRadius.circular(AppRadius.lg.r),
                border: Border.all(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_rounded,
                      color: CustomColor.kPrimaryColor, size: 20.r),
                  SizedBox(width: AppSpacing.sm.w),
                  Expanded(
                    child: Text(
                      'This is the new Humming Bird Premium bubble: '
                      'sky-blue gradient, iridescent gloss shine, '
                      'a signature wing tail and an elegant shadow.',
                      style: AppTextStyles.helper.copyWith(
                        color: CustomColor.kTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _miniBubbleRow(ChatCustomizationController cc) {
    final isPremium = cc.isPremiumStyle;
    final receivedTail =
        Color.lerp(cc.receivedColor, CustomColor.kTextOnDark, 0.55) ??
            CustomColor.kTextOnDark;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50.w,
                height: 14.h,
                decoration: cc.bubbleDecoration(
                  isMe: false,
                  isSelected: false,
                  isDark: false,
                  isMedia: false,
                ),
              ),
              if (isPremium)
                Positioned(
                  bottom: -5,
                  left: 3,
                  child: CustomPaint(
                    size: Size(10.r, 7.r),
                    painter:
                        _MiniWingTailPainter(color: receivedTail, isMe: false),
                  ),
                ),
            ],
          ),
          SizedBox(width: 6.w),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50.w,
                height: 14.h,
                decoration: cc.bubbleDecoration(
                  isMe: true,
                  isSelected: false,
                  isDark: false,
                  isMedia: false,
                ),
              ),
              if (isPremium)
                Positioned.fill(
                  child: BrandBubbleArtwork(
                    radius: cc.bubbleRadius(isMe: true),
                    markSize: 7,
                    markOpacity: 0.15,
                    markOffset: const EdgeInsets.only(top: 1.5, right: 2.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Message Bubble Colors'),
        SizedBox(height: AppSpacing.sm.h),
        _buildColorSection(
          'Sent Bubble',
          _sentColorOptions,
          controller.sentColor,
          (c) {
            controller.setSentColor(c);
            setState(() {});
          },
        ),
        SizedBox(height: AppSpacing.md.h),
        _buildColorSection(
          'Received Bubble',
          _receivedColorOptions,
          controller.receivedColor,
          (c) {
            controller.setReceivedColor(c);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildTextColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Accent Colors'),
        SizedBox(height: AppSpacing.sm.h),
        _buildColorSection(
          'Accent',
          _accentOptions,
          controller.accent,
          (c) {
            controller.setAccentColor(c);
            setState(() {});
          },
        ),
        SizedBox(height: AppSpacing.md.h),
        _buildColorSection(
          'Reactions',
          _accentOptions,
          controller.reaction,
          (c) {
            controller.setReactionColor(c);
            setState(() {});
          },
        ),
        SizedBox(height: AppSpacing.md.h),
        _buildColorSection(
          'Mentions',
          _accentOptions,
          controller.mention,
          (c) {
            controller.setMentionColor(c);
            setState(() {});
          },
        ),
        SizedBox(height: AppSpacing.md.h),
        _buildColorSection(
          'Reply',
          _receivedColorOptions,
          controller.replyTint,
          (c) {
            controller.setReplyColor(c);
            setState(() {});
          },
        ),
        SizedBox(height: AppSpacing.md.h),
        _buildColorSection(
          'Selection',
          _accentOptions,
          controller.selection,
          (c) {
            controller.setSelectionColor(c);
            setState(() {});
          },
        ),
      ],
    );
  }

  Widget _buildColorSection(
    String title,
    List<Color> options,
    Color selected,
    ValueChanged<Color> onSelect,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.label),
        SizedBox(height: AppSpacing.sm.h),
        Wrap(
          spacing: 14.w,
          runSpacing: 10.h,
          alignment: WrapAlignment.start,
          children: options.map((color) {
            final isSelected = selected.toARGB32() == color.toARGB32();
            return GestureDetector(
              onTap: () => onSelect(color),
              child: Container(
                width: 30.w,
                height: 30.w,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: CustomColor.kPrimaryColor, width: 3)
                      : Border.all(color: CustomColor.kLightBorder),
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: color.computeLuminance() > 0.5
                            ? CustomColor.kTextPrimary
                            : CustomColor.kWhite,
                        size: 14.r,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Controls ────────────────────────────────────────────────────────────────
  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.bodyMd),
            Text(
              display,
              style: AppTextStyles.label.copyWith(
                color: CustomColor.kPrimaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: CustomColor.kPrimaryColor,
          inactiveColor: CustomColor.kPrimaryLight,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchRow({
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.bodyMd),
              if (subtitle != null) ...[
                SizedBox(height: 2.h),
                Text(subtitle, style: AppTextStyles.helper),
              ],
            ],
          ),
        ),
        Switch(
          value: value,
          activeTrackColor: CustomColor.kPrimaryColor,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildChipSelector<T>({
    required String label,
    required List<T> options,
    required T selected,
    required ValueChanged<T> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        SizedBox(height: AppSpacing.xs.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options.map((o) {
            final isSelected = o == selected;
            return GestureDetector(
              onTap: () => onSelect(o),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? CustomColor.kPrimaryColor
                      : CustomColor.kUltraLightBg,
                  borderRadius: BorderRadius.circular(AppRadius.lg.r),
                  border: Border.all(
                    color: isSelected
                        ? CustomColor.kPrimaryColor
                        : CustomColor.kLightBorder,
                  ),
                ),
                child: Text(
                  o.toString(),
                  style: AppTextStyles.labelSm.copyWith(
                    color: isSelected
                        ? CustomColor.kTextOnDark
                        : CustomColor.kTextPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSegmented<T>({
    required List<_Label<T>> options,
    required T selected,
    required ValueChanged<T> onSelect,
  }) {
    return Row(
      children: options.map((o) {
        final isSelected = o.value == selected;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: InkWell(
              onTap: () => onSelect(o.value),
              borderRadius: BorderRadius.circular(AppRadius.lg.r),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? CustomColor.kPrimaryColor
                      : CustomColor.kUltraLightBg,
                  borderRadius: BorderRadius.circular(AppRadius.lg.r),
                ),
                child: Text(
                  o.label,
                  style: AppTextStyles.labelSm.copyWith(
                    color: isSelected
                        ? CustomColor.kTextOnDark
                        : CustomColor.kTextPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.label.copyWith(
        color: CustomColor.kTextSecondary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  // ── Typography ──────────────────────────────────────────────────────────────
  Widget _buildTypographySection() {
    return _buildSectionCard(
      title: 'Typography',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChipSelector<String>(
            label: 'Font Family',
            options: ChatCustomizationController.fontFamilies,
            selected: controller.fontFamily.value,
            onSelect: (v) {
              controller.setFontFamily(v);
              setState(() {});
            },
          ),
          SizedBox(height: AppSpacing.md.h),
          _buildSliderRow(
            label: 'Message Size',
            value: controller.fontSize.value,
            min: 12,
            max: 22,
            divisions: 10,
            display: '${controller.fontSize.value.round()}',
            onChanged: (v) {
              controller.setFontSize(v);
              setState(() {});
            },
          ),
          _buildSliderRow(
            label: 'Timestamp Size',
            value: controller.timestampSize.value,
            min: 8,
            max: 16,
            divisions: 8,
            display: '${controller.timestampSize.value.round()}',
            onChanged: (v) {
              controller.setTimestampSize(v);
              setState(() {});
            },
          ),
          _buildSliderRow(
            label: 'Sender Name Size',
            value: controller.senderNameSize.value,
            min: 9,
            max: 16,
            divisions: 7,
            display: '${controller.senderNameSize.value.round()}',
            onChanged: (v) {
              controller.setSenderNameSize(v);
              setState(() {});
            },
          ),
          _buildSliderRow(
            label: 'Reply Preview Size',
            value: controller.replySize.value,
            min: 9,
            max: 16,
            divisions: 7,
            display: '${controller.replySize.value.round()}',
            onChanged: (v) {
              controller.setReplySize(v);
              setState(() {});
            },
          ),
          SizedBox(height: AppSpacing.md.h),
          _buildLabel('Font Weight'),
          SizedBox(height: AppSpacing.xs.h),
          _buildSegmented<String>(
            options: [
              for (final w in ChatCustomizationController.fontWeights)
                _Label(w, w[0].toUpperCase() + w.substring(1)),
            ],
            selected: controller.fontWeight.value,
            onSelect: (v) {
              controller.setFontWeight(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  // ── Shape ───────────────────────────────────────────────────────────────────
  Widget _buildRadiusSection() {
    return _buildSectionCard(
      title: 'Bubble Shape',
      child: Column(
        children: [
          _buildSliderRow(
            label: 'Top Corner Radius',
            value: controller.bubbleRadiusTop.value,
            min: 0,
            max: 32,
            divisions: 16,
            display: '${controller.bubbleRadiusTop.value.round()}',
            onChanged: (v) {
              controller.setRadiusTop(v);
              setState(() {});
            },
          ),
          _buildSliderRow(
            label: 'Bottom Corner Radius',
            value: controller.bubbleRadiusBottom.value,
            min: 0,
            max: 32,
            divisions: 16,
            display: '${controller.bubbleRadiusBottom.value.round()}',
            onChanged: (v) {
              controller.setRadiusBottom(v);
              setState(() {});
            },
          ),
          SizedBox(height: AppSpacing.sm.h),
          _buildLabel('Chat Density'),
          SizedBox(height: AppSpacing.xs.h),
          _buildSegmented<String>(
            options: const [
              _Label('compact', 'Compact'),
              _Label('comfortable', 'Comfort'),
              _Label('cozy', 'Cozy'),
            ],
            selected: controller.chatDensity.value,
            onSelect: (v) {
              controller.setDensity(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaddingSection() {
    return _buildSectionCard(
      title: 'Bubble Padding',
      child: Column(
        children: [
          _buildSliderRow(
            label: 'Horizontal Padding',
            value: controller.bubblePaddingH.value,
            min: 4,
            max: 26,
            divisions: 11,
            display: '${controller.bubblePaddingH.value.round()}',
            onChanged: (v) {
              controller.setPaddingH(v);
              setState(() {});
            },
          ),
          _buildSliderRow(
            label: 'Vertical Padding',
            value: controller.bubblePaddingV.value,
            min: 2,
            max: 22,
            divisions: 10,
            display: '${controller.bubblePaddingV.value.round()}',
            onChanged: (v) {
              controller.setPaddingV(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSizeSection() {
    return _buildSectionCard(
      title: 'Size & Layout',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Message Width'),
          SizedBox(height: AppSpacing.xs.h),
          _buildSegmented<String>(
            options: const [
              _Label('small', 'Small'),
              _Label('medium', 'Medium'),
              _Label('large', 'Large'),
              _Label('full', 'Full'),
            ],
            selected: controller.messageWidth.value,
            onSelect: (v) {
              controller.setMessageWidth(v);
              setState(() {});
            },
          ),
          SizedBox(height: AppSpacing.md.h),
          _buildSliderRow(
            label: 'Avatar Size',
            value: controller.avatarSize.value,
            min: 20,
            max: 44,
            divisions: 12,
            display: '${controller.avatarSize.value.round()}',
            onChanged: (v) {
              controller.setAvatarSize(v);
              setState(() {});
            },
          ),
          _buildSliderRow(
            label: 'Emoji Size',
            value: controller.emojiSize.value,
            min: 10,
            max: 22,
            divisions: 12,
            display: '${controller.emojiSize.value.round()}',
            onChanged: (v) {
              controller.setEmojiSize(v);
              setState(() {});
            },
          ),
          SizedBox(height: AppSpacing.md.h),
          _buildLabel('Timestamp Position'),
          SizedBox(height: AppSpacing.xs.h),
          _buildSegmented<String>(
            options: const [
              _Label('top', 'Top'),
              _Label('bottom', 'Bottom'),
            ],
            selected: controller.timestampPosition.value,
            onSelect: (v) {
              controller.setTimestampPosition(v);
              setState(() {});
            },
          ),
          SizedBox(height: AppSpacing.md.h),
          _buildLabel('Timestamp Placement'),
          SizedBox(height: AppSpacing.xs.h),
          _buildSegmented<String>(
            options: const [
              _Label('inside', 'Inside'),
              _Label('outside', 'Outside'),
            ],
            selected: controller.timestampPlacement.value,
            onSelect: (v) {
              controller.setTimestampPlacement(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShadowSection() {
    return _buildSectionCard(
      title: 'Shadow',
      child: Column(
        children: [
          _buildSwitchRow(
            label: 'Enable Shadow',
            value: controller.shadowEnabled.value,
            onChanged: (v) {
              controller.setShadowEnabled(v);
              setState(() {});
            },
          ),
          if (controller.shadowEnabled.value) ...[
            _buildSliderRow(
              label: 'Intensity',
              value: controller.shadowStrength.value,
              min: 0.02,
              max: 0.6,
              divisions: 29,
              display: '${(controller.shadowStrength.value * 100).round()}',
              onChanged: (v) {
                controller.setShadowStrength(v);
                setState(() {});
              },
            ),
            _buildSliderRow(
              label: 'Blur',
              value: controller.shadowBlur.value,
              min: 0,
              max: 24,
              divisions: 12,
              display: '${controller.shadowBlur.value.round()}',
              onChanged: (v) {
                controller.setShadowBlur(v);
                setState(() {});
              },
            ),
            _buildSliderRow(
              label: 'Drop Offset',
              value: controller.shadowOffsetY.value,
              min: 0,
              max: 12,
              divisions: 12,
              display: '${controller.shadowOffsetY.value.round()}',
              onChanged: (v) {
                controller.setShadowOffset(v);
                setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBorderSection() {
    return _buildSectionCard(
      title: 'Border',
      child: Column(
        children: [
          _buildSwitchRow(
            label: 'Enable Border',
            value: controller.borderEnabled.value,
            onChanged: (v) {
              controller.setBorderEnabled(v);
              setState(() {});
            },
          ),
          if (controller.borderEnabled.value) ...[
            _buildSliderRow(
              label: 'Border Width',
              value: controller.borderWidth.value,
              min: 0.5,
              max: 3,
              divisions: 5,
              display: controller.borderWidth.value.toStringAsFixed(1),
              onChanged: (v) {
                controller.setBorderWidth(v);
                setState(() {});
              },
            ),
            SizedBox(height: AppSpacing.sm.h),
            _buildColorSection(
              'Border Color',
              const [
                CustomColor.kSurfaceTintStrong,
                CustomColor.kPrimaryColor,
                CustomColor.kDarkSurface3,
                CustomColor.kSlate400,
              ],
              Color(controller.borderColor.value),
              (c) {
                controller.setBorderColor(c);
                setState(() {});
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBehaviorSection() {
    return _buildSectionCard(
      title: 'Behavior',
      child: Column(
        children: [
          _buildSwitchRow(
            label: 'Read Receipts (ticks)',
            subtitle: 'Show seen/delivered ticks on sent messages',
            value: controller.showReadReceipts.value,
            onChanged: (v) {
              controller.setShowReadReceipts(v);
              setState(() {});
            },
          ),
          _buildColorSection(
            'Tick Color',
            _accentOptions,
            controller.tick,
            (c) {
              controller.setTickColor(c);
              setState(() {});
            },
          ),
          SizedBox(height: AppSpacing.md.h),
          _buildSwitchRow(
            label: 'Send on Enter',
            value: controller.enterSends.value,
            onChanged: (v) {
              controller.setEnterSends(v);
              setState(() {});
            },
          ),
          SizedBox(height: AppSpacing.md.h),
          _buildSwitchRow(
            label: 'Shake to Send',
            subtitle: 'Shake your phone to fast-send typed messages',
            value: controller.shakeToSend.value,
            onChanged: (v) {
              controller.setShakeToSend(v);
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton() {
    return OutlinedButton.icon(
      onPressed: () {
        controller.resetAll();
        setState(() {});
      },
      icon: Icon(Icons.refresh_rounded, size: 18.r),
      label: const Text('Reset Customization'),
      style: OutlinedButton.styleFrom(
        foregroundColor: CustomColor.kDangerRed,
        side: BorderSide(color: CustomColor.kDangerRed.withValues(alpha: 0.3)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        ),
        padding: EdgeInsets.symmetric(vertical: 14.h),
      ),
    );
  }
}

class _BubbleStyleOption {
  final String key;
  final String label;
  const _BubbleStyleOption(this.key, this.label);
}

class _MiniWingTailPainter extends CustomPainter {
  final Color color;
  final bool isMe;

  const _MiniWingTailPainter({required this.color, required this.isMe});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (isMe) {
      path.moveTo(0, 0);
      path.cubicTo(
        size.width * 0.85,
        size.height * 0.05,
        size.width * 1.0,
        size.height * 0.5,
        size.width * 0.82,
        size.height * 0.92,
      );
      path.quadraticBezierTo(
        size.width * 0.45,
        size.height * 1.0,
        0,
        size.height,
      );
    } else {
      path.moveTo(size.width, 0);
      path.cubicTo(
        size.width * 0.15,
        size.height * 0.05,
        0,
        size.height * 0.5,
        size.width * 0.18,
        size.height * 0.92,
      );
      path.quadraticBezierTo(
        size.width * 0.55,
        size.height * 1.0,
        size.width,
        size.height,
      );
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _MiniWingTailPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.isMe != isMe;
  }
}

class _Label<T> {
  final T value;
  final String label;
  const _Label(this.value, this.label);
}
