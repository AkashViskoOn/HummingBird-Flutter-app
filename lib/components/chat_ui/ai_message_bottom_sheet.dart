import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/button/app_button.dart';
import 'package:humming_bird/components/common/common_textfield.dart';
import 'package:humming_bird/components/schedule/schedule_bottom_sheet.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:lottie/lottie.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class AiMessageBottomSheet extends StatefulWidget {
  const AiMessageBottomSheet({super.key});

  @override
  State<AiMessageBottomSheet> createState() => _AiMessageBottomSheetState();
}

class _AiMessageBottomSheetState extends State<AiMessageBottomSheet> {
  @override
  void initState() {
    chatController.promptController = TextEditingController();
    chatController.aiMessageController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
    });
    super.initState();
  }

  @override
  void dispose() {
    chatController.promptController.dispose();
    chatController.aiMessageController.dispose();
    super.dispose();
  }

  ChatController chatController = Get.find();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) {
        chatController.generatingMessage.value = false;
        chatController.generatedMessage.value = '';
      },
      child: SafeArea(
        bottom: true,
        child: BottomSheet(
          enableDrag: false,
          onClosing: () {},
          builder: (context) {
            return Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(
                      height: 15.h,
                    ),
                    Text(
                      'Generate Message with AI',
                      style: AppTextStyles.headingLg
                          .copyWith(color: CustomColor.kTextPrimary),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    CommonTextField(
                      controller: chatController.promptController,
                      hintText: 'Enter what you want to generate...',
                      bgColor: CustomColor.kTextOnDark,
                      suffixIcon: InkWell(
                        onTap: () {
                          chatController.generateMessageWithAi();
                          FocusScope.of(context).unfocus();
                        },
                        child: const Icon(
                          Icons.send,
                          color: CustomColor.kPrimaryColor,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 18.h,
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'Generate custom message with the power of AI',
                        style: AppTextStyles.headingSm
                            .copyWith(color: CustomColor.kTextSecondary),
                      ),
                    ),
                    SizedBox(
                      height: 15.h,
                    ),
                    Obx(
                      () => chatController.generatingMessage.value
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Generating message for you',
                                  style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.w500,
                                      color: CustomColor.kDarkPrimaryColor),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    Obx(
                      () => chatController.generatingMessage.value ||
                              chatController.generatedMessage.value.isEmpty
                          ? LottieBuilder.asset(
                              AppAssets.aiLoading,
                              height: Get.height * 0.25,
                              animate: chatController.generatingMessage.value,
                              fit: BoxFit.fill,
                            )
                          : Container(
                              padding: EdgeInsets.all(15.r),
                              decoration: BoxDecoration(
                                  color: CustomColor.kPrimaryLight,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.xxxl.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: CustomColor.kPrimaryColor
                                          .withValues(alpha: 0.08),
                                      blurRadius: 8.r,
                                      offset: Offset(0, 2.h),
                                    ),
                                  ]),
                              child: TextField(
                                controller: chatController.aiMessageController
                                  ..text =
                                      chatController.generatedMessage.value,
                                minLines: 1,
                                maxLines: 10,
                                decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppRadius.fifteen.r),
                                        borderSide: const BorderSide(
                                            color: Colors.grey))),
                              ),
                            ),
                    ),
                    SizedBox(
                      height: 20.h,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AppButton(
                          text: 'Schedule',
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              builder: (context) {
                                return const ScheduleBottomSheet(
                                  generatedMessage: true,
                                );
                              },
                            );
                          },
                          backgroundColor: CustomColor.kPrimaryFill,
                          buttonSize: Size(Get.width * 0.4, 45.h),
                          fontColor: CustomColor.kTextOnDark,
                        ),
                        AppButton(
                          text: 'Send',
                          onTap: () {
                            chatController.sendMessage(
                                aiGenerated: true,
                                generatedMessage: chatController
                                    .aiMessageController.text
                                    .trim());
                          },
                          backgroundColor: CustomColor.kPrimaryFill,
                          buttonSize: Size(Get.width * 0.4, 45.h),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
