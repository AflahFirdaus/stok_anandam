import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Satu baris di sheet detail: label, value, dan tombol salin untuk menyalin nilai ke clipboard.
class DetailRowWithCopy extends StatelessWidget {
  const DetailRowWithCopy({
    super.key,
    required this.label,
    required this.value,
    this.labelWidth = 140,
  });

  final String label;
  final String? value;
  final double labelWidth;

  void _copyValue(BuildContext context) {
    final text = value?.trim().isEmpty ?? true ? '—' : (value ?? '—');
    Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Disalin ke clipboard'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = value?.trim().isEmpty ?? true ? '—' : (value ?? '—');
    final bool hasValue = value?.trim().isNotEmpty ?? false;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          if (hasValue)
            IconButton(
              icon: const Icon(Icons.content_copy_rounded, size: 14),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 16,
              onPressed: () => _copyValue(context),
              color: Colors.grey.shade400,
              tooltip: 'Salin',
            ),
        ],
      ),
    );
  }
}

/// Widget kecil untuk di dalam tabel agar teks bisa disalin (misal Nama Barang).
class CopyableTextCell extends StatelessWidget {
  const CopyableTextCell({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty || text == '—') return Text(text);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          icon: const Icon(Icons.content_copy_rounded, size: 12),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            Clipboard.setData(ClipboardData(text: text));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Disalin ke clipboard'),
                duration: Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          color: Colors.grey.shade400,
          tooltip: 'Salin',
        ),
      ],
    );
  }
}
