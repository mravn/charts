import 'dart:math';

import 'package:flutter/material.dart';

class ColorPalette {
  static final ColorPalette primary = ColorPalette(<Color>[
    Colors.blue[400],
    Colors.red[400],
    Colors.green[400],
    Colors.yellow[400],
    Colors.purple[400],
    Colors.orange[400],
    Colors.teal[400],
  ]);

  ColorPalette(List<Color> colors) : _colors = colors {
    assert(colors.isNotEmpty);
  }

  factory ColorPalette.monochrome(Color base, int length) {
    return ColorPalette(List.generate(
      length,
      (i) => _brighterColor(base, i, length),
    ));
  }

  static Color _brighterColor(Color base, int i, int n) {
    return Color.fromARGB(
      base.alpha,
      _brighterComponent(base.red, i, n),
      _brighterComponent(base.green, i, n),
      _brighterComponent(base.blue, i, n),
    );
  }

  static int _brighterComponent(int base, int i, int n) {
    return (base + i * (255 - base) / n).floor();
  }

  final List<Color> _colors;

  Color operator [](int index) => _colors[index % _colors.length];

  int get length => _colors.length;

  Color random(Random random) => this[random.nextInt(_colors.length)];
}
