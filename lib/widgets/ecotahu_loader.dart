import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Widget & CustomPainter yang mengimplementasikan animasi preloader EcoTahu
/// sesuai persis dengan `resources/views/components/loader.blade.php`.
class EcoTahuEmblem extends StatefulWidget {
  final double size;
  final Color cutoutBgColor;

  const EcoTahuEmblem({
    super.key,
    this.size = 116,
    required this.cutoutBgColor,
  });

  @override
  State<EcoTahuEmblem> createState() => _EcoTahuEmblemState();
}

class _EcoTahuEmblemState extends State<EcoTahuEmblem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double beat = (1.0 - math.cos(2.0 * math.pi * _controller.value)) / 2.0;
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _EcoTahuEmblemPainter(
            beat: beat,
            cutoutBgColor: widget.cutoutBgColor,
          ),
        );
      },
    );
  }
}

class _EcoTahuEmblemPainter extends CustomPainter {
  final double beat;
  final Color cutoutBgColor;

  _EcoTahuEmblemPainter({
    required this.beat,
    required this.cutoutBgColor,
  });

  Paint _linearPaint(Offset from, Offset to, List<Color> colors, List<double> stops) {
    return Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
        stops: stops,
      ).createShader(Rect.fromPoints(from, to));
  }

  void _withTransform({
    required Canvas canvas,
    required Offset origin,
    double rotateDeg = 0.0,
    double translateY = 0.0,
    double scale = 1.0,
    required void Function() draw,
  }) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy + translateY);
    if (rotateDeg != 0.0) {
      canvas.rotate(rotateDeg * math.pi / 180.0);
    }
    if (scale != 1.0) {
      canvas.scale(scale);
    }
    canvas.translate(-origin.dx, -origin.dy);
    draw();
    canvas.restore();
  }

  void _drawRotatedOval(
    Canvas canvas,
    double cx,
    double cy,
    double rx,
    double ry,
    double deg,
    Paint paint,
  ) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(deg * math.pi / 180.0);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2), paint);
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 210.0, size.height / 210.0);

    // Shadow halus di bawah emblem
    final shadowPaint = Paint()
      ..color = const Color(0xFF134E1E).withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(Rect.fromCenter(center: const Offset(102, 184), width: 108, height: 18), shadowPaint);

    // 1. TOP SPROUT (etSproutSway: origin 106,76, rot 0..6deg, y 0..-5, scale 1..1.05)
    _withTransform(
      canvas: canvas,
      origin: const Offset(106, 76),
      rotateDeg: 6.0 * beat,
      translateY: -5.0 * beat,
      scale: 1.0 + 0.05 * beat,
      draw: () {
        final stemMain = Paint()
          ..color = const Color(0xFF227E28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.2
          ..strokeCap = StrokeCap.round;
        final stemPath = Path()
          ..moveTo(104, 78)
          ..cubicTo(104, 64, 108, 50, 118, 39);
        canvas.drawPath(stemPath, stemMain);

        final stemSub = Paint()
          ..color = const Color(0xFF186421)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4
          ..strokeCap = StrokeCap.round;
        final stemSubPath = Path()
          ..moveTo(105, 64)
          ..cubicTo(98, 58, 91, 55, 83, 55);
        canvas.drawPath(stemSubPath, stemSub);

        final tinyLeaf = Path()
          ..moveTo(103, 61)
          ..cubicTo(97, 49, 82, 47, 74, 52)
          ..cubicTo(81, 62, 94, 65, 103, 61)
          ..close();
        canvas.drawPath(tinyLeaf, Paint()..color = const Color(0xFF176521));

        final bigSprout = Path()
          ..moveTo(108, 56)
          ..cubicTo(106, 33, 128, 17, 160, 15)
          ..cubicTo(153, 43, 136, 61, 108, 56)
          ..close();
        canvas.drawPath(
          bigSprout,
          _linearPaint(
            const Offset(100, 18),
            const Offset(155, 75),
            const [Color(0xFF76D142), Color(0xFF339A30), Color(0xFF176221)],
            const [0.0, 0.60, 1.0],
          ),
        );

        final vein = Paint()
          ..color = const Color(0xFF8CE058)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round;
        final veinPath = Path()
          ..moveTo(109, 55)
          ..cubicTo(123, 44, 137, 33, 151, 22);
        canvas.drawPath(veinPath, vein);
      },
    );

    // 2. BACK LEFT LEAF (etLeafLeft: origin 95,158, rot 0..-5deg, scale 1..1.02)
    _withTransform(
      canvas: canvas,
      origin: const Offset(95, 158),
      rotateDeg: -5.0 * beat,
      scale: 1.0 + 0.02 * beat,
      draw: () {
        final backLeft = Path()
          ..moveTo(98, 76)
          ..cubicTo(58, 64, 30, 92, 36, 132)
          ..cubicTo(48, 115, 68, 108, 98, 76)
          ..close();
        canvas.drawPath(
          backLeft,
          _linearPaint(
            const Offset(25, 65),
            const Offset(105, 165),
            const [Color(0xFF68C83E), Color(0xFF278B2B), Color(0xFF11511D)],
            const [0.0, 0.65, 1.0],
          ),
        );
      },
    );

    // 3. BACK RIGHT LEAF (etLeafRight: origin 108,160, rot 0..+5deg, scale 1..1.02)
    _withTransform(
      canvas: canvas,
      origin: const Offset(108, 160),
      rotateDeg: 5.0 * beat,
      scale: 1.0 + 0.02 * beat,
      draw: () {
        final backRight = Path()
          ..moveTo(110, 80)
          ..cubicTo(148, 70, 178, 96, 170, 138)
          ..cubicTo(158, 116, 138, 106, 110, 80)
          ..close();
        canvas.drawPath(
          backRight,
          _linearPaint(
            const Offset(175, 75),
            const Offset(105, 165),
            const [Color(0xFF68C83E), Color(0xFF25872A), Color(0xFF145A1F)],
            const [0.0, 0.70, 1.0],
          ),
        );
      },
    );

    // 4. TOFU CUBE (etTofuFloat: origin 100,112, y 0..-6, scale 1..1.025)
    _withTransform(
      canvas: canvas,
      origin: const Offset(100, 112),
      translateY: -6.0 * beat,
      scale: 1.0 + 0.025 * beat,
      draw: () {
        final topFace = Path()
          ..moveTo(102, 68)
          ..lineTo(145, 89)
          ..lineTo(102, 111)
          ..lineTo(59, 89)
          ..close();
        canvas.drawPath(
          topFace,
          _linearPaint(
            const Offset(60, 68),
            const Offset(140, 112),
            const [Color(0xFFFBF9EE), Color(0xFFEFEAD2)],
            const [0.0, 1.0],
          ),
        );

        final leftFace = Path()
          ..moveTo(59, 89)
          ..lineTo(102, 111)
          ..lineTo(102, 162)
          ..lineTo(59, 136)
          ..close();
        canvas.drawPath(
          leftFace,
          _linearPaint(
            const Offset(56, 90),
            const Offset(102, 162),
            const [Color(0xFFF1ECCE), Color(0xFFDFD4AE)],
            const [0.0, 1.0],
          ),
        );

        final rightFace = Path()
          ..moveTo(102, 111)
          ..lineTo(145, 89)
          ..lineTo(145, 138)
          ..lineTo(102, 162)
          ..close();
        canvas.drawPath(
          rightFace,
          _linearPaint(
            const Offset(102, 92),
            const Offset(146, 162),
            const [Color(0xFFE4D9B5), Color(0xFFCBBCA0)],
            const [0.0, 1.0],
          ),
        );

        final ridgeTop = Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final ridgePath = Path()
          ..moveTo(59, 89)
          ..lineTo(102, 111)
          ..lineTo(145, 89);
        canvas.drawPath(ridgePath, ridgeTop);

        canvas.drawLine(
          const Offset(102, 111),
          const Offset(102, 160),
          Paint()
            ..color = const Color(0xFFF9F5E3).withValues(alpha: 0.55)
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        );

        // Tekstur pori tahu
        _drawRotatedOval(canvas, 92, 84, 3.2, 1.6, 0, Paint()..color = const Color(0xFFD8CEAC).withValues(alpha: 0.65));
        _drawRotatedOval(canvas, 108, 91, 4.2, 2.0, 0, Paint()..color = const Color(0xFFD8CEAC).withValues(alpha: 0.55));
        _drawRotatedOval(canvas, 83, 93, 2.4, 1.3, 0, Paint()..color = const Color(0xFFD8CEAC).withValues(alpha: 0.6));
        _drawRotatedOval(canvas, 118, 85, 2.5, 1.2, 0, Paint()..color = const Color(0xFFD8CEAC).withValues(alpha: 0.5));
        _drawRotatedOval(canvas, 101, 99, 2.8, 1.4, 0, Paint()..color = const Color(0xFFD8CEAC).withValues(alpha: 0.6));

        _drawRotatedOval(canvas, 72, 110, 2.2, 3.2, -18, Paint()..color = const Color(0xFFC9BC96).withValues(alpha: 0.65));
        _drawRotatedOval(canvas, 88, 122, 2.8, 3.8, -12, Paint()..color = const Color(0xFFC9BC96).withValues(alpha: 0.6));
        canvas.drawCircle(const Offset(77, 127), 2.0, Paint()..color = const Color(0xFFC9BC96).withValues(alpha: 0.55));
        _drawRotatedOval(canvas, 93, 139, 2.0, 3.0, 0, Paint()..color = const Color(0xFFC9BC96).withValues(alpha: 0.65));
        canvas.drawCircle(const Offset(68, 122), 1.5, Paint()..color = const Color(0xFFC9BC96).withValues(alpha: 0.5));
        canvas.drawCircle(const Offset(84, 108), 1.7, Paint()..color = const Color(0xFFC9BC96).withValues(alpha: 0.5));

        _drawRotatedOval(canvas, 116, 118, 2.5, 3.6, 15, Paint()..color = const Color(0xFFB5A47E).withValues(alpha: 0.65));
        _drawRotatedOval(canvas, 131, 109, 2.0, 3.0, 18, Paint()..color = const Color(0xFFB5A47E).withValues(alpha: 0.6));
        canvas.drawCircle(const Offset(125, 128), 2.2, Paint()..color = const Color(0xFFB5A47E).withValues(alpha: 0.55));
        _drawRotatedOval(canvas, 112, 138, 1.8, 2.8, 0, Paint()..color = const Color(0xFFB5A47E).withValues(alpha: 0.6));
        canvas.drawCircle(const Offset(136, 121), 1.6, Paint()..color = const Color(0xFFB5A47E).withValues(alpha: 0.5));
      },
    );

    // 5. FRONT LEFT LEAF
    _withTransform(
      canvas: canvas,
      origin: const Offset(95, 158),
      rotateDeg: -5.0 * beat,
      scale: 1.0 + 0.02 * beat,
      draw: () {
        final frontLeft = Path()
          ..moveTo(32, 108)
          ..cubicTo(24, 148, 56, 184, 98, 176)
          ..cubicTo(84, 152, 68, 136, 32, 108)
          ..close();
        canvas.drawPath(
          frontLeft,
          _linearPaint(
            const Offset(20, 105),
            const Offset(120, 188),
            const [Color(0xFF80D846), Color(0xFF3BA433), Color(0xFF196A23)],
            const [0.0, 0.55, 1.0],
          ),
        );

        final cutPath = Path()
          ..moveTo(55, 144)
          ..cubicTo(72, 156, 86, 168, 97, 177);
        canvas.drawPath(
          cutPath,
          Paint()
            ..color = cutoutBgColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4.5
            ..strokeCap = StrokeCap.round,
        );
      },
    );

    // 6. FRONT RIGHT LEAF
    _withTransform(
      canvas: canvas,
      origin: const Offset(108, 160),
      rotateDeg: 5.0 * beat,
      scale: 1.0 + 0.02 * beat,
      draw: () {
        final frontRight = Path()
          ..moveTo(170, 106)
          ..cubicTo(172, 146, 144, 176, 106, 168)
          ..cubicTo(114, 138, 136, 118, 170, 106)
          ..close();
        canvas.drawPath(
          frontRight,
          _linearPaint(
            const Offset(180, 100),
            const Offset(105, 175),
            const [Color(0xFF64C43B), Color(0xFF228629), Color(0xFF0F4E1C)],
            const [0.0, 0.60, 1.0],
          ),
        );

        final innerHighlight = Path()
          ..moveTo(140, 128)
          ..cubicTo(154, 126, 164, 134, 156, 148)
          ..cubicTo(144, 156, 126, 162, 108, 167)
          ..cubicTo(118, 148, 128, 134, 140, 128)
          ..close();
        canvas.drawPath(
          innerHighlight,
          Paint()..color = const Color(0xFF46AF35).withValues(alpha: 0.85),
        );
      },
    );

    // 7. BOTTOM LEAF (etLeafBottom: y 0..2.5)
    _withTransform(
      canvas: canvas,
      origin: const Offset(95, 175),
      translateY: 2.5 * beat,
      draw: () {
        final bottomLeaf = Path()
          ..moveTo(44, 162)
          ..cubicTo(68, 190, 108, 192, 134, 175)
          ..cubicTo(104, 182, 72, 178, 44, 162)
          ..close();
        canvas.drawPath(bottomLeaf, Paint()..color = const Color(0xFF186B23));
      },
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EcoTahuEmblemPainter oldDelegate) =>
      oldDelegate.beat != beat || oldDelegate.cutoutBgColor != cutoutBgColor;
}

