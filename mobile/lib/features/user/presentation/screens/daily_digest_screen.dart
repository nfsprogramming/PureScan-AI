import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/user_repository.dart';

class DailyDigestScreen extends ConsumerWidget {
  const DailyDigestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanHistoryAsync = ref.watch(scanHistoryProvider);
    final List<Map<String, dynamic>> allScans = scanHistoryAsync.value ?? [];
    
    // Filter today's scans
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    final todayScans = allScans.where((scan) {
      final createdAt = scan['created_at'] as String? ?? '';
      if (createdAt.isEmpty) return false;
      try {
        final date = DateTime.parse(createdAt).toLocal();
        return date.isAfter(startOfDay);
      } catch (e) {
        return false;
      }
    }).toList();

    int safeScans = 0;
    int warningScans = 0;
    int criticalScans = 0;
    Set<String> allergensDetected = {};
    
    for (var scan in todayScans) {
      final report = scan['report_json'] as Map<String, dynamic>? ?? {};
      final score = report['final_score'] as int? ?? 0;
      final flaggedIssues = List<String>.from(report['flagged_issues'] ?? []);
      
      if (score >= 80) {
        safeScans++;
      } else if (score >= 40) {
        warningScans++;
      } else {
        criticalScans++;
      }

      for (var issue in flaggedIssues) {
        if (issue.toLowerCase().contains('allergen')) {
          allergensDetected.add(issue);
        }
      }
    }

    final totalScans = todayScans.length;
    final compliancePercentage = totalScans == 0 ? 100 : ((safeScans / totalScans) * 100).round();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Daily Health Summary',
          style: GoogleFonts.playfairDisplay(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: scanHistoryAsync.isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today, ${now.month}/${now.day}/${now.year}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Summary Cards
                Row(
                  children: [
                    Expanded(child: _buildMetricCard(context, 'Scanned', totalScans.toString(), Icons.qr_code_scanner, const Color(0xFF6B7280))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricCard(context, 'Safe', safeScans.toString(), Icons.check_circle, const Color(0xFF2E8B57))),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMetricCard(context, 'Warnings', warningScans.toString(), Icons.warning_amber, const Color(0xFFEAB308))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildMetricCard(context, 'Critical', criticalScans.toString(), Icons.error_outline, const Color(0xFFEF4444))),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Compliance Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        '$compliancePercentage%',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: compliancePercentage >= 80 ? const Color(0xFF2E8B57) : (compliancePercentage >= 50 ? const Color(0xFFEAB308) : const Color(0xFFEF4444)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Dietary Compliance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Findings
                Text(
                  'Important Findings',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                if (allergensDetected.isEmpty && warningScans == 0 && criticalScans == 0)
                  const Text('No critical warnings or allergens detected today. Great job!', style: TextStyle(color: Color(0xFF2E8B57)))
                else ...[
                  ...allergensDetected.map((allergen) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(allergen, style: const TextStyle(fontWeight: FontWeight.w500))),
                      ],
                    ),
                  )),
                  if (criticalScans > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('$criticalScans high-risk product(s) detected.', style: const TextStyle(fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  if (warningScans > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, color: Color(0xFFEAB308), size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text('$warningScans product(s) with moderate warnings detected.', style: const TextStyle(fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                ],
                
                const SizedBox(height: 32),
                
                // Insights
                Text(
                  "Today's Insight",
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, color: Color(0xFFEAB308)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          compliancePercentage >= 80 
                              ? "Excellent work today! Most of your scans matched your dietary preferences. Keep it up." 
                              : "You scanned a few items that flagged warnings today. Remember to double-check labels for hidden ingredients before consuming.",
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMetricCard(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
