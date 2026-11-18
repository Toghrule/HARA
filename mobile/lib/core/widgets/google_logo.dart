import 'package:flutter/material.dart';

/// Google's four-colour "G", drawn from its published outline (no image file and no SVG package needed).
class GoogleLogo extends StatelessWidget {
  const GoogleLogo({this.size = 24, super.key});

  final double size;

  static const _parts = [
    (Color(0xFF4285F4), 'M45.12 24.5c0-1.56-.14-3.06-.4-4.5H24v8.51h11.84c-.51 2.75-2.06 5.08-4.39 6.64v5.52h7.11c4.16-3.83 6.56-9.47 6.56-16.17z'),
    (Color(0xFF34A853), 'M24 46c5.94 0 10.92-1.97 14.56-5.33l-7.11-5.52c-1.97 1.32-4.49 2.1-7.45 2.1-5.73 0-10.58-3.87-12.31-9.07H4.34v5.7C7.96 41.07 15.4 46 24 46z'),
    (Color(0xFFFBBC05), 'M11.69 28.18C11.25 26.86 11 25.45 11 24s.25-2.86.69-4.18v-5.7H4.34C2.85 17.09 2 20.45 2 24c0 3.55.85 6.91 2.34 9.88l7.35-5.7z'),
    (Color(0xFFEA4335), 'M24 10.75c3.23 0 6.13 1.11 8.41 3.29l6.31-6.31C34.91 4.18 29.93 2 24 2 15.4 2 7.96 6.93 4.34 14.12l7.35 5.7c1.73-5.2 6.58-9.07 12.31-9.07z'),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _GooglePainter([for (final part in _parts) (part.$1, parseSvgPath(part.$2))])),
      );
}

class _GooglePainter extends CustomPainter {
  _GooglePainter(this.parts);

  final List<(Color, Path)> parts;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    for (final (color, path) in parts) {
      canvas.drawPath(path, Paint()..color = color..isAntiAlias = true);
    }
  }

  @override
  bool shouldRepaint(_GooglePainter oldDelegate) => false;
}

final _token = RegExp(r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)');

/// Reads the small part of the SVG path language the Google "G" uses: M L H V C S Z, absolute and relative.
Path parseSvgPath(String data) {
  final tokens = _token.allMatches(data).map((m) => m[0]!).toList();
  final path = Path();
  var i = 0;
  var x = 0.0, y = 0.0, startX = 0.0, startY = 0.0;
  double? lastCx, lastCy; // the last control point, for S
  var command = 'M';

  double next() => double.parse(tokens[i++]);
  bool isNumber() => i < tokens.length && !RegExp('[A-Za-z]').hasMatch(tokens[i]);

  while (i < tokens.length) {
    if (RegExp('[A-Za-z]').hasMatch(tokens[i])) command = tokens[i++];
    final relative = command == command.toLowerCase();
    final dx = relative ? x : 0.0, dy = relative ? y : 0.0;

    switch (command.toUpperCase()) {
      case 'M':
        x = dx + next();
        y = dy + next();
        startX = x;
        startY = y;
        path.moveTo(x, y);
        command = relative ? 'l' : 'L'; // more pairs after M are lines
        lastCx = null;
      case 'L':
        x = dx + next();
        y = dy + next();
        path.lineTo(x, y);
        lastCx = null;
      case 'H':
        x = dx + next();
        path.lineTo(x, y);
        lastCx = null;
      case 'V':
        y = dy + next();
        path.lineTo(x, y);
        lastCx = null;
      case 'C':
        final x1 = dx + next(), y1 = dy + next(), x2 = dx + next(), y2 = dy + next(), ex = dx + next(), ey = dy + next();
        path.cubicTo(x1, y1, x2, y2, ex, ey);
        lastCx = x2;
        lastCy = y2;
        x = ex;
        y = ey;
      case 'S':
        final x1 = lastCx == null ? x : 2 * x - lastCx, y1 = lastCx == null ? y : 2 * y - lastCy!;
        final x2 = dx + next(), y2 = dy + next(), ex = dx + next(), ey = dy + next();
        path.cubicTo(x1, y1, x2, y2, ex, ey);
        lastCx = x2;
        lastCy = y2;
        x = ex;
        y = ey;
      case 'Z':
        path.close();
        x = startX;
        y = startY;
        lastCx = null;
      default:
        throw FormatException('Unsupported path command $command');
    }

    // Repeated numbers after a command repeat that command.
    if (command.toUpperCase() != 'Z' && !isNumber()) continue;
  }

  return path;
}
