import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/privacy_provider.dart';

class SensitiveText extends ConsumerWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int maxLines;
  final TextOverflow? overflow;
  final String mask;

  const SensitiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines = 1,
    this.overflow,
    this.mask = '****',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHidden = ref.watch(
      privacyProvider.select((s) => s.isBalanceHidden),
    );

    return Text(
      isHidden ? mask : text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}
