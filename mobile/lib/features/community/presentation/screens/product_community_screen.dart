// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:mobile/core/utils/error_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../scanner/data/models/trust_score_report.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../data/community_repository.dart';
import '../../data/models/product_review.dart';
import '../../data/models/product_discussion.dart';

class ProductCommunityScreen extends ConsumerStatefulWidget {
  final String barcode;
  final String productName;
  final double averageRating;
  final String? ingredientsText;
  final ScanResponse? scanData;

  const ProductCommunityScreen({
    super.key,
    required this.barcode,
    required this.productName,
    required this.averageRating,
    this.ingredientsText,
    this.scanData,
  });

  @override
  ConsumerState<ProductCommunityScreen> createState() => _ProductCommunityScreenState();
}

class _ProductCommunityScreenState extends ConsumerState<ProductCommunityScreen> {
  final _reviewController = TextEditingController();
  int _selectedRating = 5;
  bool _isSubmitting = false;
  
  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(communityRepositoryProvider).submitReview(
        widget.barcode,
        _selectedRating,
        _reviewController.text.isNotEmpty ? _reviewController.text : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully!'), backgroundColor: Colors.green),
        );
        _reviewController.clear();
        // Refresh the list
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorFormatter.getReadableMessage(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
        title: Column(
          children: [
            Text('Community Hub', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600, fontSize: 20)),
            Text(widget.productName, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        bottom: TabBar(
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: [
            const Tab(text: 'Analysis'),
            const Tab(text: 'Reviews'),
            const Tab(text: 'Q&A'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _buildAnalysisTab(),
          _buildReviewsTab(),
          _buildDiscussionsTab(),
        ],
      ),
      ),  // closes Scaffold
    );   // closes DefaultTabController
  }

  Widget _buildAnalysisTab() {
    if (widget.scanData != null) {
      return _buildCompleteAnalysisUI(widget.scanData!);
    }

    final analysisAsync = ref.watch(productAnalysisProvider(widget.barcode));

    return analysisAsync.when(
      data: (scanData) {
        if (scanData == null) {
          return _buildEmptyAnalysis();
        }
        return _buildCompleteAnalysisUI(scanData);
      },
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF2E8B57))),
      error: (e, st) => Center(child: Text('Error loading analysis: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildCompleteAnalysisUI(ScanResponse scanData) {
    final report = scanData.trustScoreReport;
    final parsed = scanData.parsedData;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Trust Score
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Trust Score', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(report.rating, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryColor)),
                  ],
                ),
                Text('${report.finalScore}/100', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Score Breakdown
          const Text('Score Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildScoreRow('Ingredients Quality', report.ingredientQualityScore),
          _buildScoreRow('Nutrition Quality', report.nutritionScore),
          _buildScoreRow('Additives & Risks', report.additivesScore),
          _buildScoreRow('Transparency', report.transparencyScore),
          const SizedBox(height: 24),

          // 3. AI Summary
          if (report.description.isNotEmpty) ...[
            const Text('AI Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Text(report.description, style: const TextStyle(fontSize: 15, height: 1.5)),
            ),
            const SizedBox(height: 24),
          ],

          // 4. Ingredients Analysis
          const Text('Ingredient Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildIngredientSection('Natural Ingredients', parsed.naturalIngredients, primaryColor),
          _buildIngredientSection('Whole Food Ingredients', parsed.wholeFoodIngredients, primaryColor),
          _buildIngredientSection('Additives', parsed.additives, Colors.orange),
          _buildIngredientSection('Preservatives', parsed.preservatives, Colors.orange),
          _buildIngredientSection('Artificial Colors', parsed.artificialColors, Colors.red),
          _buildIngredientSection('Artificial Sweeteners', parsed.artificialSweeteners, Colors.red),
          _buildIngredientSection('High Risk Ingredients', parsed.highRiskIngredients, Colors.red.shade900),
          _buildIngredientSection('Product Claims', parsed.productClaims, primaryColor),
          
          const SizedBox(height: 16),
          const Text('Nutrition', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildLevelChip('Sugar', parsed.sugarLevel),
              _buildLevelChip('Sodium', parsed.sodiumLevel),
              _buildLevelChip('Protein', parsed.proteinLevel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, int score) {
    Color color = Colors.green;
    if (score < 40) color = Colors.red;
    else if (score < 70) color = Colors.orange;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text('$score/100', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  // _buildParsedIngredientsUI is replaced by _buildCompleteAnalysisUI

  Widget _buildLevelChip(String label, String level) {
    Color color = Colors.grey;
    final lvl = level.toLowerCase();
    if (lvl.contains('low') || lvl.contains('good')) color = Colors.green;
    if (lvl.contains('moderate') || lvl.contains('medium')) color = Colors.orange;
    if (lvl.contains('high') || lvl.contains('bad')) color = Colors.red;

    return Chip(
      label: Text('$label: $level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      backgroundColor: color,
    );
  }

  Widget _buildIngredientSection(String title, List<String> items, Color color) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) => Chip(
              label: Text(item),
              backgroundColor: color.withValues(alpha: 0.1),
              side: BorderSide(color: color.withValues(alpha: 0.5)),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAnalysis() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('Ingredient Analysis', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'No ingredient data available for this product in the community database yet. Be the first to scan and add it!',
              style: TextStyle(
                fontSize: 16, 
                height: 1.5,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsTab() {
    return FutureBuilder<List<ProductReview>>(
        future: ref.read(communityRepositoryProvider).getProductReviews(widget.barcode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
          }

          final reviews = snapshot.data ?? [];

          return CustomScrollView(
            slivers: [
              // Header with Average Rating
              SliverToBoxAdapter(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        widget.averageRating > 0 ? widget.averageRating.toStringAsFixed(1) : 'No Ratings',
                        style: GoogleFonts.playfairDisplay(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return Icon(
                            index < widget.averageRating.round() ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 28,
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Based on ${reviews.length} community reviews',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),

              // Write a Review Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rate & Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _selectedRating ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 36,
                              ),
                              onPressed: () => setState(() => _selectedRating = index + 1),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _reviewController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: 'Share your thoughts on this product...',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isSubmitting ? null : _submitReview,
                            child: _isSubmitting
                                ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Theme.of(context).colorScheme.surface, strokeWidth: 2))
                                : Text('Post Review', style: TextStyle(color: Theme.of(context).colorScheme.surface, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Reviews List
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final review = reviews[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 16),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Theme.of(context).colorScheme.secondary,
                                  backgroundImage: review.userProfileImage != null ? NetworkImage(review.userProfileImage!) : null,
                                  child: review.userProfileImage == null ? Icon(Icons.person, color: Theme.of(context).colorScheme.primary) : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            review.userFullName ?? 'Anonymous User',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          if (review.isVerifiedReviewer) ...[
                                            const SizedBox(width: 4),
                                            const Icon(Icons.verified, color: Colors.blue, size: 16),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        timeago.format(review.createdAt),
                                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: List.generate(5, (starIndex) {
                                    return Icon(
                                      starIndex < review.rating ? Icons.star : Icons.star_border,
                                      color: Colors.amber,
                                      size: 16,
                                    );
                                  }),
                                ),
                              ],
                            ),
                            if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(review.reviewText!, style: const TextStyle(fontSize: 14, height: 1.4)),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.thumb_up_outlined, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text('${review.helpfulCount} helpful', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                    childCount: reviews.length,
                  ),
                ),
              ),
              
            ],
          );
        },
      );
  }

  final _discussionController = TextEditingController();
  bool _isSubmittingDiscussion = false;

  void _submitDiscussion() async {
    if (_discussionController.text.trim().isEmpty) return;
    setState(() => _isSubmittingDiscussion = true);
    try {
      await ref.read(communityRepositoryProvider).submitDiscussion(
        widget.barcode,
        _discussionController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question posted!'), backgroundColor: Colors.green));
        _discussionController.clear();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorFormatter.getReadableMessage(e)), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmittingDiscussion = false);
    }
  }

  Widget _buildDiscussionsTab() {
    return FutureBuilder<List<ProductDiscussion>>(
      future: ref.read(communityRepositoryProvider).getProductDiscussions(widget.barcode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final discussions = snapshot.data ?? [];

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Container(
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ask the Community', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _discussionController,
                        maxLines: 2,
                        decoration: InputDecoration(hintText: 'Ask a question about this product...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          onPressed: _isSubmittingDiscussion ? null : _submitDiscussion,
                          child: Text('Post Question', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final d = discussions[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(radius: 16, backgroundColor: Theme.of(context).colorScheme.secondary, child: Icon(Icons.person, size: 16, color: Theme.of(context).colorScheme.primary)),
                              const SizedBox(width: 8),
                              Text(d.userFullName ?? 'Anonymous', style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (d.isVerifiedReviewer) const Icon(Icons.verified, color: Colors.blue, size: 14),
                              const Spacer(),
                              Text(timeago.format(d.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(d.questionText, style: const TextStyle(fontSize: 15)),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {}, // Reply functionality coming soon
                            icon: const Icon(Icons.reply, size: 16),
                            label: const Text('Reply'),
                          )
                        ],
                      ),
                    );
                  },
                  childCount: discussions.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
