import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/spacing.dart';
import '../core/theme/typography.dart';

class ZeroInput extends StatefulWidget {
  final String? hint;
  final bool obscureText;
  final TextEditingController? controller;
  final Widget? suffix;
  final VoidCallback? onSuffixTap;
  final int? maxLines;
  final TextInputType? keyboardType;

  const ZeroInput({
    super.key,
    this.hint,
    this.obscureText = false,
    this.controller,
    this.suffix,
    this.onSuffixTap,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  State<ZeroInput> createState() => _ZeroInputState();
}

class _ZeroInputState extends State<ZeroInput> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.zSurface,
        borderRadius: BorderRadius.circular(ZeroSpacing.inputRadius),
        border: Border.all(
          color: _isFocused
              ? context.zAccent.withOpacity(0.5)
              : context.zFrostWhiteStrong,
          width: 0.5,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: context.zAccentGlow,
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.symmetric(horizontal: ZeroSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              style: ZeroTypography.body(context).copyWith(
                color: context.zTextPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: ZeroTypography.body(context).copyWith(
                  color: context.zTextTertiary,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  vertical: widget.maxLines! > 1 ? ZeroSpacing.md : ZeroSpacing.lg - 4,
                ),
              ),
            ),
          ),
          if (widget.suffix != null)
            GestureDetector(
              onTap: widget.onSuffixTap,
              child: Padding(
                padding: const EdgeInsets.only(left: ZeroSpacing.sm),
                child: widget.suffix!,
              ),
            ),
        ],
      ),
    );
  }
}