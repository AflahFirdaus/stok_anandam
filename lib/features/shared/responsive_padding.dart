import 'package:flutter/material.dart';

/// Helper untuk mendapatkan padding responsif berdasarkan ukuran layar
class ResponsivePadding {
  ResponsivePadding._();

  /// Padding horizontal berdasarkan lebar layar.
  /// Mobile (< 720) pakai 16 agar konsisten dengan area search/filter.
  static double horizontal(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width < 720 ? 16.0 : 24.0;
  }

  /// Padding vertical berdasarkan tinggi layar
  static double vertical(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return height < 600 ? 16.0 : 24.0;
  }

  /// Padding semua sisi berdasarkan ukuran layar
  static EdgeInsets all(BuildContext context) {
    final h = horizontal(context);
    final v = vertical(context);
    return EdgeInsets.fromLTRB(h, v, h, v);
  }

  /// Padding horizontal saja
  static EdgeInsets horizontalOnly(BuildContext context) {
    final h = horizontal(context);
    return EdgeInsets.symmetric(horizontal: h);
  }

  /// Padding vertical saja
  static EdgeInsets verticalOnly(BuildContext context) {
    final v = vertical(context);
    return EdgeInsets.symmetric(vertical: v);
  }

  /// Spacing kecil untuk layar kecil
  static double spacing(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return height < 600 ? 12.0 : 16.0;
  }

  /// Spacing besar untuk layar kecil
  static double spacingLarge(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    return height < 600 ? 16.0 : 24.0;
  }
}
