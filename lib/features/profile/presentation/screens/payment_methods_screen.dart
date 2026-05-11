import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'package:selcom_rides_frontend/core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../domain/entities/payment_card.dart';
import '../controllers/payment_methods_controller.dart';
import '../widgets/wallet_summary_card.dart';

class PaymentMethodsScreen extends StatelessWidget {
  const PaymentMethodsScreen({super.key});

  static const PaymentCard _activeCard = PaymentCard(
    brand: 'VISA',
    fullNumber: '4233 5054 0234 1920',
    expiry: '09/26',
    cvv: '123',
    nickName: 'John deo',
  );

  static const PaymentCard _expiredCard = PaymentCard(
    brand: 'VISA',
    fullNumber: '4233 5054 0234 5455',
    expiry: '08/21',
    cvv: '123',
    nickName: 'John deo',
    isExpired: true,
  );

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PaymentMethodsController());

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppProfileHeader(
              title: AppStrings.payment.tr,
              onBack: controller.handleBack,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Obx(
                  () => WalletSummaryCard(
                    balance: controller.walletBalance.value,
                    walletNumber: controller.walletNumber.value,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Payment methods section
                  _buildSectionTitle('Payment methods'),
                  SizedBox(height: 8.h),
                  Obx(() => _buildSelcomPesaCard(controller)),
                  SizedBox(height: 14.h),
                  // Cards section
                  _buildSectionTitle('Cards'),
                  SizedBox(height: 8.h),
                  _buildCardsSection(controller),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.sectionTitle.copyWith(
        color: AppColors.textBody,
        fontWeight: FontWeight.w500,
        fontSize: 15.sp,
        height: 20 / 15,
      ),
    );
  }

  Widget _buildSelcomPesaCard(PaymentMethodsController controller) {
    bool isLinked = controller.isSelcomPesaLinked.value;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 17.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: InkWell(
        onTap: isLinked
            ? controller.openLinkedAccountSheet
            : controller.linkSelcomPesa,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  AppStrings.selcomPesa.tr,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: AppColors.black,
                    height: 20 / 15,
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
                      color: AppColors.textVerified,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      AppStrings.defaultLabel.tr,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
                if (isLinked) ...[
                  const Spacer(),
                  Icon(
                    Iconsax.arrow_right_3,
                    size: 20.w,
                    color: AppColors.textBody.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
            SizedBox(height: 5.h),
            Text(
              isLinked
                  ? 'Linked number +255 711 410 410'
                  : 'Connect your Selcom Pesa account to enable automatic, seamless ride charge deductions.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textBody,
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
                height: 20 / 12,
              ),
            ),
            if (!isLinked) ...[
              SizedBox(height: 5.h),
              Text(
                AppStrings.linkAccount.tr,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: 15.sp,
                  height: 20 / 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCardsSection(PaymentMethodsController controller) {
    return Container(
      padding: EdgeInsets.fromLTRB(10.w, 19.h, 10.w, 0.h),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        border: Border.all(color: AppColors.borderWalletCard, width: 0.8),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          _buildCardTile(
            icon: Icons.credit_card, // Replace with Visa icon if available
            brand: _activeCard.brand,
            number: _activeCard.maskedNumber,
            onTap: () => controller.openCardDetails(_activeCard),
          ),
          _buildCardTile(
            icon: Icons.credit_card,
            brand: _activeCard.brand,
            name: _activeCard.nickName,
            number: _activeCard.maskedNumber,
            onTap: () => controller.openCardDetails(_activeCard),
          ),
          _buildCardTile(
            icon: Icons.credit_card,
            brand: _expiredCard.brand,
            number: _expiredCard.maskedNumber,
            status: 'Expired',
            onTap: () => controller.openCardDetails(_expiredCard),
            showDivider: false,
          ),
          const Divider(color: AppColors.borderWalletCard, height: 1),
          _buildAddCardTile(controller),
        ],
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
            padding: EdgeInsets.only(top: 2.h, left: 8.w, right: 2.w),
            child: Row(
              children: [
                // Visa Logo placeholder
                Text(
                  brand,
                  style: TextStyle(
                    color: AppColors.textBrandVisaSecondary,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    fontSize: 16.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                if (name != null) ...[
                  Text(
                    name,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: status == 'Expired'
                          ? AppColors.textBody
                          : AppColors.textHeading,
                    ),
                  ),
                  SizedBox(width: 8.w),
                ],
                Text(
                  number,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 15.h,
                    fontWeight: FontWeight.w500,
                    color: status == 'Expired'
                        ? AppColors.textBody
                        : AppColors.textHeading,
                  ),
                ),
                if (status != null) ...[
                  SizedBox(width: 8.w),
                  Text(
                    status,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w500,
                      color: status == 'Expired'
                          ? AppColors.textBody
                          : AppColors.textHeading,
                    ),
                  ),
                ],
                const Spacer(),
                Icon(
                  Iconsax.arrow_right_3,
                  size: 20.w,
                  color: AppColors.textBody.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
          SizedBox(height: 15.h),
          if (showDivider) ...[
            const Divider(color: AppColors.borderWalletCard, height: 1),
            SizedBox(height: 18.h),
          ],
        ],
      ),
    );
  }

  Widget _buildAddCardTile(PaymentMethodsController controller) {
    return InkWell(
      onTap: controller.addCard,
      child: Padding(
        padding: EdgeInsets.only(bottom: 16.h, top: 14.h, left: 4.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.primary, size: 24.w),
            SizedBox(width: 4.w),
            Text(
              AppStrings.addDebitCreditCard.tr,
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontSize: 15.h,
                fontWeight: FontWeight.w500,
                height: 20 / 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
