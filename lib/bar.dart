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
    const stackWidthFraction = 0.9;
    final groupRanks = _selectRanks(random, 5);
    final groupCount = groupRanks.length;
    final groupDistance = size.width / (1 + groupCount);
    final groupWidth = groupDistance * groupWidthFraction;
    final startX = groupDistance - groupWidth / 2;
    final stackRanks = _selectRanks(random, ColorPalette.primary.length ~/ 2);
    final stackCount = stackRanks.length;
    final stackDistance = groupWidth / stackCount;
    final stackWidth = stackDistance * stackWidthFraction;
    final groups = List.generate(
      groupCount,
      (i) {
        final stacks = List.generate(
          stackCount,
          (j) {
            final baseColor = ColorPalette.primary[stackRanks[j]];
            final barRanks = _selectRanks(random, 4);
            final monochrome = ColorPalette.monochrome(baseColor, 4);
            final bars = List.generate(
              barRanks.length,
              (k) => Bar(
                    barRanks[k],
                    random.nextDouble() * size.height / 2,
                    monochrome[barRanks[k]],
                  ),
            );
            return BarStack(
              stackRanks[j],
              baseColor,
              startX + i * groupDistance + j * stackDistance,
              stackWidth,
              bars,
            );
          },
        );
        return BarGroup(
          groupRanks[i],
          stacks,
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
  BarGroup(this.rank, this.stacks);

  final int rank;
  final List<BarStack> stacks;

  @override
  BarGroup get empty => BarGroup(rank, <BarStack>[]);

  @override
  bool operator <(BarGroup other) => rank < other.rank;

  @override
  Tween<BarGroup> tweenTo(BarGroup other) => BarGroupTween(this, other);
}

class BarGroupTween extends Tween<BarGroup> {
  BarGroupTween(BarGroup begin, BarGroup end)
      : _stacksTween = MergeTween<BarStack>(begin.stacks, end.stacks),
        super(begin: begin, end: end) {
    assert(begin.rank == end.rank);
  }

  final MergeTween<BarStack> _stacksTween;

  @override
  BarGroup lerp(double t) => BarGroup(begin.rank, _stacksTween.lerp(t));
}

class BarStack implements MergeTweenable<BarStack> {
  BarStack(this.rank, this.baseColor, this.x, this.width, this.bars);

  final int rank;
  final Color baseColor;
  final double x;
  final double width;
  final List<Bar> bars;

  @override
  BarStack get empty => BarStack(rank, baseColor, x, 0.0, <Bar>[]);

  @override
  bool operator <(BarStack other) => rank < other.rank;

  @override
  Tween<BarStack> tweenTo(BarStack other) => BarStackTween(this, other);
}

class BarStackTween extends Tween<BarStack> {
  BarStackTween(BarStack begin, BarStack end)
      : _barsTween = MergeTween<Bar>(begin.bars, end.bars),
        super(begin: begin, end: end) {
    assert(begin.rank == end.rank);
  }

  final MergeTween<Bar> _barsTween;

  @override
  BarStack lerp(double t) => BarStack(
        begin.rank,
        Color.lerp(begin.baseColor, end.baseColor, t),
        lerpDouble(begin.x, end.x, t),
        lerpDouble(begin.width, end.width, t),
        _barsTween.lerp(t),
      );
}

class Bar extends MergeTweenable<Bar> {
  Bar(this.rank, this.height, this.color);

  final int rank;
  final double height;
  final Color color;

  @override
  Bar get empty => Bar(rank, 0.0, color);

  @override
  bool operator <(Bar other) => rank < other.rank;

  @override
  Tween<Bar> tweenTo(Bar other) => BarTween(this, other);

  static Bar lerp(Bar begin, Bar end, double t) {
    assert(begin.rank == end.rank);
    return Bar(
      begin.rank,
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
    final barPaint = Paint()..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 1.0;
    final linePath = Path();
    final chart = animation.value;
    for (final group in chart.groups) {
      for (final stack in group.stacks) {
        var y = size.height;
        for (final bar in stack.bars) {
          barPaint.color = bar.color;
          canvas.drawRect(
            Rect.fromLTWH(
              stack.x,
              y - bar.height,
              stack.width,
              bar.height,
            ),
            barPaint,
          );
          if (y < size.height) {
            linePath.moveTo(stack.x, y);
            linePath.lineTo(stack.x + stack.width, y);
          }
          y -= bar.height;
        }
        canvas.drawPath(linePath, linePaint);
        linePath.reset();
      }
    }
  }

  @override
  bool shouldRepaint(BarChartPainter old) => false;
}