class _EcoTahuLeafOWidget extends StatefulWidget {
  final double size;
  final Color color;
  final Color cutoutBgColor;

  const _EcoTahuLeafOWidget({
    required this.size,
    required this.color,
    required this.cutoutBgColor,
  });

  @override
  State<_EcoTahuLeafOWidget> createState() => _EcoTahuLeafOWidgetState();
}

class _EcoTahuLeafOWidgetState extends State<_EcoTahuLeafOWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final double beat = (1.0 - math.cos(2.0 * math.pi * _controller.value)) / 2.0;
        return CustomPaint(
          size: Size.square(widget.size),
          painter: _EcoTahuLeafOPainter(
            beat: beat,
            color: widget.color,
            cutoutBgColor: widget.cutoutBgColor,
          ),
        );
      },
    );
  }
}

class _EcoTahuLeafOPainter extends CustomPainter {
  final double beat;
  final Color color;
  final Color cutoutBgColor;

  _EcoTahuLeafOPainter({
    required this.beat,
    required this.color,
    required this.cutoutBgColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 100.0, size.height / 100.0);

    final ring = Path()
      ..fillType = PathFillType.evenOdd
      ..addOval(Rect.fromCircle(center: const Offset(50, 51), radius: 43))
      ..addOval(Rect.fromCircle(center: const Offset(50, 51), radius: 26));
    canvas.drawPath(ring, Paint()..color = color);

    // et-o-leaf-inner (origin 50,65, rot 0..-6deg, scale 1..1.07)
    canvas.save();
    canvas.translate(50, 65);
    canvas.rotate(-6.0 * beat * math.pi / 180.0);
    canvas.scale(1.0 + 0.07 * beat);
    canvas.translate(-50, -65);

    final bgMask = Path()
      ..moveTo(27, 74)
      ..cubicTo(27, 42, 49, 23, 83, 18)
      ..cubicTo(79, 52, 61, 74, 27, 74)
      ..close();
    canvas.drawPath(bgMask, Paint()..color = cutoutBgColor);

    final midvein = Path()
      ..moveTo(28, 73)
      ..cubicTo(44, 58, 56, 44, 70, 31);
    canvas.drawPath(
      midvein,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.5
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _EcoTahuLeafOPainter oldDelegate) =>
      oldDelegate.beat != beat ||
      oldDelegate.color != color ||
      oldDelegate.cutoutBgColor != cutoutBgColor;
}

class _EcoTahuWordmark extends StatefulWidget {
  final double fontSize;
  final Color ecoColor;
  final Color tahuColor;
  final Color cutoutBgColor;

