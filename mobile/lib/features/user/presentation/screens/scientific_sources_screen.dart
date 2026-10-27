import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class ScientificSourcesScreen extends StatelessWidget {
  const ScientificSourcesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurfaceVariant),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Scientific Sources',
          style: GoogleFonts.playfairDisplay(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.secondary),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'PureScan AI aggregates safety data and ingredient risk assessments from leading global health and food safety authorities.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSourceCard(
              context, 'FDA',
              'U.S. Food and Drug Administration',
              'Provides foundational data on food additives, GRAS (Generally Recognized as Safe) notifications, and allergy regulations.',
              Icons.gavel,
            ),
            const SizedBox(height: 16),
            _buildSourceCard(
              context, 'EFSA',
              'European Food Safety Authority',
              'Offers rigorous scientific advice on food chain risks, often maintaining stricter additive regulations than other regions.',
              Icons.public,
            ),
            const SizedBox(height: 16),
            _buildSourceCard(
              context, 'WHO',
              'World Health Organization',
              'Global standards and dietary guidelines, including the Codex Alimentarius, which guides international food safety.',
              Icons.health_and_safety,
            ),
            const SizedBox(height: 16),
            _buildSourceCard(
              context, 'PubMed',
              'National Institutes of Health',
              'Peer-reviewed biomedical literature utilized by our AI to assess the latest clinical studies on artificial sweeteners and preservatives.',
              Icons.science,
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Data last updated: October 2023',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceCard(BuildContext context, String title, String subtitle, String description, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3).withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4332).withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              shape: BoxShape.circle,
              border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1)),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF012D1D),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: const Color(0xFF414844),
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
