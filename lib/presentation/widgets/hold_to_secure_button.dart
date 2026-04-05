import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Hold-to-confirm control: idle → 2s ring → verifying spinner → success.
class HoldToSecureButton extends StatefulWidget {
  const HoldToSecureButton({
    super.key,
    required this.onVerified,
    this.holdDuration = const Duration(seconds: 2),
    this.verifyingDuration = const Duration(milliseconds: 1600),
  });

  final Future<void> Function() onVerified;
  final Duration holdDuration;
  final Duration verifyingDuration;

  @override
  State<HoldToSecureButton> createState() => _HoldToSecureButtonState();
}

enum _HoldPhase { idle, holding, verifying, success }

class _HoldToSecureButtonState extends State<HoldToSecureButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _holdController;
  _HoldPhase _phase = _HoldPhase.idle;
  bool _pointerDown = false;

  @override
  void initState() {
    super.initState();
    _holdController = AnimationController(
      vsync: this,
      duration: widget.holdDuration,
    )..addStatusListener(_onHoldStatus);
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _pointerDown && _phase == _HoldPhase.holding) {
      setState(() => _phase = _HoldPhase.verifying);
      _holdController.stop();
      _holdController.value = 1;
      _runVerify();
    }
  }

  Future<void> _runVerify() async {
    await Future<void>.delayed(widget.verifyingDuration);
    if (!mounted || _phase != _HoldPhase.verifying) {
      return;
    }
    await widget.onVerified();
    if (!mounted) {
      return;
    }
    setState(() => _phase = _HoldPhase.success);
  }

  @override
  void dispose() {
    _holdController.removeStatusListener(_onHoldStatus);
    _holdController.dispose();
    super.dispose();
  }

  void _onDown() {
    if (_phase == _HoldPhase.verifying || _phase == _HoldPhase.success) {
      return;
    }
    setState(() {
      _pointerDown = true;
      _phase = _HoldPhase.holding;
    });
    _holdController.duration = widget.holdDuration;
    _holdController.forward(from: 0);
  }

  void _onUpOrCancel() {
    if (_phase == _HoldPhase.verifying || _phase == _HoldPhase.success) {
      return;
    }
    _pointerDown = false;
    if (_phase == _HoldPhase.holding) {
      if (_holdController.status != AnimationStatus.completed) {
        _holdController.stop();
        SchedulerBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          _holdController.duration = const Duration(milliseconds: 280);
          _holdController.reverse(from: _holdController.value).whenComplete(() {
            if (!mounted) {
              return;
            }
            setState(() => _phase = _HoldPhase.idle);
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Listener(
      onPointerDown: (_) => _onDown(),
      onPointerUp: (_) => _onUpOrCancel(),
      onPointerCancel: (_) => _onUpOrCancel(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            if (_phase == _HoldPhase.idle || _phase == _HoldPhase.holding)
              BoxShadow(
                color: const Color(0xFFC9A962).withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
          ],
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1B1B1F),
              const Color(0xFF121214),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_phase == _HoldPhase.holding)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _holdController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ProgressRingPainter(
                        progress: _holdController.value,
                        color: const Color(0xFFC9A962),
                      ),
                    );
                  },
                ),
              ),
            _buildContent(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    switch (_phase) {
      case _HoldPhase.idle:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fingerprint_rounded, color: Colors.white.withValues(alpha: 0.92), size: 22),
              const SizedBox(width: 10),
              Text(
                'Hold to Secure',
                style: theme.textTheme.titleMedium?.copyWith(
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        );
      case _HoldPhase.holding:
        return Text(
          'Keep holding…',
          style: theme.textTheme.titleMedium?.copyWith(
            letterSpacing: 0.4,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.92),
          ),
        );
      case _HoldPhase.verifying:
        return SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            valueColor: AlwaysStoppedAnimation<Color>(
              const Color(0xFFC9A962).withValues(alpha: 0.95),
            ),
          ),
        );
      case _HoldPhase.success:
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_rounded, color: const Color(0xFF2EE59D), size: 28),
            const SizedBox(width: 8),
            Text(
              'Secured',
              style: theme.textTheme.titleMedium?.copyWith(
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2EE59D),
              ),
            ),
          ],
        );
    }
  }
}

class _ProgressRingPainter extends CustomPainter {
  _ProgressRingPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = 3.0;
    final rect = Rect.fromLTWH(
      stroke / 2,
      stroke / 2,
      size.width - stroke,
      size.height - stroke,
    );
    final r = RRect.fromRectAndRadius(rect, const Radius.circular(12));

    final bg = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawRRect(r, bg);

    if (progress <= 0) {
      return;
    }

    final path = Path()..addRRect(r);
    PathMetric? metric;
    for (final m in path.computeMetrics()) {
      metric = m;
      break;
    }
    if (metric == null) {
      return;
    }
    final len = metric.length * progress;

    final fg = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(metric.extractPath(0, len), fg);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
