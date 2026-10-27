class TrustScoreReport {
  final int finalScore;
  final int combinedScore;
  final double communityRating;
  final String rating;
  final String description;
  final int ingredientQualityScore;
  final int nutritionScore;
  final int riskPenalty;
  final int additivesScore;
  final int transparencyScore;
  final List<String> flaggedIssues;
  final List<String> alternativeProducts;

  TrustScoreReport({
    required this.finalScore,
    this.combinedScore = 0,
    this.communityRating = 0.0,
    required this.rating,
    required this.description,
    required this.ingredientQualityScore,
    required this.nutritionScore,
    required this.riskPenalty,
    required this.additivesScore,
    required this.transparencyScore,
    required this.flaggedIssues,
    required this.alternativeProducts,
  });

  factory TrustScoreReport.fromJson(Map<String, dynamic> json) {
    return TrustScoreReport(
      finalScore: json['final_score'],
      combinedScore: json['combined_score'] ?? json['final_score'],
      communityRating: (json['community_rating'] ?? 0.0).toDouble(),
      rating: json['rating'],
      description: json['description'],
      ingredientQualityScore: json['ingredient_quality_score'],
      nutritionScore: json['nutrition_score'],
      riskPenalty: json['risk_penalty'],
      additivesScore: json['additives_score'] as int? ?? 0,
      transparencyScore: json['transparency_score'] as int? ?? 0,
      flaggedIssues: List<String>.from(json['flagged_issues'] ?? []),
      alternativeProducts: List<String>.from(json['alternative_products'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'final_score': finalScore,
      'rating': rating,
      'description': description,
      'ingredient_quality_score': ingredientQualityScore,
      'nutrition_score': nutritionScore,
      'risk_penalty': riskPenalty,
      'additives_score': additivesScore,
      'transparency_score': transparencyScore,
      'flagged_issues': flaggedIssues,
      'alternative_products': alternativeProducts,
    };
  }
}

class ParsedIngredients {
  final List<String> naturalIngredients;
  final List<String> wholeFoodIngredients;
  final List<String> additives;
  final List<String> artificialColors;
  final List<String> artificialSweeteners;
  final List<String> preservatives;
  final List<String> highRiskIngredients;
  final List<String> productClaims;
  final String sugarLevel;
  final String sodiumLevel;
  final String proteinLevel;

  ParsedIngredients({
    required this.naturalIngredients,
    required this.wholeFoodIngredients,
    required this.additives,
    required this.artificialColors,
    required this.artificialSweeteners,
    required this.preservatives,
    required this.highRiskIngredients,
    required this.productClaims,
    required this.sugarLevel,
    required this.sodiumLevel,
    required this.proteinLevel,
  });

  factory ParsedIngredients.fromJson(Map<String, dynamic> json) {
    List<String> parseList(List<dynamic>? list) {
      if (list == null) return <String>[];
      return List<String>.from(list);
    }

    return ParsedIngredients(
      naturalIngredients: parseList(json['natural_ingredients']),
      wholeFoodIngredients: parseList(json['whole_food_ingredients']),
      additives: parseList(json['additives']),
      artificialColors: parseList(json['artificial_colors']),
      artificialSweeteners: parseList(json['artificial_sweeteners']),
      preservatives: parseList(json['preservatives']),
      highRiskIngredients: parseList(json['high_risk_ingredients']),
      productClaims: parseList(json['product_claims']),
      sugarLevel: json['sugar_level'] ?? 'Unknown',
      sodiumLevel: json['sodium_level'] ?? 'Unknown',
      proteinLevel: json['protein_level'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'natural_ingredients': naturalIngredients,
      'whole_food_ingredients': wholeFoodIngredients,
      'additives': additives,
      'artificial_colors': artificialColors,
      'artificial_sweeteners': artificialSweeteners,
      'preservatives': preservatives,
      'high_risk_ingredients': highRiskIngredients,
      'product_claims': productClaims,
      'sugar_level': sugarLevel,
      'sodium_level': sodiumLevel,
      'protein_level': proteinLevel,
    };
  }
}

class ScanResponse {
  final String message;
  final ParsedIngredients parsedData;
  final TrustScoreReport trustScoreReport;

  ScanResponse({
    required this.message,
    required this.parsedData,
    required this.trustScoreReport,
  });

  factory ScanResponse.fromJson(Map<String, dynamic> json) {
    return ScanResponse(
      message: json['message'],
      parsedData: ParsedIngredients.fromJson(json['parsed_data']),
      trustScoreReport: TrustScoreReport.fromJson(json['trust_score_report']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'parsed_data': parsedData.toJson(),
      'trust_score_report': trustScoreReport.toJson(),
    };
  }
}
