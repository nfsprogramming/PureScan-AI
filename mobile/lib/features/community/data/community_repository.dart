// ignore_for_file: avoid_print
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'models/product_review.dart';
import 'models/product_discussion.dart';

import 'dart:convert';
import 'package:mobile/features/scanner/data/models/trust_score_report.dart';
import 'package:mobile/core/config/api_config.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

final communityProductsProvider = FutureProvider.family<List<dynamic>, int>((ref, page) async {
  final repo = ref.watch(communityRepositoryProvider);
  return await repo.getCommunityProducts(page: page, limit: 20);
});

final productAnalysisProvider = FutureProvider.family<ScanResponse?, String>((ref, barcode) async {
  final repo = ref.watch(communityRepositoryProvider);
  return await repo.getProductAnalysis(barcode);
});

class CommunityRepository {
  final _supabase = Supabase.instance.client;

  Future<List<dynamic>> getCommunityProducts({int page = 1, int limit = 20}) async {
    final session = _supabase.auth.currentSession;
    if (session == null) return [];

    final String baseUrl = ApiConfig.baseUrl;
    final url = Uri.parse('$baseUrl/api/v1/community/products?page=$page&limit=$limit');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['data'] ?? [];
      }
    } catch (e) {
      print("Error fetching community products: $e");
    }
    return [];
  }

  Future<ScanResponse?> getProductAnalysis(String barcode) async {
    try {
      // Try to find it in product_submissions first (which usually has the most recent scan reports)
      final submissionResponse = await _supabase
          .from('product_submissions')
          .select('ingredients_text, report_json')
          .eq('barcode', barcode)
          .order('created_at', ascending: false)
          .limit(1);

      if (submissionResponse.isNotEmpty) {
        final row = submissionResponse.first;
        final ingredientsText = row['ingredients_text'];
        final reportJson = row['report_json'];
        
        if (ingredientsText != null && reportJson != null) {
          final parsedData = ParsedIngredients.fromJson(
            ingredientsText is String ? jsonDecode(ingredientsText) : ingredientsText,
          );
          final trustScoreReport = TrustScoreReport.fromJson(
            reportJson is String ? jsonDecode(reportJson) : reportJson,
          );
          return ScanResponse(message: "Analysis fetched successfully", parsedData: parsedData, trustScoreReport: trustScoreReport);
        }
      }

      // If not found in submissions, check the products table
      final productResponse = await _supabase
          .from('products')
          .select('ingredients_text, report_json')
          .eq('barcode', barcode)
          .limit(1);

      if (productResponse.isNotEmpty) {
        final row = productResponse.first;
        final ingredientsText = row['ingredients_text'];
        final reportJson = row['report_json'];
        
        if (ingredientsText != null && reportJson != null) {
          final parsedData = ParsedIngredients.fromJson(
            ingredientsText is String ? jsonDecode(ingredientsText) : ingredientsText,
          );
          final trustScoreReport = TrustScoreReport.fromJson(
            reportJson is String ? jsonDecode(reportJson) : reportJson,
          );
          return ScanResponse(message: "Analysis fetched successfully", parsedData: parsedData, trustScoreReport: trustScoreReport);
        }
      }

      return null;
    } catch (e) {
      print('Error fetching product analysis: $e');
      return null;
    }
  }

  Future<List<ProductReview>> getProductReviews(String barcode) async {
    try {
      final response = await _supabase
          .from('product_reviews')
          .select('*, users(full_name, profile_image, is_verified_reviewer, trusted_contributor_badge)')
          .eq('product_barcode', barcode)
          .order('created_at', ascending: false);

      return (response as List).map((json) => ProductReview.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching reviews: $e');
      return [];
    }
  }

  Future<void> submitReview(String barcode, int rating, String? text) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    await _supabase.from('product_reviews').upsert({
      'product_barcode': barcode,
      'user_id': userId,
      'rating': rating,
      'review_text': text,
    }, onConflict: 'product_barcode, user_id');
  }

  Future<double> getAverageRating(String barcode) async {
    try {
      final response = await _supabase
          .from('product_reviews')
          .select('rating')
          .eq('product_barcode', barcode);
      
      if (response.isEmpty) return 0.0;
      
      double sum = 0;
      for (var row in response) {
        sum += row['rating'] as int;
      }
      return sum / response.length;
    } catch (e) {
      print('Error getting avg rating: $e');
      return 0.0;
    }
  }

  Future<List<ProductDiscussion>> getProductDiscussions(String barcode) async {
    try {
      final response = await _supabase
          .from('product_discussions')
          .select('*, users(full_name, profile_image, is_verified_reviewer, trusted_contributor_badge)')
          .eq('product_barcode', barcode)
          .order('created_at', ascending: false);

      return (response as List).map((json) => ProductDiscussion.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching discussions: $e');
      return [];
    }
  }

  Future<void> submitDiscussion(String barcode, String text) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('Not logged in');

    await _supabase.from('product_discussions').insert({
      'product_barcode': barcode,
      'user_id': userId,
      'question_text': text,
    });
  }
}
