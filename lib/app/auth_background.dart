import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Latar ilustrasi halaman masuk: langit, matahari, awan, bukit, rumah,
/// pohon, truk sampah, dan tong pilah. Mengikuti desain Figma Make
/// (`AuthLandscape` dan kelas `.auth-*` di src/index.css), versi layar HP.
class AuthBackground extends StatelessWidget {
  const AuthBackground({super.key});

  static const _recycle = Color(0xFF58BB84);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final h = c.maxHeight;
        // Ikon daur ulang dipudarkan seperti aturan CSS layar kecil.
        Widget recycle(double size) => Icon(
          Icons.recycling_rounded,
          size: size,
          color: _recycle.withValues(alpha: 0.8 * 0.35),
        );
        return ExcludeSemantics(
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: _LandscapePainter())),
              Positioned(left: w * 0.27, top: h * 0.07, child: recycle(34)),
              Positioned(right: w * 0.21, top: h * 0.10, child: recycle(38)),
            ],
          ),
        );
      },
    );
  }
}

class _LandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Offset.zero & size;

    // Langit.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFC9EFD8), Color(0xFFE2F6E8), Color(0xFFBFE6C8)],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0.64, -0.7), // 82% dari kiri, 15% dari atas
          radius: 0.3,
          colors: [
            const Color(0xFFFFE067).withValues(alpha: 0.48),
            const Color(0x00FFE067),
          ],
        ).createShader(rect),
    );

    // Matahari: kanan -30px, atas 5%, skala 0,7.
    _scaled(canvas, Rect.fromLTWH(w + 30 - 104, h * 0.05, 104, 104), 0.7, (r) {
      canvas.drawCircle(
        r.center,
        52,
        Paint()
          ..color = const Color(0x8CFFDA63)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
      );
      canvas.drawCircle(r.center, 52, Paint()..color = const Color(0xFFFFDA63));
    });

    // Awan kiri: kiri -35px, atas 5%, skala 0,62.
    _scaled(canvas, Rect.fromLTWH(-35, h * 0.05, 120, 34), 0.62, (r) {
      _cloud(canvas, r.topLeft);
    });

    // Bukit belakang, tengah, depan.
    _hill(canvas, size, bottom: 0.17, height: 0.34, deg: 1, color: 0xFFB7DFC0);
    _hill(canvas, size, bottom: 0.06, height: 0.35, deg: -2, color: 0xFF91D09F);
    _hill(canvas, size, bottom: -0.19, height: 0.38, deg: 2, color: 0xFF48AB6D);

    // Benda di atas bukit dipudarkan agar formulir tetap mudah dibaca.
    canvas.saveLayer(rect, Paint()..color = const Color(0x59000000));
    _scaled(
      canvas,
      Rect.fromLTWH(-w * 0.04, h - h * 0.17 - 98, 130, 98),
      0.7,
      (r) => _house(canvas, r.topLeft),
    );
    _tree(canvas, Offset(w * 0.01, h - h * 0.29 - 92));
    _scaled(
      canvas,
      Rect.fromLTWH(-w * 0.05, h - h * 0.07 - 92, 230, 92),
      0.65,
      (r) => _truck(canvas, r.topLeft),
    );
    const binsWidth = 54 * 3 + 12 * 2.0;
    _scaled(
      canvas,
      Rect.fromLTWH(w - w * 0.03 - binsWidth, h - h * 0.05 - 72, binsWidth, 72),
      0.72,
      (r) => _bins(canvas, r.topLeft),
    );
    canvas.restore();
  }

  /// Menggambar di dalam [box] yang diskalakan dari titik tengahnya, sama
  /// seperti `transform: scale()` di CSS.
  void _scaled(Canvas canvas, Rect box, double s, void Function(Rect) draw) {
    canvas.save();
    canvas.translate(box.center.dx, box.center.dy);
    canvas.scale(s);
    canvas.translate(-box.center.dx, -box.center.dy);
    draw(box);
    canvas.restore();
  }

  void _hill(
    Canvas canvas,
    Size size, {
    required double bottom,
    required double height,
    required double deg,
    required int color,
  }) {
    final hw = size.width * 1.2;
    final hh = size.height * height;
    final r = Rect.fromLTWH(
      -size.width * 0.1,
      size.height - size.height * bottom - hh,
      hw,
      hh,
    );
    canvas.save();
    canvas.translate(r.center.dx, r.center.dy);
    canvas.rotate(deg * math.pi / 180);
    canvas.translate(-r.center.dx, -r.center.dy);
    final radius = Radius.elliptical(hw / 2, hh / 2);
    canvas.drawRRect(
      RRect.fromRectAndCorners(r, topLeft: radius, topRight: radius),
      Paint()..color = Color(color),
    );
    canvas.restore();
  }

  void _cloud(Canvas canvas, Offset o) {
    final p = Paint()..color = const Color(0xCCFFFFFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(o.dx, o.dy, 120, 34),
        const Radius.circular(17),
      ),
      p,
    );
    // Tiga lingkaran yang alasnya rata dengan bawah awan.
    for (final (left, d) in [(12.0, 52.0), (46.0, 66.0), (72.0, 48.0)]) {
      canvas.drawCircle(
        Offset(o.dx + left + d / 2, o.dy + 34 - d / 2),
        d / 2,
        p,
      );
    }
  }

  void _house(Canvas canvas, Offset o) {
    canvas.drawPath(
      Path()
        ..moveTo(o.dx - 12, o.dy + 5)
        ..lineTo(o.dx - 12 + 154, o.dy + 5)
        ..lineTo(o.dx - 12 + 77, o.dy - 43)
        ..close(),
      Paint()..color = const Color(0xFFD98152),
    );
    canvas.drawRect(
      Rect.fromLTWH(o.dx, o.dy, 130, 98),
      Paint()..color = const Color(0xFFFFF9E9),
    );
    final glass = Paint()..color = const Color(0xFF9BD1DF);
    for (final x in [18.0, 130 - 18 - 28.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(o.dx + x, o.dy + 30, 28, 28),
          const Radius.circular(3),
        ),
        glass,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(o.dx + 65 - 13.5, o.dy + 98 - 44, 27, 44),
        topLeft: const Radius.circular(4),
        topRight: const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF8F6D4C),
    );
  }

  void _tree(Canvas canvas, Offset o) {
    final leaf = Paint()..color = const Color(0xFF3E9D62);
    canvas.drawCircle(Offset(o.dx - 5 + 19, o.dy + 26 + 19), 19, leaf);
    canvas.drawCircle(Offset(o.dx + 8 + 24, o.dy + 8 + 24), 24, leaf);
    canvas.drawRect(
      Rect.fromLTWH(o.dx + 26, o.dy + 92 - 45, 8, 45),
      Paint()..color = const Color(0xFF79593F),
    );
    canvas.drawCircle(
      Offset(o.dx + 28 + 16, o.dy + 34 + 16),
      16,
      Paint()..color = const Color(0xFF338B57),
    );
  }

  void _truck(Canvas canvas, Offset o) {
    // Bak sampah dengan atap hijau.
    final box = Rect.fromLTWH(o.dx, o.dy + 92 - 20 - 72, 150, 72);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        box,
        bottomLeft: const Radius.circular(8),
        bottomRight: const Radius.circular(8),
      ),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(box.left, box.top, 150, 13),
      Paint()..color = const Color(0xFF187C45),
    );
    _recycleMark(
      canvas,
      Offset(box.center.dx, box.top + 13 + (72 - 13) / 2),
      const Color(0xFF23A05D),
    );

    // Kabin dan kacanya.
    final cab = Rect.fromLTWH(o.dx + 150, o.dy + 92 - 20 - 57, 68, 57);
    canvas.drawRRect(
      RRect.fromRectAndCorners(
        cab,
        topRight: const Radius.circular(9),
        bottomRight: const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF17834A),
    );
    final skew = 22 * math.tan(12 * math.pi / 180) / 2;
    canvas.drawPath(
      Path()
        ..moveTo(cab.left + 9 + skew, cab.top + 10)
        ..lineTo(cab.left + 44 + skew, cab.top + 10)
        ..lineTo(cab.left + 44 - skew, cab.top + 32)
        ..lineTo(cab.left + 9 - skew, cab.top + 32)
        ..close(),
      Paint()..color = const Color(0xFF9BD7E5),
    );

    // Roda.
    for (final x in [20.0, 230 - 22 - 35.0]) {
      final c = Offset(o.dx + x + 17.5, o.dy + 92 - 17.5);
      canvas.drawCircle(c, 17.5, Paint()..color = const Color(0xFF263631));
      canvas.drawCircle(c, 7.5, Paint()..color = const Color(0xFFB8D4CB));
    }
  }

  /// Dua panah melingkar sederhana, pengganti ikon daur ulang di bak truk.
  void _recycleMark(Canvas canvas, Offset c, Color color) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round;
    const r = 12.0;
    final arc = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(arc, math.pi * 1.1, math.pi * 0.75, false, p);
    canvas.drawArc(arc, math.pi * 0.1, math.pi * 0.75, false, p);
    for (final a in [math.pi * 1.85, math.pi * 0.85]) {
      final tip = c + Offset(math.cos(a), math.sin(a)) * r;
      final dir = a + math.pi / 2;
      canvas.drawLine(
        tip,
        tip + Offset(math.cos(dir + 2.5), math.sin(dir + 2.5)) * 6,
        p,
      );
      canvas.drawLine(
        tip,
        tip + Offset(math.cos(dir - 2.5), math.sin(dir - 2.5)) * 6,
        p,
      );
    }
  }

  void _bins(Canvas canvas, Offset o) {
    const bins = [
      (68.0, Color(0xFF27A760)),
      (72.0, Color(0xFFF5BD32)),
      (70.0, Color(0xFF3CA0D3)),
    ];
    var x = o.dx;
    for (final (height, color) in bins) {
      final r = Rect.fromLTWH(x, o.dy + 72 - height, 54, height);
      final shape = RRect.fromRectAndCorners(
        r,
        topLeft: const Radius.circular(5),
        topRight: const Radius.circular(5),
        bottomLeft: const Radius.circular(10),
        bottomRight: const Radius.circular(10),
      );
      canvas.drawRRect(shape, Paint()..color = color);
      canvas.save();
      canvas.clipRRect(shape);
      canvas.drawRect(
        Rect.fromLTWH(r.left, r.top, 54, 11),
        Paint()..color = const Color(0x14000000),
      );
      canvas.restore();
      x += 54 + 12;
    }
  }

  @override
  bool shouldRepaint(_LandscapePainter oldDelegate) => false;
}
