import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vyaparsetu/global/themes.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool isPassword;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int? maxLines;
  final void Function(String)? onChanged;
  final void Function(String?)? onSaved;
  final String? initialValue;
  final bool readOnly;
  final VoidCallback? onTap;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  const AppTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.onChanged,
    this.onSaved,
    this.initialValue,
    this.readOnly = false,
    this.onTap,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  bool _isFocused = false;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark ? AppTheme.primaryDark : AppTheme.primary;

    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      initialValue: widget.initialValue,
      obscureText: widget.isPassword ? _obscureText : false,
      keyboardType: widget.keyboardType,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      onChanged: widget.onChanged,
      onSaved: widget.onSaved,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: theme.textTheme.bodyLarge?.color,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null
            ? Padding(
                padding: const EdgeInsets.only(left: 12, right: 8),
                child: Icon(
                  widget.prefixIcon,
                  color: _isFocused ? accent : theme.iconTheme.color?.withValues(alpha: 0.4),
                  size: 20,
                ),
              )
            : null,
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 0,
        ),
        suffixIcon: widget.isPassword
            ? Padding(
                padding: const EdgeInsets.only(right: 12),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: theme.iconTheme.color?.withValues(alpha: 0.4),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureText = !_obscureText;
                    });
                  },
                ),
              )
            : widget.suffixIcon,
      ),
      validator: widget.validator,
    );
  }
}
