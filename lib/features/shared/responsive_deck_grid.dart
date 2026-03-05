import 'package:flutter/material.dart';

/// Komponen pembungkus untuk deck grid yang responsif.
/// Pada mobile (lebar < 720), menampilkan list satu kolom.
/// Pada desktop (lebar >= 720), menampilkan grid beberapa kolom dengan lebar maksimal tiap kartu.
class ResponsiveDeckGrid extends StatelessWidget {
  const ResponsiveDeckGrid({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.maxCrossAxisExtent = 480,
    this.spacing = 6,
    this.padding = EdgeInsets.zero,
  });

  final int itemCount;
  final Widget Function(BuildContext, int) itemBuilder;
  final double maxCrossAxisExtent;
  final double spacing;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: spacing),
      itemBuilder: itemBuilder,
    );
  }
}
