import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:humming_bird/res/colors.dart';

class ChatCustomizationController extends GetxController {
  ChatCustomizationController() : _storage = GetStorage();

  final GetStorage _storage;

  // ── Bubble Style ────────────────────────────────────────────────────────────
  static const kStylePremium = 'premium';
  static const kStyleModern = 'modern';
  static const kStyleRounded = 'rounded';
  static const kStyleMinimal = 'minimal';
  static const kStyleWhatsapp = 'whatsapp';
  static const kStyleCompact = 'compact';

  final RxString bubbleStyle = kStylePremium.obs;
  final RxInt bubbleSentColor = CustomColor.kSentBubble1.toARGB32().obs;
  final RxInt bubbleReceivedColor = CustomColor.kReceivedBubble.toARGB32().obs;
  final RxDouble bubbleRadiusTop = 16.0.obs;
  final RxDouble bubbleRadiusBottom = 16.0.obs;
  final RxDouble bubblePaddingH = 14.0.obs;
  final RxDouble bubblePaddingV = 8.0.obs;
  final RxString chatDensity = 'comfortable'.obs;
  final RxString messageWidth = 'medium'.obs;
  final RxBool shadowEnabled = true.obs;
  final RxDouble shadowStrength = 0.18.obs;
  final RxDouble shadowBlur = 8.0.obs;
  final RxDouble shadowOffsetY = 3.0.obs;
  final RxBool borderEnabled = false.obs;
  final RxDouble borderWidth = 1.0.obs;
  final RxInt borderColor = CustomColor.kLightBorder.toARGB32().obs;
  final RxDouble avatarSize = 28.0.obs;

  // ── Typography ──────────────────────────────────────────────────────────────
  final RxString fontFamily = 'System'.obs;
  final RxDouble fontSize = 14.0.obs;
  final RxString fontWeight = 'regular'.obs;
  final RxDouble timestampSize = 10.5.obs;
  final RxDouble senderNameSize = 11.0.obs;
  final RxDouble replySize = 11.0.obs;

  // ── Theme Colors ────────────────────────────────────────────────────────────
  final RxInt accentColor = CustomColor.kPrimaryColor.toARGB32().obs;
  final RxInt reactionColor = CustomColor.kPrimaryColor.toARGB32().obs;
  final RxInt mentionColor = CustomColor.kPrimaryColor.toARGB32().obs;
  final RxInt replyColor = CustomColor.kUltraLightPrimary.toARGB32().obs;
  final RxInt selectionColor = CustomColor.kPrimaryColor.toARGB32().obs;

  // ── Behavior ────────────────────────────────────────────────────────────────
  final RxBool showReadReceipts = true.obs;
  final RxInt tickColor = CustomColor.kPrimaryColor.toARGB32().obs;
  final RxString timestampPosition = 'bottom'.obs;
  final RxString timestampPlacement = 'inside'.obs;
  final RxDouble emojiSize = 13.0.obs;
  final RxBool enterSends = true.obs;
  final RxBool shakeToSend = false.obs;

  // ── Wallpaper ───────────────────────────────────────────────────────────────
  final RxString wallpaperColorHex = ''.obs;
  final RxString wallpaperGradientKey = ''.obs;
  final RxString wallpaperCustomPath = ''.obs;
  final RxBool wallpaperGlobal = true.obs;
  final RxDouble wallpaperBlur = 0.0.obs;
  final RxDouble wallpaperOpacity = 1.0.obs;

  static const _wallpaperGradients = <String, List<Color>>{
    'none': [],
    'cloud': [CustomColor.kSurfaceTintStrong, CustomColor.kSurfaceTintMuted],
    'ocean': [CustomColor.kInfoSoft, CustomColor.kSurfaceTint],
    'mint': [CustomColor.kSuccessSoft, CustomColor.kSurfaceTint],
    'sunset': [CustomColor.kWarningSoft, CustomColor.kWarningSoft],
    'lavender': [CustomColor.kBrandPurpleSoft, CustomColor.kSurfaceTintMuted],
    'midnight': [CustomColor.kDarkSurface, CustomColor.kDarkSurfaceAlt],
    'forest': [CustomColor.kSuccessDeep, CustomColor.kSuccessDeep],
    'rose': [CustomColor.kBrandPinkSoft, CustomColor.kBrandPinkSoft],
  };

