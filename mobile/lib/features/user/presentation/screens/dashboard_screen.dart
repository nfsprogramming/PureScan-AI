// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/user_repository.dart';
import 'package:mobile/features/scanner/data/models/trust_score_report.dart';
import 'package:mobile/features/user/presentation/screens/main_layout_screen.dart';
import 'package:mobile/features/user/presentation/providers/local_avatar_provider.dart';
import 'dart:io';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isProfileLoading = true;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final repo = ref.read(userRepositoryProvider);
    
    // Load profile separately so the icon shows up instantly
    repo.fetchProfile().then((profile) {
      if (mounted && profile != null) {
        setState(() {
          _profileImageUrl = profile['profile_image'];
          _isProfileLoading = false;
        });
      }
    }).catchError((_) {
      if (mounted) {
        setState(() {
          _isProfileLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scanHistoryAsync = ref.watch(scanHistoryProvider);
    final List<Map<String, dynamic>> scanHistory = scanHistoryAsync.value ?? [];
    
    // Determine Dashboard Insights based on ACTUAL scan history
    final hasScans = scanHistory.isNotEmpty;
    final latestScanScore = hasScans ? (scanHistory.first['report_json']?['final_score'] ?? 0) : 0;
    final latestScanRating = hasScans ? (scanHistory.first['report_json']?['rating'] ?? 'Unknown') : '-';
    final insightMessage = hasScans 
        ? 'Your latest scanned product scored $latestScanScore/100 ($latestScanRating). Keep making healthy choices!'
        : 'Scan your first product this week to get your personalized health insight.';
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
                  Row(
                    children: [
                      Icon(Icons.eco, color: Theme.of(context).colorScheme.onSurface, size: 32),
                      const SizedBox(width: 8),
                      Text(
                        'PureScan AI',
                        style: GoogleFonts.playfairDisplay(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      ref.read(mainNavigationProvider.notifier).setIndex(3);
                    },
                    child: Builder(
                      builder: (context) {
                        final localAvatar = ref.watch(localAvatarProvider);
                        
                        if (_isProfileLoading && localAvatar == null) {
                          return Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 2),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).colorScheme.secondary, width: 2),
                            image: localAvatar != null
                                ? DecorationImage(
                                    image: FileImage(File(localAvatar)),
                                    fit: BoxFit.cover,
                                  )
                                : (_profileImageUrl != null && _profileImageUrl!.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(_profileImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null),
                          ),
                          child: (localAvatar == null && (_profileImageUrl == null || _profileImageUrl!.isEmpty))
                              ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 24)
                              : null,
                        );
                      }
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                color: Theme.of(context).colorScheme.primary,
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    
                    // Hero Section
                    Text(
                      "Know What's Really Inside.",
                      style: GoogleFonts.playfairDisplay(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Scan ingredient labels to get AI-powered insights about your food.",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Action Buttons
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                        elevation: 2,
                      ),
                        onPressed: () {
                          ref.read(mainNavigationProvider.notifier).setIndex(2);
                        },
                        child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.document_scanner),
                          SizedBox(width: 8),
                          Text('Scan Ingredient Label', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        minimumSize: Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                          side: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 2),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        context.push('/community-search').then((_) => _loadData());
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: 8),
                          Text('Search Global Database', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Recent Scans
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Recent Scans',
                          style: GoogleFonts.playfairDisplay(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                          TextButton(
                            onPressed: () {
                              ref.read(mainNavigationProvider.notifier).setIndex(1);
                            },
                            style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text('View All', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (scanHistoryAsync.isLoading)
                      const SizedBox(
                        height: 120,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (scanHistory.isEmpty)
                      _buildEmptyState()
                    else
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: scanHistory.length > 10 ? 10 : scanHistory.length,
                          itemBuilder: (context, index) {
                            final scan = scanHistory[index];
                            final report = scan['report_json'] as Map<String, dynamic>? ?? {};
                            final score = report['final_score'] as int? ?? 0;
                            final rating = report['rating'] as String? ?? 'Unknown';
                            final productName = scan['product_name'] as String? ?? 'Scanned Item';
                            
                            return InkWell(
                              onTap: () {
                                Map<String, dynamic>? parsedData;
                                if (scan['ingredients'] != null && scan['ingredients']['parsed_json'] != null) {
                                  parsedData = scan['ingredients']['parsed_json'] is String 
                                      ? jsonDecode(scan['ingredients']['parsed_json']) 
                                      : scan['ingredients']['parsed_json'];
                                } else {
                                  parsedData = scan['report_json']?['parsed_data'];
                                }
                                
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
                              child: _buildScanCard(productName, 'Recent', score, rating),
                            );
                          },
                        ),
                      ),
                      
                    const SizedBox(height: 32),
                    
                    // Weekly Summary
                    Text(
                      'Weekly Summary',
                      style: GoogleFonts.playfairDisplay(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                            blurRadius: 30,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hasScans ? latestScanRating : 'No Scans',
                                  style: TextStyle(
                                    fontFamily: 'Playfair Display',
                                    color: Theme.of(context).colorScheme.surface,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  insightMessage,
                                  style: const TextStyle(
                                    color: Color(0xFFA5D0B9),
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: latestScanScore / 100.0,
                                  strokeWidth: 8,
                                  backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.2),
                                  color: const Color(0xFFA5D0B9),
                                ),
                                Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        hasScans ? '$latestScanScore' : '-',
                                        style: TextStyle(
                                          fontFamily: 'Playfair Display',
                                          color: Theme.of(context).colorScheme.surface,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          height: 1.0,
                                        ),
                                      ),
                                      const Text(
                                        'Score',
                                        style: TextStyle(
                                          color: Color(0xFFA5D0B9),
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Daily Insights
                    Text(
                      'Daily Insights',
                      style: GoogleFonts.playfairDisplay(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondary,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF426B54).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.psychology, color: Color(0xFF426B54)),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Clinical Tip',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF426B54),
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Understanding Preservatives: Sodium Benzoate is generally safe but watch combinations with Vitamin C.',
                                  style: TextStyle(
                                    color: Color(0xFF152B1C),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: const Column(
        children: [
          Icon(Icons.history, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No scans yet',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            'Your recent scans will appear here.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildScanCard(String title, String subtitle, int score, String rating) {
    return Container(
      width: 260,
      margin: EdgeInsets.only(right: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE1E3E4)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.fastfood, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).colorScheme.primary, width: 3),
                ),
                child: Center(
                  child: Text(
                    '$score',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 4),
              Text(
                rating,
                style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
