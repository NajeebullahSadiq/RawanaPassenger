import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_client.dart';
import '../l10n/l10n_extensions.dart';

/// Opens turn-by-turn navigation in the **native** Google Maps app (Android/iOS).
///
/// Returns `false` on web — use in-app route navigation instead
/// ([TripRouteMap.navigationMode] + [TripInAppNavigationBar]).
Future<bool> openExternalMapsNavigation({
  required double destLat,
  required double destLng,
  double? originLat,
  double? originLng,
  String? label,
}) async {
  if (kIsWeb) return false;

  final dest = '$destLat,$destLng';
  final uri = (originLat != null && originLng != null)
      ? Uri.parse(
          'https://www.google.com/maps/dir/?api=1&origin=$originLat,$originLng&destination=$dest&travelmode=driving',
        )
      : Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination=$dest&travelmode=driving',
        );

  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

/// Opens turn-by-turn navigation in Waze when installed.
Future<bool> openWazeNavigation({
  required double destLat,
  required double destLng,
}) async {
  if (kIsWeb) return false;
  final uri = Uri.parse('https://waze.com/ul?ll=$destLat,$destLng&navigate=yes');
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  return false;
}

/// Lets the driver pick Google Maps or Waze.
Future<void> showExternalMapsChooser({
  required BuildContext context,
  required double destLat,
  required double destLng,
  double? originLat,
  double? originLng,
  String? label,
}) async {
  if (kIsWeb) return;
  await showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: Text(ctx.l10n.openInGoogleMaps),
            onTap: () {
              Navigator.pop(ctx);
              openExternalMapsNavigation(
                destLat: destLat,
                destLng: destLng,
                originLat: originLat,
                originLng: originLng,
                label: label,
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.navigation_outlined),
            title: Text(ctx.l10n.openInWaze),
            onTap: () {
              Navigator.pop(ctx);
              openWazeNavigation(destLat: destLat, destLng: destLng);
            },
          ),
        ],
      ),
    ),
  );
}

/// @deprecated Use in-app navigation on web; [openExternalMapsNavigation] on mobile.
Future<bool> openMapsNavigation({
  required double destLat,
  required double destLng,
  double? originLat,
  double? originLng,
  String? label,
}) =>
    openExternalMapsNavigation(
      destLat: destLat,
      destLng: destLng,
      originLat: originLat,
      originLng: originLng,
      label: label,
    );

/// Calls a phone number (e.g. emergency / support). Trip contact uses WhatsApp.
Future<bool> callPhone(String phone) async {
  final normalized = phone.replaceAll(RegExp(r'[^\d+]'), '');
  if (normalized.isEmpty) return false;
  final uri = Uri.parse('tel:$normalized');
  if (await canLaunchUrl(uri)) {
    return launchUrl(uri);
  }
  return false;
}

/// Digits-only international number for WhatsApp deep links (no leading +).
String? whatsappPhoneDigits(String? phone) {
  if (phone == null) return null;
  var digits = phone.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return null;
  if (digits.startsWith('00')) digits = digits.substring(2);
  if (digits.length == 10 && digits.startsWith('0')) {
    digits = '93${digits.substring(1)}';
  } else if (digits.length == 9 && !digits.startsWith('93')) {
    digits = '93$digits';
  }
  return digits;
}

Future<bool> _launchExternal(Uri uri) async {
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

Future<bool> _openWhatsAppChat(String digits) async {
  final candidates = <Uri>[
    Uri.parse('whatsapp://send?phone=$digits'),
    Uri.parse('https://wa.me/$digits'),
    Uri.parse('https://api.whatsapp.com/send?phone=$digits'),
  ];
  for (final uri in candidates) {
    if (await _launchExternal(uri)) return true;
  }
  return false;
}

Future<bool> _openWhatsAppCall(String digits) async {
  final candidates = <Uri>[
    Uri.parse('whatsapp://call?phone=$digits'),
    Uri.parse('whatsapp://call?jid=$digits@s.whatsapp.net'),
  ];
  for (final uri in candidates) {
    if (await _launchExternal(uri)) return true;
  }
  return _openWhatsAppChat(digits);
}

/// Opens WhatsApp with the trip party — voice call, or chat if [voiceCall] is false.
Future<bool> openWhatsAppContact(String phone, {required bool voiceCall}) async {
  final digits = whatsappPhoneDigits(phone);
  if (digits == null) return false;
  return voiceCall ? _openWhatsAppCall(digits) : _openWhatsAppChat(digits);
}

/// Contact details the backend hands out for an active trip.
///
/// When [masked] is true, [dialNumber] is a proxy line that only works for a
/// regular phone call — WhatsApp cannot reach it, and the real number is never
/// disclosed. When unmasked (development only) [whatsappNumber] is available.
class TripContact {
  const TripContact({required this.dialNumber, this.whatsappNumber, required this.masked});

  final String dialNumber;
  final String? whatsappNumber;
  final bool masked;

  bool get supportsWhatsApp => !masked && (whatsappNumber ?? dialNumber).isNotEmpty;
}

TripContact? _parseTripContact(Map<String, dynamic> data) {
  final dial = data['dial_number'];
  if (dial is! String || dial.isEmpty) return null;
  final wa = data['whatsapp_number'];
  return TripContact(
    dialNumber: dial,
    whatsappNumber: wa is String && wa.isNotEmpty ? wa : null,
    masked: data['masked'] == true,
  );
}

Future<TripContact?> fetchTripContact(ApiClient api, String tripId) async {
  try {
    final data = await api.post('/rides/$tripId/initiate-call');
    return _parseTripContact(data);
  } catch (_) {
    return null;
  }
}

Future<bool> _openPhoneDialer(String phone) =>
    _launchExternal(Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), '')));

/// Calls the other party on an active trip — via the masked proxy line when
/// masking is on, otherwise through WhatsApp voice (falling back to the dialer).
Future<bool> callTripParty(ApiClient api, String tripId) async {
  final contact = await fetchTripContact(api, tripId);
  if (contact == null) return false;
  if (contact.supportsWhatsApp) {
    if (await openWhatsAppContact(contact.whatsappNumber ?? contact.dialNumber, voiceCall: true)) {
      return true;
    }
  }
  return _openPhoneDialer(contact.dialNumber);
}

/// Fetches the number to dial for an active trip (proxy line when masked).
Future<String?> fetchTripDialNumber(ApiClient api, String tripId) async {
  final contact = await fetchTripContact(api, tripId);
  return contact?.dialNumber;
}

/// Opens a WhatsApp chat with the other party. Returns false when the trip is
/// masked (no WhatsApp-capable number is available) so the UI can hide/disable it.
Future<bool> messageTripParty(ApiClient api, String tripId) async {
  final contact = await fetchTripContact(api, tripId);
  if (contact == null || !contact.supportsWhatsApp) return false;
  return openWhatsAppContact(contact.whatsappNumber ?? contact.dialNumber, voiceCall: false);
}