  static const fontFamilies = [
    'System',
    'Poppins',
    'Roboto',
    'Nunito',
    'Inter',
    'OpenSans',
    'Montserrat',
    'SpaceGrotesk',
  ];

  static const fontWeights = ['regular', 'medium', 'semibold', 'bold'];

  @override
  void onInit() {
    super.onInit();
    _loadAll();
  }

  void _loadAll() {
    final style = _storage.read<String>('bubble_style');
    const validStyles = [
      kStylePremium,
      kStyleModern,
      kStyleRounded,
      kStyleMinimal,
      kStyleWhatsapp,
      kStyleCompact,
    ];
    if (style == null || style == 'outlined' || !validStyles.contains(style)) {
      bubbleStyle.value = kStylePremium;
      _storage.write('bubble_style', bubbleStyle.value);
    } else {
      bubbleStyle.value = style;
    }

    bubbleSentColor.value =
        _storedInt('bubble_sent_color', CustomColor.kSentBubble1.toARGB32());
    bubbleReceivedColor.value = _storedInt(
        'bubble_received_color', CustomColor.kReceivedBubble.toARGB32());
    fontSize.value = _storedDouble('chat_font_size', 14.0);
    enterSends.value = _storedBool('enter_sends', true);
    shakeToSend.value = _storedBool('shake_send', false);

    bubbleRadiusTop.value = _storedDouble('cc_bubble_radius_top', 16.0);
    bubbleRadiusBottom.value = _storedDouble('cc_bubble_radius_bottom', 16.0);
    bubblePaddingH.value = _storedDouble('cc_bubble_padding_h', 14.0);
    bubblePaddingV.value = _storedDouble('cc_bubble_padding_v', 8.0);
    chatDensity.value = _storage.read('cc_chat_density') ?? 'comfortable';
    messageWidth.value = _storage.read('cc_message_width') ?? 'medium';
    shadowEnabled.value = _storedBool('cc_shadow_enabled', true);
    shadowStrength.value = _storedDouble('cc_shadow_strength', 0.18);
    shadowBlur.value = _storedDouble('cc_shadow_blur', 8.0);
    shadowOffsetY.value = _storedDouble('cc_shadow_offset', 3.0);
    borderEnabled.value = _storedBool('cc_border_enabled', false);
    borderWidth.value = _storedDouble('cc_border_width', 1.0);
    borderColor.value =
        _storedInt('cc_border_color', CustomColor.kLightBorder.toARGB32());
    avatarSize.value = _storedDouble('cc_avatar_size', 28.0);

    fontFamily.value = _storage.read('cc_font_family') ?? 'System';
    fontWeight.value = _storage.read('cc_font_weight') ?? 'regular';
    timestampSize.value = _storedDouble('cc_timestamp_size', 10.5);
    senderNameSize.value = _storedDouble('cc_sender_name_size', 11.0);
    replySize.value = _storedDouble('cc_reply_size', 11.0);

    accentColor.value =
        _storedInt('cc_accent_color', CustomColor.kPrimaryColor.toARGB32());
    reactionColor.value =
        _storedInt('cc_reaction_color', CustomColor.kPrimaryColor.toARGB32());
    mentionColor.value =
        _storedInt('cc_mention_color', CustomColor.kPrimaryColor.toARGB32());
    replyColor.value =
        _storedInt('cc_reply_color', CustomColor.kUltraLightPrimary.toARGB32());
    selectionColor.value =
        _storedInt('cc_selection_color', CustomColor.kPrimaryColor.toARGB32());

    showReadReceipts.value = _storedBool('cc_show_read_receipts', true);
    tickColor.value =
        _storedInt('cc_tick_color', CustomColor.kPrimaryColor.toARGB32());
    timestampPosition.value =
        _storage.read('cc_timestamp_position') ?? 'bottom';
    timestampPlacement.value =
        _storage.read('cc_timestamp_placement') ?? 'inside';
    emojiSize.value = _storedDouble('cc_emoji_size', 13.0);

    wallpaperColorHex.value = _storage.read('chat_wallpaper') ?? '';
    wallpaperGradientKey.value = _storage.read('cc_wallpaper_gradient') ?? '';
    wallpaperCustomPath.value = _storage.read('chat_wallpaper_custom') ?? '';
    wallpaperGlobal.value = _storedBool('wallpaper_global', true);
    wallpaperBlur.value = _storedDouble('cc_wallpaper_blur', 0.0);
    wallpaperOpacity.value = _storedDouble('cc_wallpaper_opacity', 1.0);
  }

