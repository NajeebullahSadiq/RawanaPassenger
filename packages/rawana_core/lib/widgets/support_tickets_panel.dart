import 'package:flutter/material.dart';

import '../l10n/l10n_extensions.dart';
import '../services/support_service.dart';
import '../theme/rawana_theme.dart';
import 'rawana_empty_state.dart';
import 'rawana_primary_button.dart';
import 'rawana_surface_card.dart';
import 'report_issue_screen.dart';

class SupportTicketsPanel extends StatefulWidget {
  const SupportTicketsPanel({super.key, required this.supportService});

  final SupportService supportService;

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RawanaPrimaryButton(
          label: context.l10n.reportAnIssue,
          icon: Icons.flag_outlined,
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportIssueScreen(supportService: widget.supportService),
              ),
            );
            _reload();
          },
        ),
        const SizedBox(height: 16),
        Text(
          context.l10n.yourTickets,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 10),
        FutureBuilder(
          future: _future,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final tickets = snapshot.data!;
            if (tickets.isEmpty) {
              return RawanaEmptyState(
                icon: Icons.forum_outlined,
                title: context.l10n.noTickets,
                dense: true,
              );
            }
            return Column(
              children: [
                for (final ticket in tickets)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: RawanaSurfaceCard(
                      shadows: const [],
                      border: Border.all(color: RawanaColors.divider),
                      padding: const EdgeInsets.all(14),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => SupportTicketThreadScreen(
                              supportService: widget.supportService,
                              ticketId: ticket['id'] as String,
                            ),
                          ),
                        );
                        _reload();
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ticket['subject'] as String? ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${ticket['status'] ?? ''} · ${ticket['category'] ?? ''}',
                                  style: const TextStyle(
                                    color: RawanaColors.onSurfaceMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: RawanaColors.onSurfaceFaint),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class SupportTicketThreadScreen extends StatefulWidget {
  const SupportTicketThreadScreen({
    super.key,
    required this.supportService,
    required this.ticketId,
  });

  final SupportService supportService;
  final String ticketId;

  @override
  State<SupportTicketThreadScreen> createState() => _SupportTicketThreadScreenState();
}

class _SupportTicketThreadScreenState extends State<SupportTicketThreadScreen> {
  final _reply = TextEditingController();
  Map<String, dynamic>? _ticket;
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
    final ticket = await widget.supportService.getTicket(widget.ticketId);
    if (mounted) setState(() => _ticket = ticket);
  }

  Future<void> _send() async {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      await widget.supportService.reply(widget.ticketId, text);
      _reply.clear();
      await _load();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = (_ticket?['messages'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return Scaffold(
      backgroundColor: RawanaColors.surface,
      appBar: AppBar(title: Text(_ticket?['subject'] as String? ?? context.l10n.yourTickets)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_ticket != null)
                  Text(
                    _ticket!['description'] as String? ?? '',
                    style: const TextStyle(height: 1.45),
                  ),
                const SizedBox(height: 16),
                for (final message in messages)
                  Align(
                    alignment: message['sender_role'] == 'admin'
                        ? Alignment.centerLeft
                        : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      constraints: const BoxConstraints(maxWidth: 320),
                      decoration: BoxDecoration(
                        color: message['sender_role'] == 'admin'
                            ? Colors.white
                            : RawanaColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: RawanaColors.divider),
                      ),
                      child: Text(message['message'] as String? ?? ''),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _reply,
                      decoration: InputDecoration(hintText: context.l10n.reply),
                    ),
                  ),
                  IconButton(
                    onPressed: _sending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
