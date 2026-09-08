import 'package:flutter/material.dart';

import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import '../utils/profile_registration.dart';

/// Shared name, phone, and email fields for passenger/driver registration.
class RegistrationEssentialsFields extends StatelessWidget {
  const RegistrationEssentialsFields({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.emailController,
    this.phoneReadOnly = false,
    this.phoneVerified = false,
    this.onChanged,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final bool phoneReadOnly;
  final bool phoneVerified;
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: nameController,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: context.l10n.fullNameRequired,
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
          ),
          onChanged: (_) => onChanged?.call(),
        ),
        const SizedBox(height: 16),
        if (phoneReadOnly) ...[
          InputDecorator(
            decoration: InputDecoration(
              labelText: context.l10n.phoneNumberRequired,
              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
              suffixIcon: phoneVerified
                  ? const Icon(Icons.verified_rounded, size: 20, color: RawanaColors.success)
                  : null,
            ),
            child: Text(
              phoneController.text,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
                decoration: BoxDecoration(
                  color: RawanaColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                ),
                child: Text(context.l10n.afPhonePrefix, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    labelText: context.l10n.phoneNumberRequired,
                    hintText: context.l10n.phoneHint,
                  ),
                  onChanged: (_) => onChanged?.call(),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            labelText: context.l10n.emailOptional,
            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 20),
          ),
          onChanged: (_) => onChanged?.call(),
        ),
      ],
    );
  }
}

bool registrationEssentialsValid({
  required String name,
  required String phone,
  required String email,
  bool phoneReadOnly = false,
}) {
  if (!isRegistrationNameValid(name)) return false;
  final normalizedPhone = phoneReadOnly ? phone : normalizeAfPhoneInput(phone);
  if (!isRegistrationPhoneValid(normalizedPhone)) return false;
  return isRegistrationEmailValid(email);
}

String registrationPhoneForSubmit({
  required String phone,
  bool phoneReadOnly = false,
}) => phoneReadOnly ? phone.trim() : normalizeAfPhoneInput(phone);
