import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/components/Models/room_messages_model.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/helper/helper.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_spacing.dart';
import 'package:humming_bird/theme/app_radius.dart';

class ChatMessageSearchPage extends StatefulWidget {
  final String title;

  const ChatMessageSearchPage({super.key, required this.title});

  @override
  State<ChatMessageSearchPage> createState() => _ChatMessageSearchPageState();
}

class _ChatMessageSearchPageState extends State<ChatMessageSearchPage> {
  final ChatController chatController = Get.find();
  final TextEditingController _searchController = TextEditingController();
  List<Messages> _results = [];

  @override
  void initState() {
    super.initState();
    _results = List.from(chatController.messages);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String value) {
    final keyword = value.trim().toLowerCase();
    setState(() {
      _results = chatController.messages.where((message) {
        final text = _preview(message).toLowerCase();
        return keyword.isEmpty ? true : text.contains(keyword);
      }).toList();
    });
  }

  String _preview(Messages message) {
    if (message.mMessageType == '0' || message.mMessageType == '5') {
      return message.mMessage ?? '';
    }
    return AppHelper.getMediaName(fileType: message.mMessageType ?? '0');
  }

  void _openMessage(Messages message) {
    final messageId = message.mId;
    if (messageId == null || messageId.isEmpty) return;
    Get.back();
    Future.delayed(const Duration(milliseconds: 220), () {
      chatController.scrollToMessage(messageId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColor.kUltraLightPrimaryColor,
      appBar: CommonAppBar(title: 'Search messages'),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(AppSpacing.xxl.w, AppSpacing.xl.h,
                  AppSpacing.xxl.w, AppSpacing.lg.h),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                textAlignVertical: TextAlignVertical.center,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'Search in ${widget.title}',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: CustomColor.kTextOnDark,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl.w, vertical: AppSpacing.xl.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _results.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.message_outlined,
                      title: 'No messages found',
                      message: 'No messages in this chat match your search.',
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(AppSpacing.xxl.w, 0,
                          AppSpacing.xxl.w, AppSpacing.xl.h),
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final message = _results[index];
                        return InkWell(
                          onTap: () => _openMessage(message),
                          borderRadius: BorderRadius.circular(AppRadius.xl.r),
                          child: Container(
                            margin: EdgeInsets.only(bottom: AppSpacing.md.h),
                            padding: EdgeInsets.all(AppSpacing.lg.r),
                            decoration: BoxDecoration(
                              color: CustomColor.kTextOnDark,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xl.r),
                              border: Border.all(
                                color: CustomColor.kScrim20,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _preview(message).isEmpty
                                      ? 'Message'
                                      : _preview(message),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMd
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                SizedBox(height: AppSpacing.xs.h),
                                Text(
                                  AppHelper.getTimeStamp(
                                    message.isScheduledMessage
                                        ? AppHelper.formatDateTimeFromEpoch(
                                            message.mScheduledAt ?? '0',
                                            'yyyy-MM-dd HH:mm:ss',
                                          )
                                        : AppHelper.getSentDate(message),
                                  ),
                                  style: AppTextStyles.caption.copyWith(
                                      color: CustomColor.kTextSecondary,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
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
