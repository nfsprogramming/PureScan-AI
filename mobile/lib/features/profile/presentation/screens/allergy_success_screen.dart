import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AllergySuccessScreen extends StatefulWidget {
  final String addedAllergy;

  const AllergySuccessScreen({super.key, required this.addedAllergy});

  @override
  State<AllergySuccessScreen> createState() => _AllergySuccessScreenState();
}

class _AllergySuccessScreenState extends State<AllergySuccessScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _bounceAnimation = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeInOutSine),
      ),
    );

    // Make the checkmark bounce up and down infinitely after popping in
    _controller.forward().then((_) {
      _controller.repeat(reverse: true, min: 0.5, max: 1.0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: () => context.pop(),
                  ),
                  Text(
                    'PureScan AI',
                    style: GoogleFonts.playfairDisplay(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated Checkmark Icon
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Glow effect
                                Container(
                                  width: 140,
                                  height: 140,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: const Color(0xFFC0EDD0).withValues(alpha: 0.3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFC0EDD0).withValues(alpha: 0.5),
                                        blurRadius: 20,
                                        spreadRadius: 10,
                                      )
                                    ],
                                  ),
                                ),
                                // Main circle
                                Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFC0EDD0),
                                    border: Border.all(color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.04),
                                        blurRadius: 30,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.check_circle,
                                    size: 56,
                                    color: Color(0xFF002112),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      '${widget.addedAllergy} Added',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      '${widget.addedAllergy} has been successfully added to your profile.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Future scan results will now automatically flag this allergen to ensure your dietary safety.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Buttons
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.onSurface,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 4,
                      ),
                      onPressed: () {
                        // Pop success screen
                        context.pop();
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('View Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 20),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.onSurface,
                        side: BorderSide(color: Colors.grey.shade300, width: 2),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        context.pushReplacement('/add_allergy');
                      },
                      child: const Text('Add Another', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
