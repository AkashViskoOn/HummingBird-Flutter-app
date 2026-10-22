import 'package:flutter/material.dart';

/// The custom humming-bird brand icon (blue `#2192CF` on transparent).
///
/// Tint with [color] (e.g. white on gradient backgrounds) via a source-in
/// color filter; omit [color] to keep the icon's natural brand blue.
class HummingIcon extends StatelessWidget {
  static const String _assetPath = 'assets/images/humming_icon.png';

  final double? size;
  final double? width;
  final double? height;
  final Color? color;

  const HummingIcon({
    super.key,
    this.size = 24,
    this.width,
    this.height,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final s = size ?? 24;
    final image = Image.asset(
      _assetPath,
      width: width ?? s,
      height: height ?? s,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => Icon(
        Icons.schedule_send_rounded,
        size: s,
        color: color,
      ),
    );
    if (color == null) return image;
    return ColorFiltered(
      colorFilter: ColorFilter.mode(color!, BlendMode.srcIn),
      child: image,
    );
  }
}

/// Renders [icon], substituting the custom humming-icon image wherever the
/// legacy `schedule_send_rounded` schedule icon was used.
Widget scheduleIcon(IconData icon, {double? size, Color? color}) {
  if (icon == Icons.schedule_send_rounded) {
    return HummingIcon(size: size, color: color);
  }
  return Icon(icon, size: size, color: color);
}
