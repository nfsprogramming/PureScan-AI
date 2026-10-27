

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../widgets/legal_widgets.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Terms of Service',
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
            const LegalParagraph('Effective Date: August 2026'),
            
            const LegalSectionTitle('1. Acceptance of Terms'),
            const LegalParagraph('By accessing or using PureScan AI, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the application.'),

            const LegalSectionTitle('2. Description of PureScan AI'),
            const LegalParagraph('PureScan AI is a mobile application designed to help users understand food product labels and ingredients. It utilizes Optical Character Recognition (OCR), databases, and Artificial Intelligence to provide an informational analysis.'),

            const LegalSectionTitle('3. Eligibility'),
            const LegalParagraph('You must be at least 13 years old to use PureScan AI. By using the app, you represent that you meet this age requirement.'),

            const LegalSectionTitle('4. User Accounts'),
            const LegalParagraph('To access certain features, you may need to create an account. You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.'),

            const LegalSectionTitle('5. Acceptable Use'),
            const LegalParagraph('You agree not to misuse the application. You must not:'),
            const LegalBulletList([
              'Violate any applicable laws',
              'Attempt to gain unauthorized access to our systems',
              'Submit false, misleading, or malicious product information',
              'Scrape or extract data automatically from the service',
            ]),

            const LegalSectionTitle('6. Food and Ingredient Information'),
            const LegalParagraph('PureScan AI provides informational food-label and ingredient analysis. It is NOT:\n\n• A doctor\n• A dietitian\n• A medical diagnosis system\n• A replacement for professional medical advice\n\nAI-generated scores, classifications, recommendations, and explanations are informational only. Users should consult qualified professionals for medical, allergy, dietary, or health decisions.'),

            const LegalSectionTitle('7. Accuracy Disclaimer'),
            const LegalParagraph('While we strive for accuracy, please be aware that:'),
            const LegalBulletList([
              'OCR technology can make mistakes reading labels',
              'Product formulas and labels can change without notice',
              'Ingredient databases can contain outdated information',
              'AI can make mistakes or misinterpret data',
            ]),
            const LegalParagraph('Product information should ALWAYS be verified against the actual physical packaging before consumption, especially if you have severe allergies.'),

            const LegalSectionTitle('8. Trust Score Disclaimer'),
            const LegalParagraph('The Trust Score is an analytical indicator created by PureScan AI based on available ingredient and nutritional data. It should NOT be represented as an official government health certification. We do not guarantee that any product is "100% safe" or "Guaranteed healthy".'),

            const LegalSectionTitle('9. Community Content'),
            const LegalParagraph('PureScan AI includes user-submitted product information and community reviews. We do not endorse and are not responsible for the accuracy of community-submitted content.'),

            const LegalSectionTitle('10. Intellectual Property'),
            const LegalParagraph('The PureScan AI application, including its original content, features, and functionality, are owned by us and are protected by international copyright, trademark, and other intellectual property laws.'),

            const LegalSectionTitle('11. Third-Party Services'),
            const LegalParagraph('Our Service may contain links to third-party web sites or services that are not owned or controlled by PureScan AI. We have no control over and assume no responsibility for the content or practices of any third-party services.'),

            const LegalSectionTitle('12. Account Termination'),
            const LegalParagraph('We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.'),

            const LegalSectionTitle('13. Limitation of Liability'),
            const LegalParagraph('In no event shall PureScan AI, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages resulting from your use of the service or reliance on any information provided.'),

            const LegalSectionTitle('14. Changes to Terms'),
            const LegalParagraph('We reserve the right to modify or replace these Terms at any time. What constitutes a material change will be determined at our sole discretion.'),

            const LegalSectionTitle('15. Contact Information'),
            const LegalParagraph('If you have any questions about these Terms, please contact us via the Help & Support section in the application.'),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
