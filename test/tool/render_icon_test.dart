@Timeout(Duration(minutes: 5))
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Renders the app icon source images into assets/icon/. Skipped unless
// RENDER_APP_ICON=1 — run after design tweaks, then:
//   dart run flutter_launcher_icons
//
// Design: a tilted white card (with mana-colored pips and text bars) over a
// fanned back card, plus a gold magnifying glass, on a purple gradient.
void main() {
  test('render app icon assets', () async {
    if (Platform.environment['RENDER_APP_ICON'] != '1') {
      markTestSkipped('set RENDER_APP_ICON=1 to regenerate icon assets');
      return;
    }

    final dir = Directory('assets/icon')..createSync(recursive: true);

    Future<void> save(String name, ui.Image image) async {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      File('${dir.path}/$name').writeAsBytesSync(bytes!.buffer.asUint8List());
    }

    // Legacy/store icon: art on gradient, content can run larger.
    await save('icon.png', await _render(background: true, contentScale: 1.2));
    // Adaptive layers: gradient background + transparent foreground with the
    // art inside the ~66% safe zone (Android crops the outer third).
    await save('icon_background.png', await _renderBackground());
    // flutter_launcher_icons wraps the foreground in a 16% inset, which
    // alone keeps the art's furthest point (~413px from center at scale 1)
    // inside the adaptive-icon safe zone — so render at full scale.
    await save('icon_foreground.png',
        await _render(background: false, contentScale: 1.0));
    // Android 13 themed icon: white silhouette on transparency.
    await save('icon_monochrome.png',
        await _render(background: false, contentScale: 1.0, monochrome: true));
  });
}

const _size = 1024;

const _manaFills = [
  Color(0xFFF0F2C0), // W
  Color(0xFFB5CDE3), // U
  Color(0xFFACA29A), // B
  Color(0xFFEB9F82), // R
  Color(0xFFC4D3CA), // G
];

Future<ui.Image> _renderBackground() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  _paintGradient(canvas);
  return recorder.endRecording().toImage(_size, _size);
}

void _paintGradient(Canvas canvas) {
  const rect = Rect.fromLTWH(0, 0, 1024, 1024);
  canvas.drawRect(
    rect,
    Paint()
      ..shader = ui.Gradient.linear(
        rect.topLeft,
        rect.bottomRight,
        [const Color(0xFF7B4FA3), const Color(0xFF45286B)],
      ),
  );
}

Future<ui.Image> _render({
  required bool background,
  required double contentScale,
  bool monochrome = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  if (background) _paintGradient(canvas);

  canvas.translate(512, 512);
  canvas.scale(contentScale);

  final white = monochrome ? Colors.white : Colors.white;
  final shadow = Paint()
    ..color = Colors.black.withValues(alpha: 0.25)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

  final card = RRect.fromRectAndRadius(
      const Rect.fromLTRB(-185, -255, 185, 255), const Radius.circular(42));

  // Fanned back card for depth.
  canvas.save();
  canvas.translate(-30, 6);
  canvas.rotate(10 * 3.14159 / 180);
  canvas.drawRRect(
      card,
      Paint()
        ..color = monochrome
            ? Colors.white.withValues(alpha: 0.55)
            : const Color(0xFFD9C7F0));
  canvas.restore();

  // Front card.
  canvas.save();
  canvas.rotate(-8 * 3.14159 / 180);
  if (!monochrome) canvas.drawRRect(card.shift(const Offset(0, 14)), shadow);
  canvas.drawRRect(card, Paint()..color = white);

  if (!monochrome) {
    // Row of mana pips near the top of the card.
    for (final (i, fill) in _manaFills.indexed) {
      final center = Offset(-124 + i * 62, -178);
      canvas.drawCircle(center, 25, Paint()..color = fill);
      canvas.drawCircle(
        center,
        25,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0x33000000),
      );
    }
    // Art box + text bars, suggested with soft grey shapes.
    final grey = Paint()..color = const Color(0xFFE2DAEC);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-140, -120, 280, 190), const Radius.circular(20)),
        grey);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-140, 100, 280, 30), const Radius.circular(15)),
        grey);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(-140, 155, 200, 30), const Radius.circular(15)),
        grey);
  }
  canvas.restore();

  // Magnifying glass, bottom-right, overlapping the card.
  final gold = Paint()
    ..color = monochrome ? Colors.white : const Color(0xFFF2B441)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 52
    ..strokeCap = StrokeCap.round;
  const lensCenter = Offset(140, 130);
  if (!monochrome) {
    canvas.drawCircle(
        lensCenter,
        122,
        Paint()
          ..color = const Color(0xFF45286B).withValues(alpha: 0.18));
  }
  canvas.drawCircle(lensCenter, 122, gold);
  canvas.drawLine(
      lensCenter + const Offset(88, 88), const Offset(330, 320), gold);

  return recorder.endRecording().toImage(_size, _size);
}
