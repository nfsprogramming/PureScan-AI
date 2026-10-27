import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_provider.dart';

class ThemeScreen extends ConsumerWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Appearance', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Select your perfect vibe.',
            style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          _buildThemeCard(
            context,
            ref,
            themeData: AppThemeData.serene,
            isActive: currentTheme.id == AppTheme.serene,
          ),
          const SizedBox(height: 16),
          _buildThemeCard(
            context,
            ref,
            themeData: AppThemeData.ocean,
            isActive: currentTheme.id == AppTheme.ocean,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref, {required AppThemeData themeData, required bool isActive}) {
    return GestureDetector(
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(themeData.id);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: themeData.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive ? themeData.primary : Colors.grey.withValues(alpha: 0.2),
            width: isActive ? 2 : 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: themeData.primary.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.palette_outlined, color: themeData.primary),
                    const SizedBox(width: 8),
                    Text(
                      themeData.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: themeData.primary,
                      ),
                    ),
                  ],
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: themeData.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.check, color: Theme.of(context).colorScheme.surface, size: 14),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildSwatchItem(themeData.primary, 'Primary')),
                const SizedBox(width: 12),
                Expanded(child: _buildSwatchItem(themeData.secondary, 'Accent')),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildSwatchItem(themeData.textSecondary, 'Neutral')),
                const SizedBox(width: 12),
                Expanded(child: _buildSwatchItem(themeData.background, 'Base', hasBorder: true)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwatchItem(Color color, String label, {bool hasBorder = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: hasBorder ? Border.all(color: Colors.grey.withValues(alpha: 0.2)) : null,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
        ),
      ],
    );
  }
}
