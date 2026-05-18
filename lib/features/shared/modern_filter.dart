import 'package:flutter/material.dart';
import 'package:stok_anandam/core/theme/app_spacing.dart';

/// Filter chip yang bisa dipilih (untuk kategori, dll)
class CustomFilterChip extends StatelessWidget {
  const CustomFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.colorScheme.primary;
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 10 : 12,
            vertical: isMobile ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: selected
                ? chipColor.withOpacity(0.12)
                : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: selected
                  ? chipColor
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: isMobile ? 14 : 16,
                  color:
                      selected ? chipColor : theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: isMobile ? 4 : 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (theme.textTheme.labelMedium ?? const TextStyle())
                      .copyWith(
                    fontSize: isMobile ? 11 : 12,
                    color: selected
                        ? chipColor
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (selected) ...[
                SizedBox(width: isMobile ? 3 : 4),
                Icon(
                  Icons.check_circle,
                  size: isMobile ? 12 : 14,
                  color: chipColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Segmented button untuk pilihan binary (asc/desc, dll)
class FilterSegmentedButton<T> extends StatelessWidget {
  const FilterSegmentedButton({
    super.key,
    required this.value,
    required this.onChanged,
    required this.segments,
  });

  final T value;
  final void Function(T) onChanged;
  final Map<T, ({String label, IconData? icon})> segments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return Container(
      padding: EdgeInsets.all(isMobile ? 3 : 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: segments.entries.map((entry) {
          final isSelected = entry.key == value;
          final segment = entry.value;
          return Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(entry.key),
                borderRadius: BorderRadius.circular(AppSpacing.md - 4),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 8 : 10,
                    vertical: isMobile ? 5 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(AppSpacing.md - 4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (segment.icon != null) ...[
                        Icon(
                          segment.icon,
                          size: isMobile ? 14 : 16,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        SizedBox(width: isMobile ? 3 : 4),
                      ],
                      Flexible(
                        child: Text(
                          segment.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              (theme.textTheme.labelMedium ?? const TextStyle())
                                  .copyWith(
                            fontSize: isMobile ? 11 : 12,
                            color: isSelected
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Badge untuk menunjukkan filter aktif
class FilterBadge extends StatelessWidget {
  const FilterBadge({
    super.key,
    required this.label,
    this.onRemove,
    this.color,
  });

  final String label;
  final VoidCallback? onRemove;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final badgeColor = color ?? theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_alt,
            size: 14,
            color: badgeColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                size: 16,
                color: badgeColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Modern search bar dengan animasi
class ModernSearchBar extends StatefulWidget {
  const ModernSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;
  final String? hintText;
  final void Function(String)? onChanged;

  @override
  State<ModernSearchBar> createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChange);
    _hasText = widget.controller.text.isNotEmpty;
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChange);
    _animationController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final isFocused = widget.focusNode.hasFocus;
    if (_isFocused != isFocused) {
      setState(() {
        _isFocused = isFocused;
      });
      if (isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  void _onTextChange() {
    final hasText = widget.controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
    widget.onChanged?.call(widget.controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(
          color: _isFocused
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        onSubmitted: (_) => widget.onSubmitted(),
        onChanged: (_) {},
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Cari...',
          prefixIcon: Icon(
            Icons.search_rounded,
            color: _isFocused
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onChanged?.call('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 600 ? 12 : 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

/// Date chip untuk filter tanggal dengan style modern
class ModernDateChip extends StatelessWidget {
  const ModernDateChip({
    super.key,
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.surfaceContainerHighest,
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppSpacing.md),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today_rounded,
                size: 18,
                color: selected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Searchable dropdown untuk filter dengan kemampuan pencarian
/// Multi-select searchable dropdown untuk filter
class MultiSelectSearchableDropdown<T> extends StatelessWidget {
  const MultiSelectSearchableDropdown({
    super.key,
    this.label,
    required this.values,
    required this.options,
    required this.onChanged,
    this.displayText,
    this.hintText,
    this.width,
  });

  final String? label;
  final List<T> values;
  final List<T> options;
  final void Function(List<T>) onChanged;
  final String Function(T)? displayText;
  final String? hintText;
  final double? width;

  String _getDisplayText(T val) {
    return displayText?.call(val) ?? val.toString();
  }

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MultiSelectSearchableDropdownSheet<T>(
        label: label ?? '',
        values: values,
        options: options,
        displayText: displayText,
        hintText: hintText ?? 'Cari...',
        onChanged: (selected) {
          onChanged(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
        InkWell(
          onTap: () => _showSearchDialog(context),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Container(
            width: width ?? double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isMobile ? 12 : 14,
            ),
            decoration: BoxDecoration(
              color: values.isNotEmpty
                  ? theme.colorScheme.primary.withOpacity(0.05)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(
                color: values.isNotEmpty
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: values.isNotEmpty ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    values.isEmpty
                        ? (hintText ?? 'Semua')
                        : values.length == 1
                            ? _getDisplayText(values.first)
                            : '${values.length} Item Terpilih',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: values.isNotEmpty
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          values.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: values.isNotEmpty
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MultiSelectSearchableDropdownSheet<T> extends StatefulWidget {
  const _MultiSelectSearchableDropdownSheet({
    required this.label,
    required this.values,
    required this.options,
    this.displayText,
    required this.hintText,
    required this.onChanged,
  });

  final String label;
  final List<T> values;
  final List<T> options;
  final String Function(T)? displayText;
  final String hintText;
  final void Function(List<T>) onChanged;

  @override
  State<_MultiSelectSearchableDropdownSheet<T>> createState() =>
      _MultiSelectSearchableDropdownSheetState<T>();
}

class _MultiSelectSearchableDropdownSheetState<T>
    extends State<_MultiSelectSearchableDropdownSheet<T>> {
  late List<T> _selectedValues;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selectedValues = List<T>.from(widget.values);
  }

  List<T> get _filteredOptions {
    if (_query.isEmpty) return widget.options;
    return widget.options.where((option) {
      final text = widget.displayText?.call(option) ?? option.toString();
      return text.toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      height: mediaQuery.size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (_selectedValues.length == widget.options.length) {
                        _selectedValues = [];
                      } else {
                        _selectedValues = List<T>.from(widget.options);
                      }
                    });
                  },
                  child: Text(_selectedValues.length == widget.options.length
                      ? 'Unselect All'
                      : 'Select All'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredOptions.length,
              itemBuilder: (context, index) {
                final option = _filteredOptions[index];
                final isSelected = _selectedValues.contains(option);
                final text =
                    widget.displayText?.call(option) ?? option.toString();

                return CheckboxListTile(
                  value: isSelected,
                  title: Text(text),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        _selectedValues.add(option);
                      } else {
                        _selectedValues.remove(option);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.trailing,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onChanged(_selectedValues);
                      Navigator.pop(context);
                    },
                    child: const Text('Pilih'),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: mediaQuery.padding.bottom),
        ],
      ),
    );
  }
}

/// Searchable dropdown untuk filter dengan kemampuan pencarian
class SearchableDropdown<T> extends StatelessWidget {
  const SearchableDropdown({
    super.key,
    this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.displayText,
    this.selectedDisplayText,
    this.hintText,
    this.width,
    this.initialSearchText,
    this.onSearchChanged,
  });

  final String? label;
  final T? value;
  final List<T> options;
  final void Function(T?) onChanged;
  final String Function(T)? displayText;
  final String Function(T)? selectedDisplayText;
  final String? hintText;
  final double? width;
  final String? initialSearchText;
  final void Function(String)? onSearchChanged;

  String _getDisplayText(T? val) {
    if (val == null) return hintText ?? 'Semua';
    if (selectedDisplayText != null) return selectedDisplayText!(val);
    return displayText?.call(val) ?? val.toString();
  }

  void _showSearchDialog(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _SearchableDropdownSheet<T>(
        label: label ?? '',
        value: value,
        options: options,
        displayText: displayText,
        hintText: hintText ?? 'Semua',
        initialSearchText: initialSearchText,
        onSearchChanged: onSearchChanged,
        onChanged: (selected) {
          Navigator.of(ctx).pop();
          onChanged(selected);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = this.width ??
        (MediaQuery.sizeOf(context).width >= 720 ? 200.0 : double.infinity);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSearchDialog(context),
          borderRadius: BorderRadius.circular(AppSpacing.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: value != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: value != null
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outlineVariant.withOpacity(0.5),
                width: value != null ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(AppSpacing.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getDisplayText(value),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: value != null
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight:
                          value != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
                  color: value != null
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchableDropdownSheet<T> extends StatefulWidget {
  const _SearchableDropdownSheet({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.displayText,
    required this.hintText,
    this.initialSearchText,
    this.onSearchChanged,
  });

  final String label;
  final T? value;
  final List<T> options;
  final void Function(T?) onChanged;
  final String Function(T)? displayText;
  final String hintText;
  final String? initialSearchText;
  final void Function(String)? onSearchChanged;

  @override
  State<_SearchableDropdownSheet<T>> createState() =>
      _SearchableDropdownSheetState<T>();
}

class _SearchableDropdownSheetState<T>
    extends State<_SearchableDropdownSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  List<T> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = widget.options;
    if (widget.initialSearchText != null) {
      _searchController.text = widget.initialSearchText!;
      _filterOptions();
    }
    _searchController.addListener(_filterOptions);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterOptions);
    _searchController.dispose();
    super.dispose();
  }

  void _filterOptions() {
    final query = _searchController.text.toLowerCase();
    widget.onSearchChanged?.call(_searchController.text);
    setState(() {
      if (query.isEmpty) {
        _filteredOptions = widget.options;
      } else {
        _filteredOptions = widget.options.where((option) {
          final text = widget.displayText?.call(option) ?? option.toString();
          return text.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.75;

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate available height for ListView
          // Header: drag handle (12 + 4) + title (16 + 20 + 16) + search (56) + spacing (8) = ~132
          const headerHeight = 132.0;
          final listHeight = constraints.maxHeight - headerHeight;

          return Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Pilih ${widget.label}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari ${widget.label.toLowerCase()}...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: listHeight > 0 ? listHeight : 200,
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount:
                      _filteredOptions.length + 1, // +1 for "Semua" option
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      // "Semua" option
                      final isSelected = widget.value == null;
                      return ListTile(
                        leading: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey,
                        ),
                        title: Text(widget.hintText),
                        onTap: () => widget.onChanged(null),
                      );
                    }
                    final option = _filteredOptions[index - 1];
                    final isSelected = widget.value == option;
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey,
                      ),
                      title: Text(widget.displayText?.call(option) ??
                          option.toString()),
                      onTap: () => widget.onChanged(option),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Compact dropdown untuk filter spesifikasi
class CompactFilterDropdown<T> extends StatelessWidget {
  const CompactFilterDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
    this.displayText,
  });

  final String label;
  final T? value;
  final List<T> options;
  final void Function(T?) onChanged;
  final String Function(T)? displayText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use a list to collect items and ensure uniqueness by manual value comparison (Matching DropdownButton behavior)
    final items = <DropdownMenuItem<T>>[];

    void addItemIfUnique(T? val, Widget child) {
      if (!items.any((item) => item.value == val)) {
        items.add(DropdownMenuItem<T>(value: val, child: child));
      }
    }

    // 1. Add "Semua" option (null)
    addItemIfUnique(
      null,
      Text(
        'Semua $label',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );

    // 2. Add current value if it's not null (Ensures it's present early to avoid error)
    if (value != null) {
      addItemIfUnique(
        value,
        Text(
          displayText?.call(value as T) ?? value.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    // 3. Add other options
    for (final option in options) {
      addItemIfUnique(
        option,
        Text(
          displayText?.call(option) ?? option.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value != null
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          border: Border.all(
            color: value != null
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withOpacity(0.5),
            width: value != null ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSpacing.md),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            value: value,
            isDense: true,
            isExpanded: true,
            hint: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: value != null
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            items: items,
            onChanged: onChanged,
            style: theme.textTheme.labelMedium?.copyWith(
              color: value != null
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Container untuk grup filter dengan title
class FilterGroup extends StatelessWidget {
  const FilterGroup({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: isMobile ? 14 : 16, color: theme.colorScheme.primary),
              SizedBox(width: isMobile ? 4 : 6),
            ],
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (theme.textTheme.labelMedium ?? const TextStyle()).copyWith(
                  fontSize: isMobile ? 11 : 12,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: isMobile ? 8 : 10),
        Wrap(
          spacing: isMobile ? 4 : 6,
          runSpacing: isMobile ? 4 : 6,
          children: children,
        ),
      ],
    );
  }
}

/// Filter container dengan search bar yang selalu terlihat dan filter yang bisa di-collapse
class FilterContainerWithSearch extends StatelessWidget {
  const FilterContainerWithSearch({
    super.key,
    required this.searchBar,
    required this.filterContent,
    this.title = 'Filter & Urutkan',
    this.initiallyExpanded = false,
    this.activeFilters,
  });

  final Widget searchBar;
  final Widget filterContent;
  final String title;
  final bool initiallyExpanded;
  final List<Widget>? activeFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Search bar selalu terlihat
          searchBar,
          // Filter aktif (termasuk emp code) selalu terlihat saat ada filter
          if (activeFilters != null && activeFilters!.isNotEmpty) ...[
            SizedBox(height: isDesktop ? 12 : 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activeFilters!,
            ),
          ],
          SizedBox(height: isDesktop ? 16 : 20),
          // Filter yang bisa di-collapse
          CollapsibleFilterContainer(
            title: title,
            initiallyExpanded: initiallyExpanded,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                filterContent,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Collapsible filter container dengan animasi
class CollapsibleFilterContainer extends StatefulWidget {
  const CollapsibleFilterContainer({
    super.key,
    required this.child,
    this.title = 'Filter & Urutkan',
    this.initiallyExpanded = false,
  });

  final Widget child;
  final String title;
  final bool initiallyExpanded;

  @override
  State<CollapsibleFilterContainer> createState() =>
      _CollapsibleFilterContainerState();
}

class _CollapsibleFilterContainerState extends State<CollapsibleFilterContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 16 : 20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.lg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(AppSpacing.md),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  RotationTransition(
                    turns: Tween<double>(begin: 0.0, end: 0.5)
                        .animate(_expandAnimation),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                widget.child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- Fixed search bar + filter sidebar (desktop-style) ---

/// Shows a filter sidebar that slides in from the right (drawer-like popup for desktop).
/// [filterContentBuilder] receives [closeSidebar] and [refreshSidebar].
/// Call [closeSidebar] after user selects an option so the sidebar closes; when they open
/// filter again, the latest selection will be shown. Do not use [refreshSidebar] for
/// normal selection (it would stack dialogs). For date chips: close first, then show
/// date picker in a post-frame callback so the picker is visible.
void showFilterSidebar(
  BuildContext context, {
  required String title,
  required Widget Function(
          void Function() closeSidebar, void Function() refreshSidebar)
      filterContentBuilder,
  double width = 380,
}) {
  final navigatorContext = context;
  void openSidebar() {
    final screenWidth = MediaQuery.sizeOf(navigatorContext).width;
    final maxSidebarWidth = screenWidth * 0.85;
    final effectiveWidth = width > maxSidebarWidth ? maxSidebarWidth : width;
    showGeneralDialog<void>(
      context: navigatorContext,
      barrierDismissible: true,
      barrierColor: Colors.black26,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, dialogChild) {
        return StatefulBuilder(
          builder: (context, setStateInternal) {
            void closeSidebar() => Navigator.of(context).pop();
            void refreshSidebar() {
              // Instant refresh without popping the dialog
              setStateInternal(() {});
            }

            final child = filterContentBuilder(closeSidebar, refreshSidebar);
            final slideAnimation = Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));
            return Align(
              alignment: Alignment.centerRight,
              child: SlideTransition(
                position: slideAnimation,
                child: Material(
                  color: Colors.transparent,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final screenW = MediaQuery.sizeOf(context).width;
                      final isMobile = screenW < 720;
                      if (screenW <= 0) {
                        return const SizedBox.shrink();
                      }
                      final maxW =
                          isMobile ? (screenW * 0.88) : (screenW * 0.45);
                      final byScreen =
                          effectiveWidth > maxW ? maxW : effectiveWidth;
                      final maxAllowed = constraints.maxWidth.isFinite &&
                              constraints.maxWidth > 0
                          ? constraints.maxWidth
                          : double.infinity;
                      final safeMax = maxAllowed.isFinite
                          ? maxAllowed
                          : (screenW - 48).clamp(1.0, double.infinity);
                      final capped = byScreen > safeMax ? safeMax : byScreen;
                      final sidebarWidth = capped < 1.0 ? 1.0 : capped;
                      return Container(
                        width: sidebarWidth,
                        height: MediaQuery.sizeOf(context).height,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(20)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 24,
                              offset: const Offset(-4, 0),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(
                                isMobile ? 16 : 24,
                                isMobile ? 16 : 24,
                                isMobile ? 16 : 24,
                                isMobile ? 12 : 16,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.tune_rounded,
                                    size: isMobile ? 20 : 24,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  SizedBox(width: isMobile ? 8 : 12),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: (isMobile
                                              ? Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                              : Theme.of(context)
                                                  .textTheme
                                                  .titleLarge)
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close_rounded,
                                        size: isMobile ? 20 : 24),
                                    onPressed: closeSidebar,
                                    tooltip: MaterialLocalizations.of(context)
                                        .closeButtonTooltip,
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.all(isMobile ? 16 : 24),
                                child: child,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  openSidebar();
}

/// Layout with a fixed search bar at the top (does not scroll) and expanded scrollable content.
/// Includes a Filter button that opens a right-side sidebar popup (slide-in from right).
/// [filterContentBuilder] receives (closeSidebar, refreshSidebar). Call closeSidebar after
/// selection so the sidebar closes; reopening will show the updated selection.
class FixedSearchFilterLayout extends StatelessWidget {
  const FixedSearchFilterLayout({
    super.key,
    required this.searchBar,
    required this.filterTitle,
    required this.filterContentBuilder,
    required this.child,
    this.activeFilterBadges,
    this.filterTooltip = 'Filter',
  });

  /// The search bar widget (e.g. [ModernSearchBar]). Stays fixed at top.
  final Widget searchBar;

  /// Title shown in the filter sidebar.
  final String filterTitle;

  /// Builder for filter sidebar content. Receives [closeSidebar]; panggil setelah user pilih opsi.
  final Widget Function(
          void Function() closeSidebar, void Function() refreshSidebar)
      filterContentBuilder;

  /// The scrollable content below the fixed bar (e.g. ListView, table, etc.).
  final Widget child;

  /// Optional badges shown next to the Filter button when filters are active.
  final List<Widget>? activeFilterBadges;

  /// Tooltip for the filter button.
  final String filterTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 720;
    final isMobile = width < 720;
    // Konsisten pakai AppSpacing.lg (16) untuk mobile agar selaras dengan padding halaman
    final barPadding = isMobile ? AppSpacing.lg : 16.0;
    const gapAfterBar = AppSpacing.lg;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Fixed top bar: does NOT scroll
        Container(
          padding: EdgeInsets.all(barPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppSpacing.lg),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = width < 600;
              final compact = width < 720;
              final barGap = isMobile ? 12.0 : 8.0;
              final filterButton = Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    final w = MediaQuery.sizeOf(context).width;
                    showFilterSidebar(
                      context,
                      title: filterTitle,
                      filterContentBuilder: filterContentBuilder,
                      width: w > 0 ? (w * 0.85) : 380,
                    );
                  },
                  borderRadius: BorderRadius.circular(AppSpacing.md),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 14 : 16,
                      vertical: compact ? 10 : 12,
                    ),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                      border: Border.all(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: compact ? 18 : 20,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        SizedBox(width: compact ? 6 : 8),
                        Text(
                          'Filter',
                          style: (compact
                                  ? theme.textTheme.labelMedium
                                  : theme.textTheme.labelLarge)
                              ?.copyWith(
                            fontSize: compact ? 13 : null,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: searchBar),
                      SizedBox(width: barGap),
                      filterButton,
                    ],
                  ),
                  if (activeFilterBadges != null &&
                      activeFilterBadges!.isNotEmpty) ...[
                    SizedBox(height: barGap),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: activeFilterBadges!,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: gapAfterBar),
        // Scrollable content
        Expanded(child: child),
      ],
    );
  }
}

/// Footer untuk filter yang berisi tombol Terapkan dan Reset
class FilterFooter extends StatelessWidget {
  const FilterFooter({
    super.key,
    required this.onApply,
    required this.onReset,
    this.applyLabel = 'Terapkan',
    this.resetLabel = 'Reset',
    this.additionalAction,
  });

  final VoidCallback onApply;
  final VoidCallback onReset;
  final String applyLabel;
  final String resetLabel;
  final Widget? additionalAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 720;

    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (additionalAction != null) ...[
            SizedBox(
              width: double.infinity,
              child: additionalAction!,
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReset,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Text(
                    resetLabel,
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: onApply,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.md),
                    ),
                    backgroundColor: theme.colorScheme.primary,
                  ),
                  child: Text(
                    applyLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class FilterLabel extends StatelessWidget {
  final String label;
  const FilterLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }
}
