import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/country_response.dart';
import '../controllers/add_card_controller.dart';

class CountrySelectScreen extends StatefulWidget {
  final List<CountriesResponse> countries;
  final CountriesResponse? selectedCountry;

  const CountrySelectScreen({
    super.key,
    required this.countries,
    this.selectedCountry,
  });

  @override
  State<CountrySelectScreen> createState() => _CountrySelectScreenState();
}

class _CountrySelectScreenState extends State<CountrySelectScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  late final AddCardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AddCardController>();
    controller.fetchCountries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CountriesResponse> get _filteredCountries {
    final query = _searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.countries;
    }
    return widget.countries.where((country) {
      final name = country.name ?? '';
      final code = country.iso2Code ?? '';
      final phone = country.phoneCode ?? '';
      return name.toLowerCase().contains(query) ||
          code.toLowerCase().contains(query) ||
          phone.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AppProfileHeader(
            title: "Select Country",
            onBack: () => Get.back(),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                children: [
                  Obx(
                    () => AppTextField(
                      hintText: "Search by country name or code...",
                      controller: _searchController,
                      onChanged: (val) => _searchQuery.value = val,
                      prefixIcon: Icon(
                        Icons.search,
                        color: AppColors.textHint,
                        size: 22.sp,
                      ),
                      suffixIcon: _searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: AppColors.textHint,
                                size: 20.sp,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _searchQuery.value = '';
                              },
                            )
                          : null,
                      textFieldBackgroundColor: AppColors.pageBackground,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: Obx(
                      () {
                        if (controller.isLoadingCountries.value) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryButton),
                            ),
                          );
                        }

                        final list = _filteredCountries;
                        if (list.isEmpty) {
                          return Center(
                            child: Text(
                              "No countries found",
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: EdgeInsets.only(bottom: 24.h),
                          itemCount: list.length,
                          separatorBuilder: (context, index) => const Divider(
                            color: AppColors.divider,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final country = list[index];
                            final isSelected = widget.selectedCountry?.id == country.id;
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 4.h,
                              ),
                              title: Text(
                                country.name ?? '',
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primaryButton : AppColors.textHeading,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    country.iso2Code ?? '',
                                    style: AppTextStyles.hint.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    SizedBox(width: 8.w),
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryButton,
                                    ),
                                  ],
                                ],
                              ),
                              onTap: () {
                                Get.back(result: country);
                              },
                            );
                          },
                        );
                      },
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
}
