import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

// Ported from Jakubantalik's thinking-orbs (Rubik mode)

double _hashD(num a, num b) {
  final h = math.sin(a * 12.9898 + b * 78.233) * 43758.5453;
  return h - h.floorToDouble();
}

class _Move {
  final int axis;
  final double lo;
  final double hi;
  final double ang;
  _Move(this.axis, this.lo, this.hi, this.ang);
}

class _Sc {
  final List<double> amount;
  final int active;
  _Sc(this.amount, this.active);
}

_Sc _solveCycle(double time, int count, double slotDur, double rest) {
  final cyc = 2 * count * slotDur + rest;
  final tc = time % cyc;
  final amount = List<double>.filled(count, 0.0);
  int active = -1;
  if (tc < 2 * count * slotDur) {
    final slot = (tc / slotDur).floor();
    final p = (tc - slot * slotDur) / slotDur;
    final cl = math.min(1.0, p / 0.7);
    final ep = 1.0 - math.pow(1.0 - cl, 3.0).toDouble();
    if (slot < count) {
      for (int i = 0; i < slot; i++) {
        amount[i] = 1.0;
      }
      amount[slot] = ep;
      active = slot;
    } else {
      final u = 2 * count - 1 - slot;
      for (int i = 0; i < u; i++) {
        amount[i] = 1.0;
      }
      amount[u] = 1.0 - ep;
      active = u;
    }
  }
  return _Sc(amount, active);
}

List<_Move> _makeMoves(int count) {
  final moves = <_Move>[];
  for (int i = 0; i < count; i++) {
    final axis = math.min(2, (_hashD(i, 2.3) * 3).floor());
    final lo = -1.0 + 0.5 * math.min(3, (_hashD(i, 5.9) * 4).floor());
    final dir = _hashD(i, 7.7) < 0.5 ? 1.0 : -1.0;
    moves.add(_Move(axis, lo, lo + 0.5, dir * math.pi / 2));
  }
  return moves;
}

class _Pt3Res {
  final double x, y, z;
  final bool inActive;
  _Pt3Res(this.x, this.y, this.z, this.inActive);
}

_Pt3Res _applyMoves(double px, double py, double pz, List<_Move> moves, _Sc sc) {
  double x = px;
  double y = py;
  double z = pz;
  bool inActive = false;
  for (int i = 0; i < moves.length; i++) {
    if (sc.amount[i] <= 0) continue;
    final mv = moves[i];
    final coord = mv.axis == 0 ? x : (mv.axis == 1 ? y : z);
    if (coord < mv.lo || coord >= mv.hi) continue;
    if (i == sc.active) inActive = true;
    final a = mv.ang * sc.amount[i];
    final ca = math.cos(a);
    final sa = math.sin(a);
    if (mv.axis == 0) {
      final y2 = y * ca - z * sa;
      z = y * sa + z * ca;
      y = y2;
    } else if (mv.axis == 1) {
      final x2 = x * ca + z * sa;
      z = -x * sa + z * ca;
      x = x2;
    } else {
      final x2 = x * ca - y * sa;
      y = x * sa + y * ca;
      x = x2;
    }
  }
  return _Pt3Res(x, y, z, inActive);
}

typedef _Projector = List<double> Function(double x, double y, double z);

_Projector _makeProj(double yaw, double tilt, double cx, double cy, double scale) {
  final st = math.sin(tilt);
  final ct = math.cos(tilt);
  final sy = math.sin(yaw);
  final cyw = math.cos(yaw);
  return (double x, double y, double z) {
    final x1 = x * cyw + z * sy;
    final z1 = -x * sy + z * cyw;
    final y1 = y * ct - z1 * st;
    final z2 = y * st + z1 * ct;
    return [cx + x1 * scale, cy - y1 * scale, z2];
  };
}

class _Dot {
  final double x, y, z, r, white;
  _Dot({required this.x, required this.y, required this.z, required this.r, required this.white});
}

class ThinkingOrb extends StatefulWidget {
  final double size;
  final bool isDark;
  
  const ThinkingOrb({
    super.key, 
    this.size = 64.0,
    this.isDark = false,
  });

  @override
  State<ThinkingOrb> createState() => _ThinkingOrbState();
}

class _ThinkingOrbState extends State<ThinkingOrb> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  double _t = 0;
  // Scaled counts for size=64 count=0.35
  final int latRings = 9; // Math.round(15 * sqrt(0.35))
  final int lonDensity = 24; // Math.round(40 * sqrt(0.35))
  final int moveCount = 14;
  late List<_Move> _moves;

  @override
  void initState() {
    super.initState();
    _moves = _makeMoves(moveCount);
    _ticker = createTicker((elapsed) {
      setState(() {
        _t = elapsed.inMicroseconds / 1000000.0 * 1.82; // speed=1.82
      });
    });
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: _RubikPainter(
        t: _t,
        latRings: latRings,
        lonDensity: lonDensity,
        moves: _moves,
        isDark: widget.isDark,
      ),
    );
  }
}

class _RubikPainter extends CustomPainter {
  final double t;
  final int latRings;
  final int lonDensity;
  final List<_Move> moves;
  final bool isDark;

  _RubikPainter({
    required this.t,
    required this.latRings,
    required this.lonDensity,
    required this.moves,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final R = (size.width / 2) * 0.82;
    final pt = _makeProj(t * 0.55, 0.35 + 0.1 * math.sin(t * 0.9), cx, cy, R);
    
    // rsPow = 0.6
    final rs = math.pow(size.width / 300.0, 0.6).toDouble();
    final sc = _solveCycle(t, 14, 0.42, 1.2);

    final dots = <_Dot>[];
    
    // Scaled radii for size=1.05
    final rBase = 0.6 * 1.05;
    final rDepth = 1.7 * 1.05;
    final rActive = 0.3 * 1.05;
    
    final inkFar = 0.62;
    final inkSpan = 0.54;

    for (int li = 0; li <= latRings; li++) {
      final lat = -math.pi / 2 + (li / latRings) * math.pi;
      final cosLat = math.cos(lat);
      final sinLat = math.sin(lat);
      final lonCount = math.max(1, (cosLat.abs() * lonDensity).round());
      for (int lj = 0; lj < lonCount; lj++) {
        final lon = (lj / lonCount) * 2 * math.pi;
        final res = _applyMoves(cosLat * math.cos(lon), sinLat, cosLat * math.sin(lon), moves, sc);
        final proj = pt(res.x, res.y, res.z);
        final px = proj[0];
        final py = proj[1];
        final zr = proj[2];
        final depth = (zr + 1) / 2;
        
        final r = (rBase + rDepth * depth + (res.inActive ? rActive : 0)) * rs;
        final white = inkFar - inkSpan * depth - (res.inActive ? 0.14 : 0);
        dots.add(_Dot(x: px, y: py, z: zr, r: r, white: white));
      }
    }

    dots.sort((a, b) => a.z.compareTo(b.z));

    final rMin = 0.3;
    for (final d in dots) {
      final w = math.min(1.0, math.max(0.0, d.white));
      final g = (isDark ? 1.0 - w : w) * 255.0;
      final paint = Paint()
        ..color = Color.fromARGB(255, g.round(), g.round(), g.round())
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(d.x, d.y), math.max(rMin, d.r), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RubikPainter oldDelegate) => t != oldDelegate.t || isDark != oldDelegate.isDark;
}
