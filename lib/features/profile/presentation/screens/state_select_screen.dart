import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';

class CountryStates {
  static const Map<String, List<String>> _statesMap = {
    'TZ': [
      'Dar es Salaam',
      'Dodoma',
      'Arusha',
      'Mwanza',
      'Kilimanjaro',
      'Zanzibar',
      'Tanga',
      'Morogoro',
      'Iringa',
      'Mbeya',
      'Kigoma',
      'Tabora',
      'Ruvuma',
      'Shinyanga',
      'Kagera',
      'Mara',
      'Singida',
      'Manyara',
      'Lindi',
      'Mtwara',
      'Pwani',
      'Rukwa',
      'Katavi',
      'Njombe',
      'Geita',
      'Simiyu',
      'Songwe'
    ],
    'US': [
      'Alabama', 'Alaska', 'Arizona', 'Arkansas', 'California', 'Colorado',
      'Connecticut', 'Delaware', 'Florida', 'Georgia', 'Hawaii', 'Idaho',
      'Illinois', 'Indiana', 'Iowa', 'Kansas', 'Kentucky', 'Louisiana',
      'Maine', 'Maryland', 'Massachusetts', 'Michigan', 'Minnesota',
      'Mississippi', 'Missouri', 'Montana', 'Nebraska', 'Nevada',
      'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
      'North Carolina', 'North Dakota', 'Ohio', 'Oklahoma', 'Oregon',
      'Pennsylvania', 'Rhode Island', 'South Carolina', 'South Dakota',
      'Tennessee', 'Texas', 'Utah', 'Vermont', 'Virginia', 'Washington',
      'West Virginia', 'Wisconsin', 'Wyoming'
    ],
    'IN': [
      'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
      'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
      'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
      'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab', 'Rajasthan',
      'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura', 'Uttar Pradesh',
      'Uttarakhand', 'West Bengal', 'Delhi'
    ],
    'GB': [
      'England', 'Scotland', 'Wales', 'Northern Ireland'
    ],
    'KE': [
      'Nairobi', 'Mombasa', 'Kisumu', 'Nakuru', 'Eldoret', 'Kiambu', 'Kakamega',
      'Machakos', 'Nyeri', 'Kilifi', 'Kericho', 'Uasin Gishu', 'Kajiado',
      'Laikipia', 'Trans Nzoia'
    ],
    'UG': [
      'Central Region (Kampala)', 'Eastern Region', 'Northern Region', 'Western Region'
    ],
    'CA': [
      'Alberta', 'British Columbia', 'Manitoba', 'New Brunswick',
      'Newfoundland and Labrador', 'Nova Scotia', 'Ontario',
      'Prince Edward Island', 'Quebec', 'Saskatchewan'
    ]
  };

  static List<String> getStatesForCountry(String countryCode) {
    final code = countryCode.toUpperCase();
    if (_statesMap.containsKey(code)) {
      return _statesMap[code]!;
    }
    // Fallback: general regions
    return [
      'Central Region',
      'Northern Region',
      'Eastern Region',
      'Western Region',
      'Southern Region',
      'State Region A',
      'State Region B',
      'State Region C',
    ];
  }
}

class StateSelectScreen extends StatefulWidget {
  final String countryCode;
  final String? selectedState;
  const StateSelectScreen({
    super.key,
    required this.countryCode,
    this.selectedState,
  });

  @override
  State<StateSelectScreen> createState() => _StateSelectScreenState();
}

class _StateSelectScreenState extends State<StateSelectScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  late final List<String> _allStates;

  @override
  void initState() {
    super.initState();
    _allStates = CountryStates.getStatesForCountry(widget.countryCode);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _filteredStates {
    final query = _searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return _allStates;
    }
    return _allStates
        .where((state) => state.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          AppProfileHeader(
            title: "Select State",
            onBack: () => Get.back(),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              child: Column(
                children: [
                  Obx(
                    () => AppTextField(
                      hintText: "Search state...",
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
                        final list = _filteredStates;
                        if (list.isEmpty) {
                          return Center(
                            child: Text(
                              "No states found",
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
                            final stateName = list[index];
                            final isSelected = widget.selectedState == stateName;
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 4.h,
                              ),
                              title: Text(
                                stateName,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primaryButton : AppColors.textHeading,
                                ),
                              ),
                              trailing: isSelected
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryButton,
                                    )
                                  : null,
                              onTap: () {
                                Get.back(result: stateName);
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
