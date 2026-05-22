import 'package:flutter/material.dart';

class InProgressPanel extends StatelessWidget {
  const InProgressPanel({
    super.key,
    this.items = const [],
    this.onCancel,
    this.onTap,
  });

  final List<InProgressItem> items;
  final void Function(int index)? onCancel;
  final void Function(int index)? onTap;

  static const double preferredWidth = 280;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = MediaQuery.sizeOf(context).width;
        final maxW = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : (screenW > 0 ? screenW : preferredWidth);
        final w = (maxW < preferredWidth ? maxW : preferredWidth)
            .clamp(1.0, preferredWidth);
        return Container(
          width: w,
          margin: const EdgeInsets.only(right: 24, top: 24, bottom: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(
                  'Dalam Proses',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Tidak ada proses',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                )
              else
                ...items.asMap().entries.map((e) => _ProgressTile(
                      item: e.value,
                      onCancel: () => onCancel?.call(e.key),
                      onTap: () => onTap?.call(e.key),
                    )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}

class InProgressItem {
  const InProgressItem({
    required this.title,
    required this.progress,
    this.subtitle,
    this.iconColor,
  });

  final String title;
  final double progress;
  final String? subtitle;
  final Color? iconColor;
}

class _ProgressTile extends StatelessWidget {
  const _ProgressTile({
    required this.item,
    this.onCancel,
    this.onTap,
  });

  final InProgressItem item;
  final VoidCallback? onCancel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = item.iconColor ?? Colors.blue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.description_outlined,
                        size: 18, color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF374151),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.subtitle != null)
                          Text(
                            item.subtitle!,
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close,
                        size: 18, color: Colors.grey.shade500),
                    onPressed: onCancel,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
