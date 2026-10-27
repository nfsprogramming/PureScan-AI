// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

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
          'Help & Support',
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
            // Contact Options
            Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'CONTACT US',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3).withValues(alpha: 0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email_outlined, color: Theme.of(context).colorScheme.primary),
                    title: Text('Email Support', style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('aipurescan@gmail.com'),
                    trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                    onTap: () {
                      _launchEmail();
                    },
                  ),
                  Divider(height: 1, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1)),
                  ListTile(
                    leading: Icon(Icons.bug_report_outlined, color: Theme.of(context).colorScheme.primary),
                    title: Text('Report an Issue', style: TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('Found an inaccurate scan? Let us know.'),
                    trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                    onTap: () {
                      _launchEmail(subject: 'Issue Report: PureScan AI');
                    },
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // FAQ Section
            Padding(
              padding: EdgeInsets.only(left: 8, bottom: 12),
              child: Text(
                'FREQUENTLY ASKED QUESTIONS',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            
            _buildFaqItem(context, 'How accurate is the scanner?',
              'PureScan AI uses our advanced AI-powered OCR to extract text and matches it against our extensive database of ingredients derived from FDA and WHO sources. However, always verify packaging directly if you have a severe allergy.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(
              context, 'How do I add a new allergy?',
              'Navigate to your Profile tab, tap "My Health Profile", scroll to the Allergies section, and tap the "+" button to search and add a specific allergen.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(context, 'Are my scans private?',
              'Yes, all scan history is securely stored in your personal profile using Supabase encryption protocols. We do not sell your dietary data.',
            ),
            const SizedBox(height: 12),
            _buildFaqItem(context, 'What is a Trust Score?',
              'The Trust Score (0-100) is a quick indicator of a product\'s safety based on the ratio of natural ingredients versus highly processed additives and preservatives.',
            ),
            
            const SizedBox(height: 40),
            Center(
              child: Text(
                'App Version 1.0.0',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7).withValues(alpha: 0.8),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItem(BuildContext context, String question, String answer) {
    return Container(
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
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconColor: Theme.of(context).colorScheme.primary,
        collapsedIconColor: const Color(0xFF414844),
        shape: const RoundedRectangleBorder(side: BorderSide.none), // removes the border when expanded
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        children: [
          Text(
            answer,
            style: TextStyle(
              color: const Color(0xFF414844),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchEmail({String subject = 'Support Request'}) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'aipurescan@gmail.com',
      query: 'subject=${Uri.encodeComponent(subject)}', 
    );

    try {
      final success = await launchUrl(emailLaunchUri, mode: LaunchMode.externalApplication);
      if (!success) {
        debugPrint('Could not launch email client');
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
    }
  }
}
