import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Outlined form field with a floating label.
///
/// Borders, focus ring (1.5dp primary), error colours, padding (16/14) and
/// text styles come from `InputDecorationThemeData` in [AppTheme].
///
/// [reserveHelperSpace] (default true) keeps one line of helper/error text
/// allocated at all times, so showing a validation error never makes the form
/// jump.
class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.initialValue,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.onTap,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.focusNode,
    this.autovalidateMode,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.reserveHelperSpace = true,
  });

  final String label;
  final TextEditingController? controller;
  final String? initialValue;
  final String? hint;
  final String? helperText;

  /// Externally supplied error (for example from a server). Overrides
  /// validator output.
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final VoidCallback? onTap;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final AutovalidateMode? autovalidateMode;
  final IconData? prefixIcon;

  /// Trailing widget (clear / show-password button, unit label...).
  final Widget? suffix;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool reserveHelperSpace;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: controller == null ? initialValue : null,
      focusNode: focusNode,
      validator: validator,
      autovalidateMode: autovalidateMode,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      onTap: onTap,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      textCapitalization: textCapitalization,
      autofillHints: autofillHints,
      inputFormatters: inputFormatters,
      obscureText: obscureText,
      enabled: enabled,
      readOnly: readOnly,
      autofocus: autofocus,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      maxLength: maxLength,
      style: context.text.bodyLarge,
      scrollPadding: const EdgeInsets.all(AppSpacing.xxl * 2),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // A single space reserves the helper line so errors don't shift layout.
        helperText: helperText ?? (reserveHelperSpace ? ' ' : null),
        errorText: errorText,
        counterText: maxLength == null ? null : '',
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: AppSizes.icon),
        suffixIcon: suffix,
      ),
    );
  }
}

/// [AppTextField] preset for passwords: obscured, autofill-aware, with a
/// show/hide toggle.
class AppPasswordField extends StatefulWidget {
  const AppPasswordField({
    super.key,
    this.label = 'Password',
    this.controller,
    this.validator,
    this.onFieldSubmitted,
    this.textInputAction = TextInputAction.done,
    this.autofillHints = const [AutofillHints.password],
    this.helperText,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction textInputAction;
  final Iterable<String> autofillHints;
  final String? helperText;
  final String? errorText;
  final bool enabled;

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) => AppTextField(
    label: widget.label,
    controller: widget.controller,
    validator: widget.validator,
    onFieldSubmitted: widget.onFieldSubmitted,
    textInputAction: widget.textInputAction,
    autofillHints: widget.autofillHints,
    helperText: widget.helperText,
    errorText: widget.errorText,
    enabled: widget.enabled,
    keyboardType: TextInputType.visiblePassword,
    prefixIcon: Icons.lock_outline_rounded,
    obscureText: _obscured,
    suffix: IconButton(
      tooltip: _obscured ? 'Show password' : 'Hide password',
      onPressed: () => setState(() => _obscured = !_obscured),
      icon: Icon(
        _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
    ),
  );
}
