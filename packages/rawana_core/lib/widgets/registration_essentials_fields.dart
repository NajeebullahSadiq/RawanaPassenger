import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/l10n_extensions.dart';
import '../theme/rawana_theme.dart';
import '../utils/profile_registration.dart';
import 'ui/rawana_text_field.dart';

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
    this.languageCode,
    this.onLanguageChanged,
  });

  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController emailController;
  final bool phoneReadOnly;
  final bool phoneVerified;
  final VoidCallback? onChanged;
  final String? languageCode;
  final ValueChanged<String>? onLanguageChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RawanaTextField(
          controller: nameController,
          label: l10n.fullNameRequired,
          prefixIcon: LucideIcons.user,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          onChanged: (_) => onChanged?.call(),
        ),
        const SizedBox(height: 16),
        if (phoneReadOnly)
          RawanaTextField(
            key: ValueKey(phoneController.text),
            initialValue: phoneController.text,
            label: l10n.phoneNumberRequired,
            prefixIcon: LucideIcons.phone,
            enabled: false,
            textDirection: TextDirection.ltr,
            suffix: phoneVerified ? const Icon(LucideIcons.badgeCheck, size: 20, color: RawanaColors.success) : null,
          )
        else
          RawanaPhoneField(
            controller: phoneController,
            label: l10n.phoneNumberRequired,
            hint: l10n.phoneHint,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onChanged?.call(),
          ),
        const SizedBox(height: 16),
        RawanaTextField(
          controller: emailController,
          label: l10n.emailOptional,
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          textDirection: TextDirection.ltr,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => onChanged?.call(),
        ),
        if (languageCode != null && onLanguageChanged != null) ...[
          const SizedBox(height: 20),
          Text(l10n.registrationLanguage, style: context.text.label.copyWith(color: RawanaColors.onSurfaceMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in [
                ('en', l10n.languageEnglish),
                ('fa', l10n.languageDari),
                ('ps', l10n.languagePashto),
              ])
                ChoiceChip(
                  label: Text(option.$2),
                  selected: languageCode == option.$1,
                  onSelected: (_) => onLanguageChanged!(option.$1),
                ),
            ],
          ),
        ],
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