  double _storedDouble(String key, double fallback) {
    final v = _storage.read(key);
    return v is num ? v.toDouble() : fallback;
  }

  bool _storedBool(String key, bool fallback) {
    final v = _storage.read(key);
    return v is bool ? v : fallback;
  }

  int _storedInt(String key, int fallback) {
    final v = _storage.read(key);
    return v is num ? v.toInt() : fallback;
  }

  void _save(String key, dynamic value) => _storage.write(key, value);

  // ── Style setters ───────────────────────────────────────────────────────────
  void setBubbleStyle(String style) {
    bubbleStyle.value = style;
    _save('bubble_style', style);
  }

  void setSentColor(Color color) {
    bubbleSentColor.value = color.toARGB32();
    _save('bubble_sent_color', bubbleSentColor.value);
  }

  void setReceivedColor(Color color) {
    bubbleReceivedColor.value = color.toARGB32();
    _save('bubble_received_color', bubbleReceivedColor.value);
  }

  void setRadiusTop(double value) {
    bubbleRadiusTop.value = value;
    _save('cc_bubble_radius_top', value);
  }

  void setRadiusBottom(double value) {
    bubbleRadiusBottom.value = value;
    _save('cc_bubble_radius_bottom', value);
  }

  void setPaddingH(double value) {
    bubblePaddingH.value = value;
    _save('cc_bubble_padding_h', value);
  }

  void setPaddingV(double value) {
    bubblePaddingV.value = value;
    _save('cc_bubble_padding_v', value);
  }

  void setDensity(String density) {
    chatDensity.value = density;
    _save('cc_chat_density', density);
  }

  void setMessageWidth(String width) {
    messageWidth.value = width;
    _save('cc_message_width', width);
  }

  void setShadowEnabled(bool value) {
    shadowEnabled.value = value;
    _save('cc_shadow_enabled', value);
  }

  void setShadowStrength(double value) {
    shadowStrength.value = value;
    _save('cc_shadow_strength', value);
  }

  void setShadowBlur(double value) {
    shadowBlur.value = value;
    _save('cc_shadow_blur', value);
  }

  void setShadowOffset(double value) {
    shadowOffsetY.value = value;
    _save('cc_shadow_offset', value);
  }

  void setBorderEnabled(bool value) {
    borderEnabled.value = value;
    _save('cc_border_enabled', value);
  }

  void setBorderWidth(double value) {
    borderWidth.value = value;
    _save('cc_border_width', value);
  }

  void setBorderColor(Color color) {
    borderColor.value = color.toARGB32();
    _save('cc_border_color', borderColor.value);
  }

  void setAvatarSize(double value) {
    avatarSize.value = value;
    _save('cc_avatar_size', value);
  }

  void setFontFamily(String family) {
    fontFamily.value = family;
    _save('cc_font_family', family);
  }

