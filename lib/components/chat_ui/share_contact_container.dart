import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/pages/chats/widgets/shared_contacts_message_bottom_sheet.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ShareContactContainer extends StatelessWidget {
  final String data;
  const ShareContactContainer({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> contacts =
        jsonDecode(data).cast<Map<String, dynamic>>();
    return Container(
      width: Get.width * 0.7,
      height: Get.height * 0.12,
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl.r, vertical: AppSpacing.xl.r),
      decoration: BoxDecoration(
        color: CustomColor.kTextOnDark,
        borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(
          //   contacts.length > 1 ? 'Contacts' : 'Contact',
          //   style: TextStyle(
          //       fontSize: 18.sp,
          //       fontWeight: FontWeight.w700,
          //       color: Colors.black),
          // ),
          Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundImage: contacts[0]['profile'] != ''
                    ? CachedNetworkImageProvider(
                        '${Endpoints.mediaBaseUrl}${contacts[0]['profile']}')
                    : const AssetImage(AppAssets.defaultProfilePic)
                        as ImageProvider,
                onBackgroundImageError: (_, __) {},
              ),
              SizedBox(
                width: 15.w,
              ),
              Flexible(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contacts[0]['name'],
                    style:
                        AppTextStyles.headingSm.copyWith(color: Colors.black),
                    overflow: TextOverflow.ellipsis,
                  ),
                  contacts.length > 1
                      ? Text('and ${contacts.length - 1} more contacts')
                      : const SizedBox.shrink(),
                ],
              ))
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => showModalBottomSheet(
                  context: context,
                  useSafeArea: true,
                  isScrollControlled: true,
                  builder: (context) =>
                      SharedContactsMessageBottomSheet(contacts: contacts),
                ),
                child: Text(
                  contacts.length > 1 ? 'View Contacts' : 'View Contact',
                  style: AppTextStyles.headingSm
                      .copyWith(color: CustomColor.kPrimaryColor),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}
