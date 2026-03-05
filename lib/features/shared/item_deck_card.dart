import 'package:flutter/material.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';

/// Satu kartu item untuk deck view: tampilkan Nama, Kategori, Stok, HPP, Grand Total.
/// Field lain ditampilkan di halaman/dialog detail.
class ItemDeckCard extends StatelessWidget {
  const ItemDeckCard({
    super.key,
    required this.nama,
    required this.kategori,
    required this.stok,
    required this.hpp,
    required this.grandTotal,
    this.onTap,
  });

  final String nama;
  final String kategori;
  final String stok;
  final String hpp;
  final String grandTotal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    nama,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kategori,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Divider(
                  height: 1,
                  color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              const SizedBox(height: 4),
              Row(
                children: [
                  _LabelValue(
                    label: 'Stok',
                    value: stok,
                    theme: theme,
                  ),
                  const SizedBox(width: 16),
                  _LabelValue(
                    label: 'HPP',
                    value: hpp,
                    theme: theme,
                  ),
                  const Spacer(),
                  _LabelValue(
                    label: 'Grand Total',
                    value: grandTotal,
                    theme: theme,
                    valueStyle: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Kartu deck modern dengan layout fleksibel (untuk Sales, Purchase, dll).
class DataDeckCard extends StatelessWidget {
  const DataDeckCard({
    super.key,
    this.headerLeft,
    this.headerRight,
    required this.title,
    this.titleRight,
    this.subtitle,
    this.subtitleRight,
    this.rows = const [],
    this.onTap,
    this.trailing,
    this.highlightLastValue = true,
  });

  final String? headerLeft;
  final String? headerRight;
  final String title;
  final String? titleRight;
  final String? subtitle;
  final String? subtitleRight;

  final List<({String label, String value})> rows;
  final VoidCallback? onTap;

  final Widget? trailing;
  final bool highlightLastValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Row (e.g., Date and DocNo)
              if (headerLeft != null || headerRight != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (headerLeft != null)
                      Flexible(
                        child: Text(
                          headerLeft!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary.withOpacity(0.8),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            fontSize: 9,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (headerRight != null)
                      Flexible(
                        child: Text(
                          headerRight!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.6),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
              ],

              // Main Row (Title and TitleRight/Value)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            height: 1.0,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null || subtitleRight != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (subtitle != null)
                                Expanded(
                                  child: Text(
                                    subtitle!,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 10,
                                      height: 1.0,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              if (subtitleRight != null) ...[
                                if (subtitle != null) const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    subtitleRight!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withOpacity(0.7),
                                      fontStyle: FontStyle.italic,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (titleRight != null) ...[
                    const SizedBox(width: 12),
                    Text(
                      titleRight!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        height: 1.0,
                      ),
                    ),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),

              // Bottom Rows (e.g., Qty, Price)
              if (rows.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (int i = 0; i < rows.length; i++) ...[
                        Expanded(
                          child: _LabelValue(
                            label: rows[i].label,
                            value: rows[i].value,
                            theme: theme,
                            crossAxisAlignment: CrossAxisAlignment.start,
                          ),
                        ),
                        if (i < rows.length - 1)
                          Container(
                            height: 16,
                            width: 1,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            color: theme.colorScheme.outlineVariant
                                .withOpacity(0.4),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({
    required this.label,
    required this.value,
    required this.theme,
    this.valueStyle,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final TextStyle? valueStyle;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final double labelSize = isMobile ? 8.0 : 9.0;
    final double valueSize = isMobile ? 12.0 : 13.0;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: labelSize,
            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: valueStyle ??
              theme.textTheme.titleSmall?.copyWith(
                fontSize: valueSize,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
