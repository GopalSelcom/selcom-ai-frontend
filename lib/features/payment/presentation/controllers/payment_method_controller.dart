import 'package:get/get.dart';
import '../../../../core/data/models/user_profile_models.dart';
import '../../../../features/profile/domain/repositories/profile_repository.dart';

class PaymentMethodController extends GetxController {
  final ProfileRepository profileRepository;

  PaymentMethodController({required this.profileRepository});

  final paymentMethods = <PaymentMethodModel>[].obs;
  final Rxn<PaymentMethodModel> selectedPayment = Rxn<PaymentMethodModel>();
  final walletBalance = Rxn<WalletBalanceModel>();
  final isLoading = false.obs;
  final error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    await Future.wait([
      loadPaymentMethods(),
      loadWalletBalance(),
    ]);
    isLoading.value = false;
  }

  Future<void> loadWalletBalance() async {
    // TODO: Skip API call for now, as it's still pending on backend
    /*
    final result = await profileRepository.getWalletBalance();
    result.fold(
      (_) => null,
      (balance) => walletBalance.value = balance,
    );
    */
  }

  Future<void> loadPaymentMethods() async {
    error.value = '';
    
    final result = await profileRepository.getPaymentMethods();
    
    result.fold(
      (failure) {
        error.value = failure.message;
        // Fallback to dummy if API fails, as requested in existing code
        paymentMethods.assignAll(_dummyPayments());
      },
      (list) {
        if (list.isEmpty) {
          paymentMethods.assignAll(_dummyPayments());
        } else {
          paymentMethods.assignAll(list);
        }
      },
    );
    
    if (selectedPayment.value == null && paymentMethods.isNotEmpty) {
      selectedPayment.value = paymentMethods.first;
    }
    
    isLoading.value = false;
  }

  void selectPaymentMethod(PaymentMethodModel method) {
    selectedPayment.value = method;
  }

  List<PaymentMethodModel> _dummyPayments() {
    return [
      PaymentMethodModel(id: 'wallet', label: 'Wallet', type: 'wallet'),
      PaymentMethodModel(id: 'card', label: 'Mastercard / Visa', type: 'card'),
      PaymentMethodModel(id: 'selcom_pesa', label: 'Selcom Pesa', type: 'selcom_pesa'),
    ];
  }
}
