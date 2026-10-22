import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/Models/user_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/common_textfield.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/theme/app_text_styles.dart';

class AddMemberBottomSheet extends StatelessWidget {
  final String roomId;
  const AddMemberBottomSheet({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.find();
    GroupController groupController = Get.find();
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      maxChildSize: 1.0,
      minChildSize: 1.0,
      builder: (context, scrollController) => Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add New Members',
                    style: AppTextStyles.headingLg
                        .copyWith(color: CustomColor.kTextPrimary),
                  ),
                  AppButton(
                    text: 'Add',
                    onTap: () {
                      groupController.addGroupMembers(roomId);
                    },
                    buttonSize: Size(90.w, 40.h),
                    backgroundColor: CustomColor.kPrimaryFill,
                  ),
                ],
              ),
              SizedBox(
                height: 15.h,
              ),
              CommonTextField(
                onChanged: (value) {
                  contactController.searchContacts(value);
                },
                bgColor: CustomColor.kTextOnDark,
                hintText: 'Search Contacts',
                suffixIcon: Icon(
                  Icons.search,
                  size: 30.r,
                  color: CustomColor.kPrimaryColor,
                ),
              ),
              SizedBox(
                height: 20.h,
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
                    builder: (_) => ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: contactController.hummingContacts.length,
                      itemBuilder: (context, index) {
                        User user = contactController.hummingContacts[index];
                        return Padding(
                            padding: EdgeInsets.symmetric(vertical: 4.h),
                            child: Obx(
                              () => ListTile(
                                onTap: () {
                                  contactController.groupParticipants
                                          .contains(user)
                                      ? contactController.groupParticipants
                                          .remove(user)
                                      : contactController.groupParticipants
                                          .add(user);
                                },
                                visualDensity: VisualDensity.compact,
                                splashColor: CustomColor.kPrimaryColor
                                    .withValues(alpha: 0.15),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(14.r))),
                                tileColor: CustomColor.kWhite,
                                leading: CircleAvatar(
                                  radius: 25.r,
                                  backgroundImage: user.userImage!.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          '${Endpoints.mediaBaseUrl}${user.userImage!}')
                                      : const AssetImage(
                                              AppAssets.defaultProfilePic)
                                          as ImageProvider,
                                  onBackgroundImageError: (_, __) {},
                                ),
                                title: Text(
                                  contactController.getAllContactsName(user),
                                  style: GoogleFonts.poppins(),
                                ),
                                subtitle: Text('${user.userMobileNum}'),
                                trailing: contactController.groupParticipants
                                        .contains(user)
                                    ? Icon(
                                        Icons.check_circle,
                                        color: CustomColor.kPrimaryColor,
                                        size: 28.r,
                                      )
                                    : null,
                              ),
                            ));
                      },
                    ),
                  );
                }
              }),
              // CommonTextField(
              //     hintText: 'Search Contacts',
              //     suffixIcon: IconButton(
              //         onPressed: () {},
              //         icon: Icon(
              //           Icons.search,
              //           color: Colors.grey[700],
              //           size: 30.sp,
              //         ))),
              // const SizedBox(
              //   height: 15,
              // ),
              // ListView.builder(
              //     shrinkWrap: true,
              //     physics: const NeverScrollableScrollPhysics(),
              //     itemCount: contactController.hummingContacts.length,
              //     itemBuilder: (context, index) {
              //       User user = contactController.hummingContacts[index];
              //       return Padding(
              //         padding: const EdgeInsets.symmetric(vertical: 7.h),
              //         child: Obx(() => ListTile(
              //               onTap: () {
              //                 contactController.groupParticipants.contains(user)
              //                     ? contactController.groupParticipants
              //                         .remove(user)
              //                     : contactController.groupParticipants
              //                         .add(user);
              //               },
              //                                               splashColor: CustomColor.kPrimaryColor.withValues(alpha: 0.15),
              //               shape: const RoundedRectangleBorder(
              //                   borderRadius:
              //                       BorderRadius.all(Radius.circular(20.r))),
              //               tileColor: CustomColor.kLightPrimaryColor,
              //               title: Text(
              //                 "${user.userFirstName} ${user.userLastName}",
              //                 style: GoogleFonts.poppins(),
              //               ),
              //               subtitle: Text("${user.userMobileNum}"),
              //               trailing: contactController.groupParticipants
              //                       .contains(user)
              //                   ? const Icon(
              //                       Icons.check_circle,
              //                       color: Colors.green,
              //                       size: 30.sp,
              //                     )
              //                   : null,
              //             )),
              //       );
              //     }),
            ],
          ),
        ),
      ),
    );
  }
}
