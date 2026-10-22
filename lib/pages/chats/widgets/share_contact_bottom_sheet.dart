import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/contact.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/common_textfield.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_icons.dart';

class ShareContactBottomSheet extends StatefulWidget {
  const ShareContactBottomSheet({super.key});

  @override
  State<ShareContactBottomSheet> createState() =>
      _ShareContactBottomSheetState();
}

class _ShareContactBottomSheetState extends State<ShareContactBottomSheet> {
  late ContactController contactController;
  late ChatController chatController;

  @override
  void initState() {
    contactController = Get.find();
    chatController = Get.find();
    chatController.shareContactsList = <Map<String, dynamic>>[].obs;
    super.initState();
  }

  @override
  void dispose() {
    chatController.shareContactsList.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (MediaQuery.of(context).size.height -
              MediaQuery.of(context).viewInsets.bottom) *
          0.92,
      padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xxxl.w, vertical: AppSpacing.lg.h),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share Contacts',
                  style: AppTextStyles.headingLg,
                ),
                AppButton(
                  text: 'Share',
                  onTap: () => chatController.shareContacts(),
                  buttonSize: Size(90.w, 40.h),
                  backgroundColor: CustomColor.kPrimaryFill,
                ),
              ],
            ),
            SizedBox(
              height: AppSpacing.lg.h,
            ),
            CommonTextField(
              onChanged: (value) {
                contactController.searchContacts(value, forAllContacts: true);
              },
              bgColor: CustomColor.kTextOnDark,
              hintText: 'Search Contacts',
              suffixIcon: Icon(
                Icons.search,
                size: AppIcons.xxxl.r,
                color: CustomColor.kPrimaryColor,
              ),
            ),
            SizedBox(
              height: AppSpacing.xxxl.h,
            ),
            Obx(() {
              if (contactController.isFetchingContacts.value) {
                return const CustomLoading();
              } else if (contactController.hummingContacts.isEmpty &&
                  contactController.allContacts.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'No saved contacts',
                  message: 'Contacts saved to the app appear here',
                );
              } else {
                return GetBuilder<ContactController>(
                  id: 'update-contacts-search',
                  builder: (_) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Humming Contacts',
                        style: AppTextStyles.headingSm,
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: contactController.hummingContacts.length,
                        itemBuilder: (context, index) {
                          User user = contactController.hummingContacts[index];
                          return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.h),
                              child: Obx(() => ListTile(
                                    onTap: () {
                                      chatController.selectSharingContact({
                                        'name': contactController
                                            .getAllContactsName(user),
                                        'number': user.userMobileNum,
                                        'profile': user.userImage,
                                      });
                                    },
                                    visualDensity: VisualDensity.compact,
                                    splashColor: Colors.blueAccent
                                        .withValues(alpha: 0.3),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10.r))),
                                    tileColor: CustomColor.kTextOnDark,
                                    leading: CircleAvatar(
                                      radius: 25.r,
                                      backgroundImage: user
                                              .userImage!.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              '${Endpoints.mediaBaseUrl}${user.userImage!}')
                                          : const AssetImage(
                                                  AppAssets.defaultProfilePic)
                                              as ImageProvider,
                                      onBackgroundImageError: (_, __) {},
                                    ),
                                    title: Text(
                                      contactController
                                          .getAllContactsName(user),
                                      style: AppTextStyles.bodyMd,
                                    ),
                                    subtitle: Text('${user.userMobileNum}'),
                                    trailing: chatController.shareContactsList
                                            .any((e) =>
                                                e['number'] ==
                                                user.userMobileNum)
                                        ? Icon(
                                            Icons.check_circle,
                                            color: CustomColor.kPrimaryColor,
                                            size: 28.r,
                                          )
                                        : null,
                                  )));
                        },
                      ),
                      SizedBox(
                        height: AppSpacing.lg.h,
                      ),
                      Text(
                        'Non Humming Contacts',
                        style: AppTextStyles.headingSm,
                      ),
                      SizedBox(
                        height: 10.h,
                      ),
                      ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: contactController.phoneContacts.length,
                        itemBuilder: (context, index) {
                          Contact contact =
                              contactController.phoneContacts[index];
                          return Padding(
                              padding: EdgeInsets.symmetric(vertical: 4.h),
                              child: Obx(() => ListTile(
                                    onTap: () {
                                      chatController.selectSharingContact({
                                        'name': contact.displayName,
                                        'number':
                                            contact.phones[0].number.toString()
                                      });
                                    },
                                    visualDensity: VisualDensity.compact,
                                    splashColor: Colors.blueAccent
                                        .withValues(alpha: 0.3),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                            Radius.circular(10.r))),
                                    tileColor: CustomColor.kTextOnDark,
                                    leading: CircleAvatar(
                                        radius: 25.r,
                                        backgroundImage: const AssetImage(
                                            AppAssets.defaultProfilePic)),
                                    title: Text(
                                      contact.displayName,
                                      style: AppTextStyles.bodyMd,
                                    ),
                                    subtitle: Text(contact.phones.isNotEmpty
                                        ? contact.phones[0].number.toString()
                                        : ''),
                                    trailing: chatController.shareContactsList
                                            .any((e) =>
                                                e['number'] ==
                                                contact.phones[0].number
                                                    .toString())
                                        ? Icon(
                                            Icons.check_circle,
                                            color: CustomColor.kPrimaryColor,
                                            size: 28.r,
                                          )
                                        : null,
                                  )));
                        },
                      ),
                    ],
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }
}
