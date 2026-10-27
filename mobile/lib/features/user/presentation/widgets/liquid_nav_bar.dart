import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class LiquidNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const LiquidNavBar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const double horizontalMargin = 20.0;
    const double barHeight = 72.0;
    // Calculate the width of the navigation bar itself
    final double navBarWidth = screenWidth - (horizontalMargin * 2);
    // Width of each tab item
    final double tabWidth = navBarWidth / 4;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(horizontalMargin, 0, horizontalMargin, 16),
        child: Container(
          height: barHeight,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light 
                ? Colors.white.withValues(alpha: 0.9)
                : Colors.black.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                blurRadius: 32,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Stack(
                children: [
                  // The liquid glass morphing pill
                  _LiquidMorphPill(
                    selectedIndex: selectedIndex,
                    tabWidth: tabWidth,
                  ),
                  // The navigation items
                  Row(
                    children: [
                      _buildNavItem(context, 0, Icons.home_outlined, Icons.home, 'Home', tabWidth),
                      _buildNavItem(context, 1, Icons.history_outlined, Icons.history, 'History', tabWidth),
                      _buildNavItem(context, 2, Icons.document_scanner_outlined, Icons.document_scanner, 'Scan', tabWidth),
                      _buildNavItem(context, 3, Icons.person_outline, Icons.person, 'Profile', tabWidth),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData inactiveIcon, IconData activeIcon, String label, double width) {
    final bool isActive = selectedIndex == index;
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onItemSelected(index),
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isActive ? 1.06 : 0.95,
              duration: const Duration(milliseconds: 450),
              curve: _LiquidMorphPill.softSpring,
              child: Icon(
                isActive ? activeIcon : inactiveIcon,
                color: isActive 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOut,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                color: isActive 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily ?? 'Inter',
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiquidMorphPill extends StatefulWidget {
  final int selectedIndex;
  final double tabWidth;
  
  static const Curve softSpring = Cubic(0.34, 1.3, 0.64, 1.0);

  const _LiquidMorphPill({
    required this.selectedIndex,
    required this.tabWidth,
  });

  @override
  State<_LiquidMorphPill> createState() => _LiquidMorphPillState();
}

class _LiquidMorphPillState extends State<_LiquidMorphPill> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _oldIndex = 0;
  int _newIndex = 0;

  @override
  void initState() {
    super.initState();
    _oldIndex = widget.selectedIndex;
    _newIndex = widget.selectedIndex;
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
    _animation = Tween<double>(begin: _oldIndex.toDouble(), end: _newIndex.toDouble())
        .animate(CurvedAnimation(parent: _controller, curve: _LiquidMorphPill.softSpring));
  }

  @override
  void didUpdateWidget(_LiquidMorphPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _oldIndex = _animation.value.round(); 
      _newIndex = widget.selectedIndex;
      
      _animation = Tween<double>(begin: _animation.value, end: _newIndex.toDouble())
          .animate(CurvedAnimation(parent: _controller, curve: _LiquidMorphPill.softSpring));
      
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentValue = _animation.value;
        final t = _controller.value;
        final distance = (_newIndex - _oldIndex).abs().toDouble();
        
        // Dynamic stretch based on distance
        final stretchMax = distance * 18.0; 
        final stretch = math.sin(t * math.pi) * stretchMax;

        final center = (currentValue + 0.5) * widget.tabWidth;
        final currentWidth = widget.tabWidth + stretch;
        final left = center - (currentWidth / 2);

        // Vertical compression
        final verticalInset = 8.0 + (stretch * 0.12);

        return Positioned(
          left: left,
          top: verticalInset,
          bottom: verticalInset,
          child: Container(
            width: currentWidth,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Theme.of(context).brightness == Brightness.light
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.white.withValues(alpha: 0.1),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
