import '../api/api_client.dart';
import '../models/platform_settings.dart';

class PlatformSettingsService {
  PlatformSettingsService(this._api);

  final ApiClient _api;

  Future<PlatformSettings> fetch() async {
    final data = await _api.get('/settings');
    return PlatformSettings.fromJson(data);
  }
}
