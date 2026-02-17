import 'package:flutter/material.dart';

/// Widget d'indicateur de validation pour les champs de formulaire
class FieldValidationIndicator extends StatelessWidget {
  final String? errorText;
  final bool isValid;
  final bool showValidIcon;
  final double size;

  const FieldValidationIndicator({
    super.key,
    this.errorText,
    required this.isValid,
    this.showValidIcon = true,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (errorText != null) {
      return Icon(
        Icons.error,
        color: Colors.red.shade600,
        size: size,
      );
    } else if (isValid && showValidIcon) {
      return Icon(
        Icons.check_circle,
        color: Colors.green.shade600,
        size: size,
      );
    }
    return const SizedBox.shrink();
  }
}

/// Widget de validation en temps réel pour les champs de texte
class RealTimeValidatedTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final int? maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final String? Function(String?) validator;
  final void Function(String)? onChanged;
  final bool isRequired;
  final bool enabled;

  const RealTimeValidatedTextField({
    super.key,
    required this.controller,
    required this.validator,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.onChanged,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  State<RealTimeValidatedTextField> createState() => _RealTimeValidatedTextFieldState();
}

class _RealTimeValidatedTextFieldState extends State<RealTimeValidatedTextField> {
  String? _errorText;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_validateField);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_validateField);
    super.dispose();
  }

  void _validateField() {
    if (!_hasInteracted) return;

    final error = widget.validator(widget.controller.text);
    if (_errorText != error) {
      setState(() {
        _errorText = error;
      });
    }
  }

  void _markInteraction() {
    if (!_hasInteracted) {
      setState(() {
        _hasInteracted = true;
      });
      _validateField();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isValid = _hasInteracted && _errorText == null && widget.controller.text.isNotEmpty;

    return TextFormField(
      controller: widget.controller,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      keyboardType: widget.keyboardType,
      decoration: InputDecoration(
        labelText: widget.labelText != null ? '${widget.labelText}${widget.isRequired ? ' *' : ''}' : null,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null ? Icon(widget.prefixIcon) : null,
        suffixIcon: _hasInteracted
            ? FieldValidationIndicator(
                errorText: _errorText,
                isValid: isValid,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: widget.enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        errorText: _errorText,
        counterText: widget.maxLength != null ? '${widget.controller.text.length}/${widget.maxLength}' : null,
      ),
      validator: (_) => _errorText,
      onChanged: (value) {
        _markInteraction();
        widget.onChanged?.call(value);
      },
      onTap: _markInteraction,
    );
  }
}

/// Widget de validation pour les sélecteurs (dropdown, etc.)
class ValidationWrapper extends StatelessWidget {
  final Widget child;
  final String? errorText;
  final bool isValid;
  final bool hasInteracted;

  const ValidationWrapper({
    super.key,
    required this.child,
    this.errorText,
    required this.isValid,
    required this.hasInteracted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            child,
            if (hasInteracted)
              Positioned(
                right: 12,
                top: 12,
                child: FieldValidationIndicator(
                  errorText: errorText,
                  isValid: isValid,
                ),
              ),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              errorText!,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
