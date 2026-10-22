import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/common/widgets/message_child_container.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/chat_ui/replied_on_container.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/group_controller.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/theme/app_shadow.dart';
import 'package:humming_bird/theme/app_animation.dart';

class MeMessageContainer extends StatefulWidget {
  final Messages message;
  final bool isGroup;
  final String roomId;
  final String userProfile;
  final UniqueKey uniqueKey;
  const MeMessageContainer(
      {super.key,
      required this.message,
      required this.isGroup,
      required this.roomId,
      required this.userProfile,
      required this.uniqueKey});

  @override
  State<MeMessageContainer> createState() => _MeMessageContainerState();
}

class _MeMessageContainerState extends State<MeMessageContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController animController;
  late Animation<Offset> replyAnimation;
  late Messages message;
  late ChatController chatController;
  late GroupController groupController;

  @override
  void initState() {
    message = widget.message;
    chatController = Get.find();

    if (widget.isGroup) {
      groupController = Get.find();
    }
    animController = AnimationController(
      vsync: this,
      duration: AppAnimation.normal,
    );
    replyAnimation = Tween(
      begin: const Offset(0.0, 0.0),
      end: const Offset(-0.6, 0.0),
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
    final isScheduled = message.isScheduledMessage;
    return InkWell(
      key: widget.uniqueKey,
      onTap: () {
        chatController.manageMessageSelector(message.mId!);
      },
      onLongPress: () {
        chatController.selectMessageOnLongPress(message.mId!);
      },
      child: Obx(
        () => Container(
          color: chatController.messageSelectorMap[message.mId] != true
              ? null
              : CustomColor.kPrimaryColor.withValues(alpha: 0.3),
          padding: EdgeInsets.only(
              left: 60.r,
              right: AppSpacing.lg.r,
              top: AppSpacing.md.r,
              bottom: AppSpacing.md.r),
          alignment: Alignment.centerRight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              message.mRepliedOn != null && !isDeletedMessage
                  ? RepliedOnContainer(messageId: message.mRepliedOn!)
                  : const SizedBox.shrink(),
              GestureDetector(
                onHorizontalDragUpdate: isDeletedMessage
                    ? null
                    : (details) {
                        if (details.primaryDelta! < 0 &&
                            details.primaryDelta! < -3) {
                          animController
                              .forward()
                              .whenComplete(() => animController.reverse());
                          chatController.replyOnMessage(message);
                        }
                      },
                child: SlideTransition(
                  position: replyAnimation,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: AppSpacing.xxl.w),
                        decoration: isScheduled
                            ? BoxDecoration(
                                color: CustomColor.kWarningDark,
                                borderRadius: BorderRadius.only(
                                  bottomLeft:
                                      Radius.circular(AppRadius.rounded.r),
                                  topLeft: Radius.circular(
                                      message.mRepliedOn != null
                                          ? 0
                                          : AppRadius.rounded.r),
                                  bottomRight: Radius.circular(0.r),
                                  topRight:
                                      Radius.circular(AppRadius.rounded.r),
                                ),
                                boxShadow: AppShadow.buttonDark,
                              )
                            : isDeletedMessage || message.mMessageType == '0'
                                ? BoxDecoration(
                                    gradient: CustomColor.sentBubbleGradient,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft:
                                          Radius.circular(AppRadius.rounded.r),
                                      topLeft: Radius.circular(
                                          message.mRepliedOn != null
                                              ? 0
                                              : AppRadius.rounded.r),
                                      bottomRight: Radius.circular(0.r),
                                      topRight:
                                          Radius.circular(AppRadius.rounded.r),
                                    ),
                                    boxShadow: AppShadow.buttonDark,
                                  )
                                : BoxDecoration(
                                    color: CustomColor.kDarkSurface2,
                                    borderRadius: BorderRadius.only(
                                      bottomLeft:
                                          Radius.circular(AppRadius.rounded.r),
                                      topLeft:
                                          Radius.circular(AppRadius.rounded.r),
                                      bottomRight: Radius.circular(0.r),
                                      topRight:
                                          Radius.circular(AppRadius.rounded.r),
                                    ),
                                  ),
                        child: Padding(
                            padding:
                                isDeletedMessage || message.mMessageType == '0'
                                    ? EdgeInsets.only(
                                        left: AppSpacing.lg.r,
                                        right: AppSpacing.lg.r,
                                        top: AppSpacing.xs.r,
                                        bottom: AppSpacing.xs.r)
                                    : EdgeInsets.only(
                                        left: AppSpacing.xxs.w,
                                        right: AppSpacing.xxs.w,
                                        top: AppSpacing.xxs.h,
                                        bottom: 3.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                isDeletedMessage
                                    ? Text(
                                        'You deleted this message',
                                        style: AppTextStyles.bodyLg.copyWith(
                                          color: CustomColor.kOverlay70,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      )
                                    : message.mMessageType == '0'
                                        ? Text(
                                            message.mMessage!,
                                            style: AppTextStyles.bodyLg
                                                .copyWith(
                                                    color: CustomColor
                                                        .kTextOnDark),
                                          )
                                        : AppHelper.checkFileType(
                                            mediaId: message.mId!,
                                            roomId: message.mRoomId!,
                                            mediaUrl:
                                                '${Endpoints.mediaBaseUrl}${message.mMedia}',
                                            fileType: message.mMessageType!,
                                            msg: message.mMessage.toString()),
                                if (isScheduled) _buildScheduledMention(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    message.isScheduledMessage
                                        ? Text(
                                            AppHelper.formatDateTimeFromEpoch(
                                                message.mScheduledAt!,
                                                'dd MMM h:mm a'),
                                            style: AppTextStyles.chatTime
                                                .copyWith(
                                                    color: CustomColor.kWhite),
                                          )
                                        : Text(
                                            AppHelper.formatSentTime(message),
                                            style: AppTextStyles.chatTime
                                                .copyWith(
                                                    color: CustomColor.kWhite),
                                          ),
                                    SizedBox(
                                      width: AppSpacing.xs.w,
                                    ),
                                    AppHelper.checkMessageStatus(
                                        message.mReadStatus.toString(),
                                        color: message.mReadStatus == '3'
                                            ? CustomColor.kSuccessSoft
                                            : CustomColor.kOverlay70),
                                  ],
                                )
                              ],
                            )),
                      ),
                      Positioned(
                          bottom: -15.h,
                          right: 0.w,
                          child: const MessageChildContainer()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The mention that sits inside a scheduled (not-yet-sent) bubble, between the
  /// message content and the time. It names the state, the type of message that
  /// was scheduled and when it will send, so the sender can tell a scheduled
  /// message apart from a normal sent one at a glance.
  Widget _buildScheduledMention() {
    final raw = message.mScheduledAt;
    final when = (raw != null && raw.isNotEmpty && raw != '0')
        ? AppHelper.formatDateTimeFromEpoch(raw, 'dd MMM, h:mm a')
        : '';
    final type = message.mMessageType == '0'
        ? 'Text'
        : AppHelper.getMediaName(fileType: message.mMessageType ?? '')
            .replaceFirst(RegExp(r'^\S+\s'), '');
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.xs.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 10.r,
            color: CustomColor.kWarningSoft,
          ),
          SizedBox(width: 3.w),
          Text(
            'Scheduled · $type${when.isNotEmpty ? ' · $when' : ''}',
            style: AppTextStyles.labelSm.copyWith(
              color: CustomColor.kWarningSoft,
              fontSize: 9.sp,
            ),
          ),
        ],
      ),
    );
  }
}