  const _EcoTahuWordmark({
    this.fontSize = 38,
    required this.ecoColor,
    required this.tahuColor,
    required this.cutoutBgColor,
  });

  @override
  State<_EcoTahuWordmark> createState() => _EcoTahuWordmarkState();
}

class _EcoTahuWordmarkState extends State<_EcoTahuWordmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      fontSize: widget.fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.1,
      height: 1.0,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text('Ec', style: baseStyle.copyWith(color: widget.ecoColor)),
        Transform.translate(
          offset: Offset(0, widget.fontSize * 0.045),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0.8),
            child: _EcoTahuLeafOWidget(
              size: widget.fontSize * 0.72,
              color: widget.ecoColor,
              cutoutBgColor: widget.cutoutBgColor,
            ),
          ),
        ),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final beat = (1.0 - math.cos(2.0 * math.pi * _controller.value)) / 2.0;
            return Opacity(
              opacity: 1.0 - 0.12 * beat,
              child: child,
            );
          },
          child: Text('Tahu', style: baseStyle.copyWith(color: widget.tahuColor)),
        ),
      ],
    );
  }
}

/// Splash Screen full-screen preloader yang identik dengan Web (`loader.blade.php`).
class EcoTahuSplashLoader extends StatelessWidget {
  final double progress;
  final String statusText;

