import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyzingLoadingView extends StatefulWidget {
  final double progress;
  
  const AnalyzingLoadingView({
    super.key,
    required this.progress,
  });

  @override
  State<AnalyzingLoadingView> createState() => _AnalyzingLoadingViewState();
}

class _AnalyzingLoadingViewState extends State<AnalyzingLoadingView>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;
  late AnimationController _floatController;

  late Timer _statusTimer;

  int _currentStatusIndex = 0;

  final List<String> _statuses = [
    "Scanning ingredient labels...",
    "Cross-referencing FSSAI standards...",
    "Identifying chemical additives...",
    "Calculating safety scores...",
    "Fetching nutritional data...",
    "Finalizing AI summary..."
  ];

  @override
  void initState() {
    super.initState();

    // Pulse Animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Scan Line Animation
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Float Animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Text Cycling
    _statusTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted) {
        setState(() {
          _currentStatusIndex = (_currentStatusIndex + 1) % _statuses.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _floatController.dispose();
    _statusTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      width: double.infinity,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Visual Anchor
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse Rings
                _buildPulseRing(0.0),
                _buildPulseRing(0.3),
                _buildPulseRing(0.6),

                // Core Icon Container
                Container(
                  width: 128,
                  height: 176,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3F6653).withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                    border: Border.all(
                      color: const Color(0xFF3F6653).withValues(alpha: 0.1),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Simulated Document Content
                      Padding(
                        padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1E3E4).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 96,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1E3E4).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 64,
                              height: 8,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE1E3E4).withValues(alpha: 0.4),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Floating Molecule
                      Align(
                        alignment: Alignment.center,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: AnimatedBuilder(
                            animation: _floatController,
                            builder: (context, child) {
                              final value = sin(_floatController.value * 2 * pi);
                              return Transform.translate(
                                offset: Offset(0, value * -10),
                                child: Transform.rotate(
                                  angle: value * (5 * pi / 180),
                                  child: Icon(
                                    Icons.science,
                                    size: 64,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      // Scan Line
                      AnimatedBuilder(
                        animation: _scanController,
                        builder: (context, child) {
                          return Positioned(
                            top: _scanController.value * 176,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: 2,
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Color(0xFF3F6653),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Typography
          Text(
            'Analyzing Ingredients...',
            style: GoogleFonts.playfairDisplay(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          const SizedBox(height: 8),

          // Status Text
          SizedBox(
            height: 24,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                _statuses[_currentStatusIndex].toUpperCase(),
                key: ValueKey<int>(_currentStatusIndex),
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Progress Indicator
          Container(
            width: 200,
            height: 6,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  curve: Curves.easeOut,
                  width: 200 * widget.progress,
                  decoration: BoxDecoration(
                    color: const Color(0xFFA4D1B4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Security Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Encrypted AI Analysis',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF426B54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPulseRing(double delay) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        var value = (_pulseController.value + delay) % 1.0;
        
        // Scale from 0.8 to 1.4
        final scale = 0.8 + (value * 0.6);
        // Opacity from 0.5 to 0
        final opacity = 0.5 * (1.0 - value);

        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF3F6653),
                  width: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
