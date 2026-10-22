import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/controllers/subscription_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class SubscriptionPackagesPage extends StatelessWidget {
  const SubscriptionPackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SubscriptionController());

    return Scaffold(

      appBar: CommonAppBar(title: 'Premium Packages'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
                itemCount: SubscriptionController.plans.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _HeroSection();
                  }
                  final plan = SubscriptionController.plans[index - 1];
                  return _PlanCard(
                    plan: plan,
                    isSelected: controller.selectedPlanId.value == plan.id,
                    onTap: () => controller.selectPlan(plan.id),
                  );
                },
              ),
            ),
            _BottomBar(controller: controller),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: CustomColor.primaryGradient,
        borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  color: CustomColor.kGoldAccent, size: 28.r),
              SizedBox(width: 8.w),
              Text(
                'Unlock Premium',
                style: AppTextStyles.headingXl
                    .copyWith(color: CustomColor.kTextOnDark),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Get access to advanced encryption, unlimited scheduled messages, priority support, and more.',
            style: AppTextStyles.subtitle.copyWith(
                color: CustomColor.kTextOnDark.withValues(alpha: 0.85),
                height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.plan,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentPlan = plan.id == 'free';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
          border: Border.all(
            color: isSelected
                ? CustomColor.kPrimaryColor
                : plan.isRecommended
                    ? CustomColor.kGoldAccent.withValues(alpha: 0.4)
                    : Colors.transparent,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: AppTextStyles.titleLg
                                .copyWith(color: CustomColor.kTextPrimary),
                          ),
                          if (plan.badge.isNotEmpty) ...[
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: plan.isRecommended
                                    ? CustomColor.kGoldAccent
                                    : CustomColor.kPrimaryLight,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm.r),
                              ),
                              child: Text(
                                plan.badge,
                                style: AppTextStyles.labelSm.copyWith(
                                    color: plan.isRecommended
                                        ? Colors.black
                                        : CustomColor.kPrimaryColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        plan.subtitle,
                        style: AppTextStyles.bodySm
                            .copyWith(color: CustomColor.kTextSecondary),
                      ),
                    ],
                  ),
                ),
                Obx(() {
                  final isThisSelected =
                      Get.find<SubscriptionController>().selectedPlanId.value ==
                          plan.id;
                  return Container(
                    width: 24.r,
                    height: 24.r,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isThisSelected
                          ? CustomColor.kPrimaryColor
                          : Colors.transparent,
                      border: Border.all(
                        color: isThisSelected
                            ? CustomColor.kPrimaryColor
                            : CustomColor.kTextTertiary,
                        width: 2,
                      ),
                    ),
                    child: isThisSelected
                        ? Icon(Icons.check,
                            color: CustomColor.kTextOnDark, size: 14.r)
                        : null,
                  );
                }),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  plan.price,
                  style: AppTextStyles.displayLarge
                      .copyWith(color: CustomColor.kTextPrimary),
                ),
                if (plan.period.isNotEmpty) ...[
                  SizedBox(width: 4.w),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h),
                    child: Text(
                      plan.period,
                      style: AppTextStyles.subtitle
                          .copyWith(color: CustomColor.kTextSecondary),
                    ),
                  ),
                ],
                const Spacer(),
                if (isCurrentPlan)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: CustomColor.kPrimaryLight,
                      borderRadius: BorderRadius.circular(AppRadius.md.r),
                    ),
                    child: Text(
                      'Current Plan',
                      style: AppTextStyles.caption
                          .copyWith(color: CustomColor.kPrimaryColor),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 14.h),
            const Divider(height: 1),
            SizedBox(height: 14.h),
            ...plan.features.map(
              (f) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_rounded,
                        color: CustomColor.kOnlineGreen, size: 18.r),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        f,
                        style: AppTextStyles.bodySm
                            .copyWith(color: CustomColor.kTextPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ...plan.notIncluded.map(
              (f) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  children: [
                    Icon(Icons.cancel_rounded,
                        color: CustomColor.kTextTertiary, size: 18.r),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        f,
                        style: AppTextStyles.bodySm
                            .copyWith(color: CustomColor.kTextTertiary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final SubscriptionController controller;

  const _BottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    final selected = controller.selectedPlanId.value;
    final plan = SubscriptionController.plans.firstWhereOrNull(
      (p) => p.id == selected,
    );

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 52.h,
          child: ElevatedButton(
            onPressed:
                plan != null && plan.id != 'free' ? controller.subscribe : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: plan != null && plan.id != 'free'
                  ? CustomColor.kPrimaryColor
                  : CustomColor.kTextTertiary,
              foregroundColor: CustomColor.kTextOnDark,
              disabledBackgroundColor: CustomColor.kTextTertiary,
              disabledForegroundColor: CustomColor.kOverlay70,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
              ),
              elevation: 0,
            ),
            child: Text(
              plan != null && plan.id != 'free'
                  ? 'Subscribe to ${plan.name}'
                  : plan?.id == 'free'
                      ? 'Your Current Plan'
                      : 'Select a Plan',
              style: AppTextStyles.titleMd,
            ),
          ),
        ),
      ),
    );
  }
}
