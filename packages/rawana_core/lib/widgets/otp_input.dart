import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/rawana_theme.dart';

/// One-time-code boxes. Always laid out left-to-right (digits read LTR in
/// Dari and Pashto too), accepts a pasted or SMS-autofilled full code in any
/// box, and shakes when [hasError] flips on.
class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;
  final bool autofocus;

  const OtpInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
    this.autofocus = true,
  });

  @override
  State<OtpInput> createState() => OtpInputState();
}

class OtpInputState extends State<OtpInput> with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _controllers =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _focusNodes = List.generate(widget.length, (i) {
    return FocusNode(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace &&
            _controllers[i].text.isEmpty &&
            i > 0) {
          _controllers[i - 1].clear();
          _focusNodes[i - 1].requestFocus();
          _notify();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
    );
  });
  late final AnimationController _shakeController =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

  String get code => _controllers.map((c) => c.text).join();

  /// Clears every box and focuses the first one.
  void clear() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
  }

  @override
  void didUpdateWidget(OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shakeController.forward(from: 0);
      HapticFeedback.mediumImpact();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _shakeController.dispose();
    super.dispose();
  }

  void _notify() {
    setState(() {});
    final value = code;
    widget.onChanged?.call(value);
    if (value.length == widget.length) widget.onCompleted(value);
  }

  void _onChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      // Paste or SMS autofill: spread from this box onwards.
      final start = digits.length >= widget.length ? 0 : index;
      for (var k = 0; k < widget.length - start; k++) {
        _controllers[start + k].text = k < digits.length ? digits[k] : _controllers[start + k].text;
      }
      final next = (start + digits.length).clamp(0, widget.length - 1);
      _focusNodes[next].requestFocus();
      if (code.length == widget.length) _focusNodes[next].unfocus();
      _notify();
      return;
    }
    _controllers[index].text = digits;
    _controllers[index].selection = TextSelection.collapsed(offset: digits.length);
    if (digits.length == 1) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          final t = _shakeController.value;
          final offset = (t < 0.5 ? t : 1 - t) * 20;
          return Transform.translate(offset: Offset(widget.hasError ? offset : 0, 0), child: child);
        },
        child: Row(
          children: List.generate(widget.length, (i) {
            final hasValue = _controllers[i].text.isNotEmpty;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i == 0 ? 0 : 6, right: i == widget.length - 1 ? 0 : 6),
                child: SizedBox(
                  height: 60,
                  child: TextField(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    autofocus: widget.autofocus && i == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    autofillHints: i == 0 ? const [AutofillHints.oneTimeCode] : null,
                    style: context.text.headline,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: hasValue ? RawanaColors.primary.withValues(alpha: 0.06) : Colors.white,
                      contentPadding: EdgeInsets.zero,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                        borderSide: BorderSide(
                          color: widget.hasError
                              ? RawanaColors.error
                              : (hasValue ? RawanaColors.primary : RawanaColors.divider),
                          width: hasValue ? 1.8 : 1.4,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                        borderSide: const BorderSide(color: RawanaColors.primary, width: 2),
                      ),
                    ),
                    onChanged: (v) => _onChanged(i, v),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
