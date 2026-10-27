import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/trust_score_report.dart';

class SavedProduct {
  final String id;
  final ScanResponse data;
  final DateTime savedAt;

  SavedProduct({
    required this.id,
    required this.data,
    required this.savedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data': data.toJson(),
      'savedAt': savedAt.toIso8601String(),
    };
  }

  factory SavedProduct.fromJson(Map<String, dynamic> json) {
    return SavedProduct(
      id: json['id'],
      data: ScanResponse.fromJson(json['data']),
      savedAt: DateTime.parse(json['savedAt']),
    );
  }
}

class SavedProductsNotifier extends Notifier<List<SavedProduct>> {
  @override
  List<SavedProduct> build() {
    _loadSavedProducts();
    return [];
  }

  Future<void> _loadSavedProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStrings = prefs.getStringList('saved_products');
    if (savedStrings != null) {
      state = savedStrings
          .map((str) => SavedProduct.fromJson(jsonDecode(str)))
          .toList()
        ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
    }
  }

  Future<void> toggleSavedProduct(ScanResponse result) async {
    final prefs = await SharedPreferences.getInstance();
    
    // We will use a hash or simply stringify the result to generate a rough ID.
    final id = jsonEncode(result.toJson()).hashCode.toString();

    final isSaved = state.any((product) => product.id == id);
    if (isSaved) {
      state = state.where((product) => product.id != id).toList();
    } else {
      final newProduct = SavedProduct(
        id: id,
        data: result,
        savedAt: DateTime.now(),
      );
      state = [newProduct, ...state];
    }
    
    final savedStrings = state.map((product) => jsonEncode(product.toJson())).toList();
    await prefs.setStringList('saved_products', savedStrings);
  }

  bool isProductSaved(ScanResponse result) {
    final id = jsonEncode(result.toJson()).hashCode.toString();
    return state.any((product) => product.id == id);
  }
}

final savedProductsProvider = NotifierProvider<SavedProductsNotifier, List<SavedProduct>>(() {
  return SavedProductsNotifier();
});
