import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ref.read(passengerServiceProvider).getProfile();
      if (!mounted) return;
      if (isPassengerProfileComplete(profile)) {
        context.go('/home');
        return;
      }
      final phone = profile['phone'] as String? ?? '';
      final hasRealPhone = isRegistrationPhoneValid(phone);
      _nameController.text = (profile['name'] as String?)?.trim() ?? '';
      _emailController.text = registrationEmailForDisplay(profile['email'] as String?);
      _photoUrl = profile['profile_photo_url'] as String?;
      if (hasRealPhone) {
        _phoneController.text = phone;
        _phoneReadOnly = true;
        _phoneVerified = true;
      } else {
        // Prefill from signup metadata so phone is not asked twice.
        final meta = ref.read(authServiceProvider).currentUser?.userMetadata;
        final metaPhone = meta?['phone'] as String?;
        final metaName = meta?['name'] as String?;
        if (isRegistrationPhoneValid(metaPhone)) {
          _phoneController.text = metaPhone!;
          _phoneReadOnly = true;
          _phoneVerified = true;
        }
        if (_nameController.text.isEmpty &&
            metaName != null &&
            metaName.trim().isNotEmpty) {
          _nameController.text = metaName.trim();
        }
      }
    } catch (e) {
      if (apiErrorKey(e) == 'driver_account_on_passenger_app') {
        _driverAccount = true;
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
    if (createAccount) {
      context.go('/email-auth?mode=signup');
    } else {
      context.go('/auth');
    }
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

  String? _mimeForFileName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _pickPhoto() async {
    final image = await ImagePicker().pickImage(
      source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
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
      setState(() => _photoUrl = url);
    } catch (e) {
      if (mounted) showRawanaError(context, e);
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _submit() async {
    if (!_formValid) return;
    setState(() => _loading = true);
    try {
      final phone = registrationPhoneForSubmit(
        phone: _phoneController.text,
        phoneReadOnly: _phoneReadOnly,
      );
      await ref.read(passengerServiceProvider).updateProfile(
            name: _nameController.text.trim(),
            phone: phone,
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
      showRawanaError(context, e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = ref.watch(localeProvider).languageCode;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(context.l10n.completeYourProfile),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: RawanaCircleIconButton(
            icon: LucideIcons.arrowLeft,
            background: RawanaColors.surfaceAlt,
            iconColor: RawanaColors.onSurface,
            elevated: false,
            size: 40,
            onPressed: _leaving ? null : () => _leave(createAccount: false),
          ),
        ),
      ),
      body: SafeArea(
        child: _loadingProfile
            ? const Center(child: CircularProgressIndicator())
            : _driverAccount
                ? _DriverAccountBlock(
                    leaving: _leaving,
                    onBack: () => _leave(createAccount: false),
                    onCreateAccount: () => _leave(createAccount: true),
                  )
                : Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      context.l10n.almostThere,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.profileSetupSubtitle,
                      style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 15, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: RawanaColors.primary.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                              image: _photoUrl != null
                                  ? DecorationImage(image: NetworkImage(_photoUrl!), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: _photoUrl == null
                                ? const Center(
                                    child: Icon(LucideIcons.user, color: RawanaColors.primary, size: 40),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: GestureDetector(
                              onTap: _uploadingPhoto ? null : _pickPhoto,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: RawanaColors.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: _uploadingPhoto
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(LucideIcons.camera, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: SingleChildScrollView(
                        child: RegistrationEssentialsFields(
                          nameController: _nameController,
                          phoneController: _phoneController,
                          emailController: _emailController,
                          phoneReadOnly: _phoneReadOnly,
                          phoneVerified: _phoneVerified,
                          onChanged: () => setState(() {}),
                          languageCode: languageCode,
                          onLanguageChanged: (code) {
                            ref.read(localeProvider.notifier).setLocale(Locale(code));
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RawanaPrimaryButton(
                      label: context.l10n.continueAction,
                      icon: LucideIcons.arrowRight,
                      loading: _loading,
                      onPressed: _formValid && !_leaving ? _submit : null,
                    ),
                    TextButton(
                      onPressed: _leaving || _loading ? null : () => _leave(createAccount: true),
                      child: Text(context.l10n.newHereCreateAccount),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _DriverAccountBlock extends StatelessWidget {
  const _DriverAccountBlock({
    required this.leaving,
    required this.onBack,
    required this.onCreateAccount,
  });

  final bool leaving;
  final VoidCallback onBack;
  final VoidCallback onCreateAccount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Text(
            context.l10n.almostThere,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.6),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.driverAccountOnPassengerApp,
            style: const TextStyle(color: RawanaColors.onSurfaceMuted, fontSize: 15, height: 1.5),
          ),
          const Spacer(),
          RawanaPrimaryButton(
            label: context.l10n.createAccount,
            icon: LucideIcons.userPlus,
            loading: leaving,
            onPressed: leaving ? null : onCreateAccount,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: leaving ? null : onBack,
            child: Text(context.l10n.back),
          ),
        ],
      ),
    );
  }
}
