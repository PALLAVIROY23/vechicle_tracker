import 'package:get_storage/get_storage.dart';


class StorageRepository {
  static const _box = 'vehicle_tracker_box';
  static const _etaAlertsKey = 'eta_alerts_enabled';
  static const _searchHistoryKey = 'search_history';

  late final GetStorage _storage;


  StorageRepository() {
    _storage = GetStorage(_box);
  }

  bool get etaAlertsEnabled => _storage.read<bool>(_etaAlertsKey) ?? true;

  Future<void> setEtaAlertsEnabled(bool value) =>
      _storage.write(_etaAlertsKey, value);

  List<String> get searchHistory =>
      (_storage.read<List>(_searchHistoryKey) ?? <String>[])
          .cast<String>();

  Future<void> addSearchHistory(String query) async {
    final history = searchHistory;
    history.remove(query);
    history.insert(0, query);
    if (history.length > 8) history.removeRange(8, history.length);
    await _storage.write(_searchHistoryKey, history);
  }

  Future<void> clearSearchHistory() => _storage.remove(_searchHistoryKey);
}
