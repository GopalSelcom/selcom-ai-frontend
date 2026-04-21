import 'package:get/get.dart';
import '../../domain/entities/payment_card.dart';

class CardDetailsController extends GetxController {
  final PaymentCard card;

  CardDetailsController({
    required this.card,
  });

  final isCvvHidden = true.obs;
  final isDeleteLoading = false.obs;

  void toggleCvvVisibility() {
    isCvvHidden.value = !isCvvHidden.value;
  }

  Future<bool> deleteCard() async {
    if (isDeleteLoading.value) return false;

    isDeleteLoading.value = true;
    try {
      // TODO(api): call delete-card endpoint/usecase here.
      await Future.delayed(const Duration(seconds: 3));
      return true;
    } finally {
      isDeleteLoading.value = false;
    }
  }
}
