import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/components/utilities/utils.dart';
import 'package:humming_bird/controllers/bird_controller.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';

class ScheduleTemplatesPage extends StatefulWidget {
  const ScheduleTemplatesPage({super.key});

  @override
  State<ScheduleTemplatesPage> createState() => _ScheduleTemplatesPageState();
}

class _ScheduleTemplatesPageState extends State<ScheduleTemplatesPage> {
  late BirdController _birdController;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _surface2 =>
      _isDark ? CustomColor.kDarkSurface2 : CustomColor.kUltraLightPrimary;
  Color get _input =>
      _isDark ? CustomColor.kDarkInputFill : CustomColor.kTextOnDark;
  Color get _border =>
      _isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
  Color get _text1 =>
      _isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
  Color get _text2 =>
      _isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
  Color get _text3 =>
      _isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;

  @override
  void initState() {
    super.initState();
    _birdController = Get.find();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _birdController.loadTemplates();
    });
  }

  void _showCreateTemplateSheet() {
    final nameController = TextEditingController();
    final messageController = TextEditingController();
    String selectedCategory = 'reminder';

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                24.w, 12.h, 24.w, MediaQuery.of(ctx).viewInsets.bottom + 32.h),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: _border,
                      borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        gradient: CustomColor.primaryGradient,
                        borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      ),
                      child: Icon(Icons.bookmark_add_rounded,
                          color: CustomColor.kTextOnDark, size: 20.r),
                    ),
                    SizedBox(width: 12.w),
                    Text(
                      'New Template',
                      style: AppTextStyles.headingMd.copyWith(color: _text1),
                    ),
                  ],
                ),
                SizedBox(height: 20.h),
                TextField(
                  controller: nameController,
                  style: AppTextStyles.bodyMd.copyWith(color: _text1),
                  decoration: InputDecoration(
                    labelText: 'Template Name',
                    labelStyle: AppTextStyles.subtitle.copyWith(color: _text3),
                    filled: true,
                    fillColor: _input,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                      borderSide: BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                      borderSide: BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                      borderSide: BorderSide(
                          color: CustomColor.kPrimaryColor, width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                TextField(
                  controller: messageController,
                  maxLines: 3,
                  style: AppTextStyles.bodyMd.copyWith(color: _text1),
                  decoration: InputDecoration(
                    labelText: 'Message',
                    labelStyle: AppTextStyles.subtitle.copyWith(color: _text3),
                    filled: true,
                    fillColor: _input,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                      borderSide: BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                      borderSide: BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                      borderSide: BorderSide(
                          color: CustomColor.kPrimaryColor, width: 1.5),
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Category',
                  style: AppTextStyles.label.copyWith(color: _text2),
                ),
                SizedBox(height: 8.h),
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    'birthday',
                    'anniversary',
                    'reminder',
                    'meeting',
                    'follow-up',
                    'greeting',
                    'custom'
                  ].map((cat) {
                    final isSelected = selectedCategory == cat;
                    return ChoiceChip(
                      label: Text(
                        cat,
                        style: AppTextStyles.bodySm.copyWith(
                            color:
                                isSelected ? CustomColor.kTextOnDark : _text1),
                      ),
                      selected: isSelected,
                      selectedColor: CustomColor.kPrimaryFill,
                      backgroundColor: _surface2,
                      onSelected: (_) =>
                          setSheetState(() => selectedCategory = cat),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.lg.r),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 20.h),
                SizedBox(
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: CustomColor.primaryGradient,
                      borderRadius: BorderRadius.circular(AppRadius.xl.r),
                      boxShadow: [
                        BoxShadow(
                          color:
                              CustomColor.kPrimaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: FilledButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final msg = messageController.text.trim();
                        if (name.isEmpty || msg.isEmpty) {
                          Utils.showGetSnackBar('Please fill in all fields');
                          return;
                        }
                        _birdController.saveTemplate({
                          'template_name': name,
                          'message': msg,
                          'category': selectedCategory,
                        });
                        Get.back();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl.r),
                        ),
                      ),
                      child: Text(
                        'Save Template',
                        style: AppTextStyles.titleMd
                            .copyWith(color: CustomColor.kTextOnDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'birthday':
        return CustomColor.kWarning;
      case 'anniversary':
        return CustomColor.kBrandPink;
      case 'reminder':
        return CustomColor.kInfo;
      case 'meeting':
        return CustomColor.kBrandPurple;
      case 'follow-up':
        return const Color(0xffF97316);
      case 'greeting':
        return CustomColor.kInfo;
      default:
        return CustomColor.kPrimaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isDark
          ? CustomColor.kDarkBackground
          : CustomColor.kUltraLightPrimary,
      appBar: CommonAppBar(
        title: 'Schedule Templates',
        backgroundColor: CustomColor.kPrimaryFill,
        actions: [
          IconButton(
            tooltip: 'Create template',
            onPressed: _showCreateTemplateSheet,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: Obx(
        () => _birdController.scheduleTemplates.isEmpty
            ? AppEmptyState(
                icon: Icons.bookmark_outline_rounded,
                title: 'No templates yet',
                message:
                    'Create reusable message templates for quick scheduling.',
                actionLabel: 'Create Template',
                onAction: _showCreateTemplateSheet,
              )
            : RefreshIndicator(
                color: CustomColor.kPrimaryColor,
                onRefresh: _birdController.loadTemplates,
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 96.h),
                  itemCount: _birdController.scheduleTemplates.length,
                  itemBuilder: (context, index) {
                    final template = _birdController.scheduleTemplates[index];
                    return Entrance(
                      delayFactor: (index % 8) * 0.05,
                      child: _TemplateCard(
                        template: template,
                        categoryColor: _categoryColor(
                            template['category']?.toString() ?? ''),
                        onTap: () {
                          Get.back(result: {
                            'message': template['message'],
                            'category': template['category'],
                          });
                        },
                        onDelete: () => _birdController
                            .deleteTemplate(template['id']?.toString() ?? ''),
                      ),
                    );
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTemplateSheet,
        backgroundColor: CustomColor.kPrimaryColor,
        foregroundColor: CustomColor.kTextOnDark,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final Map<String, dynamic> template;
  final Color categoryColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TemplateCard({
    required this.template,
    required this.categoryColor,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? CustomColor.kDarkSurface : CustomColor.kTextOnDark;
    final border = isDark ? CustomColor.kDarkBorder : CustomColor.kLightBorder;
    final text1 = isDark ? CustomColor.kTextOnDark : CustomColor.kTextPrimary;
    final text2 =
        isDark ? CustomColor.kTextOnDarkSecondary : CustomColor.kTextSecondary;
    final text3 =
        isDark ? CustomColor.kTextOnDarkMuted : CustomColor.kTextTertiary;
    return Dismissible(
      key: Key(template['id']?.toString() ?? ''),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        return await showAdaptiveDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete template?',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            content:
                Text('This cannot be undone.', style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text('Delete',
                      style: GoogleFonts.poppins(
                          color: CustomColor.dangerTextFor(
                              Theme.of(context).brightness ==
                                  Brightness.dark)))),
            ],
          ),
        );
      },
      onDismissed: (_) => onDelete(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        margin: EdgeInsets.only(bottom: 10.h),
        decoration: BoxDecoration(
          color: CustomColor.kDangerRed,
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        ),
        child: Icon(Icons.delete_rounded,
            color: CustomColor.kTextOnDark, size: 24.r),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xxl.r),
        child: Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.all(14.r),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(AppRadius.xxl.r),
            border: Border.all(color: border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      categoryColor,
                      categoryColor.withValues(alpha: 0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.fourteen.r),
                ),
                child: Icon(
                  Icons.bookmark_rounded,
                  color: CustomColor.kTextOnDark,
                  size: 21.r,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template['template_name']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMd.copyWith(color: text1),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      template['message']?.toString() ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySm.copyWith(color: text2),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                      decoration: BoxDecoration(
                        color: categoryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppRadius.sm.r),
                      ),
                      child: Text(
                        template['category']?.toString() ?? '',
                        style: AppTextStyles.labelSm
                            .copyWith(color: categoryColor),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: text3, size: 20.r),
            ],
          ),
        ),
      ),
    );
  }
}
