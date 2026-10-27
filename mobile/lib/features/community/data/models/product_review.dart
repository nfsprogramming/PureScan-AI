class ProductReview {
  final String id;
  final String productBarcode;
  final String userId;
  final int rating;
  final String? reviewText;
  final int helpfulCount;
  final DateTime createdAt;
  final String? userFullName;
  final String? userProfileImage;
  final bool isVerifiedReviewer;
  final bool trustedContributorBadge;

  ProductReview({
    required this.id,
    required this.productBarcode,
    required this.userId,
    required this.rating,
    this.reviewText,
    required this.helpfulCount,
    required this.createdAt,
    this.userFullName,
    this.userProfileImage,
    this.isVerifiedReviewer = false,
    this.trustedContributorBadge = false,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    return ProductReview(
      id: json['id'],
      productBarcode: json['product_barcode'],
      userId: json['user_id'],
      rating: json['rating'],
      reviewText: json['review_text'],
      helpfulCount: json['helpful_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
      userFullName: json['users']?['full_name'],
      userProfileImage: json['users']?['profile_image'],
      isVerifiedReviewer: json['users']?['is_verified_reviewer'] ?? false,
      trustedContributorBadge: json['users']?['trusted_contributor_badge'] ?? false,
    );
  }
}
