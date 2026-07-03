import 'package:flutter/material.dart';

/// Карточка в стиле мини-аппа (фиолетовая обводка).
class GpnCard extends StatelessWidget {
  const GpnCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFF1A0B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x668B5CF6)),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}
