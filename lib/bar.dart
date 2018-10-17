import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

import 'color_palette.dart';

class BarChart {
  BarChart(this.bars);

  factory BarChart.empty(Size size) {
    return BarChart(<Bar>[]);
  }

  factory BarChart.random(Size size, Random random) {
    const barWidthFraction = 0.75;
    const minBarDistance = 20.0;
    final barCount = random.nextInt((size.width / minBarDistance).floor()) + 1;
    final barDistance = size.width / (1 + barCount);
    final barWidth = barDistance * barWidthFraction;
    final startX = barDistance - barWidth / 2;
    final color = ColorPalette.primary.random(random);
    final bars = List.generate(
      barCount,
      (i) => Bar(
            startX + i * barDistance,
            barWidth,
            random.nextDouble() * size.height,
            color,
          ),
    );
    return BarChart(bars);
  }

  final List<Bar> bars;

  static BarChart lerp(BarChart begin, BarChart end, double t) {
    final barCount = max(begin.bars.length, end.bars.length);
    final bars = List.generate(
      barCount,
      (i) => Bar.lerp(
            begin._barOrNull(i) ?? end.bars[i].collapsed,
            end._barOrNull(i) ?? begin.bars[i].collapsed,
            t,
          ),
    );
    return BarChart(bars);
  }

  Bar _barOrNull(int index) => (index < bars.length ? bars[index] : null);
}

class BarChartTween extends Tween<BarChart> {
  BarChartTween(BarChart begin, BarChart end) : super(begin: begin, end: end);

  @override
  BarChart lerp(double t) => BarChart.lerp(begin, end, t);
}

class Bar {
  Bar(this.x, this.width, this.height, this.color);

  final double x;
  final double width;
  final double height;
  final Color color;

  Bar get collapsed => Bar(x, 0.0, 0.0, color);

  static Bar lerp(Bar begin, Bar end, double t) {
    return Bar(
      lerpDouble(begin.x, end.x, t),
      lerpDouble(begin.width, end.width, t),
      lerpDouble(begin.height, end.height, t),
      Color.lerp(begin.color, end.color, t),
    );
  }
}

class BarTween extends Tween<Bar> {
  BarTween(Bar begin, Bar end) : super(begin: begin, end: end);

  @override
  Bar lerp(double t) => Bar.lerp(begin, end, t);
}

class BarChartPainter extends CustomPainter {
  BarChartPainter(Animation<BarChart> animation)
      : animation = animation,
        super(repaint: animation);

  final Animation<BarChart> animation;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final chart = animation.value;
    for (final bar in chart.bars) {
      paint.color = bar.color;
      canvas.drawRect(
        Rect.fromLTWH(
          bar.x,
          size.height - bar.height,
          bar.width,
          bar.height,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(BarChartPainter old) => false;
}
