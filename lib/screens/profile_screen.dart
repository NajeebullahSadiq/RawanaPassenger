import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/locale_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_providers.dart';
import '../providers/trip_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _uploadingPhoto = false;

  Future<void> _pickPhoto() async {
    final image = await pickRawanaImage(context, frontCamera: true);
    if (image == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final service = ref.read(passengerServiceProvider);
      final url = await service.uploadProfilePhoto(
        bytes: await image.readAsBytes(),
        fileName: image.name.isNotEmpty ? image.name : 'photo.jpg',
        contentType: image.mimeType,
      );
      await service.updateProfile(profilePhotoUrl: url);
      ref.invalidate(passengerProfileProvider);
      if (mounted) showRawanaToast(context, context.l10n.profileUpdated, icon: LucideIcons.circleCheck);
    } catch (e) {
      if (mounted) showRawanaError(context, e);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _editName(String current) async {
    final next = await RawanaActionSheet.custom<String>(context, _EditNameSheet(initial: current));
    if (next == null || next == current || !mounted) return;
    try {
      await ref.read(passengerServiceProvider).updateProfile(name: next);
      ref.invalidate(passengerProfileProvider);
      if (mounted) showRawanaToast(context, context.l10n.profileUpdated, icon: LucideIcons.circleCheck);
    } catch (e) {
      if (mounted) showRawanaError(context, e);
    }
  }

  Future<void> _signOut() async {
    final l10n = context.l10n;
    final ok = await RawanaActionSheet.confirm(
      context,
      title: l10n.signOutQuestion,
      message: l10n.signOutNeedSignBackIn,
      confirmLabel: l10n.logOut,
      cancelLabel: l10n.cancel,
      destructive: true,
      icon: LucideIcons.logOut,
    );
    if (!ok) return;
    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go('/auth');
  }

  String _memberLabel(Map<String, dynamic> profile) {
    final raw = profile['created_at'] as String?;
    final created = raw == null ? null : DateTime.tryParse(raw);
    if (created == null) return context.l10n.memberNew;
    return '${created.year}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final profileAsync = ref.watch(passengerProfileProvider);
    return RawanaScaffold(
      title: l10n.account,
      body: RawanaAsyncBody<Map<String, dynamic>>(
        data: profileAsync.valueOrNull,
        error: profileAsync.error,
        onRetry: () => ref.invalidate(passengerProfileProvider),
        onRefresh: () => ref.refresh(passengerProfileProvider.future),
        skeleton: const RawanaSkeletonList(count: 5),
        builder: (context, profile) {
          final name = (profile['name'] as String?)?.trim();
          final displayName = name == null || name.isEmpty ? l10n.passengerFallbackName : name;
          final phone = profile['phone'] as String? ?? '';
          final email = registrationEmailForDisplay(profile['email'] as String?);
          final tripCount = profile['trip_count'];
          final rating = profile['rating_average'];
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: RawanaScaffold.pagePadding,
            children: [
              _ProfileHeader(
                name: displayName,
                contact: phone.isNotEmpty ? phone : email,
                contactIcon: phone.isNotEmpty ? LucideIcons.phone : LucideIcons.mail,
                photoUrl: profile['profile_photo_url'] as String?,
                uploading: _uploadingPhoto,
                onPhoto: _uploadingPhoto ? () {} : _pickPhoto,
                onEditName: () => _editName(name ?? ''),
                stats: [
                  (l10n.tripsStat, tripCount == null ? '—' : '$tripCount'),
                  (l10n.ratingStat, rating is num ? rating.toStringAsFixed(1) : '—'),
                  (l10n.memberStat, _memberLabel(profile)),
                ],
              ),
              const SizedBox(height: 24),
              RawanaSettingsSection(
                title: l10n.preferences,
                children: [
                  RawanaSettingsTile(
                    icon: LucideIcons.globe,
                    title: l10n.language,
                    value: l10n.languageName(ref.watch(localeProvider).languageCode),
                    onTap: () => context.push('/language'),
                  ),
                  RawanaSettingsTile(
                    icon: LucideIcons.mapPin,
                    title: l10n.savedAddresses,
                    onTap: () => context.push('/saved-addresses'),
                  ),
                  RawanaSettingsTile(
                    icon: LucideIcons.bell,
                    title: l10n.notifications,
                    onTap: () => context.push('/notifications'),
                  ),
                  RawanaSettingsTile(
                    icon: LucideIcons.calendarClock,
                    title: l10n.scheduledRides,
                    onTap: () => context.push('/scheduled-rides'),
                  ),
                  RawanaSettingsTile(
                    icon: LucideIcons.history,
                    title: l10n.rideHistory,
                    onTap: () => context.push('/history'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              RawanaSettingsSection(
                title: l10n.safetyAndSupport,
                children: [
                  RawanaSettingsTile(
                    icon: LucideIcons.shieldAlert,
                    title: l10n.emergencyContacts,
                    subtitle: l10n.emergencyContactsHint,
                    iconColor: RawanaColors.warning,
                    onTap: () => context.push('/emergency-contacts'),
                  ),
                  RawanaSettingsTile(
                    icon: LucideIcons.lifeBuoy,
                    title: l10n.helpCentre,
                    onTap: () => context.push('/help'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              RawanaSettingsSection(
                title: l10n.legalSection,
                children: [
                  RawanaSettingsTile(
                    icon: LucideIcons.fileText,
                    title: l10n.termsOfService,
                    onTap: () => context.push('/terms'),
                  ),
                  RawanaSettingsTile(
                    icon: LucideIcons.lock,
                    title: l10n.privacyPolicy,
                    onTap: () => context.push('/privacy-policy'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AccountPrivacyActions(
                onExport: () => ref.read(passengerServiceProvider).exportAccountData(),
                onDelete: () async {
                  await ref.read(passengerServiceProvider).deleteAccount();
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go('/auth');
                },
              ),
              const SizedBox(height: 20),
              RawanaSettingsSection(
                children: [
                  RawanaSettingsTile(
                    icon: LucideIcons.logOut,
                    title: l10n.logOut,
                    destructive: true,
                    showChevron: false,
                    onTap: _signOut,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  l10n.appVersionFooter,
                  style: context.text.caption.copyWith(color: RawanaColors.onSurfaceFaint, letterSpacing: 0.6),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.contact,
    required this.contactIcon,
    required this.photoUrl,
    required this.uploading,
    required this.onPhoto,
    required this.onEditName,
    required this.stats,
  });

  final String name;
  final String contact;
  final IconData contactIcon;
  final String? photoUrl;
  final bool uploading;
  final VoidCallback onPhoto;
  final VoidCallback onEditName;
  final List<(String, String)> stats;

  @override
  Widget build(BuildContext context) {
    final muted = Colors.white.withValues(alpha: 0.8);
    return RawanaSurfaceCard(
      padding: const EdgeInsets.all(20),
      gradient: RawanaColors.inkGradient,
      shadows: RawanaShadows.low,
      child: Column(
        children: [
          Row(
            children: [
              RawanaAvatarPicker(
                name: name,
                photoUrl: photoUrl,
                uploading: uploading,
                size: 68,
                semanticLabel: photoUrl == null ? context.l10n.addPhoto : context.l10n.changePhoto,
                onTap: onPhoto,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.headline.copyWith(color: Colors.white),
                          ),
                        ),
                        IconButton(
                          onPressed: onEditName,
                          tooltip: context.l10n.editName,
                          visualDensity: VisualDensity.compact,
                          icon: Icon(LucideIcons.pencil, color: muted, size: 16),
                        ),
                      ],
                    ),
                    if (contact.isNotEmpty)
                      Row(
                        children: [
                          Icon(contactIcon, color: muted, size: 13),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              contact,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                              style: context.text.caption.copyWith(color: muted),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              for (var i = 0; i < stats.length; i++) ...[
                if (i > 0) Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                Expanded(
                  child: Column(
                    children: [
                      Text(stats[i].$2, style: context.text.title.copyWith(color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(
                        stats[i].$1,
                        style: context.text.label.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EditNameSheet extends StatefulWidget {
  const _EditNameSheet({required this.initial});

  final String initial;

  @override
  State<_EditNameSheet> createState() => _EditNameSheetState();
}

class _EditNameSheetState extends State<_EditNameSheet> {
  late final _controller = TextEditingController(text: widget.initial);
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.editName, style: context.text.headline),
          const SizedBox(height: 16),
          RawanaTextField(
            controller: _controller,
            label: l10n.fullName,
            prefixIcon: LucideIcons.user,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.name],
            maxLength: 60,
            validator: (v) => (v ?? '').trim().length < 2 ? l10n.nameTooShort : null,
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          RawanaPrimaryButton(label: l10n.save, onPressed: _save),
        ],
      ),
    );
  }
}
