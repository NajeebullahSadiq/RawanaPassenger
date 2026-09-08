import '../api/api_client.dart';

class SupportService {
  final ApiClient _api;
  final String _basePath;

  /// [role] must be `passenger` or `driver`.
  SupportService(this._api, {required String role})
      : _basePath = role == 'driver' ? '/drivers' : '/passengers';

  Future<List<Map<String, dynamic>>> listTickets() async {
    final data = await _api.get('$_basePath/support-tickets');
    final list = data['tickets'] as List<dynamic>? ?? [];
    return list.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> createTicket({
    String? tripId,
    required String category,
    required String subject,
    required String description,
  }) async {
    return _api.post('$_basePath/support-tickets', data: {
      if (tripId != null) 'trip_id': tripId,
      'category': category,
      'subject': subject,
      'description': description,
    });
  }

  Future<Map<String, dynamic>> getTicket(String id) async {
    return _api.get('$_basePath/support-tickets/$id');
  }

  Future<void> reply(String ticketId, String message) async {
    await _api.post('$_basePath/support-tickets/$ticketId/messages', data: {
      'message': message,
    });
  }
}

/// UI labels for [SupportTicketCategory] API values.
const supportCategoryOptions = <String, String>{
  'billing_dispute': 'Billing / overcharge',
  'driver_behaviour': 'Driver behaviour',
  'safety_concern': 'Safety concern',
  'technical_issue': 'App / technical issue',
  'other': 'Other',
};
