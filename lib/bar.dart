import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

import 'color_palette.dart';
import 'tween.dart';

class BarChart {
  BarChart(this.groups);

  factory BarChart.empty(Size size) {
    return BarChart(<BarGroup>[]);
  }

  factory BarChart.random(Size size, Random random) {
    const groupWidthFraction = 0.75;
    const barWidthFraction = 0.9;
    final groupRanks = _selectRanks(random, 5);
    final groupCount = groupRanks.length;
    final groupDistance = size.width / (1 + groupCount);
    final groupWidth = groupDistance * groupWidthFraction;
    final startX = groupDistance - groupWidth / 2;
    final barRanks = _selectRanks(random, ColorPalette.primary.length ~/ 2);
    final barCount = barRanks.length;
    final barDistance = groupWidth / barCount;
    final barWidth = barDistance * barWidthFraction;
    final groups = List.generate(
      groupCount,
      (i) {
        final bars = List.generate(
          barCount,
          (j) => Bar(
                barRanks[j],
                startX + i * groupDistance + j * barDistance,
                barWidth,
                random.nextDouble() * size.height,
                ColorPalette.primary[barRanks[j]],
              ),
        );
        return BarGroup(
          groupRanks[i],
          bars,
        );
      },
    );
    return BarChart(groups);
  }

  static List<int> _selectRanks(Random random, int cap) {
    final ranks = <int>[];
    var rank = 0;
    while (true) {
      rank += random.nextInt(2);
      if (cap <= rank) break;
      ranks.add(rank);
      rank++;
    }
    return ranks;
  }

  final List<BarGroup> groups;
}

class BarChartTween extends Tween<BarChart> {
  BarChartTween(BarChart begin, BarChart end)
      : _groupsTween = MergeTween<BarGroup>(begin.groups, end.groups),
        super(begin: begin, end: end);

  final MergeTween<BarGroup> _groupsTween;

  @override
  BarChart lerp(double t) => BarChart(_groupsTween.lerp(t));
}

class BarGroup implements MergeTweenable<BarGroup> {
  BarGroup(this.rank, this.bars);

  final int rank;
  final List<Bar> bars;

  @override
  BarGroup get empty => BarGroup(rank, <Bar>[]);

  @override
  bool operator <(BarGroup other) => rank < other.rank;

  @override
  Tween<BarGroup> tweenTo(BarGroup other) => BarGroupTween(this, other);
}

class BarGroupTween extends Tween<BarGroup> {
  BarGroupTween(BarGroup begin, BarGroup end)
      : _barsTween = MergeTween<Bar>(begin.bars, end.bars),
        super(begin: begin, end: end) {
    assert(begin.rank == end.rank);
  }

  final MergeTween<Bar> _barsTween;

  @override
  BarGroup lerp(double t) => BarGroup(begin.rank, _barsTween.lerp(t));
}

class Bar extends MergeTweenable<Bar> {
  Bar(this.rank, this.x, this.width, this.height, this.color);

  final int rank;
  final double x;
  final double width;
  final double height;
  final Color color;

  @override
  Bar get empty => Bar(rank, x, 0.0, 0.0, color);

  @override
  bool operator <(Bar other) => rank < other.rank;

  @override
  Tween<Bar> tweenTo(Bar other) => BarTween(this, other);

  static Bar lerp(Bar begin, Bar end, double t) {
    assert(begin.rank == end.rank);
    return Bar(
      begin.rank,
      lerpDouble(begin.x, end.x, t),
      lerpDouble(begin.width, end.width, t),
      lerpDouble(begin.height, end.height, t),
      Color.lerp(begin.color, end.color, t),
    );
  }
}

class BarTween extends Tween<Bar> {
  BarTween(Bar begin, Bar end) : super(begin: begin, end: end) {
    assert(begin.rank == end.rank);
  }

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
    for (final group in chart.groups) {
      for (final bar in group.bars) {
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
  }

  @override
  bool shouldRepaint(BarChartPainter old) => false;
}
