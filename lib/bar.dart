import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

import 'color_palette.dart';
import 'tween.dart';

class BarChart {
  BarChart(this.stacks);

  factory BarChart.empty(Size size) {
    return BarChart(<BarStack>[]);
  }

  factory BarChart.random(Size size, Random random) {
    const stackWidthFraction = 0.75;
    final stackRanks = _selectRanks(random, 10);
    final stackCount = stackRanks.length;
    final stackDistance = size.width / (1 + stackCount);
    final stackWidth = stackDistance * stackWidthFraction;
    final startX = stackDistance - stackWidth / 2;
    final stacks = List.generate(
      stackCount,
      (i) {
        final barRanks = _selectRanks(random, ColorPalette.primary.length ~/ 2);
        final bars = List.generate(
          barRanks.length,
          (j) => Bar(
                barRanks[j],
                random.nextDouble() * size.height / 2,
                ColorPalette.primary[barRanks[j]],
              ),
        );
        return BarStack(
          stackRanks[i],
          startX + i * stackDistance,
          stackWidth,
          bars,
        );
      },
    );
    return BarChart(stacks);
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

  final List<BarStack> stacks;
}

class BarChartTween extends Tween<BarChart> {
  BarChartTween(BarChart begin, BarChart end)
      : _stacksTween = MergeTween<BarStack>(begin.stacks, end.stacks),
        super(begin: begin, end: end);

  final MergeTween<BarStack> _stacksTween;

  @override
  BarChart lerp(double t) => BarChart(_stacksTween.lerp(t));
}

class BarStack implements MergeTweenable<BarStack> {
  BarStack(this.rank, this.x, this.width, this.bars);

  final int rank;
  final double x;
  final double width;
  final List<Bar> bars;

  @override
  BarStack get empty => BarStack(rank, x, 0.0, <Bar>[]);

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
    for (final stack in chart.stacks) {
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

  @override
  bool shouldRepaint(BarChartPainter old) => false;
}
