import 'package:flutter/material.dart';

/// Breakpoint lebar layar: di bawah ini filter ditumpuk satu baris per filter.
const double kFilterStackBreakpoint = 640;

/// Mengembalikan true jika filter harus ditampilkan stacked (satu baris = satu filter).
bool filterStacked(BuildContext context) {
  return MediaQuery.sizeOf(context).width < kFilterStackBreakpoint;
}

/// Satu baris filter: di mode stack = label di atas, child full width; di mode inline = label kiri, child kanan.
class ResponsiveFilterRow extends StatelessWidget {
  const ResponsiveFilterRow({
    super.key,
    required this.stack,
    required this.label,
    required this.child,
  });

  final bool stack;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 6),
          child,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ),
        const SizedBox(width: 8),
        child,
      ],
    );
  }
}

/// Chip untuk pilih tanggal (tap untuk buka date picker).
class FilterDateChip extends StatelessWidget {
  const FilterDateChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
