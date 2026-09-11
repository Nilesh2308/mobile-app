import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Clean SaaS text field with focus ring, labels, and helper/error states.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hintText,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.autofocus = false,
    this.maxLines = 1,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.showClearButton = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hintText;
  final String? helperText;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final bool autofocus;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool showClearButton;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;
  late final TextEditingController _controller;
  bool _isFocused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChange);
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChange);
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
  }

  void _onTextChange() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors.of(context);
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;

    // Border color computation
    final Color borderColor;
    if (hasError) {
      borderColor = colors.error;
    } else if (_isFocused) {
      borderColor = colors.primary;
    } else {
      borderColor = colors.borderSubtle;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTextStyles.label(
              color: hasError ? colors.error : colors.textSecondary,
            ),
          ),
          AppSpacing.vGap8,
        ],
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: widget.enabled ? colors.surface : colors.surfaceSecondary.withValues(alpha: 0.5),
            borderRadius: AppRadius.borderR12,
            border: Border.all(
              color: borderColor,
              width: _isFocused ? 1.5 : 1.0,
            ),
            boxShadow: _isFocused && !hasError
                ? [
                    BoxShadow(
                      color: colors.primary.withValues(alpha: 0.12),
                      offset: const Offset(0, 0),
                      blurRadius: 4,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            autofocus: widget.autofocus,
            obscureText: widget.obscureText,
            maxLines: widget.maxLines,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            style: AppTextStyles.bodyMedium(color: colors.textPrimary),
            cursorColor: colors.primary,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s12,
                vertical: AppSpacing.s12,
              ),
              border: InputBorder.none,
              hintText: widget.hintText,
              hintStyle: AppTextStyles.bodyMedium(color: colors.textMuted),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: 18,
                      color: _isFocused ? colors.primary : colors.textMuted,
                    )
                  : null,
              suffixIcon: widget.showClearButton && _hasText
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, size: 16),
                      color: colors.textMuted,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onPressed: () {
                        _controller.clear();
                        widget.onChanged?.call('');
                      },
                    )
                  : widget.suffixIcon,
            ),
          ),
        ),
        if (hasError) ...[
          AppSpacing.vGap4,
          Text(
            widget.errorText!,
            style: AppTextStyles.caption(color: colors.error),
          ),
        ] else if (widget.helperText != null) ...[
          AppSpacing.vGap4,
          Text(
            widget.helperText!,
            style: AppTextStyles.caption(color: colors.textMuted),
          ),
        ],
      ],
    );
  }
}
