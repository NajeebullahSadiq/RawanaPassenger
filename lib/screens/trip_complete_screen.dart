import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/trip_providers.dart';

class TripCompleteScreen extends ConsumerStatefulWidget {
  const TripCompleteScreen({super.key});

  @override
  ConsumerState<TripCompleteScreen> createState() => _TripCompleteScreenState();
}

class _TripCompleteScreenState extends ConsumerState<TripCompleteScreen> {
  int _stars = 0;
  final _comment = TextEditingController();
  static const _tagKeys = [
    'Clean car',
    'Safe driving',
    'Friendly driver',
    'On time',
    'Good navigation',
  ];
  final _selectedTags = <String>{};

  String _tagLabel(AppLocalizations l10n, String key) => switch (key) {
        'Clean car' => l10n.ratingTagCleanCar,
        'Safe driving' => l10n.ratingTagSafeDriving,
        'Friendly driver' => l10n.ratingTagFriendlyDriver,
        'On time' => l10n.ratingTagOnTime,
        'Good navigation' => l10n.ratingTagGoodNavigation,
        _ => key,
      };
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final trip = ref.read(activeTripProvider).valueOrNull;
    if (trip == null || _stars == 0) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(passengerServiceProvider)
          .submitRating(
            tripId: trip.id,
            stars: _stars,
            comment: _comment.text.trim().isEmpty ? null : _comment.text.trim(),
            tags: _selectedTags.toList(),
          );
      ref.read(activeTripProvider.notifier).clearLocalTripState();
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.friendlyApiError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = ref.watch(activeTripProvider).valueOrNull;
    final fare = trip?.cashToCollect ?? 0;
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: RawanaColors.success.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.checkCheck,
                  size: 44,
                  color: RawanaColors.success,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.youHaveArrived,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.thanksForRiding,
                style: TextStyle(
                  color: RawanaColors.onSurfaceMuted,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              RawanaSurfaceCard(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                gradient: RawanaColors.primaryGradient,
                shadows: const [],
                child: Column(
                  children: [
                    Text(
                      context.l10n.payDriverCashAmount(AfnFormatter.format(fare)),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AfnFormatter.format(fare),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.2,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(
                          RawanaSpacing.radiusPill,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.banknote,
                            color: Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            context.l10n.cashAfn,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              RawanaSurfaceCard(
                shadows: const [],
                border: Border.all(color: RawanaColors.divider),
                child: Column(
                  children: [
                    _line(
                      LucideIcons.mapPin,
                      context.l10n.pickup,
                      trip?.pickupAddress ?? '—',
                      RawanaColors.success,
                    ),
                    const SizedBox(height: 10),
                    _line(
                      LucideIcons.flag,
                      context.l10n.dropoff,
                      trip?.dropoffAddress ?? '—',
                      RawanaColors.dropoffPin,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.l10n.howWasYourTrip,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.feedbackHelpsDrivers,
                style: TextStyle(
                  color: RawanaColors.onSurfaceMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final filled = i < _stars;
                  return IconButton(
                    icon: AnimatedScale(
                      duration: const Duration(milliseconds: 200),
                      scale: filled ? 1.05 : 1,
                      child: Icon(
                        filled
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: RawanaColors.accent,
                        size: 40,
                      ),
                    ),
                    onPressed: () => setState(() => _stars = i + 1),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: _tagKeys.map((t) {
                  final selected = _selectedTags.contains(t);
                  return GestureDetector(
                    onTap: () => setState(() {
                      selected ? _selectedTags.remove(t) : _selectedTags.add(t);
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? RawanaColors.primary.withValues(alpha: 0.10)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(
                          RawanaSpacing.radiusPill,
                        ),
                        border: Border.all(
                          color: selected
                              ? RawanaColors.primary
                              : RawanaColors.divider,
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Text(
                        _tagLabel(context.l10n, t),
                        style: TextStyle(
                          color: selected
                              ? RawanaColors.primary
                              : RawanaColors.onSurface,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _comment,
                maxLength: 280,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.writeAReview,
                  hintText: context.l10n.ratingCommentHint,
                ),
              ),
              const SizedBox(height: 24),
              RawanaPrimaryButton(
                label: _submitting ? context.l10n.submitting : context.l10n.submitRating,
                icon: LucideIcons.send,
                loading: _submitting,
                onPressed: _stars > 0 && !_submitting ? _submit : null,
              ),
              if (trip != null)
                TextButton.icon(
                  onPressed: () async {
                    final url = await ref.read(passengerServiceProvider).getTripReceiptUrl(trip.id);
                    if (!context.mounted) return;
                    if (url == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.l10n.tripReceipt)),
                      );
                      return;
                    }
                    await Share.share(url, subject: context.l10n.tripReceipt);
                  },
                  icon: const Icon(LucideIcons.receipt, size: 16),
                  label: Text(context.l10n.viewReceipt),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _submitting
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ReportIssueScreen(
                              supportService: ref.read(supportServiceProvider),
                              tripId: trip?.id,
                              initialCategory: 'driver_behaviour',
                            ),
                          ),
                        );
                      },
                icon: const Icon(LucideIcons.flag, size: 16),
                label: Text(context.l10n.reportAnIssue),
              ),
              TextButton(
                onPressed: () {
                  // Respect the skip: Home must not re-prompt for this trip.
                  if (trip != null) {
                    ref
                        .read(dismissedRatingPromptsProvider.notifier)
                        .update((s) => {...s, trip.id});
                  }
                  ref.read(activeTripProvider.notifier).clearLocalTripState();
                  context.go('/home');
                },
                child: Text(
                  context.l10n.skipRating,
                  style: const TextStyle(color: RawanaColors.onSurfaceMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: RawanaColors.onSurfaceMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
