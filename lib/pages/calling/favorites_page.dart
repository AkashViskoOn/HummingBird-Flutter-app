import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:humming_bird/components/common/common_app_bar.dart';
import 'package:humming_bird/components/common/app_empty_state.dart';
import 'package:humming_bird/components/common/entrance.dart';
import 'package:humming_bird/controllers/call_controller.dart';
import 'package:humming_bird/res/app_assets.dart';
import 'package:humming_bird/res/colors.dart';
import 'package:humming_bird/res/endpoints.dart';
import 'package:humming_bird/theme/app_text_styles.dart';
import 'package:humming_bird/theme/app_radius.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CallController>();

    return Scaffold(

      appBar: CommonAppBar(title: 'Favorite Contacts'),
      body: Obx(() {
        if (controller.favoriteContacts.isEmpty) {
          return _buildEmptyState();
        }
        return RefreshIndicator(
          onRefresh: controller.loadFavorites,
          child: GridView.builder(
            padding: EdgeInsets.all(16.r),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.85,
            ),
            itemCount: controller.favoriteContacts.length,
            itemBuilder: (_, i) {
              final contact = controller.favoriteContacts[i];
              return Entrance(
                delayFactor: (i % 8) * 0.05,
                child: _FavoriteContactCard(
                  contact: contact,
                  onTap: () => _showCallOptions(contact),
                  onLongPress: () => _removeFavorite(controller, contact),
                ),
              );
            },
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return const AppEmptyState(
      icon: Icons.star_border_rounded,
      title: 'No favorite contacts',
      message: 'Long press a contact in chat to add',
    );
  }

  void _showCallOptions(Map<String, dynamic> contact) {
    final id = contact['contactId']?.toString() ?? '';
    final name = contact['contactName']?.toString() ?? 'Contact';
    if (id.isEmpty) return;

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        decoration: BoxDecoration(
          color: CustomColor.kDarkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: CustomColor.kTextOnDark.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadius.xxs.r),
                ),
              ),
              SizedBox(height: 20.h),
              CircleAvatar(
                radius: 32.r,
                backgroundColor:
                    CustomColor.kPrimaryColor.withValues(alpha: 0.2),
              ),
              SizedBox(height: 12.h),
              Text(
                name,
                style: AppTextStyles.headingMd
                    .copyWith(color: CustomColor.kTextOnDark),
              ),
              SizedBox(height: 24.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _FavOptionButton(
                    icon: Icons.phone_rounded,
                    label: 'Audio Call',
                    onTap: () {
                      Get.back();
                      Get.find<CallController>().initCall(id, 'audio');
                    },
                  ),
                  _FavOptionButton(
                    icon: Icons.videocam_rounded,
                    label: 'Video Call',
                    onTap: () {
                      Get.back();
                      Get.find<CallController>().initCall(id, 'video');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeFavorite(
      CallController controller, Map<String, dynamic> contact) {
    final id = contact['contactId']?.toString() ?? '';
    final name = contact['contactName']?.toString() ?? '';
    if (id.isEmpty) return;

    Get.dialog(
      AlertDialog(
        backgroundColor: CustomColor.kDarkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xxxl.r),
        ),
        title: Text(
          'Remove from favorites?',
          style: GoogleFonts.poppins(
            color: CustomColor.kTextOnDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Remove $name from your favorite contacts?',
          style: GoogleFonts.poppins(color: CustomColor.kOverlay70),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('Cancel',
                style: GoogleFonts.poppins(color: CustomColor.kOverlay60)),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              controller.toggleFavorite(id, name, '');
            },
            child: Text('Remove',
                style: GoogleFonts.poppins(
                    color: CustomColor.dangerTextFor(Get.isDarkMode))),
          ),
        ],
      ),
    );
  }
}

class _FavoriteContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FavoriteContactCard({
    required this.contact,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final name = contact['contactName']?.toString() ?? '';
    final image = contact['contactImage']?.toString() ?? '';

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        padding: EdgeInsets.all(12.r),
        decoration: BoxDecoration(
          color: CustomColor.kCardBackground,
          borderRadius: BorderRadius.circular(AppRadius.xxl.r),
          border: Border.all(
            color: CustomColor.kLightBorder.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor:
                      CustomColor.kPrimaryColor.withValues(alpha: 0.1),
                  backgroundImage: image.isNotEmpty
                      ? CachedNetworkImageProvider(image.startsWith('http')
                          ? image
                          : '${Endpoints.mediaBaseUrl}$image')
                      : const AssetImage(AppAssets.defaultProfilePic)
                          as ImageProvider,
                  onBackgroundImageError: (_, __) {},
                ),
                Positioned(
                  top: 0.h,
                  right: 0.w,
                  child: Icon(
                    Icons.star_rounded,
                    color: CustomColor.kGoldAccent,
                    size: 16.r,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm
                  .copyWith(color: CustomColor.kTextPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavOptionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FavOptionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: CustomColor.kPrimaryColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: CustomColor.kPrimaryColor, size: 24.r),
          ),
          SizedBox(height: 8.h),
          Text(
            label,
            style: AppTextStyles.bodySm.copyWith(
                color: CustomColor.kTextOnDark.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}
