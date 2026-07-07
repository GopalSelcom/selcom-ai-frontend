class GoWalletCardModel {
  final String cardToken;
  final String maskedCard;

  GoWalletCardModel({
    required this.cardToken,
    required this.maskedCard,
  });

  factory GoWalletCardModel.fromJson(Map<String, dynamic> json) {
    return GoWalletCardModel(
      cardToken: json['card_token'] as String? ?? '',
      maskedCard: json['masked_card'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'card_token': cardToken,
      'masked_card': maskedCard,
    };
  }
}
