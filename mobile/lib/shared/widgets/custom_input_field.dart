import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:velocity_x/velocity_x.dart';
import 'package:collegebus/core/constants/constants.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool enabled;
  final int maxLines;
  final VoidCallback? onTap;
  final bool readOnly;

  const CustomInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.enabled = true,
    this.maxLines = 1,
    this.onTap,
    this.readOnly = false,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField>
    with TickerProviderStateMixin {
  bool _obscureText = true;
  late FocusNode _focusNode;
  late AnimationController _focusController;
  late AnimationController _shakeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shakeAnimation;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(
        parent: _focusController,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0), // spring overshoot curve
      ),
    );

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 8.0), weight: 10),
      TweenSequenceItem(tween: Tween<double>(begin: 8.0, end: -6.0), weight: 15),
      TweenSequenceItem(tween: Tween<double>(begin: -6.0, end: 4.0), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 4.0, end: -2.0), weight: 25),
      TweenSequenceItem(tween: Tween<double>(begin: -2.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _focusController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VStack([
      if (widget.label.isNotEmpty)
        VStack([
          widget.label.text
              .size(16)
              .medium
              .color(Theme.of(context).colorScheme.onSurface)
              .make(),
          AppSizes.paddingSmall.heightBox,
        ]),
      AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _shakeAnimation]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: TextFormField(
          focusNode: _focusNode,
          controller: widget.controller,
          obscureText: widget.isPassword ? _obscureText : false,
          keyboardType: widget.keyboardType,
          validator: (val) {
            final err = widget.validator?.call(val);
            if (err != _errorText) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _errorText = err;
                  });
                  if (err != null) {
                    _shakeController.forward(from: 0.0);
                    HapticFeedback.mediumImpact();
                  }
                }
              });
            }
            return err;
          },
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          onTap: widget.onTap,
          readOnly: widget.readOnly,
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
            prefixIcon: widget.prefixIcon,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.suffixIcon,
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            border: _buildBorder(context),
            enabledBorder: _buildBorder(
              context,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            focusedBorder: _buildBorder(
              context,
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
            errorBorder: _buildBorder(
              context,
              color: Theme.of(context).colorScheme.error,
            ),
            focusedErrorBorder: _buildBorder(
              context,
              color: Theme.of(context).colorScheme.error,
              width: 1.5,
            ),
            errorStyle: const TextStyle(height: 0, fontSize: 0),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMedium,
              vertical: AppSizes.paddingMedium,
            ),
          ),
        ),
      ),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        child: _errorText != null
            ? Container(
                padding: const EdgeInsets.only(top: 6, left: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 14,
                    ),
                    6.widthBox,
                    Expanded(
                      child: _errorText!.text
                          .size(12)
                          .medium
                          .color(Theme.of(context).colorScheme.error)
                          .make(),
                    ),
                  ],
                ),
              )
            : const SizedBox.shrink(),
      ),
    ]);
  }

  OutlineInputBorder _buildBorder(
    BuildContext context, {
    Color? color,
    double width = 1,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color:
            color ??
            Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        width: width,
      ),
    );
  }
}
