import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class TermsConditionPage extends StatelessWidget {
  const TermsConditionPage({super.key});

  static const _sections = [
    _Section(
      title: '1. Acceptance of Terms',
      body:
          'By downloading, installing, or using Humming Bird ("the App"), you agree to be bound by these Terms & Conditions. If you do not agree, please do not use the App. We reserve the right to update these terms at any time, and continued use constitutes acceptance of changes.',
    ),
    _Section(
      title: '2. Eligibility',
      body:
          'You must be at least 13 years of age to use the App. By using the App, you represent that you meet this requirement. If you are under 18, you must have parental or guardian consent.',
    ),
    _Section(
      title: '3. Account Registration',
      body:
          'You are responsible for providing accurate information during registration. You must keep your phone number and OTP secure. You are fully responsible for all activity that occurs under your account. Notify us immediately of any unauthorized use.',
    ),
    _Section(
      title: '4. Messaging & Content',
      body:
          'The App allows you to send text, media, and scheduled messages. You retain ownership of your content. You agree not to use the App for spam, harassment, illegal activity, or sharing harmful content. We reserve the right to remove content or suspend accounts that violate this policy.',
    ),
    _Section(
      title: '5. Scheduling Feature',
      body:
          'Scheduled messages are delivered based on the time you set. While we strive for timely delivery, we do not guarantee exact delivery at the scheduled second. We are not liable for missed or delayed scheduled messages due to network issues, device limitations, or server downtime.',
    ),
    _Section(
      title: '6. Privacy & Data',
      body:
          'Your messages are encrypted in transit and at rest. We collect minimal data needed for the service to function (phone number, profile information). We do not sell your personal data. Messages are stored on our servers to enable delivery across devices. See our Privacy Policy for full details.',
    ),
    _Section(
      title: '7. Third-Party Services',
      body:
          'The App uses third-party services including Firebase Cloud Messaging for push notifications and MSG91 for SMS verification. These services have their own terms and privacy policies. We are not responsible for the practices of these third parties.',
    ),
    _Section(
      title: '8. Limitation of Liability',
      body:
          'The App is provided "as is" without warranty of any kind. To the maximum extent permitted by law, we shall not be liable for any indirect, incidental, or consequential damages arising from your use of the App, including but not limited to data loss, missed messages, or service interruptions.',
    ),
    _Section(
      title: '9. Termination',
      body:
          'You may delete your account at any time via the Settings page. We reserve the right to suspend or terminate access for violations of these terms. Upon termination, your data will be permanently deleted from our servers within a reasonable period.',
    ),
    _Section(
      title: '10. Contact',
      body:
          'For questions about these Terms & Conditions, please contact our support team through the app or email us at support@myhummingbird.net.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Terms & Conditions'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.all(16.w),
                itemCount: _sections.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1.h,
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.06),
                ),
                itemBuilder: (context, index) {
                  final section = _sections[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: AppTextStyles.titleMd
                              .copyWith(color: CustomColor.kTextPrimary),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          section.body,
                          style: AppTextStyles.subtitle.copyWith(
                              color: CustomColor.kTextSecondary, height: 1.6),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});
}
