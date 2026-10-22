import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class AiChatbotPage extends StatefulWidget {
  const AiChatbotPage({super.key});

  @override
  State<AiChatbotPage> createState() => _AiChatbotPageState();
}

class _AiChatbotPageState extends State<AiChatbotPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  final RxBool _isTyping = false.obs;
  final FocusNode _focusNode = FocusNode();

  final List<String> _suggestedPrompts = [
    'Help me write a birthday message',
    'Suggest a follow-up message for work',
    'What should I reply to this?',
    'Remind me about my meeting tomorrow',
    'Translate "Hello" in Spanish',
    'Summarize my conversation',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
    });
    _messageController.clear();
    _scrollToBottom();
    _isTyping.value = true;
    _getAiResponse(text);
  }

  Future<void> _getAiResponse(String message) async {
    try {
      final geminiRes = await ApiService().post(
        path: Endpoints.aiGeminiMessage,
        data: {'prompt': message},
      );
      final geminiText =
          geminiRes['message']?.toString() ?? geminiRes['data']?.toString();
      if (geminiRes['status'] == true &&
          geminiText != null &&
          geminiText.isNotEmpty) {
        setState(() {
          _messages.add(_ChatMessage(text: geminiText, isUser: false));
        });
        _isTyping.value = false;
        _scrollToBottom();
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AiChatbot] Gemini endpoint failed: $e');
      }
    }

    try {
      final res = await ApiService().post(
        path: Endpoints.aiChatbot,
        data: {'message': message},
      );
      final data = res['data'];
      String reply;
      if (data is Map<String, dynamic> && data['response'] != null) {
        reply = data['response'].toString();
      } else {
        reply = res['message']?.toString() ??
            'Unable to generate response. Please try again.';
      }
      setState(() {
        _messages.add(_ChatMessage(text: reply, isUser: false));
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AiChatbot] Chatbot fallback failed: $e');
      }
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Unable to generate response. Please try again.',
          isUser: false,
        ));
      });
    }
    _isTyping.value = false;
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(
        title: '',
        backgroundColor: CustomColor.kWhite,
        titleWidget: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    CustomColor.kPrimaryColor,
                    CustomColor.kPrimaryMedium
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 18.r,
                backgroundColor: CustomColor.kWhite,
                child: Icon(Icons.auto_awesome_rounded,
                    size: 18.r, color: CustomColor.kPrimaryText),
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Assistant',
                  style: AppTextStyles.headingSm
                      .copyWith(color: CustomColor.kTextPrimary),
                ),
                // Accent-as-text on a white bar: the -Text ramp, not the
                // identity accents, which sat at 3.36 and 2.24:1 here.
                Obx(() => Text(
                      _isTyping.value ? 'Typing...' : 'Online',
                      style: AppTextStyles.error.copyWith(
                          color: _isTyping.value
                              ? CustomColor.kPrimaryText
                              : CustomColor.kSuccessText),
                    )),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: _messages.length,
                    itemBuilder: (_, index) {
                      final msg = _messages[index];
                      return _MessageBubble(message: msg);
                    },
                  ),
          ),
          Obx(() => _isTyping.value
              ? Padding(
                  padding: EdgeInsets.only(left: 16.w, bottom: 4.h),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: CustomColor.kWhite,
                          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                          boxShadow: [
                            BoxShadow(
                              color: CustomColor.kPrimaryColor
                                  .withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8.r,
                              height: 8.r,
                              decoration: const BoxDecoration(
                                color: CustomColor.kPrimaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'AI is thinking...',
                              style: AppTextStyles.bodySm
                                  .copyWith(color: CustomColor.kTextTertiary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink()),
          Container(
            decoration: BoxDecoration(
              color: CustomColor.kWhite,
              boxShadow: [
                BoxShadow(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w,
                  12.h + MediaQuery.of(context).padding.bottom),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _focusNode,
                      cursorColor: CustomColor.kPrimaryMedium,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Ask me anything...',
                        hintStyle: AppTextStyles.bodyMd
                            .copyWith(color: CustomColor.kTextTertiary),
                        filled: true,
                        fillColor: CustomColor.kUltraLightBg,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 12.h),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(_messageController.text),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  InkWell(
                    onTap: () => _sendMessage(_messageController.text),
                    borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                    child: Container(
                      width: 42.r,
                      height: 42.r,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: CustomColor.primaryGradient,
                        borderRadius:
                            BorderRadius.circular(AppRadius.fourteen.r),
                        boxShadow: [
                          BoxShadow(
                            color: CustomColor.kPrimaryColor
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(Icons.send_rounded,
                          size: 20.sp, color: CustomColor.kTextOnDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 40.h),
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: CustomColor.primaryGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: CustomColor.kPrimaryColor.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(Icons.auto_awesome_rounded,
                size: 40.r, color: CustomColor.kTextOnDark),
          ),
          SizedBox(height: 24.h),
          Text(
            'AI Assistant',
            style: AppTextStyles.headingXl
                .copyWith(color: CustomColor.kTextPrimary),
          ),
          SizedBox(height: 8.h),
          Text(
            'Ask me anything! I can help you write messages,\ntranslate, summarize conversations, and more.',
            textAlign: TextAlign.center,
            style: AppTextStyles.subtitle
                .copyWith(color: CustomColor.kTextSecondary, height: 1.5),
          ),
          SizedBox(height: 32.h),
          Text(
            'Try these suggestions',
            style:
                AppTextStyles.bodySm.copyWith(color: CustomColor.kTextTertiary),
          ),
          SizedBox(height: 16.h),
          ...List.generate(_suggestedPrompts.length, (index) {
            final prompt = _suggestedPrompts[index];
            return Padding(
              padding: EdgeInsets.only(bottom: 8.h),
              child: InkWell(
                onTap: () => _sendMessage(prompt),
                borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: CustomColor.kWhite,
                    borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                    border: Border.all(
                        color: CustomColor.kLightBorder.withValues(alpha: 0.6)),
                    boxShadow: [
                      BoxShadow(
                        color:
                            CustomColor.kPrimaryColor.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded,
                          size: 16.r, color: CustomColor.kPrimaryColor),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          prompt,
                          style: AppTextStyles.subtitle
                              .copyWith(color: CustomColor.kTextPrimary),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          size: 16.r, color: CustomColor.kTextTertiary),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  _ChatMessage({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isUser) ...[
            Container(
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                gradient: CustomColor.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 14.r,
                backgroundColor: CustomColor.kWhite,
                child: Icon(Icons.auto_awesome_rounded,
                    size: 14.r, color: CustomColor.kPrimaryColor),
              ),
            ),
            SizedBox(width: 8.w),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                gradient: message.isUser ? CustomColor.primaryGradient : null,
                color: message.isUser ? null : CustomColor.kWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(message.isUser ? 18.r : 5.r),
                  topRight: Radius.circular(message.isUser ? 5.r : 18.r),
                  bottomLeft: Radius.circular(18.r),
                  bottomRight: Radius.circular(18.r),
                ),
                boxShadow: [
                  BoxShadow(
                    color: CustomColor.kPrimaryColor
                        .withValues(alpha: message.isUser ? 0.25 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: AppTextStyles.bodyMd.copyWith(
                    color: message.isUser
                        ? CustomColor.kTextOnDark
                        : CustomColor.kTextPrimary,
                    height: 1.4),
              ),
            ),
          ),
          if (message.isUser) SizedBox(width: 8.w),
        ],
      ),
    );
  }
}
