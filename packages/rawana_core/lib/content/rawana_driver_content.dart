import '../l10n/app_localizations.dart';

/// Static copy for driver-facing info screens (guidelines, terms).
class RawanaInfoSection {
  const RawanaInfoSection({required this.title, required this.body});
  final String title;
  final String body;
}

List<RawanaInfoSection> localizedDriverGuidelines(AppLocalizations l10n) => [
      RawanaInfoSection(
        title: l10n.driverGuideProfessionalTitle,
        body: l10n.driverGuideProfessionalBody,
      ),
      RawanaInfoSection(
        title: l10n.driverGuideAcceptTitle,
        body: l10n.driverGuideAcceptBody,
      ),
      RawanaInfoSection(
        title: l10n.driverGuideNavigateTitle,
        body: l10n.driverGuideNavigateBody,
      ),
      RawanaInfoSection(
        title: l10n.driverGuideSafetyTitle,
        body: l10n.driverGuideSafetyBody,
      ),
      RawanaInfoSection(
        title: l10n.driverGuideFaresTitle,
        body: l10n.driverGuideFaresBody,
      ),
      RawanaInfoSection(
        title: l10n.driverGuideCancellationsTitle,
        body: l10n.driverGuideCancellationsBody,
      ),
    ];

List<RawanaInfoSection> localizedDriverTerms(AppLocalizations l10n) => [
      RawanaInfoSection(
        title: l10n.termsDriverAgreement,
        body: l10n.termsDriverAgreementBody,
      ),
      RawanaInfoSection(
        title: l10n.termsAccountVerification,
        body: l10n.termsAccountVerificationBody,
      ),
      RawanaInfoSection(
        title: l10n.termsEarningsPayouts,
        body: l10n.termsEarningsPayoutsBody,
      ),
      RawanaInfoSection(
        title: l10n.termsPrivacy,
        body: l10n.termsPrivacyBody,
      ),
      RawanaInfoSection(
        title: l10n.termsConductSuspension,
        body: l10n.termsConductSuspensionBody,
      ),
      RawanaInfoSection(
        title: l10n.termsSupport,
        body: l10n.termsSupportBody,
      ),
    ];

Map<String, String> localizedDriverSupportCategories(AppLocalizations l10n) => {
      'billing_dispute': l10n.supportFarePayment,
      'driver_behaviour': l10n.supportPassengerBehaviour,
      'safety_concern': l10n.supportSafetyConcern,
      'technical_issue': l10n.supportTechnical,
      'other': l10n.supportOther,
    };

Map<String, String> localizedPassengerSupportCategories(AppLocalizations l10n) => {
      'billing_dispute': l10n.supportBilling,
      'driver_behaviour': l10n.supportDriverBehaviour,
      'safety_concern': l10n.supportSafetyConcern,
      'technical_issue': l10n.supportTechnical,
      'other': l10n.supportOther,
    };

/// Fallback English sections for callers that have no [BuildContext] yet.
const driverGuidelinesSections = <RawanaInfoSection>[
  RawanaInfoSection(
    title: 'Stay professional',
    body:
        'Greet passengers politely, keep your vehicle clean, and follow local traffic laws. '
        'A calm, respectful attitude is the fastest way to earn five-star ratings.',
  ),
  RawanaInfoSection(
    title: 'Accept rides promptly',
    body:
        'High acceptance rates help you receive more requests. Only go online when you are '
        'ready to drive. If you must decline, do it quickly so the passenger can find another driver.',
  ),
  RawanaInfoSection(
    title: 'Navigate accurately',
    body:
        'Use the in-app route to pickup and drop-off. Confirm the destination with the passenger '
        'before starting the trip. If the address is unclear, call or message through the app.',
  ),
  RawanaInfoSection(
    title: 'Safety first',
    body:
        'Do not drive tired or under the influence. Report safety concerns immediately through '
        'Support. In an emergency, contact local authorities first, then notify Rawana.',
  ),
  RawanaInfoSection(
    title: 'Fares & payments',
    body:
        'Fares are calculated automatically from distance, time, and zone pricing. Do not ask '
        'passengers for extra cash unless agreed in the app. Earnings appear in your wallet after each completed trip.',
  ),
  RawanaInfoSection(
    title: 'Cancellations',
    body:
        'Avoid cancelling after accepting a ride. Frequent cancellations lower your performance '
        'score and may reduce future requests. Cancel only when necessary and add a clear reason.',
  ),
];

const driverTermsSections = <RawanaInfoSection>[
  RawanaInfoSection(
    title: 'Driver agreement',
    body:
        'By using Rawana Driver you agree to provide ride-hailing services in line with platform '
        'rules, local regulations, and the documents you submitted during onboarding.',
  ),
  RawanaInfoSection(
    title: 'Account & verification',
    body:
        'You must keep your licence, vehicle registration, and identity documents valid and up to date. '
        'Rawana may suspend accounts with expired or fraudulent documents.',
  ),
  RawanaInfoSection(
    title: 'Earnings & payouts',
    body:
        'Trip fares are credited to your wallet minus Rawana\'s commission. Payout requests are '
        'processed according to finance team schedules. Fraudulent activity may result in withheld balances.',
  ),
  RawanaInfoSection(
    title: 'Privacy',
    body:
        'We collect location while you are online, trip history, and contact details to operate the '
        'service. Passenger phone numbers may be masked during active trips. See Privacy & security in your profile for account controls.',
  ),
  RawanaInfoSection(
    title: 'Conduct & suspension',
    body:
        'Harassment, discrimination, unsafe driving, or repeated complaints can lead to temporary '
        'suspension or permanent removal from the platform.',
  ),
  RawanaInfoSection(
    title: 'Support',
    body:
        'For disputes, safety reports, or account help, use in-app Support or email support@rawana.af. '
        'We aim to respond to urgent safety issues as quickly as possible.',
  ),
];

const driverSupportCategoryOptions = <String, String>{
  'billing_dispute': 'Fare / payment issue',
  'driver_behaviour': 'Passenger behaviour',
  'safety_concern': 'Safety concern',
  'technical_issue': 'App / technical issue',
  'other': 'Other',
};