  const EcoTahuSplashLoader({
    super.key,
    required this.progress,
    this.statusText = 'Menyiapkan kesegaran alami...',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
    final ecoColor = isDark ? const Color(0xFF248F38) : const Color(0xFF134E1E);
    final tahuColor = isDark ? const Color(0xFF68C944) : const Color(0xFF52AE32);
    final trackColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08);
    final subtextColor =
        isDark ? Colors.white.withValues(alpha: 0.60) : Colors.black.withValues(alpha: 0.55);

    final clampedProgress = progress.clamp(0.0, 1.0);
    final percentInt = (clampedProgress * 100).round();

    final progressArea = SizedBox(
      width: 248,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 5,
              color: trackColor,
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOut,
                widthFactor: clampedProgress,
                child: Container(
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF134E1E), Color(0xFF52AE32)],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: subtextColor,
                ),
              ),
              Text(
                '$percentInt%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: subtextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return ColoredBox(
      color: bgColor,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              if (isWide) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    EcoTahuEmblem(size: 124, cutoutBgColor: bgColor),
                    const SizedBox(width: 24),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _EcoTahuWordmark(
                          fontSize: 52,
                          ecoColor: ecoColor,
                          tahuColor: tahuColor,
                          cutoutBgColor: bgColor,
                        ),
                        const SizedBox(height: 24),
                        progressArea,
                      ],
                    ),
                  ],
                );
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  EcoTahuEmblem(size: 112, cutoutBgColor: bgColor),
                  const SizedBox(height: 16),
                  _EcoTahuWordmark(
                    fontSize: 40,
                    ecoColor: ecoColor,
                    tahuColor: tahuColor,
                    cutoutBgColor: bgColor,
                  ),
                  const SizedBox(height: 24),
                  progressArea,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Loader in-app bergaya EcoTahu untuk menggantikan CircularProgressIndicator polos.
