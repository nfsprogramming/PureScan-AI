import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidGlassBackground extends StatefulWidget {
  final int currentIndex;
  final int tabCount;

  const LiquidGlassBackground({
    super.key,
    required this.currentIndex,
    required this.tabCount,
  });

  @override
  State<LiquidGlassBackground> createState() => _LiquidGlassBackgroundState();
}

class _LiquidGlassBackgroundState extends State<LiquidGlassBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousIndex = 0.0;
  double _targetIndex = 0.0;

  @override
  void initState() {
    super.initState();
    _targetIndex = widget.currentIndex.toDouble();
    _previousIndex = _targetIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: const SpringCurve(),
    );
  }

  @override
  void didUpdateWidget(LiquidGlassBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _previousIndex = _previousIndex + (_targetIndex - _previousIndex) * _controller.value;
      _targetIndex = widget.currentIndex.toDouble();
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tabWidth = constraints.maxWidth / widget.tabCount;
        
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final double t = _animation.value;
            final double distance = _targetIndex - _previousIndex; // Signed distance
            
            // Center interpolation
            final double currentCenterIndex = _previousIndex + (distance * t);
            final double currentCenterX = (currentCenterIndex * tabWidth) + (tabWidth / 2);
            
            // Morph/Stretch logic (stretches in the direction of movement)
            // Sine wave peaks at t=0.5
            final double stretchIntensity = math.sin(t * math.pi).clamp(0.0, 1.0);
            
            // 35% of tab width stretch per tab traveled (capped)
            final double extraWidth = stretchIntensity * math.min(distance.abs() * tabWidth * 0.35, tabWidth * 0.6);
            
            // Offset the center in the direction of travel to keep trailing edge mostly fixed and stretch leading edge
            final double stretchOffset = distance.sign * (extraWidth / 2);

            const double horizontalInset = 10.0;
            const double verticalInset = 2.0;

            final double baseWidth = tabWidth - (horizontalInset * 2);
            final double baseHeight = constraints.maxHeight - (verticalInset * 2);
            
            final double currentWidth = baseWidth + extraWidth;
            
            // Slightly reduce height when stretching to simulate constant volume
            final double heightReduction = stretchIntensity * distance.abs() * 0.05;
            final double currentHeight = baseHeight * (1.0 - heightReduction.clamp(0.0, 0.15));
            
            final double leftPos = currentCenterX + stretchOffset - (currentWidth / 2);
            final double topPos = (constraints.maxHeight - currentHeight) / 2;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: leftPos,
                  top: topPos,
                  width: currentWidth,
                  height: currentHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.5),
                              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
                              Colors.white.withValues(alpha: 0.2),
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.25),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class SpringCurve extends Curve {
  const SpringCurve();
  @override
  double transformInternal(double t) {
    // A soft spring curve with ~5-10% overshoot
    return 1.0 - math.pow(math.e, -7.0 * t) * math.cos(math.pi * 2.2 * t);
  }
}
