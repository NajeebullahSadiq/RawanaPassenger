import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import '../utils/maps_navigation.dart';
import 'rawana_primary_button.dart';

/// In-app call between the passenger and driver on the trip's Rawana line.
class TripCallScreen extends StatefulWidget {
  const TripCallScreen({
    super.key,
    required this.api,
    required this.tripId,
    required this.partyName,
  });

  final ApiClient api;
  final String tripId;
  final String partyName;

  @override
  State<TripCallScreen> createState() => _TripCallScreenState();
}

class _TripCallScreenState extends State<TripCallScreen> {
  bool _starting = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _starting = true;
      _failed = false;
    });
    final ok = await dialTripContact(widget.api, widget.tripId);
    if (!mounted) return;
    setState(() {
      _starting = false;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white),
                ),
              ),
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phone_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.callingName(widget.partyName),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                _failed
                    ? l10n.couldNotStartCall
                    : _starting
                        ? l10n.connecting
                        : l10n.callConnectedHint,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 15, height: 1.4),
              ),
              const Spacer(),
              if (_failed)
                RawanaPrimaryButton(
                  label: l10n.tryAgain,
                  onPressed: _start,
                )
              else
                RawanaPrimaryButton(
                  label: l10n.endCall,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
