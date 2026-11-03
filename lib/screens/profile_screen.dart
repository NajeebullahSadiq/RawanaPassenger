import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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

  String? _mimeForFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (image == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final fileName = image.name.isNotEmpty ? image.name : 'photo.jpg';
      final url = await ref.read(passengerServiceProvider).uploadProfilePhoto(
            bytes: await image.readAsBytes(),
            fileName: fileName,
            contentType: _mimeForFileName(fileName),
          );
      await ref.read(passengerServiceProvider).updateProfile(profilePhotoUrl: url);
      ref.invalidate(passengerProfileProvider);
    } catch (e) {
      if (mounted) showRawanaError(context, e);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _editName(String current) async {
    final controller = TextEditingController(text: current);
    final next = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.editName),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          decoration: InputDecoration(labelText: ctx.l10n.fullName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(ctx.l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null || next.length < 2) return;
    try {
      await ref.read(passengerServiceProvider).updateProfile(name: next);
      ref.invalidate(passengerProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.profileUpdated)),
        );
      }
    } catch (e) {
      if (mounted) {
        showRawanaError(context, e);
      }
    }
  }

  String _memberLabel(Map<String, dynamic> profile) {
    final raw = profile['created_at'] as String?;
    final created = raw == null ? null : DateTime.tryParse(raw);
    if (created == null) return context.l10n.memberNew;
    return '${created.year}';
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(passengerProfileProvider);
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(
        title: Text(context.l10n.account),
        centerTitle: true,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.friendlyApiError(e))),
        data: (profile) {
          final name = profile['name'] as String? ?? context.l10n.passengerFallbackName;
          final phone = profile['phone'] as String? ?? '';
          final email = profile['email'] as String? ?? '';
          final photoUrl = profile['profile_photo_url'] as String?;
          final tripCount = profile['trip_count'];
          final rating = profile['rating_average'];
          return ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: RawanaSurfaceCard(
                  padding: const EdgeInsets.all(20),
                  gradient: RawanaColors.inkGradient,
                  shadows: const [],
                  child: Column(
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _uploadingPhoto ? null : _pickPhoto,
                            child: Stack(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      width: 2,
                                    ),
                                    image: photoUrl != null && photoUrl.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(photoUrl),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: photoUrl == null || photoUrl.isEmpty
                                      ? const Icon(LucideIcons.user, color: Colors.white, size: 28)
                                      : null,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: _uploadingPhoto
                                        ? const Padding(
                                            padding: EdgeInsets.all(4),
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(LucideIcons.camera, size: 12, color: RawanaColors.primary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 20,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => _editName(name),
                                      icon: const Icon(LucideIcons.pencil, color: Colors.white70, size: 16),
                                      tooltip: context.l10n.editName,
                                    ),
                                  ],
                                ),
                                if (phone.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.phone, color: Colors.white70, size: 12),
                                      const SizedBox(width: 6),
                                      Text(
                                        phone,
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.85),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ] else if (email.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(LucideIcons.mail, color: Colors.white70, size: 12),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          email,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _miniStat(
                              context.l10n.tripsStat,
                              tripCount == null ? '—' : '$tripCount',
                            ),
                          ),
                          Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                          Expanded(
                            child: _miniStat(
                              context.l10n.ratingStat,
                              rating is num ? rating.toStringAsFixed(1) : '—',
                            ),
                          ),
                          Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                          Expanded(child: _miniStat(context.l10n.memberStat, _memberLabel(profile))),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              RawanaSectionLabel(context.l10n.preferences),
              _section([
                _menuItem(
                  icon: LucideIcons.globe,
                  title: context.l10n.language,
                  subtitle: context.l10n.languageName(ref.watch(localeProvider).languageCode),
                  onTap: () => context.push('/language'),
                ),
                _menuItem(
                  icon: LucideIcons.mapPin,
                  title: context.l10n.savedAddresses,
                  onTap: () => context.push('/saved-addresses'),
                ),
                _menuItem(
                  icon: LucideIcons.bell,
                  title: context.l10n.notifications,
                  onTap: () => context.push('/notifications'),
                ),
                _menuItem(
                  icon: LucideIcons.calendarClock,
                  title: context.l10n.scheduledRides,
                  onTap: () => context.push('/scheduled-rides'),
                ),
                _menuItem(
                  icon: LucideIcons.clock,
                  title: context.l10n.rideHistory,
                  onTap: () => context.push('/history'),
                ),
              ]),
              RawanaSectionLabel(context.l10n.safetyAndSupport),
              _section([
                _menuItem(
                  icon: LucideIcons.shieldAlert,
                  title: context.l10n.emergencyContacts,
                  iconColor: RawanaColors.warning,
                  onTap: () => context.push('/emergency-contacts'),
                ),
                _menuItem(
                  icon: LucideIcons.lifeBuoy,
                  title: context.l10n.helpCentre,
                  onTap: () => context.push('/help'),
                ),
              ]),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: AccountPrivacyActions(
                  onExport: () => ref.read(passengerServiceProvider).exportAccountData(),
                  onDelete: () async {
                    await ref.read(passengerServiceProvider).deleteAccount();
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                  icon: const Icon(LucideIcons.logOut, size: 18),
                  label: Text(context.l10n.logOut),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RawanaColors.error,
                    side: BorderSide(color: RawanaColors.error.withValues(alpha: 0.4)),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  context.l10n.appVersionFooter,
                  style: TextStyle(
                    color: RawanaColors.onSurfaceFaint,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _miniStat(String label, String value) => Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      );

  Widget _section(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
        border: Border.all(color: RawanaColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 64),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (iconColor ?? RawanaColors.primary).withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(icon, size: 18, color: iconColor ?? RawanaColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronRight, size: 18, color: RawanaColors.onSurfaceFaint),
        ],
      ),
    );
  }
}
