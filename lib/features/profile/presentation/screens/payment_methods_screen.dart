import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../controllers/payment_methods_controller.dart';
import '../widgets/wallet_summary_card.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentMethodsController());

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppProfileHeader(title: 'Payment', onBack: controller.handleBack),
            SizedBox(height: 24.h),

            // Wallet Card
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Obx(
                () => WalletSummaryCard(
                  balance: controller.walletBalance.value,
                  walletNumber: controller.walletNumber.value,
                ),
              ),
            ),

            SizedBox(height: 32.h),

            // Payment methods section
            _buildSectionTitle('Payment methods'),
            SizedBox(height: 12.h),
            Obx(() => _buildSelcomPesaCard(controller)),

            SizedBox(height: 32.h),

            // Cards section
            _buildSectionTitle('Cards'),
            SizedBox(height: 12.h),
            _buildCardsSection(controller),

            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Text(
        title,
        style: AppTextStyles.sectionTitle.copyWith(
          color: AppColors.shade2,
          fontSize: 15.sp,
        ),
      ),
    );
  }

  Widget _buildSelcomPesaCard(PaymentMethodsController controller) {
    bool isLinked = controller.isSelcomPesaLinked.value;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          border: Border.all(color: const Color(0xFFE6E9EE), width: 0.8),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: InkWell(
          onTap: isLinked ? null : controller.linkSelcomPesa,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Selcom Pesa',
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.shade1,
                    ),
                  ),
                  if (isLinked) ...[
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        'Default',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 20.w,
                    color: AppColors.shade2.withOpacity(0.5),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Text(
                isLinked
                    ? 'Linked number +255 711 410 410'
                    : 'Connect your Selcom Pesa account to enable automatic, seamless ride charge deductions.',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.shade2,
                  fontSize: 13.sp,
                  height: 1.5,
                ),
              ),
              if (!isLinked) ...[
                SizedBox(height: 12.h),
                Text(
                  'Link Account',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardsSection(PaymentMethodsController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FD),
          border: Border.all(color: const Color(0xFFE6E9EE), width: 0.8),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          children: [
            _buildCardTile(
              icon: Icons.credit_card, // Replace with Visa icon if available
              brand: 'VISA',
              number: '**** 2232',
              onTap: () {},
            ),
            _buildCardTile(
              icon: Icons.credit_card,
              brand: 'VISA',
              name: 'John deo',
              number: '**** 2232',
              onTap: () {},
            ),
            _buildCardTile(
              icon: Icons.credit_card,
              brand: 'VISA',
              number: '**** 5455',
              status: 'Expired',
              onTap: () {},
              showDivider: false,
            ),
            Divider(color: const Color(0xFFE6E9EE), height: 1),
            _buildAddCardTile(controller),
          ],
        ),
      ),
    );
  }

  Widget _buildCardTile({
    required IconData icon,
    required String brand,
    String? name,
    required String number,
    String? status,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
            child: Row(
              children: [
                // Visa Logo placeholder
                Row(
                  children: [
                    Text(
                      brand,
                      style: TextStyle(
                        color: const Color(0xFF00579F),
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(width: 12.w),
                  ],
                ),
                if (name != null) ...[
                  Text(
                    name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: status == 'Expired'
                          ? AppColors.shade2
                          : AppColors.shade1,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  number,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w500,
                    color: status == 'Expired'
                        ? AppColors.shade2
                        : AppColors.shade1,
                  ),
                ),
                if (status != null) ...[
                  SizedBox(width: 8.w),
                  Text(
                    status,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: status == 'Expired'
                          ? AppColors.shade2
                          : AppColors.shade1,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 20.w,
                  color: AppColors.shade2.withOpacity(0.5),
                ),
              ],
            ),
          ),
          if (showDivider)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Divider(color: const Color(0xFFE6E9EE), height: 1),
            ),
        ],
      ),
    );
  }

  Widget _buildAddCardTile(PaymentMethodsController controller) {
    return InkWell(
      onTap: controller.addCard,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
        child: Row(
          children: [
            Icon(Icons.add, color: AppColors.primary, size: 24.w),
            SizedBox(width: 12.w),
            Text(
              'Add debit/credit card',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
