// TODO Implement this library.
class SubscriptionPlan {
  final String id;
  final String name;
  final int price;
  final List<String> benefits;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.price,
    required this.benefits,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['_id'],
      name: json['name'],
      price: json['price'],
      benefits: List<String>.from(json['benefits']),
    );
  }
}

class UserSubscriptionStatus {
  final SubscriptionPlan? currentPlan;
  final SubscriptionPlan? nextPlan;
  final bool isMaxTier;

  UserSubscriptionStatus({
    this.currentPlan,
    this.nextPlan,
    required this.isMaxTier,
  });

  factory UserSubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionStatus(
      currentPlan: json['currentPlan'] != null
          ? SubscriptionPlan.fromJson(json['currentPlan'])
          : null,
      nextPlan: json['nextPlan'] != null
          ? SubscriptionPlan.fromJson(json['nextPlan'])
          : null,
      isMaxTier: json['isMaxTier'] ?? false,
    );
  }
}

class UpgradeResponse {
  final String paymentUrl;

  UpgradeResponse({required this.paymentUrl});

  factory UpgradeResponse.fromJson(Map<String, dynamic> json) {
    return UpgradeResponse(paymentUrl: json['paymentUrl']);
  }
}
