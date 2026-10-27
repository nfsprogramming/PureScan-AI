import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:go_router/go_router.dart';
import 'package:mobile/features/community/presentation/screens/product_community_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/models/trust_score_report.dart';
import '../widgets/allergy_warning_dialog.dart';
import '../providers/saved_products_provider.dart';
import '../../data/scanner_repository.dart';
import '../../../community/data/community_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final ScanResponse result;

  const AnalysisResultScreen({super.key, required this.result});

  @override
  ConsumerState<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  int _currentTabIndex = 0;
  String _productName = 'Scanned Product';
  String _brandName = 'Unknown Brand';
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.result.trustScoreReport.flaggedIssues.isNotEmpty) {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Dismiss',
          barrierColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, animation, secondaryAnimation) {
            return AllergyWarningDialog(
              flaggedIngredients: widget.result.trustScoreReport.flaggedIssues,
            );
          },
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final report = widget.result.trustScoreReport;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFF1F2937), size: 28),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  ),
                  const Text(
                    'Scan Result',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  Consumer(
                    builder: (context, ref, child) {

                      // Since we want this UI to rebuild when saved state changes, we need to watch the whole list
                      // or just read it. Wait, `isProductSaved` reads the state from Notifier. It's better to watch the provider.
                      final savedList = ref.watch(savedProductsProvider);
                      // Recalculate isSaved based on the current watched list
                      final id = jsonEncode(widget.result.toJson()).hashCode.toString();
                      final isCurrentlySaved = savedList.any((p) => p.id == id);
                      
                      return IconButton(
                        icon: Icon(
                          isCurrentlySaved ? Icons.favorite : Icons.favorite_border, 
                          color: isCurrentlySaved ? Colors.red : const Color(0xFF1F2937), 
                          size: 24
                        ),
                        onPressed: () {
                          ref.read(savedProductsProvider.notifier).toggleSavedProduct(widget.result);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isCurrentlySaved ? 'Removed from Saved Products' : 'Added to Saved Products'),
                              duration: const Duration(seconds: 1),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 120),
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      // Product Info Section
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 80,
                              height: 112,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                boxShadow: const [
                                  BoxShadow(color: Colors.black12, blurRadius: 4),
                                ],
                              ),
                              child: const Center(
                                child: Icon(Icons.image_outlined, color: Colors.grey, size: 32),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  GestureDetector(
                                    onTap: () => _showEditNameDialog(),
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _productName,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937),
                                              height: 1.2,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.edit, size: 16, color: Color(0xFF6B7280)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  GestureDetector(
                                    onTap: () => _showEditNameDialog(),
                                    child: Text(
                                      _brandName,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Community Hub Button
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Theme.of(context).colorScheme.primary),
                            foregroundColor: Theme.of(context).colorScheme.primary,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductCommunityScreen(
                                  barcode: 'unknown',
                                  productName: 'Scanned Product',
                                  averageRating: report.communityRating,
                                  ingredientsText: jsonEncode(widget.result.parsedData.toJson()),
                                  scanData: widget.result,
                                ),
                              ),
                            );
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.forum_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('View Community Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Alternatives Section
                      if (report.alternativeProducts.isNotEmpty)
                        _buildAlternativesSection(report.alternativeProducts),
                        
                      // Tabs
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
                        ),
                        child: Row(
                          children: [
                            _buildTab('Overview', 0),
                            _buildTab('Ingredients', 1),
                            _buildTab('Nutrition', 2),
                            _buildTab('Claims', 3),
                          ],
                        ),
                      ),
                      
                      IndexedStack(
                        index: _currentTabIndex,
                        children: [
                          _buildOverviewTab(report, widget.result.parsedData),
                          _buildIngredientsTab(widget.result.parsedData),
                          _buildNutritionTab(widget.result.parsedData),
                          _buildClaimsTab(report, widget.result.parsedData),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
              ),
              child: IconButton(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                icon: const Row(
                  children: [
                    Icon(Icons.share, color: Color(0xFF1F2937), size: 20),
                    SizedBox(width: 8),
                    Text('Share', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1F2937))),
                  ],
                ),
                onPressed: () {
                  final score = widget.result.trustScoreReport.finalScore;
                  final rating = widget.result.trustScoreReport.rating;
                  // ignore: deprecated_member_use
                  Share.share('I just scanned a product with PureScan AI! It got a Trust Score of $score/100 ($rating).\n\nCheck it out and download the app here: https://purescanai.com/download');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B57),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 4,
                ),
                onPressed: () async {
                  await Printing.layoutPdf(
                    onLayout: (PdfPageFormat format) async => _generatePdf(format, widget.result),
                  );
                },
                child: const Text('View Full Report', style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    bool isSelected = _currentTabIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // Ensure full area is clickable
        onTap: () {
          setState(() {
            _currentTabIndex = index;
          });
        },
        child: Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF2E8B57) : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF2E8B57) : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, int score, int maxScore, String rating) {
    bool isWarning = score < (maxScore * 0.7);
    Color color = isWarning ? const Color(0xFFF59E0B) : const Color(0xFF2E8B57);
    
    // Scale the score to 100 for display to match the UI if we want, but UI expects actual numbers.
    // Wait, the backend returns raw subscores (e.g. 40 out of 40). We can display it as scaled to 100 to make the UI look good.
    int displayScore = (score * 100 / maxScore).round();
    
    return Expanded(
      child: Container(
        height: 100,
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 1))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: Color(0xFF6B7280),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$displayScore',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              isWarning ? 'Moderate' : 'Good',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHighlight(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF2E8B57), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesSection(List<String> alternatives) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'Healthier Alternatives',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: alternatives.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 16),
                      const SizedBox(height: 8),
                      Text(
                        alternatives[index],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final nameController = TextEditingController(text: _productName == 'Scanned Product' ? '' : _productName);
    final brandController = TextEditingController(text: _brandName == 'Unknown Brand' ? '' : _brandName);
    bool shareWithCommunity = true;

    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
    final isAdmin = [
      'mohammed.nifras.000555@gmail.com',
      'developer@purescanai.com',
      'admin@purescanai.com',
      'nfs.photographer@gmail.com',
      'developer@email.com',
      'admin@yourdomain.com',
      'developer@yourdomain.com'
    ].contains(currentUserEmail);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            scrollable: true,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Name This Product', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    hintText: 'e.g. Lays Classic',
                    prefixIcon: const Icon(Icons.inventory_2_outlined, color: Color(0xFF2E8B57)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E8B57), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: brandController,
                  decoration: InputDecoration(
                    labelText: 'Brand Name',
                    hintText: 'e.g. Frito-Lay',
                    prefixIcon: const Icon(Icons.storefront_outlined, color: Color(0xFF2E8B57)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2E8B57), width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2E8B57).withValues(alpha: 0.3)),
                  ),
                  child: CheckboxListTile(
                    value: shareWithCommunity,
                    onChanged: (val) {
                      setDialogState(() => shareWithCommunity = val ?? true);
                    },
                    activeColor: Color(0xFF2E8B57),
                    title: Text(
                      isAdmin ? 'Publish directly to Community' : 'Share with Community',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                    ),
                    subtitle: Text(
                      isAdmin ? 'Publish this product instantly' : 'Help others by adding this to the public database',
                      style: const TextStyle(fontFamily: 'Inter', fontSize: 11, color: Color(0xFF2E8B57)),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E8B57),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  final newName = nameController.text.trim();
                  final newBrand = brandController.text.trim();
                  
                  setState(() {
                    if (newName.isNotEmpty) _productName = newName;
                    if (newBrand.isNotEmpty) _brandName = newBrand;
                  });
                  
                  Navigator.pop(ctx);
                  
                  if (shareWithCommunity && newName.isNotEmpty) {
                    try {
                      final repo = ref.read(scannerRepositoryProvider);
                      final result = await repo.submitProduct(
                        productName: newName,
                        brandName: newBrand,
                        ingredientsText: jsonEncode(widget.result.parsedData.toJson()),
                        reportJson: widget.result.trustScoreReport.toJson(),
                      );
                      
                      if (result != null) {
                        // Invalidate community products so they refresh
                        ref.invalidate(communityProductsProvider);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Product submitted!'),
                              backgroundColor: const Color(0xFF2E8B57),
                              behavior: SnackBarBehavior.floating,
                            )
                          );
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to submit product. Please try again.'),
                              backgroundColor: Colors.red,
                            )
                          );
                        }
                      }
                    } catch (e) {
                      debugPrint('Error submitting product: $e');
                    }
                  }
                },
                child: Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildOverviewTab(TrustScoreReport report, ParsedIngredients parsedData) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trust Score Card
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('About Trust Score', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
                      content: const Text(
                        'The Trust Score is an AI-calculated metric ranging from 0 to 100. It considers ingredient quality, nutritional value, additive risks, and brand transparency.\n\n'
                        '• 80-100: Excellent, very clean\n'
                        '• 60-79: Good, minor concerns\n'
                        '• 40-59: Moderate, consume in moderation\n'
                        '• 0-39: Poor, highly processed',
                        style: TextStyle(fontFamily: 'Inter', height: 1.4),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Got it', style: TextStyle(color: Color(0xFF2E8B57))),
                        ),
                      ],
                    ),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'Trust Score',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.info_outline, color: Color(0xFF6B7280), size: 16),
                  ],
                ),
              ),
              Container(),
            ],
          ),
          const SizedBox(height: 8),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${report.finalScore}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E8B57),
                        ),
                      ),
                      const Text(
                        '/100',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    report.rating,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2E8B57),
                    ),
                  ),
                ],
              ),
              
              // Circular Gauge
              SizedBox(
                width: 64,
                height: 64,
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 64,
                        height: 64,
                        child: CircularProgressIndicator(
                          value: report.combinedScore > 0 ? report.combinedScore / 100.0 : report.finalScore / 100.0,
                          strokeWidth: 6,
                          backgroundColor: Colors.grey.shade200,
                          color: const Color(0xFF2E8B57),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(Icons.shield, color: Color(0xFF2E8B57), size: 24),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Animated Linear Progress
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: report.combinedScore > 0 ? report.combinedScore / 100.0 : report.finalScore / 100.0),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  value >= 0.8 ? const Color(0xFF2E8B57)
                  : value >= 0.6 ? const Color(0xFF4CAF50)
                  : value >= 0.4 ? const Color(0xFFFFA726)
                  : const Color(0xFFE53935),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          Text(
            report.description,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF1F2937),
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Metrics Grid
          Row(
            children: [
              _buildMetricCard('Ingredients Quality', report.ingredientQualityScore, 40, 'Good'),
              const SizedBox(width: 8),
              _buildMetricCard('Nutrition Quality', report.nutritionScore, 30, 'Good'),
              const SizedBox(width: 8),
              _buildMetricCard('Additives & Risks', report.additivesScore, 100, 'Moderate'),
              const SizedBox(width: 8),
              _buildMetricCard('Transparency', report.transparencyScore, 100, 'Excellent'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // AI Summary Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEEFCF5),
              border: Border.all(color: const Color(0xFF2E8B57).withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, color: Color(0xFF2E8B57), size: 16),
                    SizedBox(width: 8),
                    Text(
                      'AI Summary',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  report.description,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: Color(0xFF1F2937),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Key Highlights
          const Text(
            'Key Highlights',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
          ),
          const SizedBox(height: 12),
          
          if (parsedData.sodiumLevel == 'Low' || parsedData.sodiumLevel == 'Very Low')
            _buildHighlight('Low Sodium'),
          if (parsedData.sugarLevel == 'Low' || parsedData.sugarLevel == 'Very Low')
            _buildHighlight('Low Sugar'),
          if (parsedData.proteinLevel == 'High')
            _buildHighlight('High Protein'),
          if (parsedData.additives.isEmpty)
            _buildHighlight('No Additives'),
          if (parsedData.preservatives.isEmpty)
            _buildHighlight('No Preservatives'),
          if (parsedData.artificialColors.isEmpty)
            _buildHighlight('No Artificial Colors'),
          if (parsedData.naturalIngredients.isNotEmpty || parsedData.wholeFoodIngredients.isNotEmpty)
            _buildHighlight('Contains Natural/Whole Foods'),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab(ParsedIngredients data) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIngredientList('Natural Ingredients', data.naturalIngredients, primaryColor),
          _buildIngredientList('Whole Food Ingredients', data.wholeFoodIngredients, primaryColor),
          _buildIngredientList('Additives', data.additives, Colors.orange),
          _buildIngredientList('Preservatives', data.preservatives, Colors.orange),
          _buildIngredientList('Artificial Colors', data.artificialColors, Colors.red),
          _buildIngredientList('High Risk Ingredients', data.highRiskIngredients, Colors.red[900]!),
        ],
      ),
    );
  }

  Widget _buildIngredientList(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => Chip(
              label: Text(item, style: const TextStyle(fontSize: 12)),
              backgroundColor: color.withValues(alpha: 0.1),
              side: BorderSide(color: color.withValues(alpha: 0.3)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTab(ParsedIngredients data) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nutrition Levels', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.water_drop, color: Colors.blue),
            title: const Text('Sodium Level'),
            trailing: Text(data.sodiumLevel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.cookie, color: Colors.brown),
            title: const Text('Sugar Level'),
            trailing: Text(data.sugarLevel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.fitness_center, color: Colors.orange),
            title: const Text('Protein Level'),
            trailing: Text(data.proteinLevel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimsTab(TrustScoreReport report, ParsedIngredients data) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Product Claims & Warnings', style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Product Claims from label
            if (data.productClaims.isNotEmpty) ...[
              const Text('Label Claims:', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E8B57))),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: data.productClaims.map((claim) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF2E8B57), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF2E8B57), size: 14),
                      const SizedBox(width: 4),
                      Text(claim, style: const TextStyle(fontSize: 13, color: Color(0xFF1B5E20), fontWeight: FontWeight.w600)),
                    ],
                  ),
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Flagged Issues / Warnings
            const Text('Allergens & Warnings:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 8),
            if (report.flaggedIssues.isNotEmpty) ...
              report.flaggedIssues.map((e) => ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(e),
              ))
            else
              const ListTile(
                leading: Icon(Icons.check_circle, color: Colors.green),
                title: Text('No major allergens or high-risk issues flagged.'),
              ),
          ],
        ),
      ),
    );
  }

  Future<Uint8List> _generatePdf(PdfPageFormat format, ScanResponse response) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    
    final primaryColor = PdfColor.fromHex('#012D1D');
    final secondaryColor = PdfColor.fromHex('#BDEACD');
    final textColor = PdfColor.fromHex('#1F2937');
    final dangerColor = PdfColor.fromHex('#BA1A1A');

    // Load Logo
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/app_logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (e) {
      debugPrint('Could not load logo for PDF: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        theme: pw.ThemeData.withFont(
          base: pw.Font.helvetica(),
          bold: pw.Font.helveticaBold(),
        ),
        build: (context) {
          return [
            // Header
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      if (logoImage != null) ...[
                        pw.Image(logoImage, width: 48, height: 48),
                        pw.SizedBox(width: 16),
                      ],
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('PureScan AI', style: pw.TextStyle(color: PdfColors.white, fontSize: 32, fontWeight: pw.FontWeight.bold)),
                          pw.SizedBox(height: 6),
                          pw.Text('Clinical Nutritional Analysis', style: pw.TextStyle(color: secondaryColor, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  pw.Text(
                    'Date: ${DateTime.now().toIso8601String().split('T')[0]}',
                    style: const pw.TextStyle(color: PdfColors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 32),
            
            // Executive Summary
            pw.Text('EXECUTIVE SUMMARY', style: pw.TextStyle(color: primaryColor, fontSize: 14, fontWeight: pw.FontWeight.bold, letterSpacing: 1.2)),
            pw.SizedBox(height: 4),
            pw.Divider(color: secondaryColor, thickness: 2),
            pw.SizedBox(height: 16),
            
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text('Trust Score', style: pw.TextStyle(color: textColor, fontSize: 12)),
                        pw.SizedBox(height: 4),
                        pw.Text('${response.trustScoreReport.finalScore}/100', style: pw.TextStyle(color: primaryColor, fontSize: 28, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 2),
                        pw.Text(response.trustScoreReport.rating.toUpperCase(), style: pw.TextStyle(color: response.trustScoreReport.finalScore >= 70 ? primaryColor : dangerColor, fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 1.1)),
                      ],
                    ),
                  ),
                  pw.Container(width: 1, height: 60, color: PdfColors.grey300),
                  pw.SizedBox(width: 16),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                      response.trustScoreReport.description,
                      style: pw.TextStyle(color: textColor, fontSize: 11, lineSpacing: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Nutrition Facts
            pw.Text('NUTRITION SUMMARY', style: pw.TextStyle(color: primaryColor, fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 1.1)),
            pw.SizedBox(height: 2),
            pw.Divider(color: secondaryColor, thickness: 1.5),
            pw.SizedBox(height: 12),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _buildPdfStatBox('Sugar', response.parsedData.sugarLevel, primaryColor),
                pw.SizedBox(width: 6),
                _buildPdfStatBox('Sodium', response.parsedData.sodiumLevel, primaryColor),
                pw.SizedBox(width: 6),
                _buildPdfStatBox('Protein', response.parsedData.proteinLevel, primaryColor),
              ]
            ),
            pw.SizedBox(height: 20),

            // Ingredients
            pw.Text('INGREDIENTS BREAKDOWN', style: pw.TextStyle(color: primaryColor, fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 1.1)),
            pw.SizedBox(height: 2),
            pw.Divider(color: secondaryColor, thickness: 1.5),
            pw.SizedBox(height: 12),
            
            if (response.parsedData.naturalIngredients.isNotEmpty)
              _buildPdfIngredientSection('Natural Ingredients', response.parsedData.naturalIngredients, primaryColor),
              
            if (response.parsedData.wholeFoodIngredients.isNotEmpty)
              _buildPdfIngredientSection('Whole Foods', response.parsedData.wholeFoodIngredients, primaryColor),
              
            if (response.parsedData.additives.isNotEmpty)
              _buildPdfIngredientSection('Additives', response.parsedData.additives, PdfColor.fromHex('#E65100')),
              
            if (response.parsedData.preservatives.isNotEmpty)
              _buildPdfIngredientSection('Preservatives', response.parsedData.preservatives, PdfColor.fromHex('#E65100')),
              
            if (response.parsedData.highRiskIngredients.isNotEmpty)
              _buildPdfIngredientSection('High-Risk Ingredients', response.parsedData.highRiskIngredients, dangerColor),
              
            if (response.parsedData.artificialColors.isNotEmpty)
              _buildPdfIngredientSection('Artificial Colors', response.parsedData.artificialColors, dangerColor),
              
            if (response.parsedData.artificialSweeteners.isNotEmpty)
              _buildPdfIngredientSection('Artificial Sweeteners', response.parsedData.artificialSweeteners, dangerColor),
            
            // Product Claims
            if (response.parsedData.productClaims.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Text('PRODUCT CLAIMS', style: pw.TextStyle(color: primaryColor, fontSize: 12, fontWeight: pw.FontWeight.bold, letterSpacing: 1.1)),
              pw.SizedBox(height: 2),
              pw.Divider(color: secondaryColor, thickness: 1.5),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 6,
                runSpacing: 4,
                children: response.parsedData.productClaims.map((claim) => pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#E8F5E9'),
                    border: pw.Border.all(color: primaryColor, width: 1),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
                  ),
                  child: pw.Text(claim, style: pw.TextStyle(color: primaryColor, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                )).toList(),
              ),
            ],
            
            pw.SizedBox(height: 16),
            if (response.trustScoreReport.flaggedIssues.isNotEmpty) ...[
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FFEBEE'),
                  border: pw.Border.all(color: dangerColor, width: 1.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PRODUCT CLAIMS & WARNINGS', style: pw.TextStyle(color: dangerColor, fontSize: 11, fontWeight: pw.FontWeight.bold, letterSpacing: 1.1)),
                    pw.SizedBox(height: 8),
                    ...response.trustScoreReport.flaggedIssues.map((e) => pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 4),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('• ', style: pw.TextStyle(color: dangerColor, fontWeight: pw.FontWeight.bold, fontSize: 12)),
                          pw.Expanded(child: pw.Text(e, style: pw.TextStyle(color: dangerColor, fontSize: 11, lineSpacing: 1.2))),
                        ]
                      )
                    )),
                  ],
                ),
              ),
            ],
            
            pw.SizedBox(height: 24),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text(
                'Generated by PureScan AI - This report is for informational purposes only and does not constitute medical advice.',
                style: const pw.TextStyle(color: PdfColors.grey600, fontSize: 10),
                textAlign: pw.TextAlign.center,
              )
            )
          ];
        },
      ),
    );
    return pdf.save();
  }

  pw.Widget _buildPdfStatBox(String title, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(title.toUpperCase(), style: pw.TextStyle(color: PdfColors.grey600, fontSize: 9, fontWeight: pw.FontWeight.bold, letterSpacing: 1.1)),
            pw.SizedBox(height: 6),
            pw.Text(value, style: pw.TextStyle(color: color, fontSize: 14, fontWeight: pw.FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildPdfIngredientSection(String title, List<String> items, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(color: color, fontSize: 11, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(items.join(', '), style: const pw.TextStyle(color: PdfColors.grey800, fontSize: 10, lineSpacing: 1.3)),
        ],
      ),
    );
  }

}
