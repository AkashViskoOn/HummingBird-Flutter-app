import 'package:get/get.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final String subtitle;
  final String price;
  final String period;
  final String badge;
  final bool isRecommended;
  final List<String> features;
  final List<String> notIncluded;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.period,
    this.badge = '',
    this.isRecommended = false,
    required this.features,
    this.notIncluded = const [],
  });
}

class SubscriptionController extends GetxController {
  final selectedPlanId = RxString('');
  final isLoading = RxBool(false);
  final isSubscribed = RxBool(false);
  final currentPlanId = RxString('free');

  static const plans = [
    SubscriptionPlan(
      id: 'free',
      name: 'Free',
      subtitle: 'Basic messaging',
      price: '\u20B90',
      period: 'forever',
      features: [
        'Text & media messaging',
        'Basic encryption',
        'Up to 10 scheduled messages',
        'Standard support',
      ],
      notIncluded: [
        'Advanced encryption (AES/Blowfish)',
        'Unlimited scheduled messages',
        'Priority support',
        'No ads',
      ],
    ),
    SubscriptionPlan(
      id: 'premium_monthly',
      name: 'Premium',
      subtitle: 'Monthly plan',
      price: '\u20B9199',
      period: '/month',
      badge: 'Popular',
      isRecommended: true,
      features: [
        'All Free features',
        'Advanced encryption (AES/Blowfish)',
        'Unlimited scheduled messages',
        'Priority support',
        'Ad-free experience',
        'Larger file sharing (100MB)',
      ],
    ),
    SubscriptionPlan(
      id: 'premium_yearly',
      name: 'Premium',
      subtitle: 'Yearly plan',
      price: '\u20B91,999',
      period: '/year',
      badge: 'Best Value',
      features: [
        'All Premium features',
        '2 months free',
        'Exclusive themes',
        'Early access to new features',
        'Dedicated support',
      ],
    ),
    SubscriptionPlan(
      id: 'lifetime',
      name: 'Lifetime',
      subtitle: 'One-time payment',
      price: '\u20B94,999',
      period: 'lifetime',
      badge: 'Limited',
      features: [
        'All Premium features forever',
        'Future premium features',
        'Priority lifetime support',
        'Special badge on profile',
        'Beta access',
      ],
    ),
  ];

  void selectPlan(String planId) {
    selectedPlanId.value = planId;
  }

  void subscribe() {
    if (selectedPlanId.value.isEmpty) return;
    isLoading.value = true;
    isLoading.value = false;
    isSubscribed.value = true;
    currentPlanId.value = selectedPlanId.value;
  }
}
