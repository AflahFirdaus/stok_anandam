import 'dart:async';
import 'package:dio/dio.dart';
import 'package:stok_anandam/injection.dart';

class AutocompleteService {
  final Dio _dio = getIt<Dio>();
  
  // Local Caching: Map<query, suggestions>
  final Map<String, List<String>> _cache = {};

  Future<List<String>> getSuggestions(String query) async {
    if (query.isEmpty) return [];

    // 1. Check Cache
    if (_cache.containsKey(query)) {
      return _cache[query]!;
    }

    try {
      // 2. API Request (assuming endpoint provided by user)
      final response = await _dio.get(
        '/api/search/suggestions',
        queryParameters: {'query': query},
      );

      if (response.statusCode == 200) {
        // Assume minimal JSON payload: ["item1", "item2"] or List of objects
        final List<dynamic> data = response.data;
        final suggestions = data.map((e) => e.toString()).toList();

        // 3. Save to Cache
        _cache[query] = suggestions;
        
        return suggestions;
      }
    } catch (e) {
      // Handle error or return empty
      print('Autocomplete Error: $e');
    }

    return [];
  }

  void clearCache() => _cache.clear();
}
