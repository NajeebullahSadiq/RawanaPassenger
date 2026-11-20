import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:rawana_core/rawana_core.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../providers/trip_providers.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _loading = false;
  bool _leaving = false;
  bool _loadingProfile = true;
  bool _uploadingPhoto = false;
  bool _phoneReadOnly = false;
  bool _phoneVerified = false;
  bool _driverAccount = false;
  Object? _loadError;
  String? _error;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loadingProfile = true;
      _loadError = null;
    });
    try {
      final profile = await ref.read(passengerServiceProvider).getProfile();
      if (!mounted) return;
      if (isPassengerProfileComplete(profile)) {
        context.go('/home');
        return;
      }
      final phone = profile['phone'] as String? ?? '';
      _nameController.text = (profile['name'] as String?)?.trim() ?? '';
      _emailController.text = registrationEmailForDisplay(profile['email'] as String?);
      _photoUrl = profile['profile_photo_url'] as String?;
      if (isRegistrationPhoneValid(phone)) {
        _phoneController.text = phone;
        _phoneReadOnly = true;
        _phoneVerified = true;
      } else {
        // Prefill from signup metadata so the phone is not asked twice.
        final meta = ref.read(authServiceProvider).currentUser?.userMetadata;
        final metaPhone = meta?['phone'] as String?;
        final metaName = meta?['name'] as String?;
        if (isRegistrationPhoneValid(metaPhone)) {
          _phoneController.text = metaPhone!;
          _phoneReadOnly = true;
          _phoneVerified = true;
        }
        if (_nameController.text.isEmpty && metaName != null && metaName.trim().isNotEmpty) {
          _nameController.text = metaName.trim();
        }
      }
    } catch (e) {
      if (apiErrorKey(e) == 'driver_account_on_passenger_app') {
        _driverAccount = true;
      } else {
        _loadError = e;
      }
    } finally {
      if (mounted) setState(() => _loadingProfile = false);
    }
  }

  Future<void> _leave({required bool createAccount}) async {
    if (_leaving) return;
    setState(() => _leaving = true);
    try {
      await ref.read(authServiceProvider).signOut();
    } catch (_) {}
    if (!mounted) return;
    context.go(createAccount ? '/email-auth?mode=signup' : '/auth');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool get _formValid => registrationEssentialsValid(
        name: _nameController.text,
        phone: _phoneController.text,
        email: _emailController.text,
        phoneReadOnly: _phoneReadOnly,
      );

  Future<void> _pickPhoto() async {
    final image = await pickRawanaImage(context, frontCamera: true);
    if (image == null || !mounted) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await ref.read(passengerServiceProvider).uploadProfilePhoto(
            bytes: await image.readAsBytes(),
            fileName: image.name.isNotEmpty ? image.name : 'photo.jpg',
            contentType: image.mimeType,
          );
      if (mounted) setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) showRawanaError(context, e);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (!_formValid) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(passengerServiceProvider).updateProfile(
            name: _nameController.text.trim(),
            phone: registrationPhoneForSubmit(phone: _phoneController.text, phoneReadOnly: _phoneReadOnly),
            email: registrationEmailForDisplay(_emailController.text),
            language: ref.read(localeProvider).languageCode,
            profilePhotoUrl: _photoUrl,
          );
      if (mounted) context.go('/home');
    } catch (e) {
      if (!mounted) return;
      if (apiErrorKey(e) == 'driver_account_on_passenger_app') {
        setState(() => _driverAccount = true);
        return;
      }
      setState(() => _error = context.l10n.friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (_loadingProfile) {
      return RawanaScaffold(title: l10n.completeYourProfile, showBack: false, body: const RawanaSkeletonList(count: 4));
    }
    if (_driverAccount) return _DriverAccountBlock(leaving: _leaving, onLeave: _leave);
    if (_loadError != null) {
      return RawanaScaffold(
        title: l10n.completeYourProfile,
        onBack: () => _leave(createAccount: false),
        body: Center(
          child: RawanaErrorState(
            title: l10n.somethingWentWrong,
            message: l10n.friendlyApiError(_loadError!),
            retryLabel: l10n.tryAgain,
            onRetry: _loadProfile,
          ),
        ),
      );
    }
    return RawanaScaffold(
      title: l10n.completeYourProfile,
      onBack: _leaving ? null : () => _leave(createAccount: false),
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RawanaPrimaryButton(
            label: l10n.continueAction,
            icon: RawanaIcons.forward,
            loading: _loading,
            onPressed: _formValid && !_leaving ? _submit : null,
          ),
          TextButton(
            onPressed: _leaving || _loading ? null : () => _leave(createAccount: true),
            child: Text(l10n.newHereCreateAccount),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          RawanaPageHeader(title: l10n.almostThere, subtitle: l10n.profileSetupSubtitle),
          const SizedBox(height: 24),
          Center(
            child: RawanaAvatarPicker(
              name: _nameController.text,
              photoUrl: _photoUrl,
              uploading: _uploadingPhoto,
              semanticLabel: _photoUrl == null ? l10n.addPhoto : l10n.changePhoto,
              onTap: _pickPhoto,
            ),
          ),
          const SizedBox(height: 28),
          RegistrationEssentialsFields(
            nameController: _nameController,
            phoneController: _phoneController,
            emailController: _emailController,
            phoneReadOnly: _phoneReadOnly,
            phoneVerified: _phoneVerified,
            onChanged: () => setState(() {}),
            languageCode: ref.watch(localeProvider).languageCode,
            onLanguageChanged: (code) => ref.read(localeProvider.notifier).setLocale(Locale(code)),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            RawanaBanner.error(message: _error!),
          ],
        ],
      ),
    );
  }
}

class _DriverAccountBlock extends StatelessWidget {
  const _DriverAccountBlock({required this.leaving, required this.onLeave});

  final bool leaving;
  final Future<void> Function({required bool createAccount}) onLeave;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return RawanaScaffold(
      onBack: leaving ? null : () => onLeave(createAccount: false),
      bottomBar: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RawanaPrimaryButton(
            label: l10n.createAccount,
            icon: LucideIcons.userPlus,
            loading: leaving,
            onPressed: leaving ? null : () => onLeave(createAccount: true),
          ),
          TextButton(onPressed: leaving ? null : () => onLeave(createAccount: false), child: Text(l10n.back)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: RawanaPageHeader(
          icon: LucideIcons.car,
          iconColor: RawanaColors.warning,
          title: l10n.almostThere,
          subtitle: l10n.driverAccountOnPassengerApp,
        ),
      ),
    );
  }
}
