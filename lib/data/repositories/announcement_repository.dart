import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../api_new_endpoints.dart';
import '../models/announcement.dart';

class AnnouncementRepository {
  final ApiNewEndpoints _api;
  final SharedPreferences _prefs;

  AnnouncementRepository(this._api, this._prefs);

  static const String _localCacheKey = 'cached_announcements_v1';

  /// Fetch active announcements: attempts to load from backend API,
  /// falls back to locally cached announcements if backend fails or is not ready yet.
  Future<List<Announcement>> getAnnouncements() async {
    try {
      final remoteData = await _api.getAnnouncements();
      // If we got successful results (or even empty, meaning API is up and functional)
      // we cache them locally and return.
      await _cacheLocally(remoteData);
      return remoteData;
    } catch (e) {
      // Backend is unavailable or not yet implemented; return local backup cache
      return _getLocalCached();
    }
  }

  /// Create announcement: saves to backend first.
  /// If backend fails (e.g. 404/500/No connection), we save it to the local fallback cache so that the app works seamlessly!
  Future<void> createAnnouncement(Announcement announcement) async {
    final Map<String, dynamic> data = announcement.toJson();
    try {
      await _api.createAnnouncement(data);
      // Refresh local cache by fetching again
      await getAnnouncements();
    } catch (e) {
      // Fallback: save to local fallback cache
      final currentList = await _getLocalCached();
      final newId = DateTime.now().millisecondsSinceEpoch;
      final newAnnouncement = Announcement(
        id: newId,
        title: announcement.title,
        subtitle: announcement.subtitle,
        startDate: announcement.startDate,
        expiredDate: announcement.expiredDate,
      );
      currentList.add(newAnnouncement);
      await _cacheLocally(currentList);
    }
  }

  /// Update announcement
  Future<void> updateAnnouncement(int id, Announcement announcement) async {
    final Map<String, dynamic> data = announcement.toJson();
    try {
      await _api.updateAnnouncement(id, data);
      await getAnnouncements();
    } catch (e) {
      // Fallback: update in local fallback cache
      final currentList = await _getLocalCached();
      final index = currentList.indexWhere((element) => element.id == id);
      if (index != -1) {
        currentList[index] = Announcement(
          id: id,
          title: announcement.title,
          subtitle: announcement.subtitle,
          startDate: announcement.startDate,
          expiredDate: announcement.expiredDate,
        );
        await _cacheLocally(currentList);
      }
    }
  }

  /// Delete announcement
  Future<void> deleteAnnouncement(int id) async {
    try {
      await _api.deleteAnnouncement(id);
      await getAnnouncements();
    } catch (e) {
      // Fallback: delete from local fallback cache
      final currentList = await _getLocalCached();
      currentList.removeWhere((element) => element.id == id);
      await _cacheLocally(currentList);
    }
  }

  // --- PRIVATE CACHING HELPERS ---

  Future<void> _cacheLocally(List<Announcement> list) async {
    final jsonList = list.map((e) => e.toJson()).toList();
    await _prefs.setString(_localCacheKey, jsonEncode(jsonList));
  }

  Future<List<Announcement>> _getLocalCached() async {
    final cachedStr = _prefs.getString(_localCacheKey);
    if (cachedStr == null || cachedStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(cachedStr) as List;
      return decoded
          .map((e) => Announcement.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
