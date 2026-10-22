import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/media_model.dart';
import 'package:humming_bird/components/chat_ui/download_media_button.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/database/local_database.dart';
import 'package:humming_bird/pages/chats/chat_screens/widgets/image_viewer_widget.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ImageWidget extends StatelessWidget {
  final String mediaUrl;
  final String mediaId;
  final String roomId;
  final Key imageKey;
  final String msg;
  const ImageWidget(
      {super.key,
      required this.mediaUrl,
      required this.mediaId,
      required this.roomId,
      required this.imageKey,
      required this.msg});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.find();
    return GetBuilder<ChatController>(
        id: mediaId,
        builder: (controller) {
          MediaModel? media = LocalDatabase.getMedia(mediaId);
          return Container(
              width: 0.5.sw,
              height: 0.2.sh,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.fifteen.r),
                  color: CustomColor.kDarkSurface2,
                  boxShadow: [
                    BoxShadow(
                      color: CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                      blurRadius: 10.r,
                      offset: Offset(0, 4.h),
                    ),
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  media == null
                      ? ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppRadius.eighteen.r),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image(
                                key: imageKey,
                                image: CachedNetworkImageProvider(mediaUrl),
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: CustomColor.kDarkSurface2,
                                ),
                              ),
                              BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                                child: Container(
                                  alignment: Alignment.center,
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  child: DownloadMediaButton(
                                    mediaUrl: mediaUrl,
                                    roomId: roomId,
                                    mediaType: '1',
                                    mediaId: mediaId,
                                    iconSize: 45,
                                    iconColor: CustomColor.kTextOnDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : FutureBuilder(
                          future: chatController.getMediaFromPath(mediaId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: SizedBox(
                                    width: 40.r,
                                    height: 40.r,
                                    child: const CircularProgressIndicator
                                        .adaptive()),
                              );
                            } else if (snapshot.connectionState ==
                                    ConnectionState.done &&
                                snapshot.hasData) {
                              return InkWell(
                                onTap: () => Get.to(
                                    () => FullScreenImageView(url: mediaUrl)),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      AppRadius.eighteen.r),
                                  child: Image.memory(snapshot.data!,
                                      fit: BoxFit.cover,
                                      width: double.maxFinite,
                                      height: 0.2.sh,
                                      errorBuilder: (_, __, ___) => Container(
                                            width: double.maxFinite,
                                            height: 0.2.sh,
                                            color: CustomColor.kDarkSurface2,
                                          )),
                                ),
                              );
                            } else {
                              return const Center(
                                  child: Text(
                                'Can\'t load file',
                                style:
                                    TextStyle(color: CustomColor.kTextOnDark),
                              ));
                            }
                          },
                        ),
                  msg != ''
                      ? Padding(
                          padding:
                              EdgeInsets.only(left: 5.r, bottom: 4.r, top: 4.r),
                          child: Text(
                            msg,
                            style: AppTextStyles.bodyLg
                                .copyWith(color: CustomColor.kTextPrimary),
                          ),
                        )
                      : const SizedBox.shrink()
                ],
              )
              // ? ClipRRect(
              //     borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
              //     child: Image.memory(
              //       media.bytes!,
              //       fit: BoxFit.cover,
              //     ),
              //   )
              // : ClipRRect(
              //     borderRadius: BorderRadius.circular(AppRadius.eighteen.r),
              //     child: Image.network(
              //       mediaUrl,
              //       fit: BoxFit.cover,
              //     ),
              //   ),
              );
        });
  }
}
