// Regenerates the brand artwork consumed by `flutter_launcher_icons` and
// `flutter_native_splash` (configured in pubspec.yaml).
//
// Run with:
//
//     flutter test tool/generate_brand_art.dart
//
// The output is committed, so this only needs re-running when the brand colour
// or the glyph changes.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:qalqul/core/theme.dart';
import 'package:qalqul/shared/brand/brand_mark.dart';

const String outDir = 'assets/brand';

void paintGradientBackground(Canvas canvas, double size) {
  canvas.drawRect(
    Rect.fromLTWH(0, 0, size, size),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        Offset(size, size),
        [AppTheme.primary, AppTheme.primaryDeep],
      ),
  );
}

/// Renders [paint] to a PNG of [size]×[size] and writes it to [path].
Future<void> writePng(
    String path, double size, void Function(Canvas) paint) async {
  final image = await renderImage(size, paint);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(data!.buffer.asUint8List());
  stdout.writeln('wrote $path (${size.toInt()}x${size.toInt()})');
}

Future<ui.Image> renderImage(double size, void Function(Canvas) paint) {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder, Rect.fromLTWH(0, 0, size, size)));
  return recorder.endRecording().toImage(size.toInt(), size.toInt());
}

/// Bounding box (in pixels, `Rect`) of every pixel with non-zero alpha.
Future<Rect> alphaBounds(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  final w = image.width;
  final h = image.height;
  var minX = w, minY = h, maxX = -1, maxY = -1;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (bytes[(y * w + x) * 4 + 3] > 8) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  expect(maxX, greaterThanOrEqualTo(minX), reason: 'image has no visible pixels');
  return Rect.fromLTRB(minX.toDouble(), minY.toDouble(),
      (maxX + 1).toDouble(), (maxY + 1).toDouble());
}

/// Reads a single pixel as `(r, g, b, a)`.
Future<(int, int, int, int)> pixel(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final bytes = data!.buffer.asUint8List();
  final i = (y * image.width + x) * 4;
  return (bytes[i], bytes[i + 1], bytes[i + 2], bytes[i + 3]);
}

void main() {
  test('generate brand art', () async {
    // iOS + legacy Android launcher icon: full-bleed gradient, larger glyph.
    await writePng('$outDir/icon.png', 1024, (c) {
      paintGradientBackground(c, 1024);
      paintBrandGlyph(c, 1024, scale: 1.3);
    });

    // Android adaptive foreground: transparent, glyph inside the 66% safe zone.
    await writePng('$outDir/icon_foreground.png', 1024, (c) {
      paintBrandGlyph(c, 1024);
    });

    // Android adaptive monochrome layer (themed icons, API 33+).
    await writePng('$outDir/icon_monochrome.png', 1024, (c) {
      paintBrandGlyph(c, 1024);
    });

    // Splash logo: white mark on a transparent canvas.
    await writePng('$outDir/splash_logo.png', 512, (c) {
      paintBrandGlyph(c, 512);
    });
  });

  test('adaptive foreground stays inside the 66% safe zone', () async {
    final image = await renderImage(1024, (c) => paintBrandGlyph(c, 1024));
    final box = await alphaBounds(image);
    image.dispose();

    // Android masks adaptive icons with a circle of radius 1/3 of the canvas.
    const center = 512.0;
    const safeRadius = 1024 / 3;
    final corners = <Offset>[
      box.topLeft,
      box.topRight,
      box.bottomLeft,
      box.bottomRight,
    ];
    for (final c in corners) {
      final d = (c - const Offset(center, center)).distance;
      expect(d, lessThanOrEqualTo(safeRadius),
          reason: 'glyph corner $c escapes the safe zone (r=$safeRadius)');
    }
    expect(box.width, lessThan(1024 * 0.7));
    expect(box.height, lessThan(1024 * 0.7));
    // Roughly centred, so no launcher mask clips one side.
    expect(box.center.dx, closeTo(center, 6));
    expect(box.center.dy, closeTo(center, 6));
  });

  test('glyph has the expected structure', () async {
    final image = await renderImage(1024, (c) => paintBrandGlyph(c, 1024));

    // Transparent outside the glyph...
    expect((await pixel(image, 0, 0)).$4, 0);
    // ...opaque white at the centre of the display bar's gap...
    final box = await alphaBounds(image);
    // The vertical band between the display bar and the keys must be empty,
    // otherwise the mark reads as one solid block at launcher sizes.
    final gapY = ((box.top + box.bottom) / 2).round();
    expect((await pixel(image, 512, gapY)).$4, 0);

    // Each of the four keys has a white centre.
    for (final offset in const [
      Offset(410, 470),
      Offset(615, 470),
      Offset(410, 670),
      Offset(615, 670),
    ]) {
      final p = await pixel(image, offset.dx.round(), offset.dy.round());
      expect(p.$4, 255, reason: 'no key at $offset');
      expect(p.$1, 255, reason: 'key at $offset is not white');
      expect(p.$2, 255);
      expect(p.$3, 255);
    }
    image.dispose();
  });

  test('launcher icon paints an opaque gradient', () async {
    final image = await renderImage(1024, (c) {
      paintGradientBackground(c, 1024);
      paintBrandGlyph(c, 1024, scale: 1.3);
    });
    final topLeft = await pixel(image, 4, 4);
    final bottomRight = await pixel(image, 1019, 1019);
    image.dispose();

    for (final p in [topLeft, bottomRight]) {
      expect(p.$4, 255, reason: 'launcher icon must not be transparent');
      // Blue-ish: more blue than red, and not white.
      expect(p.$3, greaterThan(p.$1));
      expect(p.$1, lessThan(200));
    }
    // A gradient, not a flat fill.
    expect(topLeft, isNot(bottomRight));
  });
}
