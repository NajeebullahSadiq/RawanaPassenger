import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/rawana_theme.dart';

class OtpInput extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final bool hasError;

  const OtpInput({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.hasError = false,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> with SingleTickerProviderStateMixin {
  late final List<TextEditingController> _controllers =
      List.generate(widget.length, (_) => TextEditingController());
  late final List<FocusNode> _focusNodes =
      List.generate(widget.length, (_) => FocusNode());
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
  }

  @override
  void didUpdateWidget(OtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasError && !oldWidget.hasError) {
      _shakeController.forward(from: 0);
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

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final offset = _shakeController.value < 0.5
            ? _shakeController.value * 20
            : (1 - _shakeController.value) * 20;
        return Transform.translate(
          offset: Offset(offset * (widget.hasError ? 1 : 0), 0),
          child: child,
        );
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(widget.length, (i) {
          final hasValue = _controllers[i].text.isNotEmpty;
          return SizedBox(
            width: 50,
            height: 60,
            child: TextField(
              controller: _controllers[i],
              focusNode: _focusNodes[i],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: RawanaColors.onSurface,
              ),
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(RawanaSpacing.radiusMd),
                  borderSide: const BorderSide(color: RawanaColors.error, width: 1.8),
                ),
              ),
              onChanged: (v) => _onChanged(i, v),
            ),
          );
        }),
      ),
    );
  }
}
