// ignore_for_file: avoid_print
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mobile/core/config/api_config.dart';
import 'models/trust_score_report.dart';
final scannerRepositoryProvider = Provider<ScannerRepository>((ref) {
  return ScannerRepository();
});

class ScannerRepository {
  final TextRecognizer _textRecognizer;

  ScannerRepository() : _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  Future<String> extractTextFromImage(String imagePath) async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      print("ML Kit is not supported on desktop. Using mock OCR text.");
      return "Ingredients: Water, Almonds, Sugar, Sea Salt, Vanilla Extract.";
    }

    final inputImage = InputImage.fromFilePath(imagePath);
    final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
    
    if (recognizedText.text.trim().isEmpty) {
      throw Exception("No text found in the image. Please try again.");
    }

    return recognizedText.text;
  }

	Future<ScanResponse?> sendOcrTextToBackend(String text, {String? barcode}) async {
		print("Sending extracted text to backend: $text");
		
		final session = Supabase.instance.client.auth.currentSession;
		if (session == null) {
			print("No active session found.");
			return null;
		}

		final String baseUrl = ApiConfig.baseUrl;
		final url = Uri.parse('$baseUrl/api/v1/scan/ocr');

		List<String> diets = [];
		List<String> allergies = [];

		int? age;

		try {
			final userResp = await Supabase.instance.client
				.from('users')
				.select('age')
				.eq('id', session.user.id)
				.maybeSingle();
			if (userResp != null && userResp['age'] != null) {
				age = userResp['age'] as int;
			}

			final prefs = await Supabase.instance.client
				.from('user_preferences')
				.select('diets, allergies')
				.eq('user_id', session.user.id)
				.maybeSingle();
			
			if (prefs != null) {
				diets = List<String>.from(prefs['diets'] ?? []);
				allergies = List<String>.from(prefs['allergies'] ?? []);
			}
		} catch (e) {
			print("Warning: Failed to load user profile for scan: $e");
		}

		String clinicalThreshold = 'Medium';
		try {
			final prefs = await SharedPreferences.getInstance();
			clinicalThreshold = prefs.getString('clinicalThreshold') ?? 'Medium';
		} catch (e) {
			print("Warning: Failed to load clinical threshold: $e");
		}

		double avgRating = 0.0;
		if (barcode != null) {
			try {
				final response = await Supabase.instance.client
					.from('product_reviews')
					.select('rating')
					.eq('product_barcode', barcode);
				
				if (response.isNotEmpty) {
					double sum = 0;
					for (var row in response) {
						sum += row['rating'] as int;
					}
					avgRating = sum / response.length;
				}
			} catch (e) {
				print("Warning: Failed to load avg rating: $e");
			}
		}

		final Map<String, dynamic> payload = {
			'extracted_text': text,
			'community_rating': avgRating,
			'user_profile': {
				'age': age ?? 0,
				'diets': diets,
				'allergies': allergies,
				'clinical_threshold': clinicalThreshold,
			}
		};

		try {
			final response = await http.post(
				url,
				headers: {
					'Content-Type': 'application/json',
					'Authorization': 'Bearer ${session.accessToken}',
				},
				body: jsonEncode(payload),
			);

			if (response.statusCode == 200) {
				final decoded = jsonDecode(response.body);
				return ScanResponse.fromJson(decoded);
			} else {
				print("Failed to analyze: ${response.body}");
				return null;
			}
		} catch (e) {
			print("HTTP Error: $e");
			return null;
		}
	}

  Future<Map<String, dynamic>?> sendBarcodeToBackend(String barcode) async {
    print("Sending barcode to backend: $barcode");
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      print("No active session found.");
      return null;
    }

    final String baseUrl = ApiConfig.baseUrl;
    final url = Uri.parse('$baseUrl/api/v1/scan/barcode');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'barcode': barcode}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("Failed to check barcode: ${response.body}");
        return null;
      }
    } catch (e) {
      print("HTTP Error: $e");
      return null;
    }
  }

  Future<bool> submitContribution(String barcode, String productName) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return false;

    final String baseUrl = ApiConfig.baseUrl;
    final url = Uri.parse('$baseUrl/api/v1/contribute');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'barcode': barcode,
          'product_name': productName,
        }),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Error submitting contribution: $e");
      return false;
    }
  }

  Future<Map<String, dynamic>?> submitProduct({
    required String productName,
    required String brandName,
    required String ingredientsText,
    required Map<String, dynamic> reportJson,
  }) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return null;

    final String baseUrl = ApiConfig.baseUrl;
    final url = Uri.parse('$baseUrl/api/v1/contribute');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({
          'barcode': '', // manual
          'product_name': productName,
          'brand_name': brandName,
          'ingredients_text': ingredientsText,
          'report_json': jsonEncode(reportJson),
        }),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("Failed to submit product: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error submitting product: $e");
      return null;
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