class EcoTahuLoadingIndicator extends StatefulWidget {
  final double size;
  final String? message;

  const EcoTahuLoadingIndicator({
    super.key,
    this.size = 76,
    this.message = 'Memuat kesegaran...',
  });

  @override
  State<EcoTahuLoadingIndicator> createState() => _EcoTahuLoadingIndicatorState();
}

class _EcoTahuLoadingIndicatorState extends State<EcoTahuLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _barController;

  @override
  void initState() {
    super.initState();
    _barController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _barController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final ecoColor = isDark ? const Color(0xFF248F38) : const Color(0xFF134E1E);
    final tahuColor = isDark ? const Color(0xFF68C944) : const Color(0xFF52AE32);
    final trackColor =
        isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08);
    final subtextColor =
        isDark ? Colors.white.withValues(alpha: 0.62) : Colors.black.withValues(alpha: 0.55);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          EcoTahuEmblem(size: widget.size, cutoutBgColor: scaffoldColor),
          const SizedBox(height: 10),
          _EcoTahuWordmark(
            fontSize: 22,
            ecoColor: ecoColor,
            tahuColor: tahuColor,
            cutoutBgColor: scaffoldColor,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 136,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Stack(
                children: [
                  Container(color: trackColor),
                  AnimatedBuilder(
                    animation: _barController,
                    builder: (context, child) {
                      final dx = -60.0 + _barController.value * 196.0;
                      return Transform.translate(offset: Offset(dx, 0), child: child);
                    },
                    child: Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF134E1E), Color(0xFF52AE32)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (widget.message != null && widget.message!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.message!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: subtextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
