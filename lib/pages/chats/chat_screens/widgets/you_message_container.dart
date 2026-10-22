import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/chat_ui/group_sender_name.dart';
import 'package:humming_bird/components/chat_ui/replied_on_container.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_animation.dart';

class YouMessageContainer extends StatefulWidget {
  final Messages message;
  final bool isGroup;
  final String roomId;
  final String userProfile;
  final UniqueKey uniqueKey;
  const YouMessageContainer(
      {super.key,
      required this.message,
      required this.isGroup,
      required this.roomId,
      required this.userProfile,
      required this.uniqueKey});

  @override
  State<YouMessageContainer> createState() => _YouMessageContainerState();
}

class _YouMessageContainerState extends State<YouMessageContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController animController;
  late Animation<Offset> replyAnimation;
  late Messages message;
  late ChatController chatController;
  late GroupController groupController;

  @override
  void initState() {
    chatController = Get.find();
    if (widget.isGroup) {
      groupController = Get.find();
    }
    message = widget.message;
    animController = AnimationController(
      vsync: this,
      duration: AppAnimation.normal,
    );
    replyAnimation = Tween(
      begin: const Offset(0.0, 0.0),
      end: const Offset(0.6, 0.0),
    ).animate(
      CurvedAnimation(
        curve: AppAnimation.decelerate,
        parent: animController,
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDeletedMessage = message.mIsDeleted == '1';
    return VisibilityDetector(
      key: widget.uniqueKey,
      onVisibilityChanged: (info) {
        if (info.visibleFraction * 100 >= 50 && message.mReadStatus != '3') {
          message.mReadStatus = '3';
          WidgetsBinding.instance.addPostFrameCallback((_) {
            chatController.updateMessage(message, true, widget.isGroup);
          });
        }
      },
      child: InkWell(
        onTap: () {
          chatController.manageMessageSelector(message.mId!,
              isYouMessage: true);
        },
        onLongPress: () {
          chatController.selectMessageOnLongPress(message.mId!,
              isYouMessage: true);
        },
        child: Obx(
          () => Container(
            color: chatController.messageSelectorMap[message.mId] != true
                ? null
                : CustomColor.kPrimaryColor.withValues(alpha: 0.3),
            padding: EdgeInsets.only(
                left: AppSpacing.lg.r,
                right: 50.r,
                top: AppSpacing.md.r,
                bottom: AppSpacing.md.r),
            alignment: Alignment.centerLeft,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GetBuilder<ContactController>(
                    id: 'Update Group',
                    builder: (_) {
                      return CircleAvatar(
                        radius: 18.r,
                        backgroundImage: widget.isGroup
                            ? groupController.getGroupImage(widget.roomId)
                            : widget.userProfile.isNotEmpty
                                ? CachedNetworkImageProvider(
                                    '${Endpoints.mediaBaseUrl}${widget.userProfile}')
                                : const AssetImage(AppAssets.defaultProfilePic)
                                    as ImageProvider,
                        onBackgroundImageError: (_, __) {},
                      );
                    }),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    message.mRepliedOn != null && !isDeletedMessage
                        ? Padding(
                            padding: EdgeInsets.only(left: 15.w),
                            child: RepliedOnContainer(
                                messageId: message.mRepliedOn!),
                          )
                        : const SizedBox.shrink(),
                    GestureDetector(
                      onHorizontalDragUpdate: (details) {
                        if (details.primaryDelta! > 0 &&
                            details.primaryDelta! > 3) {
                          animController
                              .forward()
                              .whenComplete(() => animController.reverse());
                          chatController.replyOnMessage(message);
                        }
                      },
                      child: SlideTransition(
                        position: replyAnimation,
                        child: Container(
                          margin: EdgeInsets.only(left: AppSpacing.lg.w),
                          decoration: BoxDecoration(
                            color: CustomColor.kReceivedBubble,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(AppRadius.rounded.r),
                              topLeft: Radius.circular(0.r),
                              bottomRight: Radius.circular(AppRadius.rounded.r),
                              topRight: Radius.circular(AppRadius.rounded.r),
                            ),
                            boxShadow: AppShadow.cardLight,
                          ),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                widget.isGroup && !isDeletedMessage
                                    ? SenderNameContainer(
                                        senderId: message.mSenderId!,
                                      )
                                    : const SizedBox.shrink(),
                                Padding(
                                  padding: message.mMessageType == '0'
                                      ? EdgeInsets.symmetric(
                                          horizontal: AppSpacing.lg.w,
                                          vertical: AppSpacing.xs.h)
                                      : EdgeInsets.symmetric(
                                          horizontal: AppSpacing.xxs.w,
                                          vertical: AppSpacing.xxs.h),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      isDeletedMessage
                                          ? Text(
                                              'This message was deleted',
                                              style:
                                                  AppTextStyles.bodyLg.copyWith(
                                                color:
                                                    CustomColor.kTextTertiary,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            )
                                          : message.mMessageType == '0'
                                              ? Text(
                                                  message.mMessage!,
                                                  style: AppTextStyles.bodyLg,
                                                )
                                              : AppHelper.checkFileType(
                                                  mediaId: message.mId!,
                                                  roomId: message.mRoomId!,
                                                  mediaUrl:
                                                      '${Endpoints.mediaBaseUrl}${message.mMedia}',
                                                  fileType:
                                                      message.mMessageType!,
                                                  msg: message.mMessage
                                                      .toString()),
                                      Text(
                                        message.isScheduledMessage
                                            ? message.mMessageType != '0'
                                                ? '    ${AppHelper.formatTime(AppHelper.formatDateTimeFromEpoch(message.mScheduledAt!, 'yyyy-MM-dd HH:mm:ss'))}'
                                                : AppHelper.formatTime(AppHelper
                                                    .formatDateTimeFromEpoch(
                                                        message.mScheduledAt!,
                                                        'yyyy-MM-dd HH:mm:ss'))
                                            : message.mMessageType != '0'
                                                ? '    ${AppHelper.formatSentTime(message)}'
                                                : AppHelper.formatSentTime(
                                                    message),
                                        style: AppTextStyles.chatTime.copyWith(
                                            color: CustomColor.kTextTertiary),
                                      )
                                    ],
                                  ),
                                ),
                              ]),
                        ),
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
