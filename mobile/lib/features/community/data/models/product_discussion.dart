class ProductDiscussion {
  final String id;
  final String productBarcode;
  final String userId;
  final String questionText;
  final bool resolved;
  final DateTime createdAt;
  final String? userFullName;
  final String? userProfileImage;
  final bool isVerifiedReviewer;
  final bool trustedContributorBadge;

  ProductDiscussion({
    required this.id,
    required this.productBarcode,
    required this.userId,
    required this.questionText,
    required this.resolved,
    required this.createdAt,
    this.userFullName,
    this.userProfileImage,
    this.isVerifiedReviewer = false,
    this.trustedContributorBadge = false,
  });

  factory ProductDiscussion.fromJson(Map<String, dynamic> json) {
    return ProductDiscussion(
      id: json['id'],
      productBarcode: json['product_barcode'],
      userId: json['user_id'],
      questionText: json['question_text'],
      resolved: json['resolved'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      userFullName: json['users']?['full_name'],
      userProfileImage: json['users']?['profile_image'],
      isVerifiedReviewer: json['users']?['is_verified_reviewer'] ?? false,
      trustedContributorBadge: json['users']?['trusted_contributor_badge'] ?? false,
    );
  }
}
