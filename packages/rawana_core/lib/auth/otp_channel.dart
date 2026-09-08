import '../l10n/app_localizations.dart';

/// How the OTP code is delivered to the user.
enum RawanaOtpChannel {
  sms('sms', 'SMS'),
  whatsapp('whatsapp', 'WhatsApp');

  const RawanaOtpChannel(this.value, this.label);
  final String value;

  /// English label for non-UI / API fallbacks. Prefer [localizedLabel] in widgets.
  final String label;

  String localizedLabel(AppLocalizations l10n) => switch (this) {
        RawanaOtpChannel.sms => l10n.otpChannelSms,
        RawanaOtpChannel.whatsapp => l10n.otpChannelWhatsApp,
      };
}
