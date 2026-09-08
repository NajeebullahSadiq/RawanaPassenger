import 'package:flutter/material.dart';
import '../content/rawana_driver_content.dart';
import '../l10n/l10n_extensions.dart';
import '../services/support_service.dart';
import '../theme/rawana_theme.dart';
import 'rawana_primary_button.dart';

/// Shared incident / support ticket form for passenger and driver apps.
class ReportIssueScreen extends StatefulWidget {
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
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  late String _category;
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _submitting = false;
  bool _didInitSubject = false;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? 'other';
    if (widget.initialSubject != null) {
      _subjectController.text = widget.initialSubject!;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitSubject) return;
    _didInitSubject = true;
    if (widget.initialSubject == null && widget.tripId != null) {
      _subjectController.text = context.l10n.issueWithTrip(
        widget.tripId!.substring(0, 8),
      );
    }
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = context.l10n;
    final subject = _subjectController.text.trim();
    final description = _descriptionController.text.trim();
    if (subject.length < 3 || description.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportValidation)),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await widget.supportService.createTicket(
        tripId: widget.tripId,
        category: _category,
        subject: subject,
        description: description,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.reportSubmitted)),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.failedToSubmit('$e'))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? l10n.reportAnIssue)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (widget.tripId != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                l10n.tripShortId(widget.tripId!.substring(0, 8)),
                style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ),
          Text(l10n.category, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: (widget.categoryOptions ?? localizedPassengerSupportCategories(l10n))
                .entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: _submitting ? null : (v) => setState(() => _category = v ?? 'other'),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _subjectController,
            decoration: InputDecoration(
              labelText: l10n.subject,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            enabled: !_submitting,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: l10n.whatHappened,
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            enabled: !_submitting,
          ),
          if (_category == 'safety_concern') ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Text(
                l10n.safetyReportPriority,
                style: const TextStyle(color: RawanaColors.error, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 24),
          RawanaPrimaryButton(
            label: _submitting ? l10n.submitting : l10n.submitReport,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
