import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/l10n_extensions.dart';
import '../services/trip_chat_service.dart';
import '../theme/rawana_theme.dart';

/// In-app chat between the passenger and driver of an active trip.
///
/// WhatsApp stays a separate, explicit action ([onWhatsApp]) so the default
/// conversation never leaves the app.
class TripChatScreen extends StatefulWidget {
  const TripChatScreen({
    super.key,
    required this.tripId,
    required this.service,
    required this.myRole,
    required this.partyName,
    this.partySubtitle,
    this.onCall,
    this.onWhatsApp,
  });

  final String tripId;
  final TripChatService service;

  /// `passenger` or `driver` — decides which bubbles are "mine".
  final String myRole;
  final String partyName;
  final String? partySubtitle;
  final VoidCallback? onCall;
  final VoidCallback? onWhatsApp;

  @override
  State<TripChatScreen> createState() => _TripChatScreenState();
}

class _TripChatScreenState extends State<TripChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<TripMessage> _messages = const [];
  final List<TripMessage> _outgoing = [];
  bool _loading = true;
  bool _canSend = true;
  String? _loadError;
  Timer? _pollTimer;
  int _localId = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _load());
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final thread = await widget.service.fetch(widget.tripId);
      if (!mounted) return;
      final hadUnread = thread.messages.any(
        (m) => m.senderRole != widget.myRole && m.readAt == null,
      );
      setState(() {
        _messages = thread.messages;
        _canSend = thread.canSend;
        _loading = false;
        _loadError = null;
      });
      if (hadUnread) unawaited(widget.service.markRead(widget.tripId).catchError((_) {}));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_messages.isEmpty) _loadError = context.l10n.chatLoadFailed;
      });
    }
  }

  Future<void> _send([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || !_canSend) return;
    if (preset == null) _controller.clear();
    final local = TripMessage(
      id: 'local_${_localId++}',
      senderRole: widget.myRole,
      body: text,
      createdAt: DateTime.now(),
      pending: true,
    );
    setState(() => _outgoing.add(local));
    await _deliver(local);
  }

  Future<void> _deliver(TripMessage local) async {
    try {
      final sent = await widget.service.send(widget.tripId, local.body);
      if (!mounted) return;
      setState(() {
        _outgoing.removeWhere((m) => m.id == local.id);
        if (!_messages.any((m) => m.id == sent.id)) {
          _messages = [..._messages, sent];
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final i = _outgoing.indexWhere((m) => m.id == local.id);
        if (i >= 0) _outgoing[i] = local.copyWith(pending: false, failed: true);
      });
      unawaited(_load());
    }
  }

  void _retry(TripMessage failed) {
    setState(() {
      final i = _outgoing.indexWhere((m) => m.id == failed.id);
      if (i >= 0) _outgoing[i] = failed.copyWith(pending: true, failed: false);
    });
    _deliver(failed);
  }

  List<String> _quickReplies(BuildContext context) {
    final l10n = context.l10n;
    return widget.myRole == 'driver'
        ? [l10n.chatQuickOnMyWay, l10n.chatQuickArrived, l10n.chatQuickFewMinutes]
        : [l10n.chatQuickWaiting, l10n.chatQuickComing, l10n.chatQuickFewMinutes];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final all = [..._messages, ..._outgoing];
    final reversed = all.reversed.toList();

    return Scaffold(
      backgroundColor: RawanaColors.surfaceAlt,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: RawanaColors.primary.withValues(alpha: 0.12),
              child: Text(
                widget.partyName.trim().isNotEmpty
                    ? widget.partyName.trim()[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: RawanaColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.partyName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  if (widget.partySubtitle != null &&
                      widget.partySubtitle!.isNotEmpty)
                    Text(
                      widget.partySubtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: RawanaColors.onSurfaceMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (widget.onWhatsApp != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 4),
              child: TextButton.icon(
                onPressed: widget.onWhatsApp,
                icon: const Icon(Icons.chat_rounded, size: 18, color: _whatsAppGreen),
                label: Text(
                  l10n.whatsApp,
                  style: const TextStyle(
                    color: _whatsAppGreen,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          if (widget.onCall != null)
            IconButton(
              onPressed: widget.onCall,
              tooltip: l10n.call,
              icon: const Icon(Icons.phone_rounded, color: RawanaColors.success),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading && all.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : all.isEmpty
                    ? _EmptyChat(text: _loadError ?? l10n.chatEmpty)
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        itemCount: reversed.length,
                        itemBuilder: (context, index) {
                          final message = reversed[index];
                          final mine = message.senderRole == widget.myRole;
                          return _Bubble(
                            message: message,
                            mine: mine,
                            onRetry: message.failed ? () => _retry(message) : null,
                          );
                        },
                      ),
          ),
          if (_canSend)
            _Composer(
              controller: _controller,
              quickReplies: all.isEmpty || all.length < 3
                  ? _quickReplies(context)
                  : const [],
              onQuickReply: _send,
              onSend: _controller.text.trim().isEmpty ? null : _send,
            )
          else
            SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.chatClosed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: RawanaColors.onSurfaceMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

const _whatsAppGreen = Color(0xFF128C4A);

class _EmptyChat extends StatelessWidget {
  const _EmptyChat({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 48,
              color: RawanaColors.onSurfaceMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: RawanaColors.onSurfaceMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.mine, this.onRetry});

  final TripMessage message;
  final bool mine;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(message.createdAt).format(context);
    final radius = BorderRadiusDirectional.only(
      topStart: const Radius.circular(18),
      topEnd: const Radius.circular(18),
      bottomStart: Radius.circular(mine ? 18 : 4),
      bottomEnd: Radius.circular(mine ? 4 : 18),
    );
    final meta = message.failed
        ? context.l10n.chatSendFailed
        : message.pending
            ? '…'
            : time;

    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: GestureDetector(
        onTap: onRetry,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.78,
          ),
          padding: const EdgeInsets.fromLTRB(14, 9, 14, 7),
          decoration: BoxDecoration(
            color: mine ? RawanaColors.primary : Colors.white,
            borderRadius: radius,
            border: message.failed
                ? Border.all(color: RawanaColors.error)
                : null,
            boxShadow: mine ? null : RawanaShadows.low,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.body,
                style: TextStyle(
                  color: mine ? Colors.white : RawanaColors.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.failed)
                    const Padding(
                      padding: EdgeInsetsDirectional.only(end: 4),
                      child: Icon(Icons.refresh_rounded, size: 12, color: RawanaColors.error),
                    ),
                  Text(
                    meta,
                    style: TextStyle(
                      color: message.failed
                          ? RawanaColors.error
                          : mine
                              ? Colors.white70
                              : RawanaColors.onSurfaceMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (mine && !message.pending && !message.failed) ...[
                    const SizedBox(width: 4),
                    Icon(
                      message.readAt != null
                          ? Icons.done_all_rounded
                          : Icons.done_rounded,
                      size: 14,
                      color: Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.quickReplies,
    required this.onQuickReply,
    required this.onSend,
  });

  final TextEditingController controller;
  final List<String> quickReplies;
  final ValueChanged<String> onQuickReply;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quickReplies.isNotEmpty)
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  itemCount: quickReplies.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) => ActionChip(
                    label: Text(quickReplies[i]),
                    onPressed: () => onQuickReply(quickReplies[i]),
                    backgroundColor: RawanaColors.primary.withValues(alpha: 0.08),
                    side: BorderSide.none,
                    labelStyle: const TextStyle(
                      color: RawanaColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => onSend?.call(),
                      decoration: InputDecoration(
                        hintText: context.l10n.chatHint,
                        counterText: '',
                        isDense: true,
                        filled: true,
                        fillColor: RawanaColors.surfaceAlt,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: RawanaColors.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: onSend,
                    style: IconButton.styleFrom(
                      backgroundColor: RawanaColors.primary,
                      disabledBackgroundColor: RawanaColors.outline,
                    ),
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