  void setFontSize(double value) {
    fontSize.value = value;
    _save('chat_font_size', value);
  }

  void setFontWeight(String weight) {
    fontWeight.value = weight;
    _save('cc_font_weight', weight);
  }

  void setTimestampSize(double value) {
    timestampSize.value = value;
    _save('cc_timestamp_size', value);
  }

  void setSenderNameSize(double value) {
    senderNameSize.value = value;
    _save('cc_sender_name_size', value);
  }

  void setReplySize(double value) {
    replySize.value = value;
    _save('cc_reply_size', value);
  }

  void setAccentColor(Color color) {
    accentColor.value = color.toARGB32();
    _save('cc_accent_color', accentColor.value);
  }

  void setReactionColor(Color color) {
    reactionColor.value = color.toARGB32();
    _save('cc_reaction_color', reactionColor.value);
  }

  void setMentionColor(Color color) {
    mentionColor.value = color.toARGB32();
    _save('cc_mention_color', mentionColor.value);
  }

  void setReplyColor(Color color) {
    replyColor.value = color.toARGB32();
    _save('cc_reply_color', replyColor.value);
  }

  void setSelectionColor(Color color) {
    selectionColor.value = color.toARGB32();
    _save('cc_selection_color', selectionColor.value);
  }

  void setShowReadReceipts(bool value) {
    showReadReceipts.value = value;
    _save('cc_show_read_receipts', value);
  }

  void setTickColor(Color color) {
    tickColor.value = color.toARGB32();
    _save('cc_tick_color', tickColor.value);
  }

  void setTimestampPosition(String position) {
    timestampPosition.value = position;
    _save('cc_timestamp_position', position);
  }

  void setTimestampPlacement(String placement) {
    timestampPlacement.value = placement;
    _save('cc_timestamp_placement', placement);
  }

  void setEmojiSize(double value) {
    emojiSize.value = value;
    _save('cc_emoji_size', value);
  }

  void setEnterSends(bool value) {
    enterSends.value = value;
    _save('enter_sends', value);
  }

  void setShakeToSend(bool value) {
    shakeToSend.value = value;
    _save('shake_send', value);
  }

  // ── Wallpaper ───────────────────────────────────────────────────────────────
  void setWallpaperColor(String hex) {
    wallpaperColorHex.value = hex;
    wallpaperGradientKey.value = '';
    wallpaperCustomPath.value = '';
    _save('chat_wallpaper', hex);
    _storage.remove('cc_wallpaper_gradient');
    _storage.remove('chat_wallpaper_custom');
  }

  void setWallpaperGradient(String key) {
    wallpaperGradientKey.value = key;
    wallpaperColorHex.value = '';
    wallpaperCustomPath.value = '';
    _save('cc_wallpaper_gradient', key);
    _storage.remove('chat_wallpaper');
    _storage.remove('chat_wallpaper_custom');
  }

  void setWallpaperCustom(String path) {
    wallpaperCustomPath.value = path;
    wallpaperColorHex.value = '';
    wallpaperGradientKey.value = '';
    _save('chat_wallpaper_custom', path);
    _storage.remove('chat_wallpaper');
    _storage.remove('cc_wallpaper_gradient');
  }

  /// Copies a picked image to a persistent app directory so the path survives
  /// temp-file cleanup by the OS.  Returns the new persistent path, or the
  /// original path if the copy fails.
  Future<String> persistWallpaperImage(String tempPath) async {
    try {
      final src = File(tempPath);
      if (!await src.exists()) return tempPath;
      final docs = await getApplicationDocumentsDirectory();
      final wallDir = Directory('${docs.path}/wallpapers');
      if (!await wallDir.exists()) await wallDir.create(recursive: true);
      final ext = tempPath.split('.').lastOrNull ?? 'jpg';
      final dest = File('${wallDir.path}/chat_wallpaper.$ext');
      await src.copy(dest.path);
      setWallpaperCustom(dest.path);
      return dest.path;
    } catch (_) {
      setWallpaperCustom(tempPath);
      return tempPath;
    }
  }

