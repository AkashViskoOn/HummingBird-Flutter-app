import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/pages/contacts/add_new_contact.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';

class SharedContactsMessageBottomSheet extends StatelessWidget {
  final List<Map<String, dynamic>> contacts;
  const SharedContactsMessageBottomSheet({super.key, required this.contacts});

  @override
  Widget build(BuildContext context) {
    return BottomSheet(
      onClosing: () {},
      builder: (context) {
        return Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg.r, vertical: AppSpacing.xxxl.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                contacts.length > 1 ? 'Contacts' : 'Contact',
                style: AppTextStyles.headingXl,
              ),
              SizedBox(
                height: AppSpacing.lg.h,
              ),
              ListView.builder(
                shrinkWrap: true,
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onLongPress: () => Clipboard.setData(
                        ClipboardData(text: contacts[index]['number'])),
                    leading: CircleAvatar(
                      radius: 30.r,
                      backgroundImage: contacts[index]['profile'] != ''
                          ? CachedNetworkImageProvider(
                              '${Endpoints.mediaBaseUrl}${contacts[index]['profile']}')
                          : const AssetImage(AppAssets.defaultProfilePic)
                              as ImageProvider,
                      onBackgroundImageError: (_, __) {},
                    ),
                    title: Text(
                      contacts[index]['name'],
                      style: AppTextStyles.headingSm,
                    ),
                    subtitle: Text(
                      contacts[index]['number'],
                      style: AppTextStyles.bodyMd
                          .copyWith(color: CustomColor.kTextSecondary),
                    ),
                    trailing: AppButton(
                      text: 'Save',
                      onTap: () => Get.to(() => const AddContact(), arguments: {
                        'name': contacts[index]['name'],
                        'number': contacts[index]['number']
                      }),
                      buttonSize: Size(Get.width * 0.2, 40),
                    ),
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }
}
