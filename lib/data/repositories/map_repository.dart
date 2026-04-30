import 'package:dio/dio.dart';
import '../models/map_delivery.dart';

class MapRepository {
  final Dio _dio;

  MapRepository(this._dio);

  Future<List<MapDelivery>> getTodaysDeliveries() async {
    try {
      final response = await _dio.get('/api/map/pengiriman');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['data'];
        return data.map((json) => MapDelivery.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load map deliveries');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> searchLocationPhoton(String query) async {
    try {
      // Gunakan instance Dio baru agar tidak terpengaruh interceptor global (seperti Auth Header)
      final photonDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'StokAnandamApp/1.0',
        },
      ));

      // Cek apakah query adalah koordinat (lat, lon)
      final coordRegExp = RegExp(r'^([-+]?\d{1,2}(?:\.\d+)?),\s*([-+]?\d{1,3}(?:\.\d+)?)$');
      final match = coordRegExp.firstMatch(query.trim());

      Response response;
      if (match != null) {
        final lat = match.group(1);
        final lon = match.group(2);
        response = await photonDio.get(
          'https://photon.komoot.io/reverse',
          queryParameters: {
            'lat': lat,
            'lon': lon,
          },
        );
      } else {
        response = await photonDio.get(
          'https://photon.komoot.io/api',
          queryParameters: {
            'q': query,
            'limit': 10,
          },
        );
      }
      
      final List<dynamic> features = response.data['features'] ?? [];
      return features.map((f) {
        final props = f['properties'] ?? {};
        final geom = f['geometry']?['coordinates'] ?? [0.0, 0.0];
        
        final name = props['name'] ?? props['street'] ?? 'Unknown';
        
        final city = props['city'] ?? props['town'] ?? props['municipality'] ?? '';
        final county = props['county'] ?? '';
        final state = props['state'] ?? '';
        final district = props['district'] ?? props['suburb'] ?? props['city_district'] ?? props['quarter'] ?? '';
        final village = props['village'] ?? props['hamlet'] ?? props['neighbourhood'] ?? props['isolated_dwelling'] ?? '';
        
        // Prefer Kabupaten (county) over City (which is often state capital)
        final kab = county.isNotEmpty ? county : city;
        
        // Build full address more specifically
        final addressParts = [
          props['street'],
          village,
          district,
          kab,
          state,
        ].where((e) => e != null && e.toString().isNotEmpty).toList();
        
        return {
          "name": name,
          "fullAddress": addressParts.join(', '),
          "postalCode": props['postcode'] ?? '',
          "city": kab,
          "district": district,
          "village": village,
          "latitude": geom.length > 1 ? geom[1] : 0.0,
          "longitude": geom.length > 0 ? geom[0] : 0.0,
          "state": state,
        };
      }).toList();
    } catch (e) {
      // Untuk debugging: kembalikan pesan error sebagai hasil agar user tahu apa yang terjadi
      return [
        {
          "name": "Pencarian Gagal",
          "fullAddress": "Error: ${e.toString()}",
          "postalCode": "-",
          "latitude": 0.0,
          "longitude": 0.0,
        }
      ];
    }
  }

  Future<Map<String, dynamic>?> reverseGeocodePhoton(double lat, double lon) async {
    try {
      final photonDio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'StokAnandamApp/1.0',
        },
      ));

      final response = await photonDio.get(
        'https://photon.komoot.io/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lon,
        },
      );

      final List<dynamic> features = response.data['features'] ?? [];
      if (features.isNotEmpty) {
        final f = features.first;
        final props = f['properties'] ?? {};
        final geom = f['geometry']?['coordinates'] ?? [lon, lat];

        final city = props['city'] ?? props['town'] ?? '';
        final county = props['county'] ?? '';
        final state = props['state'] ?? '';
        final district = props['district'] ?? props['suburb'] ?? props['city_district'] ?? '';
        final village = props['village'] ?? props['hamlet'] ?? props['neighbourhood'] ?? '';

        final name = props['name'] ?? props['street'] ?? 'Unknown';
        final kab = county.isNotEmpty ? county : city;
        
        final addressParts = [
          props['street'],
          village,
          district,
          kab,
          state,
        ].where((e) => e != null && e.toString().isNotEmpty).toList();

        return {
          "name": name,
          "fullAddress": addressParts.join(', '),
          "postalCode": props['postcode'] ?? '',
          "city": kab,
          "district": district,
          "village": village,
          "latitude": geom.length > 1 ? geom[1] : lat,
          "longitude": geom.length > 0 ? geom[0] : lon,
          "state": state,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