  void setWallpaperGlobal(bool value) {
    wallpaperGlobal.value = value;
    _save('wallpaper_global', value);
  }

  void setWallpaperBlur(double value) {
    wallpaperBlur.value = value;
    _save('cc_wallpaper_blur', value);
  }

  void setWallpaperOpacity(double value) {
    wallpaperOpacity.value = value;
    _save('cc_wallpaper_opacity', value);
  }

  void resetWallpaper() {
    wallpaperColorHex.value = '';
    wallpaperGradientKey.value = '';
    wallpaperCustomPath.value = '';
    wallpaperBlur.value = 0;
    wallpaperOpacity.value = 1;
    wallpaperGlobal.value = true;
    _storage.remove('chat_wallpaper');
    _storage.remove('cc_wallpaper_gradient');
    _storage.remove('chat_wallpaper_custom');
    _storage.remove('cc_wallpaper_blur');
    _storage.remove('cc_wallpaper_opacity');
    _storage.remove('wallpaper_global');
  }

  void resetAll() {
    setBubbleStyle(kStylePremium);
    setSentColor(CustomColor.kSentBubble1);
    setReceivedColor(CustomColor.kReceivedBubble);
    setRadiusTop(16);
    setRadiusBottom(16);
    setPaddingH(14);
    setPaddingV(8);
    setDensity('comfortable');
    setMessageWidth('medium');
    setShadowEnabled(true);
    setShadowStrength(0.18);
    setShadowBlur(8);
    setShadowOffset(3);
    setBorderEnabled(false);
    setBorderWidth(1);
    setBorderColor(CustomColor.kLightBorder);
    setAvatarSize(28);
    setFontFamily('System');
    setFontSize(14);
    setFontWeight('regular');
    setTimestampSize(10.5);
    setSenderNameSize(11);
    setReplySize(11);
    setAccentColor(CustomColor.kPrimaryColor);
    setReactionColor(CustomColor.kPrimaryColor);
    setMentionColor(CustomColor.kPrimaryColor);
    setReplyColor(CustomColor.kUltraLightPrimary);
    setSelectionColor(CustomColor.kPrimaryColor);
    setShowReadReceipts(true);
    setTickColor(CustomColor.kPrimaryColor);
    setTimestampPosition('bottom');
    setTimestampPlacement('inside');
    setEmojiSize(13);
    setEnterSends(true);
    setShakeToSend(false);
    resetWallpaper();
  }

  // ── Derived values ──────────────────────────────────────────────────────────
  bool get isPremiumStyle => bubbleStyle.value == kStylePremium;

  Color get sentColor => Color(bubbleSentColor.value);

  /// True when the user explicitly picked a sent bubble color.
  bool get sentColorCustomized => _storage.hasData('bubble_sent_color');

  /// Effective sent bubble base — light brand blue unless the user chose a
  /// custom color.
  Color get effectiveSentBase =>
      sentColorCustomized ? sentColor : CustomColor.kPrimaryLight;

  Color get receivedColor => Color(bubbleReceivedColor.value);

  Color get sentGradientEnd => _sentGradientEnd(sentColor);

  /// True when the outgoing bubble is light (default signature bubble, or a
  /// user-chosen light sent color) — drives text/timestamp/tick contrast.
  bool get isSentBubbleLight =>
      isPremiumStyle ||
      !sentColorCustomized ||
      sentColor.computeLuminance() > 0.45;

  Color get sentTextColor =>
      isSentBubbleLight ? CustomColor.kTextPrimary : CustomColor.kTextOnDark;

  Color get sentTimestampColor => isSentBubbleLight
      ? CustomColor.kTextTertiary
      : CustomColor.kTextOnDark.withValues(alpha: 0.75);

