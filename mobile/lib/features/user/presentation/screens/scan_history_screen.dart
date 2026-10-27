// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/user_repository.dart';
import 'package:mobile/features/scanner/data/models/trust_score_report.dart';

class ScanHistoryScreen extends ConsumerStatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  ConsumerState<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends ConsumerState<ScanHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final scanHistoryAsync = ref.watch(scanHistoryProvider);
    final List<Map<String, dynamic>> scanHistory = scanHistoryAsync.value ?? [];
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
          'Scan History',
          style: GoogleFonts.playfairDisplay(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: const Color(0xFFE5E7EB),
            height: 1.0,
          ),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2E8B57),
        onRefresh: () async {
          ref.invalidate(scanHistoryProvider);
          await ref.read(scanHistoryProvider.future);
        },
        child: scanHistoryAsync.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57)))
          : scanHistory.isEmpty
              ? ListView(
                  // Must be scrollable for RefreshIndicator to work on empty state
                  children: [_buildEmptyState()],
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  itemCount: scanHistory.length,
                  itemBuilder: (context, index) {
                    final scan = scanHistory[index];
                    final report = scan['report_json'] as Map<String, dynamic>? ?? {};
                    final score = report['final_score'] as int? ?? 0;
                    final rating = report['rating'] as String? ?? 'Unknown';
                    final productName = scan['product_name'] as String? ?? 'Scanned Item';
                    // We can also extract the date from created_at
                    final createdAt = scan['created_at'] as String? ?? '';
                    final dateLabel = createdAt.isNotEmpty && createdAt.length >= 10 
                        ? createdAt.substring(0, 10) 
                        : 'Recent';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: () {
                          Map<String, dynamic>? parsedData;
                          if (scan['ingredients'] != null && scan['ingredients']['parsed_json'] != null) {
                            parsedData = scan['ingredients']['parsed_json'] is String 
                                ? jsonDecode(scan['ingredients']['parsed_json']) 
                                : scan['ingredients']['parsed_json'];
                          } else {
                            parsedData = scan['report_json']?['parsed_data'];
                          }
                          
                          // Because scan_history's report_json IS the TrustScoreReport,
                          // trustScore is just scan['report_json'] itself, unless it was deeply nested.
                          final trustScore = scan['report_json'];
                          
                          final response = ScanResponse(
                            message: 'History Scan',
                            parsedData: parsedData != null ? ParsedIngredients.fromJson(parsedData) : ParsedIngredients(
                              naturalIngredients: [], wholeFoodIngredients: [], additives: [], artificialColors: [], artificialSweeteners: [], preservatives: [], highRiskIngredients: [], productClaims: [], sugarLevel: 'Unknown', sodiumLevel: 'Unknown', proteinLevel: 'Unknown',
                            ),
                            trustScoreReport: trustScore != null ? TrustScoreReport.fromJson(trustScore) : TrustScoreReport(
                              finalScore: score, rating: rating, description: 'Details missing from old scan', ingredientQualityScore: 0, nutritionScore: 0, riskPenalty: 0, additivesScore: 0, transparencyScore: 0, flaggedIssues: [], alternativeProducts: [],
                            ),
                          );
                          
                          context.push('/result', extra: response);
                        },
                        child: _buildScanCard(productName, dateLabel, score, rating),
                      ),
                    );
                  },
              ),
        ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No scan history yet',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your previous scans will appear here.',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard(String name, String time, int score, String status) {
    Color statusColor;
    if (score >= 80) {
      statusColor = const Color(0xFF2E8B57); // Green
    } else if (score >= 60) {
      statusColor = const Color(0xFF86AF99); // Light Green
    } else if (score >= 40) {
      statusColor = const Color(0xFFEAB308); // Yellow
    } else {
      statusColor = const Color(0xFFEF4444); // Red
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.image_outlined, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score/100',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: statusColor,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
