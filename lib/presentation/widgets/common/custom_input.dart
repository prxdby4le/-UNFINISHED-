// lib/presentation/widgets/common/custom_input.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Input customizado com visual premium
class CustomInput extends StatefulWidget {
  final String? label;
  final String? hint;
  final String? error;
  final TextEditingController? controller;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final TextCapitalization textCapitalization;
  final int maxLines;
  final bool autofocus;

  const CustomInput({
    super.key,
    this.label,
    this.hint,
    this.error,
    this.controller,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.onChanged,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  State<CustomInput> createState() => _CustomInputState();
}

class _CustomInputState extends State<CustomInput> {
  bool _isFocused = false;
  bool _isObscured = true;

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: hasError 
                  ? AppTheme.error 
                  : _isFocused 
                      ? AppTheme.primary 
                      : AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Input field
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: hasError 
                  ? AppTheme.error 
                  : _isFocused 
                      ? AppTheme.primary 
                      : AppTheme.surfaceHighlight,
              width: _isFocused || hasError ? 2 : 1,
            ),
            boxShadow: _isFocused ? [
              BoxShadow(
                color: (hasError ? AppTheme.error : AppTheme.primary)
                    .withOpacity(0.15),
                blurRadius: 12,
                spreadRadius: -4,
              ),
            ] : null,
          ),
          child: Focus(
            onFocusChange: (focused) {
              setState(() => _isFocused = focused);
            },
            child: TextFormField(
              controller: widget.controller,
              obscureText: widget.obscureText && _isObscured,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              validator: widget.validator,
              textCapitalization: widget.textCapitalization,
              maxLines: widget.obscureText ? 1 : widget.maxLines,
              autofocus: widget.autofocus,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.textTertiary,
                ),
                prefixIcon: widget.prefixIcon != null
                    ? Icon(
                        widget.prefixIcon,
                        color: _isFocused 
                            ? AppTheme.primary 
                            : AppTheme.textTertiary,
                        size: 20,
                      )
                    : null,
                suffixIcon: widget.obscureText
                    ? GestureDetector(
                        onTap: () => setState(() => _isObscured = !_isObscured),
                        child: Icon(
                          _isObscured 
                              ? Icons.visibility_outlined 
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textTertiary,
                          size: 20,
                        ),
                      )
                    : widget.suffixIcon != null
                        ? GestureDetector(
                            onTap: widget.onSuffixTap,
                            child: Icon(
                              widget.suffixIcon,
                              color: AppTheme.textTertiary,
                              size: 20,
                            ),
                          )
                        : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),
        
        // Error message
        if (hasError) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppTheme.error,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Campo de busca com visual premium
class SearchInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;

  const SearchInput({
    super.key,
    this.controller,
    this.hint = 'Buscar...',
    this.onChanged,
    this.onClear,
  });

  @override
  State<SearchInput> createState() => _SearchInputState();
}

class _SearchInputState extends State<SearchInput> {
  bool _hasText = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller?.text.isNotEmpty ?? false;
    widget.controller?.addListener(_updateHasText);
  }

  void _updateHasText() {
    final hasText = widget.controller?.text.isNotEmpty ?? false;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_updateHasText);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
        border: Border.all(
          color: _isFocused ? AppTheme.primary : AppTheme.surfaceHighlight,
          width: _isFocused ? 2 : 1,
        ),
        boxShadow: _isFocused ? [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: -4,
          ),
        ] : null,
      ),
      child: Focus(
        onFocusChange: (focused) {
          setState(() => _isFocused = focused);
        },
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textTertiary,
            ),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: _isFocused ? AppTheme.primary : AppTheme.textTertiary,
              size: 20,
            ),
            suffixIcon: _hasText
                ? GestureDetector(
                    onTap: () {
                      widget.controller?.clear();
                      widget.onClear?.call();
                    },
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppTheme.textTertiary,
                      size: 18,
                    ),
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ),
    );
  }
}
