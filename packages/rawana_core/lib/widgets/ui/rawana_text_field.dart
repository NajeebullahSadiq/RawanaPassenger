import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../l10n/app_ui_l10n.dart';
import '../../l10n/l10n_extensions.dart';
import '../../theme/rawana_theme.dart';

/// Labelled text input. With [obscure] it gets a show / hide toggle.
class RawanaTextField extends StatefulWidget {
  const RawanaTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.obscure = false,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.autofocus = false,
    this.autofillHints,
    this.inputFormatters,
    this.errorText,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.textDirection,
    this.initialValue,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool obscure;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final bool autofocus;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final TextDirection? textDirection;
  final String? initialValue;

  @override
  State<RawanaTextField> createState() => _RawanaTextFieldState();
}

class _RawanaTextFieldState extends State<RawanaTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
      controller: widget.controller,
      initialValue: widget.controller == null ? widget.initialValue : null,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      validator: widget.validator,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      obscureText: _hidden,
      maxLines: widget.obscure ? 1 : widget.maxLines,
      maxLength: widget.maxLength,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      textDirection: widget.textDirection,
      style: context.text.body.copyWith(color: RawanaColors.onSurface),
      decoration: InputDecoration(
        hintText: widget.hint,
        errorText: widget.errorText,
        errorMaxLines: 3,
        counterText: '',
        prefixIcon: widget.prefixIcon == null ? null : Icon(widget.prefixIcon, size: 20),
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _hidden ? context.l10n.showPassword : context.l10n.hidePassword,
                icon: Icon(_hidden ? LucideIcons.eye : LucideIcons.eyeOff, size: 20),
                onPressed: () => setState(() => _hidden = !_hidden),
              )
            : widget.suffix,
      ),
    );
    if (widget.label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label!, style: context.text.label.copyWith(color: RawanaColors.onSurfaceMuted)),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}

/// Afghan mobile number input: fixed +93 prefix, digits only, always LTR.
class RawanaPhoneField extends StatelessWidget {
  const RawanaPhoneField({
    super.key,
    required this.controller,
    this.label,
    this.hint = '70 123 4567',
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
  });

  final TextEditingController controller;
  final String? label;
  final String hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool enabled;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final field = Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: controller,
        autofocus: autofocus,
        enabled: enabled,
        keyboardType: TextInputType.phone,
        textInputAction: textInputAction,
        autofillHints: const [AutofillHints.telephoneNumberNational],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
        style: context.text.title,
        decoration: InputDecoration(
          hintText: hint,
          errorText: errorText,
          errorMaxLines: 3,
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('+93', style: context.text.title),
                const SizedBox(width: 10),
                Container(width: 1, height: 22, color: RawanaColors.divider),
              ],
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        ),
      ),
    );
    if (label == null) return field;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label!, style: context.text.label.copyWith(color: RawanaColors.onSurfaceMuted)),
        const SizedBox(height: 8),
        field,
      ],
    );
  }
}
