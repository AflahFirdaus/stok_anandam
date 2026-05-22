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
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.04),
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
              const SizedBox(height: 8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade600,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _LabelValue(
                        label: 'Stok',
                        value: stok,
                        theme: theme,
                        isInverse: true,
                      ),
                    ),
                    _VerticalDivider(),
                    Expanded(
                      child: _LabelValue(
                        label: 'Modal',
                        value: hpp,
                        theme: theme,
                        isInverse: true,
                      ),
                    ),
                    _VerticalDivider(),
                    Expanded(
                      child: _LabelValue(
                        label: 'Pricelist',
                        value: grandTotal,
                        theme: theme,
                        isInverse: true,
                        valueStyle: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
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
    this.extraContent,
    this.highlightLastValue = true,
  });

  final String? headerLeft;
  final String? headerRight;
  final String title;
  final String? titleRight;
  final String? subtitle;
  final String? subtitleRight;
  final Widget? extraContent;

  final List<({String label, String value})> rows;
  final VoidCallback? onTap;

  final Widget? trailing;
  final bool highlightLastValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.03),
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
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            fontSize: 10,
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
                                .withValues(alpha: 0.6),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            height: 1.2,
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
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 13,
                                      height: 1.3,
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
                                          .withValues(alpha: 0.7),
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
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                        height: 1.2,
                      ),
                    ),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),

              if (extraContent != null) ...[
                const SizedBox(height: 8),
                extraContent!,
              ],

              if (rows.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 222, 235, 247),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromARGB(255, 222, 235, 247)
                            .withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      for (int i = 0; i < rows.length; i++) ...[
                        Expanded(
                          child: _LabelValue(
                            label: rows[i].label,
                            value: rows[i].value,
                            theme: theme,
                            isInverse: true,
                            crossAxisAlignment: CrossAxisAlignment.start,
                          ),
                        ),
                        if (i < rows.length - 1) _VerticalDivider(),
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

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      width: 1.5,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color.fromARGB(255, 57, 124, 223).withValues(alpha: 0.4),
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
    this.isInverse = false,
  });

  final String label;
  final String value;
  final ThemeData theme;
  final TextStyle? valueStyle;
  final CrossAxisAlignment crossAxisAlignment;
  final bool isInverse;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final double labelSize = isMobile ? 8.0 : 10.0;
    final double valueSize = isMobile ? 10.0 : 12.0;

    final Color labelColor = isInverse
        ? Colors.black.withValues(alpha: 0.8)
        : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final Color valueColor = isInverse
        ? Colors.black
        : theme.colorScheme.onSurface.withValues(alpha: 0.8);

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: labelSize,
            color: labelColor,
            fontWeight: FontWeight.w600,
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
                color: valueColor,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
