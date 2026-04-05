import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Smoothly interpolates numeric price changes using [TweenAnimationBuilder].
class AnimatedPriceDisplay extends StatefulWidget {
  const AnimatedPriceDisplay({
    super.key,
    required this.price,
    this.style,
  });

  final double price;
  final TextStyle? style;

  @override
  State<AnimatedPriceDisplay> createState() => _AnimatedPriceDisplayState();
}

class _AnimatedPriceDisplayState extends State<AnimatedPriceDisplay> {
  late double _from;
  late double _to;

  static final _fmt = NumberFormat.currency(locale: 'en_US', symbol: '\$');

  @override
  void initState() {
    super.initState();
    _from = widget.price;
    _to = widget.price;
  }

  @override
  void didUpdateWidget(covariant AnimatedPriceDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.price != widget.price) {
      _from = _to;
      _to = widget.price;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey<double>(_to),
      tween: Tween<double>(begin: _from, end: _to),
      duration: const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Text(
          _fmt.format(value),
          style: widget.style,
        );
      },
    );
  }
}
