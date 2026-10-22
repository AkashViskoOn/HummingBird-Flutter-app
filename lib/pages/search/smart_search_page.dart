import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:humming_bird/apis/api_service/api_service.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/loading/custom_loading.dart';
import 'package:humming_bird/controllers/chat_controller.dart';
import 'package:humming_bird/controllers/contact_controller.dart';
import 'package:humming_bird/pages/chats/chat_screens/chat_screen.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class SmartSearchPage extends StatefulWidget {
  const SmartSearchPage({super.key});

  @override
  State<SmartSearchPage> createState() => _SmartSearchPageState();
}

class _SmartSearchPageState extends State<SmartSearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ChatController _chatController = Get.find();
  final ContactController _contactController = Get.find();
  final FocusNode _focusNode = FocusNode();
  final RxList<Map<String, dynamic>> _results = <Map<String, dynamic>>[].obs;
  final RxBool _isSearching = false.obs;

  final List<String> _quickSuggestions = [
    'recent messages',
    'unread messages',
    'messages with photos',
    'messages with links',
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      _results.value = [];
      return;
    }
    _isSearching.value = true;
    try {
      final res = await ApiService().getData(
        path: Endpoints.aiSmartSearch,
        queryParameters: {'query': query.trim()},
      );
      if (res['status'] == true && res['data'] != null) {
        _results.value = List<Map<String, dynamic>>.from(res['data']);
      } else {
        _localSearch(query.trim());
      }
    } catch (_) {
      _localSearch(query.trim());
    }
    _isSearching.value = false;
  }

  void _localSearch(String query) {
    final lower = query.toLowerCase();
    final allMessages = _chatController.messages.where((m) {
      return (m.mMessage?.toLowerCase().contains(lower) ?? false);
    }).toList();
    _results.value = allMessages
        .map((m) => {
              'm_id': m.mId,
              'm_message': m.mMessage,
              'm_created_at': m.mCreatedAt,
              'm_sender_id': m.mSenderId,
              'm_room_id': m.mRoomId,
              'relevance': 'high',
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: CommonAppBar(title: 'Smart Search'),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
            color: CustomColor.kWhite,
            child: Container(
              decoration: BoxDecoration(
                color: CustomColor.kUltraLightBg,
                borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                border: Border.all(color: CustomColor.kLightBorder),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _focusNode,
                style: AppTextStyles.bodyMd
                    .copyWith(color: CustomColor.kTextPrimary),
                decoration: InputDecoration(
                  hintText: 'Search messages, people…',
                  hintStyle: AppTextStyles.bodyMd
                      .copyWith(color: CustomColor.kTextTertiary),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: CustomColor.kTextTertiary, size: 20.r),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'Close',
                          onPressed: () {
                            _searchController.clear();
                            _results.value = [];
                          },
                          icon: Icon(Icons.close_rounded,
                              color: CustomColor.kTextTertiary, size: 18.r),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                ),
                onChanged: (val) {
                  setState(() {});
                  _performSearch(val);
                },
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              if (_isSearching.value) {
                return const CustomLoading();
              }
              if (_results.isEmpty && _searchController.text.isNotEmpty) {
                return const AppEmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No results found',
                  message: 'Try a different search term.',
                );
              }
              if (_results.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Suggestions',
                        style: AppTextStyles.subtitle
                            .copyWith(color: CustomColor.kTextTertiary),
                      ),
                      SizedBox(height: 12.h),
                      ..._quickSuggestions.map((s) => InkWell(
                            onTap: () {
                              _searchController.text = s;
                              _performSearch(s);
                            },
                            borderRadius: BorderRadius.circular(AppRadius.xl.r),
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 10.h),
                              child: Row(
                                children: [
                                  Icon(Icons.trending_up_rounded,
                                      size: 18.r,
                                      color: CustomColor.kPrimaryColor),
                                  SizedBox(width: 10.w),
                                  Text(
                                    s,
                                    style: AppTextStyles.bodyMd.copyWith(
                                        color: CustomColor.kTextPrimary),
                                  ),
                                ],
                              ),
                            ),
                          )),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: EdgeInsets.fromLTRB(16.w, 16.w, 16.w,
                    16.w + MediaQuery.of(context).padding.bottom),
                itemCount: _results.length,
                itemBuilder: (_, index) {
                  final item = _results[index];
                  return Entrance(
                      delayFactor: (index % 8) * 0.05,
                      child: _ResultCard(
                        message: item['m_message']?.toString() ?? '',
                        senderId: item['m_sender_id']?.toString() ?? '',
                        roomId: item['m_room_id']?.toString() ?? '',
                        createdAt: item['m_created_at']?.toString() ?? '',
                        relevance: item['relevance']?.toString() ?? 'medium',
                        onTap: () {
                          _chatController.fetchMessages(
                            item['m_room_id']?.toString() ?? '',
                            item['m_sender_id']?.toString() ?? '',
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                name: _contactController.getUserNameById(
                                    item['m_sender_id']?.toString() ?? ''),
                                roomId: item['m_room_id']?.toString() ?? '',
                                receiverId:
                                    item['m_sender_id']?.toString() ?? '',
                              ),
                            ),
                          );
                        },
                      ));
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String message;
  final String senderId;
  final String roomId;
  final String createdAt;
  final String relevance;
  final VoidCallback onTap;

  const _ResultCard({
    required this.message,
    required this.senderId,
    required this.roomId,
    required this.createdAt,
    required this.relevance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final contactController = Get.find<ContactController>();
    final senderName = contactController.getUserNameById(senderId);
    final relevanceColor = relevance == 'high'
        ? CustomColor.kSuccess
        : relevance == 'medium'
            ? CustomColor.kGoldAccent
            : CustomColor.kTextTertiary;

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        child: Container(
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: CustomColor.kWhite,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            border: Border.all(
                color: CustomColor.kLightBorder.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: CustomColor.kPrimaryColor.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22.r,
                backgroundImage: const AssetImage(AppAssets.defaultProfilePic)
                    as ImageProvider,
                backgroundColor: CustomColor.kPrimaryLight,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            senderName,
                            style: AppTextStyles.subtitle
                                .copyWith(color: CustomColor.kTextPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: relevanceColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.sm.r),
                          ),
                          child: Text(
                            relevance.toUpperCase(),
                            style: AppTextStyles.labelSm
                                .copyWith(color: relevanceColor),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.subtitle
                          .copyWith(color: CustomColor.kTextSecondary),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      _formatDate(createdAt),
                      style: AppTextStyles.labelSm
                          .copyWith(color: CustomColor.kTextTertiary),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Icon(Icons.chevron_right_rounded,
                  color: CustomColor.kTextTertiary, size: 18.r),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String date) {
    if (date.isEmpty) return '';
    try {
      final parsed = DateTime.parse(date);
      final now = DateTime.now();
      if (parsed.day == now.day &&
          parsed.month == now.month &&
          parsed.year == now.year) {
        return 'Today';
      }
      final yesterday = now.subtract(const Duration(days: 1));
      if (parsed.day == yesterday.day &&
          parsed.month == yesterday.month &&
          parsed.year == yesterday.year) {
        return 'Yesterday';
      }
      return '${parsed.day}/${parsed.month}/${parsed.year}';
    } catch (_) {
      return date;
    }
  }
}
