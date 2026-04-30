import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:stok_anandam/features/shared/autocomplete_service.dart';
import 'package:stok_anandam/injection.dart';

class AutocompleteSearchField extends StatefulWidget {
  final String label;
  final String hint;
  final Function(String) onSelected;
  final TextEditingController? controller;

  const AutocompleteSearchField({
    super.key,
    required this.label,
    required this.hint,
    required this.onSelected,
    this.controller,
  });

  @override
  State<AutocompleteSearchField> createState() => _AutocompleteSearchFieldState();
}

class _AutocompleteSearchFieldState extends State<AutocompleteSearchField> {
  final AutocompleteService _service = getIt<AutocompleteService>();
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return TypeAheadField<String>(
      controller: _controller,
      builder: (context, controller, focusNode) {
        return TextField(
          controller: controller,
          focusNode: focusNode,
          autofocus: false,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search),
            border: const OutlineInputBorder(),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _controller.clear();
                      setState(() {});
                    },
                  )
                : null,
          ),
        );
      },
      // Debounce: 300ms (built-in in flutter_typeahead)
      debounceDuration: const Duration(milliseconds: 300),
      
      // Suggestions Callback with Caching Logic inside Service
      suggestionsCallback: (search) async {
        if (search.length < 2) return []; // Optional: only search if >= 2 chars
        return await _service.getSuggestions(search);
      },

      // UI: Loading state
      loadingBuilder: (context) => const SizedBox(
        height: 100,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),

      // UI: Suggestions list item
      itemBuilder: (context, suggestion) {
        return ListTile(
          title: Text(suggestion),
          leading: const Icon(Icons.history, size: 18),
        );
      },

      // UI: Empty state
      emptyBuilder: (context) => const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('Tidak ada saran ditemukan'),
      ),

      // Action on selection
      onSelected: (suggestion) {
        _controller.text = suggestion;
        widget.onSelected(suggestion);
      },
    );
  }
}