  /// Bubble tail color — matches the light signature gradient, otherwise the
  /// gradient end of the user's sent color.
  Color get sentTailColor => isPremiumStyle || !sentColorCustomized
      ? CustomColor.kPrimaryLight
      : sentGradientEnd;

  Color get accent => Color(accentColor.value);

  Color get reaction => Color(reactionColor.value);

  Color get mention => Color(mentionColor.value);

  Color get replyTint => Color(replyColor.value);

  Color get selection => Color(selectionColor.value);

  Color get tick => Color(tickColor.value);

  double get densityFactor => switch (chatDensity.value) {
        'compact' => 0.8,
        'cozy' => 1.25,
        _ => 1.0,
      };

  double get maxWidthFactor => switch (messageWidth.value) {
        'small' => 0.55,
        'large' => 0.85,
        'full' => 0.95,
        _ => 0.72,
      };

  FontWeight get messageWeight => switch (fontWeight.value) {
        'medium' => FontWeight.w500,
        'semibold' => FontWeight.w600,
        'bold' => FontWeight.w700,
        _ => FontWeight.w400,
      };

  TextStyle _withFamily(TextStyle base) {
    if (fontFamily.value == 'System') return base;
    final g = GoogleFonts.getFont(
      fontFamily.value,
      textStyle: base,
    );
    return g;
  }

  Color receivedBubbleColor(bool isDark) {
    final isCustom = _storage.hasData('bubble_received_color');
    if (isCustom) return receivedColor;
    return isDark
        ? CustomColor.kReceivedBubbleDark
        : CustomColor.kReceivedBubble;
  }

  /// True when the incoming bubble is light (default #F0F4FA, or a light
  /// user-chosen color) — drives text/timestamp contrast.
  bool isReceivedBubbleLight(bool isDark) =>
      receivedBubbleColor(isDark).computeLuminance() > 0.45;

  Color _sentGradientEnd(Color base) =>
      Color.lerp(base, CustomColor.kTextOnDark, 0.22) ?? base;

  BorderRadius bubbleRadius({required bool isMe}) {
    final top = bubbleRadiusTop.value.r;
    final bottom = bubbleRadiusBottom.value.r;
    switch (bubbleStyle.value) {
      case kStylePremium:
        if (isMe) {
          // Signature outgoing bubble: large 22-24px organic radius, no sharp edges.
          final r = ((top + bottom) / 2).clamp(22.0, 24.0);
          return BorderRadius.only(
            topLeft: Radius.circular(r),
            topRight: Radius.circular(r),
            bottomLeft: Radius.circular(r - 2),
            bottomRight: Radius.circular(r - 2),
          );
        } else {
          return BorderRadius.only(
            topLeft: Radius.circular(top * 0.4),
            topRight: Radius.circular(top),
            bottomLeft: Radius.circular(bottom),
            bottomRight: Radius.circular(bottom * 0.4),
          );
        }
      case kStyleRounded:
        final r = (top + bottom) / 2 * 1.6;
        return BorderRadius.circular(r);
      case kStyleModern:
        return BorderRadius.only(
          topLeft: Radius.circular(top * 0.9),
          topRight: Radius.circular(top * 0.55),
          bottomLeft: Radius.circular(bottom * 0.55),
          bottomRight: Radius.circular(bottom * 0.9),
        );
      case kStyleMinimal:
        final r = (top + bottom) / 2 * 0.9;
        return BorderRadius.circular(r);
      case kStyleWhatsapp:
        final r = (top + bottom) / 2 * 0.35;
        return BorderRadius.circular(r);
      case kStyleCompact:
        final r = (top + bottom) / 2 * 0.25;
        return BorderRadius.circular(r);
      default:
        return BorderRadius.circular((top + bottom) / 2);
    }
  }

