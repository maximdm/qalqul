import 'package:flutter/material.dart';

import 'package:qalqul/core/theme.dart';

/// The Qalqul mark: a display bar over a 2×2 keypad — a calculator reduced to
/// four keys.
///
/// This is the single source of truth for the artwork: [paintBrandGlyph] is used
/// both by the in-app [BrandMark] and by `tool/generate_brand_art.dart`, which
/// renders the launcher icon and splash PNGs from it.
///
/// The layout is expressed as fractions of the canvas so the same code renders
/// correctly at any size. [scale] must stay at or below 1.0 for the launcher
/// foreground: Android only guarantees the inner 66% of an adaptive icon
/// survives its mask.
void paintBrandGlyph(
  Canvas canvas,
  double size, {
  double scale = 1.0,
  Color color = Colors.white,
}) {
  const keySize = 175 / 1024;
  const gap = 35 / 1024;
  const displayHeight = 90 / 1024;
  const displayGap = 50 / 1024;

  final key = size * keySize * scale;
  final g = size * gap * scale;
  final display = size * displayHeight * scale;
  final displayToKeys = size * displayGap * scale;

  final totalWidth = key * 2 + g;
  final totalHeight = display + displayToKeys + key * 2 + g;
  final left = (size - totalWidth) / 2;
  final top = (size - totalHeight) / 2;

  final paint = Paint()..color = color;

  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, totalWidth, display),
      Radius.circular(size * 20 / 1024 * scale),
    ),
    paint,
  );

  final keysTop = top + display + displayToKeys;
  for (var row = 0; row < 2; row++) {
    for (var col = 0; col < 2; col++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left + col * (key + g),
            keysTop + row * (key + g),
            key,
            key,
          ),
          Radius.circular(size * 40 / 1024 * scale),
        ),
        paint,
      );
    }
  }
}

/// Paints the mark, optionally on the brand-gradient tile used as the launcher
/// icon's background.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 96, this.gradient = true});

  final double size;

  /// When true the glyph sits on the brand-gradient tile (icon look); when false
  /// only the glyph is drawn, ready to be tinted by [color].
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _BrandMarkPainter(
          gradient: gradient ? scheme.primary : scheme.surface,
          glyphColor:
              gradient ? Colors.white : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  _BrandMarkPainter({required this.gradient, required this.glyphColor});

  /// Background colour, or `null` for a transparent tile.
  final Color? gradient;
  final Color glyphColor;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = gradient;
    if (bg != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(size.width * 0.22),
        ),
        Paint()..color = bg,
      );
    }
    paintBrandGlyph(
      canvas,
      size.width,
      scale: bg != null ? 1.3 : 1.0,
      color: glyphColor,
    );
  }

  @override
  bool shouldRepaint(_BrandMarkPainter old) =>
      old.gradient != gradient || old.glyphColor != glyphColor;
}

/// Brand gradient used by the launcher icon and splash screen. Kept in sync with
/// the values in `pubspec.yaml` (`flutter_launcher_icons` / `flutter_native_splash`).
const brandGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppTheme.primary, AppTheme.primaryDeep],
);
