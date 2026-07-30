import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_profile_header.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../data/models/state_response.dart';
import '../controllers/add_card_controller.dart';

class StateSelectScreen extends StatefulWidget {
  final List<StateResponse> states;
  final StateResponse? selectedState;

  const StateSelectScreen({
    super.key,
    required this.states,
    this.selectedState,
  });

  @override
  State<StateSelectScreen> createState() => _StateSelectScreenState();
}

class _StateSelectScreenState extends State<StateSelectScreen> {
  final TextEditingController _searchController = TextEditingController();
  final RxString _searchQuery = ''.obs;
  late final AddCardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<AddCardController>();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StateResponse> get _filteredStates {
    final query = _searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      return widget.states;
    }
    return widget.states
        .where((state) => (state.name ?? '').toLowerCase().contains(query))
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
                        if (controller.isLoadingStates.value) {
                          return const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryButton),
                            ),
                          );
                        }

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
                            final state = list[index];
                            final isSelected = widget.selectedState?.id == state.id;
                            return ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 4.h,
                              ),
                              title: Text(
                                state.name ?? '',
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
                                Get.back(result: state);
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
