import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';

/// Radius for deck cards (enterprise panels).
const double kDeckCardRadius = AppRadius.card;

/// Enterprise-style deck layout: padded scroll area with optional title and actions.
/// Use as the main content wrapper for list/detail pages.
class DeckView extends StatelessWidget {
  const DeckView({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.padding,
    this.background,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 600;
    final paddingValue = padding ?? EdgeInsets.fromLTRB(
      isNarrow ? AppSpacing.md : AppSpacing.xl,
      isNarrow ? AppSpacing.md : AppSpacing.xl,
      isNarrow ? AppSpacing.md : AppSpacing.xl,
      AppSpacing.xl,
    );
    final backgroundColor = background ?? theme.colorScheme.surfaceContainerLow.withOpacity(0.4);

    return Container(
      color: backgroundColor,
      child: SingleChildScrollView(
        padding: paddingValue,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null || (actions != null && actions!.isNotEmpty)) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (title != null)
                    Expanded(
                      child: Text(
                        title!,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: -0.25,
                        ),
                      ),
                    ),
                  if (actions != null && actions!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Enterprise-style card for deck layout: subtle border, shadow, rounded corners.
/// Use for filters, tables, and content blocks.
class DeckCard extends StatelessWidget {
  const DeckCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.actions,
    this.padding,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final EdgeInsets? padding;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paddingValue = padding ?? const EdgeInsets.all(AppSpacing.md);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(kDeckCardRadius),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: clipBehavior,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null || (actions != null && actions!.isNotEmpty)) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(
                paddingValue.left,
                paddingValue.top,
                paddingValue.right,
                AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions != null && actions!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: actions!,
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: paddingValue.left, right: paddingValue.right),
              child: Divider(height: 1, color: theme.colorScheme.outlineVariant.withOpacity(0.5)),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                paddingValue.left,
                AppSpacing.sm,
                paddingValue.right,
                paddingValue.bottom,
              ),
              child: child,
            ),
          ] else
            Padding(
              padding: paddingValue,
              child: child,
            ),
        ],
      ),
    );
  }
}

/// Page-level deck: title bar + optional breadcrumb slot, then [child] in deck style.
class PageDeck extends StatelessWidget {
  const PageDeck({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.actions,
    this.breadcrumb,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? breadcrumb;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isNarrow = MediaQuery.sizeOf(context).width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (breadcrumb != null) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(
              isNarrow ? AppSpacing.lg : AppSpacing.xl,
              AppSpacing.md,
              isNarrow ? AppSpacing.lg : AppSpacing.xl,
              0,
            ),
            child: breadcrumb!,
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (title != null || (actions != null && actions!.isNotEmpty))
          Container(
            color: theme.colorScheme.surface,
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? AppSpacing.lg : AppSpacing.xl,
              vertical: isNarrow ? AppSpacing.md : AppSpacing.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (title != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title!,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.25,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                if (actions != null && actions!.isNotEmpty)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: actions!,
                  ),
              ],
            ),
          ),
        Flexible(
          child: child,
        ),
      ],
    );
  }
}

/// Section title for use inside deck (smaller than page title).
class DeckSectionTitle extends StatelessWidget {
  const DeckSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
