import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../content/rawana_driver_content.dart';
import '../l10n/app_ui_l10n.dart';
import '../l10n/l10n_extensions.dart';
import '../services/support_service.dart';
import '../theme/rawana_theme.dart';
import 'rawana_empty_state.dart';
import 'rawana_primary_button.dart';
import 'report_issue_screen.dart';
import 'show_rawana_error.dart';
import 'ui/rawana_banner.dart';
import 'ui/rawana_error_state.dart';
import 'ui/rawana_icons.dart';
import 'ui/rawana_scaffold.dart';
import 'ui/rawana_skeleton.dart';
import 'ui/status_pill.dart';

/// "Report an issue" button plus the user's support tickets.
class SupportTicketsPanel extends StatefulWidget {
  const SupportTicketsPanel({super.key, required this.supportService, this.categoryOptions});

  final SupportService supportService;

  /// Category labels for the report form and ticket rows; defaults to passenger categories.
  final Map<String, String>? categoryOptions;

  @override
  State<SupportTicketsPanel> createState() => _SupportTicketsPanelState();
}

class _SupportTicketsPanelState extends State<SupportTicketsPanel> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.supportService.listTickets();
  }

  void _reload() {
    setState(() => _future = widget.supportService.listTickets());
  }

  Future<void> _report() async {
    final sent = await showReportIssueSheet(
      context,
      supportService: widget.supportService,
      categoryOptions: widget.categoryOptions,
    );
    if (sent && mounted) _reload();
  }

  Future<void> _open(Map<String, dynamic> ticket) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupportTicketThreadScreen(
          supportService: widget.supportService,
          ticketId: ticket['id'] as String,
          initialSubject: ticket['subject'] as String?,
        ),
      ),
    );
    if (mounted) _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final categories = widget.categoryOptions ?? localizedPassengerSupportCategories(l10n);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RawanaPrimaryButton(label: l10n.reportAnIssue, icon: LucideIcons.flag, onPressed: _report),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 0, 4, 8),
          child: Text(l10n.yourTickets, style: context.text.label.copyWith(color: RawanaColors.onSurfaceMuted)),
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return RawanaBanner.error(
                message: l10n.friendlyApiError(snapshot.error!),
                action: TextButton(onPressed: _reload, child: Text(l10n.tryAgain)),
              );
            }
            if (!snapshot.hasData) return const RawanaSkeletonList(count: 2, padding: EdgeInsets.zero);
            final tickets = snapshot.data!;
            if (tickets.isEmpty) {
              return RawanaEmptyState(icon: LucideIcons.messagesSquare, title: l10n.noTickets, dense: true);
            }
            return Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(RawanaSpacing.radiusLg),
                border: Border.all(color: RawanaColors.divider),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < tickets.length; i++) ...[
                    if (i > 0) const Divider(height: 1, indent: 16),
                    _TicketRow(
                      ticket: tickets[i],
                      categoryLabel: categories[tickets[i]['category']] ?? l10n.supportOther,
                      onTap: () => _open(tickets[i]),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _TicketRow extends StatelessWidget {
  const _TicketRow({required this.ticket, required this.categoryLabel, required this.onTap});

  final Map<String, dynamic> ticket;
  final String categoryLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final updated = DateTime.tryParse(ticket['updated_at'] as String? ?? ticket['created_at'] as String? ?? '');
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket['subject'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.text.bodyStrong,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [categoryLabel, if (updated != null) context.l10n.relativeTime(updated)].join(' · '),
                      style: context.text.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TicketStatusPill(status: ticket['status'] as String?),
              const SizedBox(width: 4),
              const Icon(RawanaIcons.chevronForward, size: 18, color: RawanaColors.onSurfaceFaint),
            ],
          ),
        ),
      ),
    );
  }
}

/// Localised pill for `open` / `in_progress` / `resolved` support tickets.
class TicketStatusPill extends StatelessWidget {
  const TicketStatusPill({super.key, required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (status) {
      'resolved' => StatusPill(label: l10n.ticketStatusResolved, color: RawanaColors.success),
      'in_progress' => StatusPill(label: l10n.ticketStatusInProgress, color: RawanaColors.warning),
      _ => StatusPill(label: l10n.ticketStatusOpen, color: RawanaColors.primary),
    };
  }
}

class SupportTicketThreadScreen extends StatefulWidget {
  const SupportTicketThreadScreen({
    super.key,
    required this.supportService,
    required this.ticketId,
    this.initialSubject,
  });

  final SupportService supportService;
  final String ticketId;
  final String? initialSubject;

  @override
  State<SupportTicketThreadScreen> createState() => _SupportTicketThreadScreenState();
}

class _SupportTicketThreadScreenState extends State<SupportTicketThreadScreen> {
  final _reply = TextEditingController();
  Map<String, dynamic>? _ticket;
  Object? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final ticket = await widget.supportService.getTicket(widget.ticketId);
      if (mounted) {
        setState(() {
          _ticket = ticket;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await widget.supportService.reply(widget.ticketId, text);
      _reply.clear();
      await _load();
    } catch (e) {
      if (mounted) showRawanaError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ticket = _ticket;
    final messages = (ticket?['messages'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final title = ticket?['subject'] as String? ?? widget.initialSubject ?? l10n.supportTicket;
    return RawanaScaffold(
      title: title,
      actions: [
        if (ticket != null)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 12),
            child: Center(child: TicketStatusPill(status: ticket['status'] as String?)),
          ),
      ],
      body: Column(
        children: [
          Expanded(
            child: ticket == null
                ? (_error != null
                    ? Center(
                        child: RawanaErrorState(
                          title: l10n.somethingWentWrong,
                          message: l10n.friendlyApiError(_error!),
                          retryLabel: l10n.tryAgain,
                          onRetry: _load,
                        ),
                      )
                    : const RawanaSkeletonList(count: 3))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      children: [
                        _Bubble(
                          text: ticket['description'] as String? ?? '',
                          mine: true,
                          author: l10n.youLabel,
                          at: DateTime.tryParse(ticket['created_at'] as String? ?? ''),
                        ),
                        for (final message in messages)
                          _Bubble(
                            text: message['message'] as String? ?? '',
                            mine: message['sender_role'] != 'admin',
                            author: message['sender_role'] == 'admin' ? l10n.supportAgentLabel : l10n.youLabel,
                            at: DateTime.tryParse(message['created_at'] as String? ?? ''),
                          ),
                        if (ticket['status'] == 'resolved') ...[
                          const SizedBox(height: 8),
                          RawanaBanner(
                            tone: RawanaBannerTone.success,
                            icon: LucideIcons.circleCheck,
                            message: l10n.ticketResolvedNote,
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          if (ticket != null)
            Material(
              color: Colors.white,
              elevation: 8,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _reply,
                          minLines: 1,
                          maxLines: 4,
                          maxLength: 2000,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(hintText: l10n.reply, counterText: ''),
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton.filled(
                        tooltip: l10n.sendReply,
                        onPressed: _sending ? null : _send,
                        icon: _sending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(LucideIcons.sendHorizontal, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine, required this.author, this.at});

  final String text;
  final bool mine;
  final String author;
  final DateTime? at;

  @override
  Widget build(BuildContext context) {
    final meta = [author, if (at != null) context.l10n.relativeTime(at!)].join(' · ');
    return Align(
      alignment: mine ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: mine ? RawanaColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
          border: Border.all(color: mine ? RawanaColors.primary.withValues(alpha: 0.18) : RawanaColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(meta, style: context.text.caption),
            const SizedBox(height: 4),
            Text(text, style: context.text.body),
          ],
        ),
      ),
    );
  }
}
