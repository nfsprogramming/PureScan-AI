

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/legal_widgets.dart'; // I will create this

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.onSurface,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const LegalParagraph('Effective Date: August 2026\n\nPureScan AI helps users understand food product labels and ingredients using scanning, databases, and AI-powered analysis.'),
            
            const LegalSectionTitle('1. Information We Collect'),
            const LegalParagraph('We may collect the following information:'),
            const LegalBulletList([
              'Account information',
              'Profile information',
              'Dietary preferences',
              'Allergy preferences',
              'Product scans',
              'Scan history',
              'Images submitted for scanning',
              'App usage information',
              'Device/technical information where applicable',
            ]),

            const LegalSectionTitle('2. How We Use Information'),
            const LegalParagraph('The collected information is used to:'),
            const LegalBulletList([
              'Process food label scans',
              'Generate ingredient analysis',
              'Personalize results',
              'Maintain scan history',
              'Improve the application',
              'Provide community features',
              'Maintain application security',
            ]),

            const LegalSectionTitle('3. Camera and Images'),
            const LegalParagraph('Camera and image access is required to capture food labels for analysis. Images may be processed for Optical Character Recognition (OCR) and ingredient extraction. Images are processed ephemerally and are not permanently stored on our servers unless explicitly submitted for community features.'),

            const LegalSectionTitle('4. AI Processing'),
            const LegalParagraph('PureScan AI uses Artificial Intelligence (AI) to interpret ingredient information and generate health explanations. Please be aware that AI-generated information may contain errors, and you should always verify the information.'),

            const LegalSectionTitle('5. Health Information'),
            const LegalParagraph('We treat your dietary preferences, allergies, and health-related preferences with care. PureScan AI is strictly an informational tool and is not a medical diagnosis, treatment service, or professional dietitian service.'),

            const LegalSectionTitle('6. Data Storage'),
            const LegalParagraph('Data is stored securely using Supabase cloud infrastructure. We implement standard security practices to protect your data.'),

            const LegalSectionTitle('7. Third-Party Services'),
            const LegalParagraph('We utilize the following third-party services to provide our features:'),
            const LegalBulletList([
              'Supabase (Authentication and Database)',
              'Open Food Facts (Product Database)',
              'NVIDIA AI APIs (Ingredient Analysis)',
            ]),

            const LegalSectionTitle('8. Data Sharing'),
            const LegalParagraph('Data is only shared with third-party services when strictly necessary to provide the core functionality of the application (such as sending extracted text to an AI provider for analysis).'),

            const LegalSectionTitle('9. Data Retention'),
            const LegalParagraph('Your data is retained for as long as your account is active to provide you with your scan history and personalized preferences. You may request deletion at any time.'),

            const LegalSectionTitle('10. User Rights'),
            const LegalParagraph('You have the right to:'),
            const LegalBulletList([
              'View your data',
              'Update your data',
              'Delete your account and associated data',
            ]),

            const LegalSectionTitle('11. Children\'s Privacy'),
            const LegalParagraph('PureScan AI is not intended for use by children under the age of 13. We do not knowingly collect personal information from children.'),

            const LegalSectionTitle('12. Changes to Privacy Policy'),
            const LegalParagraph('We may update our Privacy Policy from time to time. Any changes will be reflected in this application, and we encourage you to review this page periodically.'),

            const LegalSectionTitle('13. Contact'),
            const LegalParagraph('If you have questions about this Privacy Policy, please contact us through the Help & Support section within the application.'),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
