import 'package:flutter/material.dart';

class ChromeTabGroup<T> {
  final String id;
  final String label;
  final List<T> children;

  ChromeTabGroup({
    required this.id,
    required this.label,
    required this.children,
  });
}

class ChromeTab extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int? count;
  final bool isParent;

  const ChromeTab({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.count,
    this.isParent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor =
        isParent ? theme.colorScheme.primary : theme.colorScheme.secondary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: EdgeInsets.only(
          left: isParent ? 8 : 4,
          right: isParent ? 0 : 4,
          top: isParent ? 4 : 0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isParent ? 20 : 16,
          vertical: isParent ? 10 : 8,
        ),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isParent
                      ? [
                          theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.7),
                          theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.2),
                        ]
                      : [
                          theme.colorScheme.surface,
                          theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.05),
                        ],
                )
              : null,
          color: !isActive ? Colors.transparent : null,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
          border: isActive
              ? Border.all(
                  color: activeColor.withValues(alpha: isParent ? 0.3 : 0.1),
                  width: 1,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isParent ? 14 : 13,
                letterSpacing: isParent ? 0.3 : 0.1,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : Colors.grey.shade600,
              ),
            ),
            if (count != null && count! > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? [activeColor, activeColor.withValues(alpha: 0.8)]
                        : [Colors.grey.shade400, Colors.grey.shade300],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: activeColor.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
