import 'package:flutter/material.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';

/// DataDeckCard — kartu deck dengan layout fleksibel.
class DataDeckCard extends StatelessWidget {
  const DataDeckCard({
    super.key,
    this.headerLeft,
    this.headerRight,
    required this.title,
    this.titleRight,
    this.subtitle,
    this.subtitleRight,
    this.chip,
    this.trailing,
    this.extraContent,
    this.rows = const [],
    this.onTap,
    this.highlightLastValue = false,
  });

  final String? headerLeft;
  final String? headerRight;
  final String title;
  final String? titleRight;
  final String? subtitle;
  final String? subtitleRight;
  final Widget? chip;
  final Widget? trailing;
  final Widget? extraContent;
  final List<({String label, String value})> rows;
  final VoidCallback? onTap;
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
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (headerLeft != null || headerRight != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                if (headerLeft != null)
                                  Text(headerLeft!,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                if (headerRight != null) ...[
                                  const Spacer(),
                                  Text(headerRight!,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                              color: theme
                                                  .colorScheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ],
                              ],
                            ),
                          ),
                        Text(title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),

if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                        if (subtitleRight != null && subtitleRight!.isNotEmpty)
                          ...[
                            const SizedBox(height: 2),
                            Text(subtitleRight!,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
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
                  if (chip != null) ...[
                    const SizedBox(width: 8),
                    chip!,
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
                  ),
                  child: Row(
                    children: [
                      for (int i = 0; i < rows.length; i++) ...[
                        if (i > 0) _VerticalDivider(),
                        Expanded(
                          child: _LabelValue(
                            label: rows[i].label,
                            value: rows[i].value,
                            theme: theme,
                            isInverse: true,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            valueStyle: (highlightLastValue &&
                                    i == rows.length - 1)
                                ? theme.textTheme.titleSmall?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
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