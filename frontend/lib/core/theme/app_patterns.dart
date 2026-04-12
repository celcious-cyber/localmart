import 'package:flutter/material.dart';

class WavyPatternPainter extends CustomPainter {
  final Color color;

  WavyPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Base scaling logic
    final sw = size.width / 900;
    final sh = size.height / 600;

    // Use the parameter color as base, and create two variants for layering
    final paint1 = Paint()
      ..color = color.withValues(alpha: color.a * 0.8)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = color.withValues(alpha: color.a * 0.4)
      ..style = PaintingStyle.fill;

    // --- Top Right Group (translate 900, 0) ---
    // Path 1 (Primary Blob)
    final path1 = Path();
    path1.moveTo(size.width, 351.5 * sh);
    path1.cubicTo(
        size.width - 24.5 * sw, 295.3 * sh, 
        size.width - 48.9 * sw, 239 * sh, 
        size.width - 95.3 * sw, 230 * sh);
    path1.cubicTo(
        size.width - 141.6 * sw, 221.1 * sh, 
        size.width - 209.9 * sw, 259.5 * sh, 
        size.width - 248.6 * sw, 248.6 * sh);
    path1.cubicTo(
        size.width - 287.3 * sw, 237.7 * sh, 
        size.width - 296.3 * sw, 177.5 * sh, 
        size.width - 308.6 * sw, 127.8 * sh);
    path1.cubicTo(
        size.width - 320.8 * sw, 78.2 * sh, 
        size.width - 336.2 * sw, 39.1 * sh, 
        size.width - 351.5 * sw, 0);
    path1.lineTo(size.width, 0);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Path 2 (Lighter)
    final path2 = Path();
    path2.moveTo(size.width, 175.8 * sh);
    path2.cubicTo(
        size.width - 12.2 * sw, 147.6 * sh, 
        size.width - 24.5 * sw, 119.5 * sh, 
        size.width - 47.6 * sw, 115 * sh);
    path2.cubicTo(
        size.width - 70.8 * sw, 110.6 * sh, 
        size.width - 105 * sw, 129.7 * sh, 
        size.width - 124.3 * sw, 124.3 * sh);
    path2.cubicTo(
        size.width - 143.6 * sw, 118.8 * sh, 
        size.width - 148.2 * sw, 88.7 * sh, 
        size.width - 154.3 * sw, 63.9 * sh);
    path2.cubicTo(
        size.width - 160.4 * sw, 39.1 * sh, 
        size.width - 168.1 * sw, 19.5 * sh, 
        size.width - 175.8 * sw, 0);
    path2.lineTo(size.width, 0);
    path2.close();
    canvas.drawPath(path2, paint2);

    // --- Bottom Left Group (translate 0, 600) ---
    // Path 3 (Darker)
    final path3 = Path();
    path3.moveTo(0, size.height - 351.5 * sh);
    path3.cubicTo(
        46.8 * sw, size.height - 347.4 * sh, 
        93.5 * sw, size.height - 343.3 * sh, 
        134.5 * sw, size.height - 324.8 * sh);
    path3.cubicTo(
        175.5 * sw, size.height - 306.3 * sh, 
        210.8 * sw, size.height - 273.5 * sh, 
        238.3 * sw, size.height - 238.3 * sh);
    path3.cubicTo(
        265.8 * sw, size.height - 203.1 * sh, 
        285.5 * sw, size.height - 165.6 * sh, 
        303 * sw, size.height - 125.5 * sh);
    path3.cubicTo(
        320.6 * sw, size.height - 85.4 * sh, 
        336.1 * sw, size.height - 42.7 * sh, 
        351.5 * sw, size.height);
    path3.lineTo(0, size.height);
    path3.close();
    canvas.drawPath(path3, paint1);

    // Path 4 (Lighter)
    final path4 = Path();
    path4.moveTo(0, size.height - 175.8 * sh);
    path4.cubicTo(
        23.4 * sw, size.height - 173.7 * sh, 
        46.8 * sw, size.height - 171.6 * sh, 
        67.3 * sw, size.height - 162.4 * sh);
    path4.cubicTo(
        87.8 * sw, size.height - 153.1 * sh, 
        105.4 * sw, size.height - 136.7 * sh, 
        119.1 * sw, size.height - 119.1 * sh);
    path4.cubicTo(
        132.9 * sw, size.height - 101.6 * sh, 
        142.7 * sw, size.height - 82.8 * sh, 
        151.5 * sw, size.height - 62.8 * sh);
    path4.cubicTo(
        160.3 * sw, size.height - 42.7 * sh, 
        168 * sw, size.height - 21.4 * sh, 
        175.8 * sw, size.height);
    path4.lineTo(0, size.height);
    path4.close();
    canvas.drawPath(path4, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
