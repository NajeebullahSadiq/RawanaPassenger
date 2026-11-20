import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../content/rawana_driver_content.dart';
import '../l10n/l10n_extensions.dart';
import '../services/support_service.dart';
import '../theme/rawana_theme.dart';
import 'rawana_primary_button.dart';
import 'show_rawana_error.dart';
import 'ui/rawana_action_sheet.dart';
import 'ui/rawana_banner.dart';
import 'ui/rawana_scaffold.dart';
import 'ui/rawana_text_field.dart';

/// Opens the report form in a bottom sheet. Resolves to true when a ticket was filed.
Future<bool> showReportIssueSheet(
  BuildContext context, {
  required SupportService supportService,
  String? tripId,
  String? initialCategory,
  Map<String, String>? categoryOptions,
  String? initialSubject,
}) async {
  final sent = await RawanaActionSheet.custom<bool>(
    context,
    ReportIssueForm(
      supportService: supportService,
      tripId: tripId,
      initialCategory: initialCategory,
      categoryOptions: categoryOptions,
      initialSubject: initialSubject,
      showTitle: true,
      onSubmitted: () => Navigator.of(context).pop(true),
    ),
  );
  if (sent == true && context.mounted) showRawanaToast(context, context.l10n.reportSubmitted);
  return sent == true;
}

/// Shared incident / support ticket page for passenger and driver apps.
class ReportIssueScreen extends StatelessWidget {
  const ReportIssueScreen({
    super.key,
    required this.supportService,
    this.tripId,
    this.initialCategory,
    this.title,
    this.categoryOptions,
    this.initialSubject,
  });

  final SupportService supportService;
  final String? tripId;
  final String? initialCategory;
  final String? title;
  final Map<String, String>? categoryOptions;
  final String? initialSubject;

  @override
  Widget build(BuildContext context) {
    return RawanaScaffold(
      title: title ?? context.l10n.reportAnIssue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: ReportIssueForm(
          supportService: supportService,
          tripId: tripId,
          initialCategory: initialCategory,
          categoryOptions: categoryOptions,
          initialSubject: initialSubject,
          onSubmitted: () {
            showRawanaToast(context, context.l10n.reportSubmitted);
            Navigator.of(context).pop(true);
          },
        ),
      ),
    );
  }
}

/// Category, subject and description, with inline validation.
class ReportIssueForm extends StatefulWidget {
  const ReportIssueForm({
    super.key,
    required this.supportService,
    required this.onSubmitted,
    this.tripId,
    this.initialCategory,
    this.categoryOptions,
    this.initialSubject,
    this.showTitle = false,
  });

  final SupportService supportService;
  final VoidCallback onSubmitted;
  final String? tripId;
  final String? initialCategory;
  final Map<String, String>? categoryOptions;
  final String? initialSubject;
  final bool showTitle;

  @override
  State<ReportIssueForm> createState() => _ReportIssueFormState();
}

class _ReportIssueFormState extends State<ReportIssueForm> {
  final _formKey = GlobalKey<FormState>();
  late String _category = widget.initialCategory ?? 'other';
  final _subject = TextEditingController();
  final _description = TextEditingController();
  bool _submitting = false;
  bool _didInitSubject = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitSubject) return;
    _didInitSubject = true;
    if (widget.initialSubject != null) {
      _subject.text = widget.initialSubject!;
    } else if (widget.tripId != null) {
      _subject.text = context.l10n.issueWithTrip(_short(widget.tripId!));
    }
  }

  static String _short(String id) => id.length > 8 ? id.substring(0, 8) : id;

  @override
  void dispose() {
    _subject.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await widget.supportService.createTicket(
        tripId: widget.tripId,
        category: _category,
        subject: _subject.text.trim(),
        description: _description.text.trim(),
      );
      if (mounted) widget.onSubmitted();
    } catch (e) {
      if (mounted) setState(() => _error = context.l10n.friendlyApiError(e));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = widget.categoryOptions ?? localizedPassengerSupportCategories(l10n);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showTitle) ...[
            Text(l10n.reportAnIssue, style: context.text.headline),
            const SizedBox(height: 4),
          ],
          if (widget.tripId != null) ...[
            Text(l10n.tripShortId(_short(widget.tripId!)), style: context.text.caption),
            const SizedBox(height: 16),
          ],
          Text(l10n.category, style: context.text.label.copyWith(color: RawanaColors.onSurfaceMuted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in categories.entries)
                ChoiceChip(
                  label: Text(e.value),
                  selected: _category == e.key,
                  onSelected: _submitting ? null : (_) => setState(() => _category = e.key),
                ),
            ],
          ),
          const SizedBox(height: 20),
          RawanaTextField(
            controller: _subject,
            label: l10n.subject,
            enabled: !_submitting,
            maxLength: 120,
            textInputAction: TextInputAction.next,
            validator: (v) => (v ?? '').trim().length < 3 ? l10n.reportValidation : null,
          ),
          const SizedBox(height: 16),
          RawanaTextField(
            controller: _description,
            label: l10n.whatHappened,
            enabled: !_submitting,
            maxLines: 5,
            maxLength: 2000,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => (v ?? '').trim().length < 10 ? l10n.reportValidation : null,
          ),
          if (_category == 'safety_concern') ...[
            const SizedBox(height: 16),
            RawanaBanner(
              tone: RawanaBannerTone.error,
              icon: LucideIcons.shieldAlert,
              message: l10n.safetyReportPriority,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            RawanaBanner.error(message: _error!),
          ],
          const SizedBox(height: 24),
          RawanaPrimaryButton(
            label: _submitting ? l10n.submitting : l10n.submitReport,
            loading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