  BoxDecoration bubbleDecoration({
    required bool isMe,
    required bool isSelected,
    required bool isDark,
    required bool isMedia,
  }) {
    final radius = bubbleRadius(isMe: isMe);
    final color = isMe ? effectiveSentBase : receivedBubbleColor(isDark);
    final bool isSignature = isMe && isPremiumStyle;
    final List<BoxShadow> shadows = shadowEnabled.value
        ? [
            BoxShadow(
              color: (isSignature
                      ? CustomColor.kBrandPrimary
                      : (isMe ? sentColor : CustomColor.kPrimaryColor))
                  .withValues(alpha: shadowStrength.value),
              blurRadius: shadowBlur.value.r,
              offset: Offset(0, shadowOffsetY.value),
            ),
          ]
        : const [];

    Border? border;
    if (isSignature) {
      // Signature outgoing bubble: thin premium 1px border.
      border = Border.all(
        color: CustomColor.kBrandBorder.withValues(alpha: 0.65),
        width: 1,
      );
    } else if (borderEnabled.value) {
      border = Border.all(
        color: Color(borderColor.value),
        width: borderWidth.value,
      );
    }

    Gradient? gradient;
    if (isSignature) {
      // Signature outgoing bubble: soft light brand sky gradient.
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          CustomColor.kPrimaryLight,
          CustomColor.kBrandLight,
          CustomColor.kUltraLightPrimary,
        ],
        stops: const [0.0, 0.45, 1.0],
      );
    } else if (isMe && bubbleStyle.value == kStyleModern) {
      final base = effectiveSentBase;
      gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(base, CustomColor.kTextOnDark, 0.28)!,
          base,
          Color.lerp(base, CustomColor.kPrimaryDark, 0.22)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      );
    } else if (!isMe && isPremiumStyle) {
      final base = receivedBubbleColor(isDark);
      gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          base,
          Color.lerp(base, CustomColor.kTextOnDark, 0.6)!,
        ],
      );
      // Soft edge so the incoming bubble stands out from the wallpaper.
      border = Border.all(
        color: isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder,
        width: 1,
      );
    }

    Border? finalBorder = border;
    List<BoxShadow>? finalShadows = shadows.isEmpty ? null : shadows;
    if (isSelected) {
      finalBorder = Border.all(
        color: CustomColor.kPrimaryColor.withValues(alpha: 0.85),
        width: 1.6,
      );
      finalShadows = [
        ...shadows,
        BoxShadow(
          color: CustomColor.kPrimaryColor.withValues(alpha: 0.25),
          blurRadius: 18.r,
          spreadRadius: 1.r,
          offset: Offset.zero,
        ),
      ];
    }

    return BoxDecoration(
      color: gradient == null ? color : null,
      gradient: gradient,
      border: finalBorder,
      boxShadow: finalShadows,
      borderRadius: radius,
    );
  }

  EdgeInsets bubblePadding({required bool isMe, required bool isMedia}) {
    if (isMedia) return EdgeInsets.all(1.r);
    final d = densityFactor;
    return EdgeInsets.symmetric(
      horizontal: bubblePaddingH.value.r * d,
      vertical: bubblePaddingV.value.r * d,
    );
  }

  TextStyle messageTextStyle({required bool isMe, required bool isDark}) {
    final base = TextStyle(
      fontSize: fontSize.value.sp,
      fontWeight: messageWeight,
      height: 1.45,
      color: isMe
          ? sentTextColor
          : isReceivedBubbleLight(isDark)
              ? CustomColor.kTextPrimary
              : CustomColor.kTextOnDark,
    );
    return _withFamily(base);
  }

  TextStyle timestampStyle({required bool isMe, bool isDark = false}) {
    return _withFamily(
      TextStyle(
        fontSize: timestampSize.value.sp,
        color: isMe
            ? sentTimestampColor
            : isReceivedBubbleLight(isDark)
                ? CustomColor.kTextTertiary
                : CustomColor.kTextOnDark.withValues(alpha: 0.75),
      ),
    );
  }

  TextStyle senderNameStyle({bool isDark = false}) {
    return _withFamily(
      TextStyle(
        fontSize: senderNameSize.value.sp,
        fontWeight: FontWeight.w600,
        color: mention,
      ),
    );
  }

  TextStyle replyTextStyle({bool isDark = false}) {
    return _withFamily(
      TextStyle(
        fontSize: replySize.value.sp,
        color: isDark
            ? CustomColor.kTextOnDarkSecondary
            : CustomColor.kTextSecondary,
      ),
    );
  }

  // ── Wallpaper layer ─────────────────────────────────────────────────────────
  String roomWallpaperColor(String roomId) {
    final key = 'room_wallpaper_$roomId';
    return _storage.read(key) ?? wallpaperColorHex.value;
  }

  String roomWallpaperGradient(String roomId) {
    final key = 'room_wallpaper_gradient_$roomId';
    return _storage.read(key) ?? wallpaperGradientKey.value;
  }

  String roomWallpaperCustom(String roomId) {
    final key = 'room_wallpaper_custom_$roomId';
    return _storage.read(key) ?? wallpaperCustomPath.value;
  }

  void setRoomWallpaper(
      {required String roomId,
      String? colorHex,
      String? gradientKey,
      String? customPath}) {
    if (!wallpaperGlobal.value) {
      if (colorHex != null) _storage.write('room_wallpaper_$roomId', colorHex);
      if (gradientKey != null)
        _storage.write('room_wallpaper_gradient_$roomId', gradientKey);
      if (customPath != null)
        _storage.write('room_wallpaper_custom_$roomId', customPath);
    }
  }

  static List<String> get wallpaperGradientKeys =>
      _wallpaperGradients.keys.where((k) => k != 'none').toList();

  static List<Color> gradientColors(String key) =>
      _wallpaperGradients[key] ?? const [];

  Color _hexToColor(String hex) {
    var h = hex.replaceAll('#', '');
    if (h.length == 6) h = 'FF$h';
    return Color(
        int.tryParse('0x$h') ?? CustomColor.kUltraLightPrimary.toARGB32());
  }

  Widget buildWallpaperLayer({
    required BuildContext context,
    String? roomId,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blur = wallpaperBlur.value;
    final opacity = wallpaperOpacity.value.clamp(0.2, 1.0);

    final custom = roomId != null && !wallpaperGlobal.value
        ? roomWallpaperCustom(roomId)
        : wallpaperCustomPath.value;
    final gradientKey = roomId != null && !wallpaperGlobal.value
        ? roomWallpaperGradient(roomId)
        : wallpaperGradientKey.value;
    final colorHex = roomId != null && !wallpaperGlobal.value
        ? roomWallpaperColor(roomId)
        : wallpaperColorHex.value;

    Widget base;
    final defaultGradient = isDark
        ? const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CustomColor.kDarkBackground,
              CustomColor.kDarkSurface2,
              CustomColor.kDarkBackground,
            ],
          )
        : const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              CustomColor.kUltraLightPrimary,
              CustomColor.kLightSurface2,
              CustomColor.kUltraLightPrimary,
            ],
          );

    if (custom.isNotEmpty && File(custom).existsSync()) {
      Widget img = Image.file(
        File(custom),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      );
      if (blur > 0) {
        img = ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: img,
        );
      }
      base = img;
    } else if (gradientKey.isNotEmpty &&
        _wallpaperGradients.containsKey(gradientKey)) {
      final colors = _wallpaperGradients[gradientKey]!;
      if (blur > 0) {
        base = ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
          ),
        );
      } else {
        base = Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
        );
      }
    } else if (colorHex.isNotEmpty) {
      base = Container(
        width: double.infinity,
        height: double.infinity,
        color: _hexToColor(colorHex),
      );
    } else {
      base = Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: defaultGradient),
      );
    }

    if (opacity >= 1.0) return base;
    return Opacity(opacity: opacity, child: base);
  }
}
